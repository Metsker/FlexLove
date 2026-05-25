package.path = package.path .. ";./?.lua"
local originalSearchers = package.searchers or package.loaders
table.insert(originalSearchers, 2, function(modname)
  if modname == "FlexLove" then
    return loadfile("./init.lua")
  end
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
-- Display Property - CSS-Style API
-- ============================================================================

TestDisplayCreation = {}

function TestDisplayCreation:setUp()
  FlexLove.init()
end

function TestDisplayCreation:tearDown()
  FlexLove.destroy()
end

function TestDisplayCreation:test_default_display_is_flex()
  local element = FlexLove.new({ width = 100, height = 100 })
  luaunit.assertEquals(element.display, "flex")
end

function TestDisplayCreation:test_display_flex()
  local element = FlexLove.new({ display = "flex", width = 100, height = 100 })
  luaunit.assertEquals(element.display, "flex")
end

function TestDisplayCreation:test_display_grid()
  local element = FlexLove.new({ display = "grid", width = 100, height = 100, gridColumns = 2, gridRows = 2 })
  luaunit.assertEquals(element.display, "grid")
end

function TestDisplayCreation:test_display_none()
  local element = FlexLove.new({ display = "none", width = 100, height = 100 })
  luaunit.assertEquals(element.display, "none")
end

function TestDisplayCreation:test_invalid_display_defaults_to_flex()
  local element = FlexLove.new({ display = "invalid", width = 100, height = 100 })
  luaunit.assertEquals(element.display, "flex")
end

-- ============================================================================
-- Display: none excludes element from layout
-- ============================================================================

TestDisplayLayout = {}

function TestDisplayLayout:setUp()
  FlexLove.init()
end

function TestDisplayLayout:tearDown()
  FlexLove.destroy()
end

function TestDisplayLayout:test_display_none_child_takes_no_space_in_flex()
  local parent = FlexLove.new({
    display = "flex",
    flexDirection = "row",
    width = 500,
    height = 100,
    children = {
      { id = "first", width = 100, height = 100 },
      { id = "hidden", display = "none", width = 200, height = 100 },
      { id = "last", width = 100, height = 100 },
    },
  })

  local first = parent.children[1]
  local last = parent.children[3]

  luaunit.assertEquals(first.x, parent.x)
  -- The hidden child should be skipped; last starts where first ended.
  luaunit.assertEquals(last.x, first.x + first.width)
end

function TestDisplayLayout:test_display_none_toggling_at_runtime()
  local parent = FlexLove.new({
    display = "flex",
    flexDirection = "row",
    width = 300,
    height = 100,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  local b = parent.children[2]
  b.display = "none"
  parent:layoutChildren()
  -- After hiding, b is excluded and a remains at start.
  luaunit.assertEquals(parent.children[1].x, parent.x)
end

function TestDisplayLayout:test_display_none_preserves_flex_props_for_later_flip()
  -- Construct hidden with flex props pre-configured. CSS semantics: those
  -- props stay on the element and take effect when display flips to "flex".
  local parent = FlexLove.new({
    display = "none",
    flexDirection = "column",
    width = 100,
    height = 300,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  luaunit.assertEquals(parent.flexDirection, "column")

  parent.display = "flex"
  parent:layoutChildren()

  local a = parent.children[1]
  local b = parent.children[2]
  -- Column direction: b stacks below a, not to the right of it.
  luaunit.assertEquals(b.x, a.x)
  luaunit.assertEquals(b.y, a.y + a.height)
end

function TestDisplayLayout:test_direct_flex_prop_mutation_takes_effect()
  -- The LayoutEngine pulls flex props from the element at the top of each
  -- layoutChildren pass, so direct field assignment is enough - no
  -- setProperty / invalidateLayout call required. Mirrors the visual-prop
  -- contract in docs/usage.md.
  local parent = FlexLove.new({
    display = "flex",
    flexDirection = "row",
    width = 300,
    height = 300,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  local a = parent.children[1]
  local b = parent.children[2]
  luaunit.assertEquals(b.x, a.x + a.width) -- row: side by side
  luaunit.assertEquals(b.y, a.y)

  parent.flexDirection = "column"
  parent:layoutChildren()

  -- After direct mutation, column direction: b stacks below a.
  luaunit.assertEquals(b.x, a.x)
  luaunit.assertEquals(b.y, a.y + a.height)
end

os.exit(luaunit.LuaUnit.run())
