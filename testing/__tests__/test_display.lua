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

function TestDisplayLayout:test_direct_gap_mutation_takes_effect()
  -- Covers the numeric layout-input category. `gap` flows through the
  -- pull-at-use-time block and the layoutInputsHash separately from the
  -- enum props, so a stale snapshot or missing hash entry would slip past
  -- the flexDirection test alone.
  local parent = FlexLove.new({
    display = "flex",
    flexDirection = "row",
    gap = 0,
    width = 300,
    height = 100,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  local a = parent.children[1]
  local b = parent.children[2]
  luaunit.assertEquals(b.x, a.x + a.width) -- gap = 0: children touch

  parent.gap = 20
  parent:layoutChildren()

  luaunit.assertEquals(b.x, a.x + a.width + 20)
end

function TestDisplayLayout:test_direct_justifyContent_mutation_takes_effect()
  -- `justifyContent` picks a specific code branch inside the flex math.
  -- Verifies the pulled value actually changes layout output, not just
  -- which field the engine reads from.
  local parent = FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "flex-start",
    width = 300,
    height = 100,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  local a = parent.children[1]
  luaunit.assertEquals(a.x, parent.x) -- flex-start: pinned to leading edge

  parent.justifyContent = "center"
  parent:layoutChildren()

  -- Two 50px children in a 300px container: 200px free space, 100px
  -- leading offset under "center".
  luaunit.assertEquals(a.x, parent.x + 100)
end

function TestDisplayLayout:test_FlexLove_update_drives_reactive_layout()
  -- The actual frame-driven contract: edit a field, see it next frame.
  -- `FlexLove.update` walks topElements and calls `layoutChildren` so
  -- direct mutation propagates without an explicit `layoutChildren()` or
  -- `invalidateLayout()` call by the user. Mirrors `Renderer:draw`
  -- running every frame.
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

  local a = parent.children[1]
  local b = parent.children[2]
  luaunit.assertEquals(b.x, a.x + a.width) -- row baseline

  parent.flexDirection = "column"
  FlexLove.update(0)

  -- After the frame's update pass, layout reflects the mutation - no
  -- manual layoutChildren call.
  luaunit.assertEquals(b.x, a.x)
  luaunit.assertEquals(b.y, a.y + a.height)
end

function TestDisplayLayout:test_FlexLove_update_propagates_deep_mutation()
  -- A grandchild mutates its own layout-input prop. The topElement's
  -- cache hash doesn't see anything diff at its level - the change is
  -- two levels deep. The "always recurse on skip" path in LayoutEngine
  -- ensures the grandchild's own cache still gets a chance to detect it.
  local root = FlexLove.new({
    display = "flex",
    width = 400,
    height = 400,
    children = {
      {
        id = "mid",
        display = "flex",
        width = 400,
        height = 400,
        children = {
          {
            id = "grand",
            display = "flex",
            flexDirection = "row",
            width = 200,
            height = 200,
            children = {
              { id = "leaf1", width = 50, height = 50 },
              { id = "leaf2", width = 50, height = 50 },
            },
          },
        },
      },
    },
  })

  local grand = root.children[1].children[1]
  local leaf1 = grand.children[1]
  local leaf2 = grand.children[2]
  luaunit.assertEquals(leaf2.x, leaf1.x + leaf1.width) -- grand is row

  grand.flexDirection = "column"
  FlexLove.update(0)

  -- The grandchild's flexDirection flip takes effect through the cache's
  -- skip-but-recurse path.
  luaunit.assertEquals(leaf2.x, leaf1.x)
  luaunit.assertEquals(leaf2.y, leaf1.y + leaf1.height)
end

function TestDisplayLayout:test_direct_grid_columns_mutation_takes_effect()
  -- Grid props go through a separate engine code path (Grid.layoutGridItems).
  -- The pull-at-use-time block covers gridRows/gridColumns/columnGap/rowGap
  -- too; this test guards that branch.
  local parent = FlexLove.new({
    display = "grid",
    gridRows = 2,
    gridColumns = 1,
    width = 400,
    height = 200,
    children = {
      { id = "a", width = 50, height = 50 },
      { id = "b", width = 50, height = 50 },
    },
  })

  local b = parent.children[2]
  -- 2 rows, 1 column: each cell 400x100, b sits below a.
  luaunit.assertEquals(b.x, 0)
  luaunit.assertEquals(b.y, 100)

  parent.gridColumns = 2
  parent:layoutChildren()

  -- 2 rows, 2 columns now: each cell 200x100, b fills column 2 of row 1.
  luaunit.assertEquals(b.x, 200)
  luaunit.assertEquals(b.y, 0)
end

os.exit(luaunit.LuaUnit.run())
