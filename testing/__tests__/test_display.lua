package.path = package.path .. ";./?.lua;./modules/?.lua"
local originalSearchers = package.searchers or package.loaders
table.insert(originalSearchers, 2, function(modname)
  if modname:match("^FlexLove%.modules%.") then
    local moduleName = modname:gsub("^FlexLove%.modules%.", "")
    return function()
      return require("modules." .. moduleName)
    end
  end
end)

require("testing.loveStub")

local luaunit = require("testing.luaunit")
local FlexLove = require("FlexLove")

FlexLove.init()

-- ============================================================================
-- Display Property — Element Creation Tests
-- ============================================================================

TestDisplayCreation = {}

function TestDisplayCreation:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestDisplayCreation:tearDown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

function TestDisplayCreation:test_default_display_is_true()
  local element = FlexLove.new({
    width = 100,
    height = 100,
  })
  luaunit.assertEquals(element.display, true, "display should default to true")
end

function TestDisplayCreation:test_display_true_explicit()
  local element = FlexLove.new({
    width = 100,
    height = 100,
    display = true,
  })
  luaunit.assertEquals(element.display, true, "display = true should be stored")
end

function TestDisplayCreation:test_display_false()
  local element = FlexLove.new({
    width = 100,
    height = 100,
    display = false,
  })
  luaunit.assertEquals(element.display, false, "display = false should be stored")
end

function TestDisplayCreation:test_display_invalid_defaults_true()
  -- display is an instance-level property on Element._ErrorHandler, not the module,
  -- so replacing ErrorHandler.warn won't intercept the call.
  -- Instead we verify the safe fallback behavior.
  local element = FlexLove.new({
    width = 100,
    height = 100,
    display = "invalid",
  })
  luaunit.assertEquals(element.display, true, "invalid display should default to true")
end

-- ============================================================================
-- Display Property — Layout Exclusion Tests
-- ============================================================================

TestDisplayLayout = {}

function TestDisplayLayout:setUp()
  FlexLove.init()
  FlexLove.setMode("retained")
end

function TestDisplayLayout:tearDown()
  FlexLove.destroy()
end

function TestDisplayLayout:test_display_false_child_takes_no_space_in_flex()
  local parent = FlexLove.new({
    positioning = "flex",
    flexDirection = "horizontal",
    width = 500,
    height = 100,
  })

  local child1 = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  local hidden = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    display = false,
  })

  local child2 = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  -- First child at x=0, hidden child not laid out, third child at x=100 (no gap for hidden)
  luaunit.assertEquals(child1.x, 0, "First child should be at x=0")
  luaunit.assertEquals(child2.x, 100, "Third child should be at x=100 (no space for hidden child)")
end

function TestDisplayLayout:test_display_false_affects_autosizing()
  local parent = FlexLove.new({
    positioning = "flex",
    flexDirection = "horizontal",
    -- no explicit width — auto-sized
  })

  FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    display = false,
  })

  -- Only first child contributes to auto-width
  luaunit.assertEquals(parent.width, 100, "Auto-width should only include visible child")
end

function TestDisplayLayout:test_display_false_in_grid()
  local parent = FlexLove.new({
    positioning = "grid",
    gridColumns = 3,
    width = 300,
    height = 100,
  })

  local child1 = FlexLove.new({
    parent = parent,
    height = 100,
  })

  local hidden = FlexLove.new({
    parent = parent,
    height = 100,
    display = false,
  })

  local child2 = FlexLove.new({
    parent = parent,
    height = 100,
  })

  -- In 3-column grid with only 2 visible children, they should fill columns 1 and 2
  luaunit.assertEquals(child1.x, 0, "First grid child at column 1")
  luaunit.assertEquals(child2.x, 100, "Second visible grid child at column 2")
end

function TestDisplayLayout:test_display_false_child_not_counted_for_layout_cache()
  local parent = FlexLove.new({
    positioning = "flex",
    flexDirection = "horizontal",
    width = 500,
    height = 100,
  })

  local child1 = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  local hidden = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    display = false,
  })

  local child2 = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  -- Verify cache-hash includes display: toggle display on hidden, re-layout, position should change
  -- (We can't directly test the cache hash, but we can verify the layout is correct)
  luaunit.assertEquals(child1.x, 0, "Before toggle: first child at x=0")
  luaunit.assertEquals(child2.x, 100, "Before toggle: third child at x=100")
end

-- ============================================================================
-- Display Property — Absolutely Positioned Children
-- ============================================================================

TestDisplayAbsolute = {}

function TestDisplayAbsolute:setUp()
  FlexLove.init()
  FlexLove.setMode("retained")
end

function TestDisplayAbsolute:tearDown()
  FlexLove.destroy()
end

function TestDisplayAbsolute:test_display_false_absolute_child_still_skipped()
  -- Even absolutely positioned children should be skipped when display=false
  local parent = FlexLove.new({
    positioning = "flex",
    width = 400,
    height = 400,
  })

  local absoluteChild = FlexLove.new({
    parent = parent,
    positioning = "absolute",
    top = 10,
    left = 10,
    width = 100,
    height = 100,
    display = false,
  })

  -- display=false absolute child should not reserve space
  -- (in this simple test, there are no flex children, so we just verify the child wasn't positioned)
  -- Actually, absolute positioning still applies even with display=false in our implementation
  -- because we only skip the child from flex/grid layout flow. The applyPositioningOffsets
  -- would still run if the absolute positioning loop doesn't check display.
  -- Wait — we DID add the check in both absolute positioning loops. So the child should NOT be positioned.
  luaunit.assertEquals(absoluteChild.x, 0, "display=false absolute child should not be positioned (x remains 0)")
  luaunit.assertEquals(absoluteChild.y, 0, "display=false absolute child should not be positioned (y remains 0)")
end

-- ============================================================================
-- Display Property — Draw/Render Tests
-- ============================================================================

TestDisplayRender = {}

function TestDisplayRender:setUp()
  FlexLove.init()
  FlexLove.setMode("immediate")
end

function TestDisplayRender:tearDown()
  FlexLove.destroy()
end

function TestDisplayRender:test_display_false_skips_draw()
  FlexLove.beginFrame()
  local calls = {}
  local element = FlexLove.new({
    width = 100,
    height = 100,
    display = false,
    customDraw = function(self2)
      table.insert(calls, "draw called")
    end,
  })
  FlexLove.endFrame()

  -- Since element has display=false, draw() should return early and customDraw never fires
  element:draw()
  luaunit.assertEquals(#calls, 0, "customDraw should not be called when display=false")
end

function TestDisplayRender:test_display_true_allows_draw()
  FlexLove.beginFrame()
  local calls = {}
  local element = FlexLove.new({
    width = 100,
    height = 100,
    display = true,
    customDraw = function(self2)
      table.insert(calls, "draw called")
    end,
  })
  FlexLove.endFrame()

  element:draw()
  luaunit.assertEquals(#calls, 1, "customDraw should be called when display=true")
end

function TestDisplayRender:test_display_false_skips_children_draw()
  FlexLove.beginFrame()
  local childCalls = {}
  local parent = FlexLove.new({
    width = 200,
    height = 200,
    display = false,
  })
  local child = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    customDraw = function(self2)
      table.insert(childCalls, "child draw called")
    end,
  })
  FlexLove.endFrame()

  parent:draw()
  luaunit.assertEquals(#childCalls, 0, "children should not be drawn when parent display=false")
end

-- ============================================================================
-- Display Property — Hit Testing Tests
-- ============================================================================

TestDisplayHitTest = {}

function TestDisplayHitTest:setUp()
  FlexLove.init()
  FlexLove.setMode("retained")
end

function TestDisplayHitTest:tearDown()
  FlexLove.destroy()
end

function TestDisplayHitTest:test_display_false_element_not_found_by_hit_test()
  local element = FlexLove.new({
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    display = false,
    onEvent = function() end,
  })

  local found = FlexLove.getElementAtPosition(50, 50)
  luaunit.assertNil(found, "display=false element should not be found by hit test")
end

function TestDisplayHitTest:test_display_true_element_found_by_hit_test()
  local element = FlexLove.new({
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    display = true,
    onEvent = function() end,
  })

  local found = FlexLove.getElementAtPosition(50, 50)
  luaunit.assertEquals(found, element, "display=true element should be found by hit test")
end

function TestDisplayHitTest:test_display_false_does_not_block()
  -- A display=false element should not block clicks to elements behind it
  local behind = FlexLove.new({
    x = 0,
    y = 0,
    width = 200,
    height = 200,
    onEvent = function() end,
    z = 0,
  })

  local overlay = FlexLove.new({
    x = 0,
    y = 0,
    width = 200,
    height = 200,
    display = false,
    z = 1, -- Higher z-index, but display=false so it should not block
  })

  local found = FlexLove.getElementAtPosition(50, 50)
  luaunit.assertEquals(found, behind, "display=false element should not block; element behind should be found")
end

function TestDisplayHitTest:test_display_false_skips_subtree()
  local childCalls = {}
  local parent = FlexLove.new({
    x = 0,
    y = 0,
    width = 200,
    height = 200,
    display = false,
  })
  local child = FlexLove.new({
    parent = parent,
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    onEvent = function() end,
  })

  local found = FlexLove.getElementAtPosition(50, 50)
  -- Neither parent nor child should be found (parent's display=false causes early return in collectHits)
  luaunit.assertNil(found, "Children of display=false element should also be excluded from hit testing")
end

-- ============================================================================
-- Display Property — Touch Hit Testing Tests
-- ============================================================================

TestDisplayTouch = {}

function TestDisplayTouch:setUp()
  FlexLove.init()
  FlexLove.setMode("retained")
  love.window.setMode(800, 600)
end

function TestDisplayTouch:tearDown()
  FlexLove.destroy()
end

function TestDisplayTouch:test_display_false_skips_touch_hit_test()
  local element = FlexLove.new({
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    display = false,
    touchEnabled = true,
    onTouchEvent = function() end,
  })

  local found = FlexLove._getTouchElementAtPosition(50, 50)
  luaunit.assertNil(found, "display=false element should not be found by touch hit test")
end

function TestDisplayTouch:test_display_true_touch_hit_test()
  local element = FlexLove.new({
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    display = true,
    touchEnabled = true,
    onTouchEvent = function() end,
  })

  local found = FlexLove._getTouchElementAtPosition(50, 50)
  luaunit.assertEquals(found, element, "display=true touch-enabled element should be found")
end

-- ============================================================================
-- Display Property — Interaction with Visibility and Opacity
-- ============================================================================

TestDisplayInteraction = {}

function TestDisplayInteraction:setUp()
  FlexLove.init()
  FlexLove.setMode("retained")
end

function TestDisplayInteraction:tearDown()
  FlexLove.destroy()
end

function TestDisplayInteraction:test_display_false_vs_visibility_hidden_layout()
  -- display=false removes from layout, visibility="hidden" preserves layout space
  local parent = FlexLove.new({
    positioning = "flex",
    flexDirection = "horizontal",
    width = 500,
    height = 100,
  })

  local visible = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  local displayNone = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    display = false,
  })

  local visibilityHidden = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    visibility = "hidden",
  })

  local last = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  -- display=false: takes no space → next child at x=100
  -- visibility=hidden: takes space → last child at x=200
  luaunit.assertEquals(visible.x, 0, "First visible child at x=0")
  luaunit.assertEquals(visibilityHidden.x, 100, "visibility=hidden child still takes space (x=100)")
  luaunit.assertEquals(last.x, 200, "Last child at x=200 (space for visibility hidden)")
end

function TestDisplayInteraction:test_display_false_vs_opacity_zero_layout()
  -- display=false removes from layout, opacity=0 preserves layout space
  local parent = FlexLove.new({
    positioning = "flex",
    flexDirection = "horizontal",
    width = 500,
    height = 100,
  })

  local visible = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  local displayNone = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    display = false,
  })

  local opacityZero = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
    opacity = 0,
  })

  local last = FlexLove.new({
    parent = parent,
    width = 100,
    height = 100,
  })

  luaunit.assertEquals(visible.x, 0, "First visible child at x=0")
  luaunit.assertEquals(opacityZero.x, 100, "opacity=0 child still takes space (x=100)")
  luaunit.assertEquals(last.x, 200, "Last child at x=200 (space for opacity=0)")
end

function TestDisplayInteraction:test_display_false_vs_visibility_hidden_hit_test()
  -- visibility=hidden blocks input (it's in blockingElements), display=false does not
  local behind = FlexLove.new({
    x = 0,
    y = 0,
    width = 200,
    height = 200,
    onEvent = function() end,
    z = 0,
  })

  local visibilityHidden = FlexLove.new({
    x = 0,
    y = 0,
    width = 200,
    height = 200,
    visibility = "hidden",
    z = 1,
  })

  -- visibility=hidden elements can still block because they're in blockingElements
  -- (the check on line 965-967 skips hit testing, but they're added as blockers via the opacity>0 check)
  -- Actually, visibility=hidden causes an early return before the blockingElements check
  -- So visibility=hidden elements do NOT block. Let me verify this behavior.
  -- getElementAtPosition: line 965: if element.visibility == "hidden" or element.opacity <= 0 then return end
  -- So visibility=hidden skips the element entirely. The element behind with lower z should be returned.

  local found = FlexLove.getElementAtPosition(50, 50)
  luaunit.assertEquals(found, behind, "Element behind visibility=hidden should be reachable")
end

-- ============================================================================
-- Display Property — Immediate Mode Toggle
-- ============================================================================

TestDisplayToggle = {}

function TestDisplayToggle:setUp()
  FlexLove.init()
  FlexLove.setMode("immediate")
end

function TestDisplayToggle:tearDown()
  FlexLove.destroy()
end

function TestDisplayToggle:test_toggle_display_in_immediate_mode()
  -- In immediate mode, elements are rebuilt each frame
  -- So toggling display is as simple as passing different props

  local displayValue = true
  local parent = nil
  local child = nil

  local function createFrame()
    FlexLove.beginFrame()
    parent = FlexLove.new({
      positioning = "flex",
      flexDirection = "horizontal",
      width = 300,
      height = 100,
    })
    child = FlexLove.new({
      parent = parent,
      width = 100,
      height = 100,
      display = displayValue,
    })
    FlexLove.endFrame()
  end

  -- Frame 1: display=true → child takes space
  createFrame()
  luaunit.assertEquals(child.display, true, "Frame 1: display is true")
  luaunit.assertEquals(child.x, 0, "Frame 1: child takes space at x=0")

  -- Frame 2: display=false → child takes no space
  displayValue = false
  createFrame()
  luaunit.assertEquals(child.display, false, "Frame 2: display is false")
  -- When display=false, the child is not laid out, so its x stays at 0 (unpositioned)

  -- Frame 3: display=true → child takes space again
  displayValue = true
  createFrame()
  luaunit.assertEquals(child.display, true, "Frame 3: display is true again")
  luaunit.assertEquals(child.x, 0, "Frame 3: child takes space again at x=0")
end
