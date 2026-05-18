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
-- Basic Children Prop Tests
-- ============================================================================

TestChildrenPropBasic = {}

function TestChildrenPropBasic:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestChildrenPropBasic:tearDown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

function TestChildrenPropBasic:test_children_prop_creates_children()
  local parent = FlexLove.new({
    id = "parent",
    width = 300,
    height = 200,
    children = {
      { text = "child1" },
      { text = "child2" },
    },
  })

  luaunit.assertEquals(#parent.children, 2)
  luaunit.assertEquals(parent.children[1].text, "child1")
  luaunit.assertEquals(parent.children[2].text, "child2")
end

function TestChildrenPropBasic:test_children_have_correct_parent()
  local parent = FlexLove.new({
    id = "parent",
    width = 300,
    height = 200,
    children = {
      { text = "A" },
      { text = "B" },
    },
  })

  luaunit.assertEquals(parent.children[1].parent, parent)
  luaunit.assertEquals(parent.children[2].parent, parent)
end

function TestChildrenPropBasic:test_new_returns_parent_element()
  local result = FlexLove.new({
    id = "parent",
    width = 300,
    height = 200,
    children = {
      { text = "A" },
      { text = "B" },
    },
  })

  luaunit.assertEquals(result.id, "parent")
  luaunit.assertTrue(result.children[1].text == "A")
end

function TestChildrenPropBasic:test_no_children_prop_unchanged()
  local element = FlexLove.new({
    id = "solo",
    width = 100,
    height = 100,
  })

  luaunit.assertEquals(#element.children, 0)
end

function TestChildrenPropBasic:test_empty_children_is_noop()
  local element = FlexLove.new({
    id = "empty",
    width = 100,
    height = 100,
    children = {},
  })

  luaunit.assertEquals(#element.children, 0)
end

-- ============================================================================
-- Nested Children Tests
-- ============================================================================

TestChildrenPropNested = {}

function TestChildrenPropNested:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestChildrenPropNested:tearDown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

function TestChildrenPropNested:test_two_level_nesting()
  local root = FlexLove.new({
    id = "root",
    width = 300,
    height = 200,
    children = {
      {
        text = "child",
        children = {
          { text = "grandchild" },
        },
      },
    },
  })

  luaunit.assertEquals(#root.children, 1)
  local child = root.children[1]
  luaunit.assertEquals(child.text, "child")
  luaunit.assertEquals(#child.children, 1)
  luaunit.assertEquals(child.children[1].text, "grandchild")
end

function TestChildrenPropNested:test_nested_parent_relationships()
  local root = FlexLove.new({
    id = "root",
    width = 300,
    height = 200,
    children = {
      {
        text = "child",
        children = {
          { text = "grandchild" },
        },
      },
    },
  })

  local child = root.children[1]
  local grandchild = child.children[1]

  luaunit.assertEquals(child.parent, root)
  luaunit.assertEquals(grandchild.parent, child)
end

function TestChildrenPropNested:test_three_level_nesting()
  local root = FlexLove.new({
    id = "root",
    width = 300,
    height = 200,
    children = {
      {
        text = "L1",
        children = {
          {
            text = "L2",
            children = {
              { text = "L3" },
            },
          },
        },
      },
    },
  })

  local L1 = root.children[1]
  local L2 = L1.children[1]
  local L3 = L2.children[1]

  luaunit.assertEquals(L1.text, "L1")
  luaunit.assertEquals(L2.text, "L2")
  luaunit.assertEquals(L3.text, "L3")
  luaunit.assertEquals(L3.parent, L2)
  luaunit.assertEquals(L2.parent, L1)
  luaunit.assertEquals(L1.parent, root)
end

function TestChildrenPropNested:test_multiple_children_at_each_level()
  local root = FlexLove.new({
    id = "root",
    width = 400,
    height = 300,
    children = {
      {
        text = "A",
        children = {
          { text = "A1" },
          { text = "A2" },
        },
      },
      {
        text = "B",
        children = {
          { text = "B1" },
        },
      },
    },
  })

  luaunit.assertEquals(#root.children, 2)
  luaunit.assertEquals(#root.children[1].children, 2)
  luaunit.assertEquals(#root.children[2].children, 1)
  luaunit.assertEquals(root.children[1].children[1].text, "A1")
  luaunit.assertEquals(root.children[1].children[2].text, "A2")
  luaunit.assertEquals(root.children[2].children[1].text, "B1")
end

-- ============================================================================
-- Validation and Edge Case Tests
-- ============================================================================

TestChildrenPropValidation = {}

function TestChildrenPropValidation:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
  self.warnings = {}
  self.originalWarn = FlexLove._ErrorHandler.warn
  FlexLove._ErrorHandler.warn = function(_, module, code, details)
    table.insert(self.warnings, { module = module, code = code, details = details })
  end
end

function TestChildrenPropValidation:tearDown()
  FlexLove._ErrorHandler.warn = self.originalWarn
  FlexLove.endFrame()
  FlexLove.destroy()
end

function TestChildrenPropValidation:test_invalid_children_type_warns()
  local element = FlexLove.new({
    id = "test",
    width = 100,
    height = 100,
    children = "invalid",
  })

  luaunit.assertEquals(#element.children, 0)
  luaunit.assertTrue(#self.warnings > 0)
  luaunit.assertEquals(self.warnings[1].code, "ELEM_010")
end

function TestChildrenPropValidation:test_nil_entries_skipped_with_warning()
  local element = FlexLove.new({
    id = "test",
    width = 100,
    height = 100,
    children = { nil, { text = "ok" }, nil },
  })

  luaunit.assertEquals(#element.children, 1)
  luaunit.assertEquals(element.children[1].text, "ok")
  -- Lua # on sparse array {nil, {text="ok"}, nil} returns 2, so trailing nil is not iterated
  luaunit.assertTrue(#self.warnings >= 1)
  for _, w in ipairs(self.warnings) do
    luaunit.assertEquals(w.code, "ELEM_011")
  end
end

function TestChildrenPropValidation:test_non_table_entries_skipped_with_warning()
  local element = FlexLove.new({
    id = "test",
    width = 100,
    height = 100,
    children = { 42, true, { text = "valid" } },
  })

  luaunit.assertEquals(#element.children, 1)
  luaunit.assertEquals(element.children[1].text, "valid")
  luaunit.assertTrue(#self.warnings >= 2)
  for _, w in ipairs(self.warnings) do
    luaunit.assertEquals(w.code, "ELEM_012")
  end
end

function TestChildrenPropValidation:test_empty_children_no_warning()
  local element = FlexLove.new({
    id = "test",
    width = 100,
    height = 100,
    children = {},
  })

  luaunit.assertEquals(#element.children, 0)
  luaunit.assertEquals(#self.warnings, 0)
end

function TestChildrenPropValidation:test_original_children_table_not_mutated()
  local originalChildren = {
    { text = "A" },
    { text = "B" },
  }

  FlexLove.new({
    id = "test",
    width = 100,
    height = 100,
    children = originalChildren,
  })

  -- Original tables should not have a parent key injected
  luaunit.assertNil(originalChildren[1].parent)
  luaunit.assertNil(originalChildren[2].parent)
  luaunit.assertEquals(#originalChildren, 2)
end

-- ============================================================================
-- Integration Tests (Issue #5 style example)
-- ============================================================================

TestChildrenPropIntegration = {}

function TestChildrenPropIntegration:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestChildrenPropIntegration:tearDown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

function TestChildrenPropIntegration:test_issue5_style_grid_example()
  local COLS = 4
  local headerCells = {}
  for i = 1, COLS do
    table.insert(headerCells, { text = "Col " .. i, width = "100%", height = 30 })
  end

  local bodyCells = {}
  for i = 1, 8 do
    table.insert(bodyCells, { text = "Cell " .. i, width = "100%", height = 20 })
  end

  local container = FlexLove.new({
    id = "grid_container",
    width = 400,
    height = 300,
    positioning = "flex",
    flexDirection = "vertical",
    gap = 8,
    padding = { horizontal = 16, vertical = 16 },
    children = {
      {
        text = "BILLS",
        textSize = 32,
        textAlign = "start",
        width = "100%",
      },
      {
        positioning = "grid",
        gridColumns = COLS,
        width = "100%",
        height = 30,
        columnGap = 4,
        children = headerCells,
      },
      {
        positioning = "grid",
        gridColumns = COLS,
        gridRows = 2,
        width = "100%",
        height = 48,
        columnGap = 4,
        rowGap = 4,
        children = bodyCells,
      },
    },
  })

  -- Verify structure
  luaunit.assertEquals(#container.children, 3)

  -- Title
  luaunit.assertEquals(container.children[1].text, "BILLS")

  -- Header grid
  local headerGrid = container.children[2]
  luaunit.assertEquals(headerGrid.positioning, "grid")
  luaunit.assertEquals(#headerGrid.children, COLS)
  for i, cell in ipairs(headerGrid.children) do
    luaunit.assertEquals(cell.text, "Col " .. i)
    luaunit.assertEquals(cell.parent, headerGrid)
  end

  -- Body grid
  local bodyGrid = container.children[3]
  luaunit.assertEquals(bodyGrid.positioning, "grid")
  luaunit.assertEquals(#bodyGrid.children, 8)
  for i, cell in ipairs(bodyGrid.children) do
    luaunit.assertEquals(cell.text, "Cell " .. i)
    luaunit.assertEquals(cell.parent, bodyGrid)
  end

  -- Verify parent chain
  luaunit.assertEquals(headerGrid.parent, container)
  luaunit.assertEquals(bodyGrid.parent, container)
end

function TestChildrenPropIntegration:test_children_with_flex_properties()
  local container = FlexLove.new({
    id = "flex_container",
    width = 300,
    height = 200,
    positioning = "flex",
    flexDirection = "horizontal",
    children = {
      { width = 100, height = 100, flexGrow = 1 },
      { width = 100, height = 100, flexGrow = 2 },
    },
  })

  luaunit.assertEquals(#container.children, 2)
  luaunit.assertEquals(container.children[1].flexGrow, 1)
  luaunit.assertEquals(container.children[2].flexGrow, 2)
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
