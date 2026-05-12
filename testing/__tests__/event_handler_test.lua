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
local EventHandler = require("modules.EventHandler")
local InputEvent = require("modules.InputEvent")
local utils = require("modules.utils")
local ErrorHandler = require("modules.ErrorHandler")
ErrorHandler.init({})
EventHandler.init({ Performance = nil, ErrorHandler = ErrorHandler, InputEvent = InputEvent, utils = utils })

TestEventHandler = {}

-- Mock Context module
local MockContext = {
  getContext = function()
    return {}
  end,
  setFocused = function() end,
}

-- Helper to create EventHandler with dependencies
local function createEventHandler(config)
  config = config or {}
  return EventHandler.new(config, {
    InputEvent = InputEvent,
    Context = MockContext,
    utils = utils,
  })
end

-- Mock element
local function createMockElement()
  return {
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    disabled = false,
    editable = false,
    _focused = false,
    padding = { left = 0, right = 0, top = 0, bottom = 0 },
    _borderBoxWidth = 100,
    _borderBoxHeight = 100,
    isFocused = function(self)
      return self._focused
    end,
    focus = function(self)
      self._focused = true
    end,
  }
end

-- Test: new() creates instance with defaults
function TestEventHandler:test_new_creates_with_defaults()
  local handler = createEventHandler()

  luaunit.assertNotNil(handler)
  luaunit.assertNil(handler.onEvent)
  luaunit.assertFalse(handler:isAnyButtonPressed())
end

-- Test: new() accepts custom onEvent callback
function TestEventHandler:test_new_accepts_custom_onEvent()
  local onEventCalled = false
  local handler = createEventHandler({
    onEvent = function()
      onEventCalled = true
    end,
  })

  luaunit.assertNotNil(handler.onEvent)
end

-- Test: initialize() sets element reference
-- function TestEventHandler:test_initialize_sets_element()
--   Removed: _element field no longer exists
-- end

-- Test: getState() returns state data that can restore behavior via setState
function TestEventHandler:test_getState_returns_state()
  local handler = createEventHandler()
  handler.onEvent = function() end

  -- Press button 1 and verify through public API
  handler._pressed[1] = true
  luaunit.assertTrue(handler:isButtonPressed(1))

  -- Capture state
  local state = handler:getState()
  luaunit.assertNotNil(state)

  -- Create new handler and restore from state
  local restored = createEventHandler()
  restored:setState(state)

  -- Verify behavior is restored through public API
  luaunit.assertTrue(restored:isButtonPressed(1))
end

-- Test: setState() restores state
function TestEventHandler:test_setState_restores_state()
  local handler = createEventHandler()

  local state = {
    _pressed = { [1] = true },
  }

  handler:setState(state)

  -- Verify behavior is restored through public API
  luaunit.assertTrue(handler:isButtonPressed(1))
end

-- Test: setState() handles nil gracefully
function TestEventHandler:test_setState_handles_nil()
  local handler = createEventHandler()
  handler._pressed[1] = true

  handler:setState(nil)

  -- Should not error, should preserve button press state
  luaunit.assertTrue(handler:isButtonPressed(1))
end

-- Test: setState() uses defaults for missing values
function TestEventHandler:test_setState_uses_defaults()
  local handler = createEventHandler()

  handler:setState({}) -- Empty state

  -- No button should be pressed after empty state restore
  luaunit.assertFalse(handler:isAnyButtonPressed())
end

-- Test: resetScrollbarPressFlag() allows detecting button state after press
function TestEventHandler:test_resetScrollbarPressFlag()
  local handler = createEventHandler()

  handler:resetScrollbarPressFlag()

  -- Simulate a press by setting internal state directly (setup, not assertion)
  handler._pressed[1] = true
  luaunit.assertTrue(handler:isButtonPressed(1))
end

-- Test: isAnyButtonPressed() returns false when no buttons pressed
function TestEventHandler:test_isAnyButtonPressed_returns_false()
  local handler = createEventHandler()

  luaunit.assertFalse(handler:isAnyButtonPressed())
end

-- Test: isAnyButtonPressed() returns true when button pressed
function TestEventHandler:test_isAnyButtonPressed_returns_true()
  local handler = createEventHandler()
  handler._pressed[1] = true

  luaunit.assertTrue(handler:isAnyButtonPressed())
end

-- Test: isButtonPressed() checks specific button
function TestEventHandler:test_isButtonPressed_checks_specific_button()
  local handler = createEventHandler()
  handler._pressed[1] = true
  handler._pressed[2] = false

  luaunit.assertTrue(handler:isButtonPressed(1))
  luaunit.assertFalse(handler:isButtonPressed(2))
  luaunit.assertFalse(handler:isButtonPressed(3))
end

-- Test: processMouseEvents() returns early if no element
-- function TestEventHandler:test_processMouseEvents_no_element()
--   local handler = createEventHandler()
--
--   -- Should not error
--   handler:processMouseEvents(element, 50, 50, true, true)
-- end

-- Test: processMouseEvents() handles press event
function TestEventHandler:test_processMouseEvents_press()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventReceived = nil
  handler.onEvent = function(el, event)
    eventReceived = event
  end

  -- Mock love.mouse.isDown for button 1
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1
  end

  -- First call - button just pressed
  handler:processMouseEvents(element, 50, 50, true, true)

  luaunit.assertNotNil(eventReceived)
  luaunit.assertEquals(eventReceived.type, "press")
  luaunit.assertEquals(eventReceived.button, 1)
  luaunit.assertTrue(handler:isButtonPressed(1))

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() handles drag event
function TestEventHandler:test_processMouseEvents_drag()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1
  end

  -- First call - press at (50, 50)
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Second call - drag to (60, 70)
  handler:processMouseEvents(element, 60, 70, true, true)

  luaunit.assertTrue(#eventsReceived >= 2)
  -- Find drag event
  local dragEvent = nil
  for _, event in ipairs(eventsReceived) do
    if event.type == "drag" then
      dragEvent = event
      break
    end
  end

  luaunit.assertNotNil(dragEvent, "Should receive drag event")
  luaunit.assertEquals(dragEvent.dx, 10)
  luaunit.assertEquals(dragEvent.dy, 20)

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() handles release and click
function TestEventHandler:test_processMouseEvents_release_and_click()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  local isButtonDown = true
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1 and isButtonDown
  end

  -- Press
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Release
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Should have: press, click, release events
  luaunit.assertTrue(#eventsReceived >= 3)

  local hasPress = false
  local hasClick = false
  local hasRelease = false

  for _, event in ipairs(eventsReceived) do
    if event.type == "press" then
      hasPress = true
    end
    if event.type == "click" then
      hasClick = true
    end
    if event.type == "release" then
      hasRelease = true
    end
  end

  luaunit.assertTrue(hasPress, "Should have press event")
  luaunit.assertTrue(hasClick, "Should have click event")
  luaunit.assertTrue(hasRelease, "Should have release event")

  love.mouse.isDown = originalIsDown
end

function TestEventHandler:test_processMouseEvents_release_invokes_select_hook()
  local handler = createEventHandler()
  local element = createMockElement()
  local selectReleaseCalls = 0

  element._handleSelectRelease = function()
    selectReleaseCalls = selectReleaseCalls + 1
  end
  element._selectState = { open = false }

  local isButtonDown = true
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1 and isButtonDown
  end

  handler:processMouseEvents(element, 50, 50, true, true)
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  luaunit.assertEquals(selectReleaseCalls, 1)

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() detects double-click
function TestEventHandler:test_processMouseEvents_double_click()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  local isButtonDown = false
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1 and isButtonDown
  end

  -- First click
  isButtonDown = true
  handler:processMouseEvents(element, 50, 50, true, true)
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Second click (quickly after first)
  isButtonDown = true
  handler:processMouseEvents(element, 50, 50, true, true)
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Find click events
  local clickEvents = {}
  for _, event in ipairs(eventsReceived) do
    if event.type == "click" then
      table.insert(clickEvents, event)
    end
  end

  luaunit.assertTrue(#clickEvents >= 2)
  -- Second click should have clickCount = 2
  if #clickEvents >= 2 then
    luaunit.assertEquals(clickEvents[2].clickCount, 2)
  end

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() handles rightclick
function TestEventHandler:test_processMouseEvents_rightclick()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  local isButtonDown = false
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 2 and isButtonDown
  end

  -- Right click press and release
  isButtonDown = true
  handler:processMouseEvents(element, 50, 50, true, true)
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  local hasRightClick = false
  for _, event in ipairs(eventsReceived) do
    if event.type == "rightclick" then
      hasRightClick = true
      luaunit.assertEquals(event.button, 2)
    end
  end

  luaunit.assertTrue(hasRightClick, "Should have rightclick event")

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() handles middleclick
function TestEventHandler:test_processMouseEvents_middleclick()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  local isButtonDown = false
  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 3 and isButtonDown
  end

  -- Middle click press and release
  isButtonDown = true
  handler:processMouseEvents(element, 50, 50, true, true)
  isButtonDown = false
  handler:processMouseEvents(element, 50, 50, true, true)

  local hasMiddleClick = false
  for _, event in ipairs(eventsReceived) do
    if event.type == "middleclick" then
      hasMiddleClick = true
      luaunit.assertEquals(event.button, 3)
    end
  end

  luaunit.assertTrue(hasMiddleClick, "Should have middleclick event")

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() respects disabled state
function TestEventHandler:test_processMouseEvents_disabled()
  local handler = createEventHandler()
  local element = createMockElement()
  element.disabled = true
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventReceived = false
  handler.onEvent = function(el, event)
    eventReceived = true
  end

  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1
  end

  handler:processMouseEvents(element, 50, 50, true, true)

  -- Should not fire event for disabled element
  luaunit.assertFalse(eventReceived)

  love.mouse.isDown = originalIsDown
end

-- Test: processMouseEvents() fires unhover when disabled element was hovered
function TestEventHandler:test_processMouseEvents_disabled_fires_unhover()
  local handler = createEventHandler()
  local element = createMockElement()

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  -- First hover the element
  handler:processMouseEvents(element, 50, 50, true, true)
  luaunit.assertEquals(#eventsReceived, 1)
  luaunit.assertEquals(eventsReceived[1].type, "hover")

  -- Now disable the element and move mouse away
  element.disabled = true
  handler:processMouseEvents(element, 50, 50, false, true)

  -- Should fire unhover to keep events balanced
  luaunit.assertEquals(#eventsReceived, 2)
  luaunit.assertEquals(eventsReceived[2].type, "unhover")
end

-- Test: processMouseEvents() fires unhover when element disabled during hover
function TestEventHandler:test_processMouseEvents_disabled_during_hover()
  local handler = createEventHandler()
  local element = createMockElement()

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  -- First hover the element
  handler:processMouseEvents(element, 50, 50, true, true)
  luaunit.assertEquals(#eventsReceived, 1)
  luaunit.assertEquals(eventsReceived[1].type, "hover")

  -- Disable the element while mouse is still hovering
  element.disabled = true
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Should fire unhover to keep events balanced
  luaunit.assertEquals(#eventsReceived, 2)
  luaunit.assertEquals(eventsReceived[2].type, "unhover")
end

-- Test: processTouchEvents() handles touch
function TestEventHandler:test_processTouchEvents()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local eventsReceived = {}
  handler.onEvent = function(el, event)
    table.insert(eventsReceived, event)
  end

  -- Mock touch API
  local originalGetTouches = love.touch.getTouches
  local originalGetPosition = love.touch.getPosition

  love.touch.getTouches = function()
    return { "touch1" }
  end

  love.touch.getPosition = function(id)
    if id == "touch1" then
      return 150, 150 -- Outside element bounds
    end
  end

  -- First call - touch starts inside
  love.touch.getPosition = function(id)
    if id == "touch1" then
      return 50, 50 -- Inside element
    end
  end
  handler:processTouchEvents(element)

  -- Second call - touch moves outside
  love.touch.getPosition = function(id)
    if id == "touch1" then
      return 150, 150 -- Outside element
    end
  end
  handler:processTouchEvents(element)

  -- Should receive touch event
  luaunit.assertTrue(#eventsReceived >= 1)

  love.touch.getTouches = originalGetTouches
  love.touch.getPosition = originalGetPosition
end

-- Test: processTouchEvents() returns early if no element
-- function TestEventHandler:test_processTouchEvents_no_element()
--   local handler = createEventHandler()
--
--   -- Should not error
--   handler:processTouchEvents(element)
-- end

-- Test: processTouchEvents() returns early if no onEvent
function TestEventHandler:test_processTouchEvents_no_onEvent()
  local handler = createEventHandler()
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  -- Should not error (no onEvent callback)
  handler:processTouchEvents(element)
end

-- Test: onEventDeferred flag defers callback execution
function TestEventHandler:test_onEventDeferred()
  -- Mock FlexLove module
  local deferredCallbacks = {}
  local MockFlexLove = {
    deferCallback = function(callback)
      table.insert(deferredCallbacks, callback)
    end,
  }
  package.loaded["FlexLove"] = MockFlexLove

  local eventsReceived = {}
  local handler = createEventHandler({
    onEventDeferred = true,
    onEvent = function(el, event)
      table.insert(eventsReceived, event)
    end,
  })
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1
  end

  -- Press and release mouse button
  handler:processMouseEvents(element, 50, 50, true, true)
  love.mouse.isDown = function()
    return false
  end
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Events should not be immediately executed
  luaunit.assertEquals(#eventsReceived, 0)

  -- Should have deferred callbacks queued
  luaunit.assertTrue(#deferredCallbacks > 0)

  -- Execute deferred callbacks
  for _, callback in ipairs(deferredCallbacks) do
    callback()
  end

  -- Now events should be received
  luaunit.assertTrue(#eventsReceived > 0)

  -- Check that we got a click event
  local hasClick = false
  for _, event in ipairs(eventsReceived) do
    if event.type == "click" then
      hasClick = true
      break
    end
  end
  luaunit.assertTrue(hasClick, "Should have received click event")

  love.mouse.isDown = originalIsDown
  package.loaded["FlexLove"] = nil
end

-- Test: onEventDeferred = false executes immediately
function TestEventHandler:test_onEventDeferred_false()
  local eventsReceived = {}
  local handler = createEventHandler({
    onEventDeferred = false,
    onEvent = function(el, event)
      table.insert(eventsReceived, event)
    end,
  })
  local element = createMockElement()
  -- handler:initialize(element) -- Removed: element now passed as parameter

  local originalIsDown = love.mouse.isDown
  love.mouse.isDown = function(button)
    return button == 1
  end

  -- Press and release mouse button
  handler:processMouseEvents(element, 50, 50, true, true)
  love.mouse.isDown = function()
    return false
  end
  handler:processMouseEvents(element, 50, 50, true, true)

  -- Events should be immediately executed
  luaunit.assertTrue(#eventsReceived > 0)

  -- Check that we got a click event
  local hasClick = false
  for _, event in ipairs(eventsReceived) do
    if event.type == "click" then
      hasClick = true
      break
    end
  end
  luaunit.assertTrue(hasClick, "Should have received click event")

  love.mouse.isDown = originalIsDown
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
