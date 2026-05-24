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
-- Display Property - CSS-Style API
-- ============================================================================

TestDisplayCreation = {}

function TestDisplayCreation:setUp()
  FlexLove.init()
end

function TestDisplayCreation:tearDown()
  FlexLove.destroy()
end

function TestDisplayCreation:test_default_display_is_block()
  local element = FlexLove.new({ width = 100, height = 100 })
  luaunit.assertEquals(element.display, "block")
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

function TestDisplayCreation:test_invalid_display_defaults_to_block()
  local element = FlexLove.new({ display = "invalid", width = 100, height = 100 })
  luaunit.assertEquals(element.display, "block")
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
    flexDirection = "horizontal",
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
    flexDirection = "horizontal",
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

os.exit(luaunit.LuaUnit.run())
