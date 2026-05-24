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

local utils = require("modules.utils")

-- ============================================================================
-- Test Suite: TextAlignVertical Enum
-- ============================================================================

TestTextAlignEnums = {}

function TestTextAlignEnums:setUp()
  FlexLove.init()
end

function TestTextAlignEnums:tearDown()
  FlexLove.destroy()
end

function TestTextAlignEnums:test_text_align_vertical_enum_exists()
  luaunit.assertNotNil(utils.enums.TextAlignVertical)
  luaunit.assertEquals(utils.enums.TextAlignVertical.START, "start")
  luaunit.assertEquals(utils.enums.TextAlignVertical.CENTER, "center")
  luaunit.assertEquals(utils.enums.TextAlignVertical.END, "end")
end

function TestTextAlignEnums:test_text_align_enum_unchanged()
  luaunit.assertEquals(utils.enums.TextAlign.START, "start")
  luaunit.assertEquals(utils.enums.TextAlign.CENTER, "center")
  luaunit.assertEquals(utils.enums.TextAlign.END, "end")
  luaunit.assertEquals(utils.enums.TextAlign.JUSTIFY, "justify")
end

-- ============================================================================
-- Test Suite: Element.new textAlign Parsing
-- ============================================================================

TestTextAlignParsing = {}

function TestTextAlignParsing:setUp()
  FlexLove.init()
end

function TestTextAlignParsing:tearDown()
  FlexLove.destroy()
end

local function createElement(props)
  local p = props or {}
  p.width = p.width or 100
  p.height = p.height or 50
  p.x = p.x or 0
  p.y = p.y or 0
  return FlexLove.new(p)
end

-- Simple string values (backward compatibility)
function TestTextAlignParsing:test_simple_start()
  local el = createElement({ textAlign = "start" })
  luaunit.assertEquals(el.textAlign, "start")
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_simple_center()
  local el = createElement({ textAlign = "center" })
  luaunit.assertEquals(el.textAlign, "center")
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_simple_end()
  local el = createElement({ textAlign = "end" })
  luaunit.assertEquals(el.textAlign, "end")
  luaunit.assertEquals(el.textAlignHorizontal, "end")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_no_text_align()
  local el = createElement({})
  luaunit.assertEquals(el.textAlign, "start")
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

-- Table format
function TestTextAlignParsing:test_table_both_center()
  local el = createElement({ textAlign = { horizontal = "center", vertical = "center" } })
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "center")
end

function TestTextAlignParsing:test_table_horizontal_start_vertical_end()
  local el = createElement({ textAlign = { horizontal = "start", vertical = "end" } })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "end")
end

function TestTextAlignParsing:test_table_horizontal_end_vertical_center()
  local el = createElement({ textAlign = { horizontal = "end", vertical = "center" } })
  luaunit.assertEquals(el.textAlignHorizontal, "end")
  luaunit.assertEquals(el.textAlignVertical, "center")
end

function TestTextAlignParsing:test_table_invalid_horizontal_warns()
  local el = createElement({ textAlign = { horizontal = "invalid" } })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_table_invalid_vertical_warns()
  local el = createElement({ textAlign = { horizontal = "center", vertical = "invalid" } })
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

-- Compound strings (9 combinations)
function TestTextAlignParsing:test_compound_top_left()
  local el = createElement({ textAlign = "top-left" })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_compound_top_center()
  local el = createElement({ textAlign = "top-center" })
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_compound_top_right()
  local el = createElement({ textAlign = "top-right" })
  luaunit.assertEquals(el.textAlignHorizontal, "end")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_compound_center_left()
  local el = createElement({ textAlign = "center-left" })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "center")
end

function TestTextAlignParsing:test_compound_center_center()
  local el = createElement({ textAlign = "center-center" })
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "center")
end

function TestTextAlignParsing:test_compound_center_right()
  local el = createElement({ textAlign = "center-right" })
  luaunit.assertEquals(el.textAlignHorizontal, "end")
  luaunit.assertEquals(el.textAlignVertical, "center")
end

function TestTextAlignParsing:test_compound_bottom_left()
  local el = createElement({ textAlign = "bottom-left" })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "end")
end

function TestTextAlignParsing:test_compound_bottom_center()
  local el = createElement({ textAlign = "bottom-center" })
  luaunit.assertEquals(el.textAlignHorizontal, "center")
  luaunit.assertEquals(el.textAlignVertical, "end")
end

function TestTextAlignParsing:test_compound_bottom_right()
  local el = createElement({ textAlign = "bottom-right" })
  luaunit.assertEquals(el.textAlignHorizontal, "end")
  luaunit.assertEquals(el.textAlignVertical, "end")
end

-- Invalid compound strings
function TestTextAlignParsing:test_invalid_compound_warns()
  local el = createElement({ textAlign = "invalid-compound" })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_invalid_vertical_part_warns()
  local el = createElement({ textAlign = "middle-right" })
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignParsing:test_backward_compat_textAlign_stored()
  -- self.textAlign should always store the original value
  local el1 = createElement({ textAlign = "center" })
  luaunit.assertEquals(el1.textAlign, "center")

  local el2 = createElement({ textAlign = { horizontal = "end", vertical = "center" } })
  -- For tables, self.textAlign stores the table reference
  luaunit.assertTrue(type(el2.textAlign) == "table")
  luaunit.assertEquals(el2.textAlign.horizontal, "end")
  luaunit.assertEquals(el2.textAlign.vertical, "center")

  local el3 = createElement({ textAlign = "top-left" })
  luaunit.assertEquals(el3.textAlign, "top-left")
end

-- ============================================================================
-- Test Suite: Backward Compatibility
-- ============================================================================

TestTextAlignBackwardCompat = {}

function TestTextAlignBackwardCompat:setUp()
  FlexLove.init()
end

function TestTextAlignBackwardCompat:tearDown()
  FlexLove.destroy()
end

function TestTextAlignBackwardCompat:test_old_string_textAlign_still_works()
  local el = createElement({ textAlign = "start", text = "Hello" })
  luaunit.assertEquals(el.textAlign, "start")
  luaunit.assertEquals(el.textAlignHorizontal, "start")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

function TestTextAlignBackwardCompat:test_justify_preserved()
  local el = createElement({ textAlign = "justify" })
  luaunit.assertEquals(el.textAlign, "justify")
  luaunit.assertEquals(el.textAlignHorizontal, "justify")
  luaunit.assertEquals(el.textAlignVertical, "start")
end

-- ============================================================================
-- Test Suite: Renderer drawText with new textAlign
-- ============================================================================

TestTextAlignRenderer = {}

function TestTextAlignRenderer:setUp()
  FlexLove.init()
end

function TestTextAlignRenderer:tearDown()
  FlexLove.destroy()
end

function TestTextAlignRenderer:test_draw_with_start_does_not_error()
  local el = createElement({ textAlign = "start", text = "Hello" })
  -- Should not throw
  local ok = pcall(function()
    el:draw(nil)
  end)
  luaunit.assertTrue(ok)
end

function TestTextAlignRenderer:test_draw_with_center_does_not_error()
  local el = createElement({ textAlign = "center", text = "Hello" })
  local ok = pcall(function()
    el:draw(nil)
  end)
  luaunit.assertTrue(ok)
end

function TestTextAlignRenderer:test_draw_with_table_textAlign_does_not_error()
  local el = createElement({ textAlign = { horizontal = "center", vertical = "center" }, text = "Hello" })
  local ok = pcall(function()
    el:draw(nil)
  end)
  luaunit.assertTrue(ok)
end

function TestTextAlignRenderer:test_draw_with_compound_textAlign_does_not_error()
  local el = createElement({ textAlign = "bottom-right", text = "Hello" })
  local ok = pcall(function()
    el:draw(nil)
  end)
  luaunit.assertTrue(ok)
end

function TestTextAlignRenderer:test_draw_with_wrapped_text_does_not_error()
  local el = createElement({
    textAlign = "center",
    text = "Hello world wrapped text",
    textWrap = "word",
    width = 50,
    height = 100,
  })
  local ok = pcall(function()
    el:draw(nil)
  end)
  luaunit.assertTrue(ok)
end

-- ============================================================================
-- Test Suite: Integration
-- ============================================================================

TestTextAlignIntegration = {}

function TestTextAlignIntegration:setUp()
  FlexLove.init()
end

function TestTextAlignIntegration:tearDown()
  FlexLove.destroy()
end

function TestTextAlignIntegration:test_element_with_textAlign_renders_in_immediate_mode()

  local element = FlexLove.new({
    id = "test_immediate_align",
    width = 200,
    height = 100,
    text = "Hello",
    textAlign = "center",
  })

  luaunit.assertNotNil(element)
  luaunit.assertEquals(element.textAlignHorizontal, "center")
  luaunit.assertEquals(element.textAlignVertical, "start")
end

function TestTextAlignIntegration:test_all_compound_strings_parse_without_error()
  local compounds = {
    "top-left",
    "top-center",
    "top-right",
    "center-left",
    "center-center",
    "center-right",
    "bottom-left",
    "bottom-center",
    "bottom-right",
  }
  for _, compound in ipairs(compounds) do
    local el = createElement({ textAlign = compound, text = "Test" })
    luaunit.assertNotNil(el.textAlignHorizontal, "Failed for " .. compound)
    luaunit.assertNotNil(el.textAlignVertical, "Failed for " .. compound)
  end
end

-- Run tests if this file is executed directly
if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
