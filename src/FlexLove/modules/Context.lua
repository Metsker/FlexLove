---@class Context
local modulePath = (...):match("(.-)[^%.]+$")
local _ZIndex = require(modulePath .. "ZIndex")
local Context = {
  topElements = {},
  baseScale = nil,
  scaleFactors = { x = 1.0, y = 1.0 },
  defaultTheme = nil,
  _focusedElement = nil,
  _activeEventElement = nil,
  _cachedViewport = { width = 0, height = 0 },
  _settingFocus = false,
  _onFocusChanged = nil,

  _navigationContext = {
    lastFocusedElement = nil,
    navigationMode = "sequential",
    containerElement = nil,
  },

  initialized = false,

  _debugDraw = false,
  _debugDrawKey = nil,
}

---@return number, number -- scaleX, scaleY
function Context.getScaleFactors()
  return Context.scaleFactors.x, Context.scaleFactors.y
end

--- Set the focused element. Automatically blurs the previously focused element if different.
---@param element Element|nil
function Context.setFocused(element)
  if Context._focusedElement == element then
    return
  end

  if Context._settingFocus then
    return
  end
  Context._settingFocus = true

  local oldFocusedElement = Context._focusedElement

  if oldFocusedElement and oldFocusedElement ~= element then
    if oldFocusedElement._textEditor then
      oldFocusedElement._textEditor:blur(oldFocusedElement)
    end
  end

  Context._focusedElement = element

  if Context._onFocusChanged then
    Context._onFocusChanged(element)
  end

  if element and element._textEditor then
    element._textEditor._focused = true
  end

  Context._settingFocus = false
end

--- Get the currently focused element.
---@return Element|nil
function Context.getFocused()
  return Context._focusedElement
end

--- Clear focus.
function Context.clearFocus()
  Context.setFocused(nil)
end

--- Get the navigation context.
---@return table
function Context.getNavigationContext()
  return Context._navigationContext
end

--- Push current focus onto a stack (for modals/dialogs).
---@param element Element?
function Context.pushFocusStack(element)
  Context._navigationContext.lastFocusedElement = Context._focusedElement
  if element then
    Context.setFocused(element)
  end
end

--- Pop focus from the stack (return from modal).
---@return Element?
function Context.popFocusStack()
  local previous = Context._navigationContext.lastFocusedElement
  Context._navigationContext.lastFocusedElement = nil
  Context.setFocused(previous)
  return previous
end

--- Set the navigation container (scope for tab navigation).
---@param element Element?
function Context.setNavigationContainer(element)
  Context._navigationContext.containerElement = element
end

--- Get the navigation container.
---@return Element?
function Context.getNavigationContainer()
  return Context._navigationContext.containerElement
end

return Context
