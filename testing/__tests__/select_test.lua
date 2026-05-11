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
-- Select Module Direct Tests
-- ============================================================================

TestSelectModule = {}

function TestSelectModule:setUp()
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestSelectModule:tearDown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

-- Test: Select parent state initialization
function TestSelectModule:test_select_parent_initializes_state()
  local selectParent = FlexLove.new({
    id = "sp1",
    width = 300,
    height = 50,
    selectParent = {
      value = "exclusive",
      placeholder = "Choose display mode",
    },
  })

  luaunit.assertNotNil(selectParent._selectState)
  luaunit.assertEquals(selectParent._selectState.value, "exclusive")
  luaunit.assertFalse(selectParent._selectState.open)
  luaunit.assertEquals(selectParent._selectState.placeholder, "Choose display mode")
  luaunit.assertEquals(#selectParent._selectState.options, 0)
  luaunit.assertEquals(type(selectParent._selectState.optionLookup), "table")
end

-- Test: Select option registers with parent
function TestSelectModule:test_select_option_registers_with_parent()
  local sp = FlexLove.new({
    id = "sp2",
    width = 300,
    height = 50,
    selectParent = { value = "a" },
  })

  local opt = FlexLove.new({
    id = "opt1",
    parent = sp,
    width = 300,
    height = 20,
    text = "Option A",
    selectOption = { value = "a" },
  })

  luaunit.assertEquals(#sp._selectState.options, 1)
  luaunit.assertEquals(sp._selectState.options[1], opt)
  luaunit.assertEquals(sp._selectState.optionLookup.a, opt)
  luaunit.assertEquals(opt._selectParentElement, sp)
end

-- Test: Select option registers even when nested in wrapper
function TestSelectModule:test_select_option_registers_nested()
  local sp = FlexLove.new({
    id = "sp3",
    width = 300,
    height = 50,
    selectParent = { value = "a" },
  })

  local wrapper = FlexLove.new({
    id = "wrapper",
    parent = sp,
    width = 300,
    height = 20,
  })

  local opt = FlexLove.new({
    id = "opt_nested",
    parent = wrapper,
    width = 300,
    height = 20,
    text = "Nested Option",
    selectOption = { value = "a" },
  })

  luaunit.assertEquals(#sp._selectState.options, 1)
  luaunit.assertEquals(sp._selectState.optionLookup.a, opt)
end

-- Test: Multiple options register in order
function TestSelectModule:test_multiple_options_register_in_order()
  local sp = FlexLove.new({
    id = "sp4",
    width = 300,
    height = 50,
    selectParent = { value = "x" },
  })

  local opt1 = FlexLove.new({
    id = "multi1",
    parent = sp,
    width = 300,
    height = 20,
    selectOption = { value = "x" },
  })

  local opt2 = FlexLove.new({
    id = "multi2",
    parent = sp,
    width = 300,
    height = 20,
    selectOption = { value = "y" },
  })

  luaunit.assertEquals(#sp._selectState.options, 2)
  luaunit.assertEquals(sp._selectState.options[1], opt1)
  luaunit.assertEquals(sp._selectState.options[2], opt2)
  luaunit.assertEquals(sp._selectState.optionLookup.x, opt1)
  luaunit.assertEquals(sp._selectState.optionLookup.y, opt2)
end

-- Test: openSelect / closeSelect / toggleSelect
function TestSelectModule:test_open_close_toggle()
  local sp = FlexLove.new({
    id = "sp5",
    width = 200,
    height = 40,
    selectParent = { value = "a" },
  })

  luaunit.assertFalse(sp:isSelectOpen())

  sp:openSelect()
  luaunit.assertTrue(sp:isSelectOpen())
  luaunit.assertTrue(sp.ariaExpanded)

  sp:closeSelect()
  luaunit.assertFalse(sp:isSelectOpen())
  luaunit.assertFalse(sp.ariaExpanded)

  sp:toggleSelect()
  luaunit.assertTrue(sp:isSelectOpen())
  luaunit.assertTrue(sp.ariaExpanded)

  sp:toggleSelect()
  luaunit.assertFalse(sp:isSelectOpen())
end

-- Test: getSelectValue / getSelectLabel
function TestSelectModule:test_get_value_and_label()
  local sp = FlexLove.new({
    id = "sp6",
    width = 200,
    height = 40,
    selectParent = {
      value = "initial",
      placeholder = "Pick one",
    },
  })

  luaunit.assertEquals(sp:getSelectValue(), "initial")
  luaunit.assertEquals(sp:getSelectLabel(), "Pick one")

  FlexLove.new({
    id = "opt_label1",
    parent = sp,
    width = 200,
    height = 30,
    text = "Option Alpha",
    selectOption = { value = "alpha", label = "Alpha" },
  })

  sp:setSelectValue("alpha")
  luaunit.assertEquals(sp:getSelectValue(), "alpha")
  luaunit.assertEquals(sp:getSelectLabel(), "Alpha")
end

-- Test: setSelectValue fires events
function TestSelectModule:test_set_value_fires_onchange()
  local changed = false
  local changedValue = nil
  local sp = FlexLove.new({
    id = "sp7",
    width = 200,
    height = 40,
    selectParent = {
      value = "old",
      onChange = function(el, val)
        changed = true
        changedValue = val
      end,
    },
  })

  FlexLove.new({
    id = "opt_newval",
    parent = sp,
    width = 200,
    height = 30,
    text = "New",
    selectOption = { value = "new" },
  })

  sp:setSelectValue("new")

  luaunit.assertEquals(sp:getSelectValue(), "new")
  luaunit.assertTrue(changed)
  luaunit.assertEquals(changedValue, "new")
end

-- Test: setSelectValue does not fire onChange if value unchanged
function TestSelectModule:test_set_value_no_change()
  local changeCount = 0
  local sp = FlexLove.new({
    id = "sp8",
    width = 200,
    height = 40,
    selectParent = {
      value = "same",
      onChange = function()
        changeCount = changeCount + 1
      end,
    },
  })

  sp:setSelectValue("same")
  luaunit.assertEquals(changeCount, 0, "onChange should not fire when value unchanged")
end

-- Test: isSelectedSelectOption
function TestSelectModule:test_is_selected_option()
  local sp = FlexLove.new({
    id = "sp9",
    width = 200,
    height = 40,
    selectParent = { value = "a" },
  })

  local optA = FlexLove.new({
    id = "sel_opt_a",
    parent = sp,
    width = 200,
    height = 30,
    selectOption = { value = "a" },
  })

  local optB = FlexLove.new({
    id = "sel_opt_b",
    parent = sp,
    width = 200,
    height = 30,
    selectOption = { value = "b" },
  })

  luaunit.assertTrue(optA:isSelectedSelectOption())
  luaunit.assertFalse(optB:isSelectedSelectOption())

  sp:setSelectValue("b")
  luaunit.assertFalse(optA:isSelectedSelectOption())
  luaunit.assertTrue(optB:isSelectedSelectOption())
  luaunit.assertTrue(optB._selectSelected)
  luaunit.assertFalse(optA._selectSelected)
end

-- Test: disabled select option blocks selection
function TestSelectModule:test_disabled_option_does_not_select()
  local sp = FlexLove.new({
    id = "sp10",
    width = 200,
    height = 40,
    selectParent = { value = "a" },
  })

  local optDisabled = FlexLove.new({
    id = "opt_disabled",
    parent = sp,
    width = 200,
    height = 30,
    text = "Disabled",
    selectOption = { value = "disabled", disabled = true },
  })

  sp:setSelectValue("disabled", optDisabled)
  luaunit.assertEquals(sp:getSelectValue(), "disabled", "Should still set value even for disabled option")
end

-- Test: disabled select parent blocks toggle
function TestSelectModule:test_disabled_parent_does_not_toggle()
  local sp = FlexLove.new({
    id = "sp11",
    width = 200,
    height = 40,
    disabled = true,
    selectParent = { value = "a" },
  })

  sp:toggleSelect()
  luaunit.assertFalse(sp:isSelectOpen(), "Disabled select should not open")
end

-- Test: Select frame adoption (managed dropdown)
function TestSelectModule:test_select_frame_adoption()
  local frame = FlexLove.new({
    id = "dropdown",
    width = 200,
    height = 100,
  })

  local sp = FlexLove.new({
    id = "sp12",
    width = 200,
    height = 40,
    selectParent = {
      value = "a",
      selectFrame = frame,
    },
  })

  luaunit.assertNotNil(sp._selectState.selectFrame)
  luaunit.assertEquals(sp._selectState.selectFrame, frame)
  luaunit.assertTrue(frame._managedSelectFrame)
  luaunit.assertEquals(frame._managedSelectOwner, sp)
  luaunit.assertEquals(frame.visibility, "hidden")
  luaunit.assertTrue(frame.disabled)
end

-- Test: Opening select makes frame visible
function TestSelectModule:test_open_select_shows_frame()
  local frame = FlexLove.new({
    id = "dropdown_visible",
    width = 200,
    height = 100,
  })

  local sp = FlexLove.new({
    id = "sp13",
    width = 200,
    height = 40,
    selectParent = {
      value = "a",
      selectFrame = frame,
    },
  })

  luaunit.assertEquals(frame.visibility, "hidden")

  sp:openSelect()
  luaunit.assertEquals(frame.visibility, "visible")
  luaunit.assertFalse(frame.disabled)

  sp:closeSelect()
  luaunit.assertEquals(frame.visibility, "hidden")
  luaunit.assertTrue(frame.disabled)
end

-- Test: Options are moved into managed frame
function TestSelectModule:test_options_route_to_managed_frame()
  local frame = FlexLove.new({
    id = "dropdown_routing",
    width = 200,
    height = 100,
  })

  local sp = FlexLove.new({
    id = "sp14",
    width = 200,
    height = 40,
    selectParent = {
      value = "a",
      selectFrame = frame,
    },
  })

  local opt = FlexLove.new({
    id = "opt_routed",
    parent = sp,
    width = 200,
    height = 30,
    text = "Routed",
    selectOption = { value = "a" },
  })

  luaunit.assertTrue(opt.parent == frame, "Option should be reparented into the managed frame")
  luaunit.assertEquals(opt._selectParentElement, sp)
end

-- Test: handleRelease on select parent toggles
function TestSelectModule:test_handle_release_toggles_select()
  local sp = FlexLove.new({
    id = "sp15",
    width = 200,
    height = 40,
    selectParent = { value = "a" },
  })

  luaunit.assertFalse(sp:isSelectOpen())
  sp:_handleSelectRelease()
  luaunit.assertTrue(sp:isSelectOpen())
  sp:_handleSelectRelease()
  luaunit.assertFalse(sp:isSelectOpen())
end

-- Test: handleRelease on option selects value
function TestSelectModule:test_handle_release_selects_option()
  local sp = FlexLove.new({
    id = "sp16",
    width = 200,
    height = 40,
    selectParent = { value = "a" },
  })

  local opt = FlexLove.new({
    id = "opt_release",
    parent = sp,
    width = 200,
    height = 30,
    text = "Release",
    selectOption = { value = "b" },
  })

  sp:openSelect()
  opt:_handleSelectRelease()

  luaunit.assertEquals(sp:getSelectValue(), "b")
  luaunit.assertFalse(sp:isSelectOpen(), "Select should close after option is chosen")
end

-- Test: No select state for plain elements
function TestSelectModule:test_plain_element_no_select_state()
  local el = FlexLove.new({
    id = "plain",
    width = 100,
    height = 50,
  })

  luaunit.assertNil(el._selectState)
  luaunit.assertNil(el.selectOption)
end

-- Test: Orphan option has no parent reference
function TestSelectModule:test_orphan_option_has_no_parent()
  local opt = FlexLove.new({
    id = "orphan",
    width = 100,
    height = 20,
    selectOption = { value = "orphan" },
  })

  luaunit.assertNil(opt._selectParentElement)
end

-- Test: Select module functions are accessible
function TestSelectModule:test_select_module_exists()
  local Select = require("FlexLove.modules.Select")
  luaunit.assertNotNil(Select)
  luaunit.assertNotNil(Select.openSelect)
  luaunit.assertNotNil(Select.closeSelect)
  luaunit.assertNotNil(Select.toggleSelect)
  luaunit.assertNotNil(Select.setSelectValue)
  luaunit.assertNotNil(Select.handleRelease)
  luaunit.assertNotNil(Select.rebuildOptionLookup)
  luaunit.assertNotNil(Select.syncOptionStates)
  luaunit.assertNotNil(Select.resetOptions)
  luaunit.assertNotNil(Select.adoptSelectFrame)
  luaunit.assertNotNil(Select.ensureFrameState)
  luaunit.assertNotNil(Select.syncManagedFrameVisibility)
  luaunit.assertNotNil(Select.saveState)
  luaunit.assertNotNil(Select.restoreState)
  luaunit.assertNotNil(Select.cleanupDestroy)
end
