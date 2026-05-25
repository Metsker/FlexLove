local packageName = ... or "FlexLove"
local modulePath = packageName:match("(.-)[^%.]+$")
if modulePath == "" then
  modulePath = packageName .. "."
end

local function req(name)
  return require(modulePath .. "modules." .. name)
end

---@type ErrorHandler
local ErrorHandler = req("ErrorHandler")
local utils = req("utils")
local Calc = req("Calc")
local Units = req("Units")
local Context = req("Context")
local RoundedRect = req("RoundedRect")
local Grid = req("Grid")
local InputEvent = req("InputEvent")
local TextEditor = req("TextEditor")
---@type LayoutEngine
local LayoutEngine = req("LayoutEngine")
local Renderer = req("Renderer")
---@type EventHandler
local EventHandler = req("EventHandler")
local ScrollManager = req("ScrollManager")
---@type ZIndex
local ZIndex = req("ZIndex")
---@type Element
local Element = req("Element")
---@type Color
local Color = req("Color")
---@type Select
local Select = req("Select")

local Blur = req("Blur")
---@type Performance
local Performance = req("Performance")
---@type KeyboardNavigation
local KeyboardNavigation = req("KeyboardNavigation")
---@type FocusIndicator
local FocusIndicator = req("FocusIndicator")
local ImageRenderer = req("ImageRenderer")
local ImageScaler = req("ImageScaler")
local NinePatch = req("NinePatch")
local ImageCache = req("ImageCache")
local GestureRecognizer = req("GestureRecognizer")
---@type Animation
local Animation = req("Animation")
---@type Theme
local Theme = req("Theme")

local Transform = Animation.Transform

local enums = utils.enums

local flexlove = Context
flexlove._VERSION = "0.15.0"
flexlove._DESCRIPTION = "CSS-style UI library for LÖVE2D"
flexlove._URL = "https://github.com/mikefreno/FlexLove"
flexlove._LICENSE = [[
  MIT License

  Copyright (c) 2025 Mike Freno

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]

---@type GCConfig
flexlove._gcConfig = {
  strategy = "auto",
  memoryThreshold = 100,
  interval = 60,
  stepSize = 200,
}
---@type GCState
flexlove._gcState = {
  framesSinceLastGC = 0,
  lastMemory = 0,
  gcCount = 0,
}

---@type function[]
flexlove._deferredCallbacks = {}

---@type table<string, Element>
flexlove._touchOwners = {}

---@type table<number, boolean>
flexlove._mouseButtonStates = {}

---@type GestureRecognizer|nil
flexlove._gestureRecognizer = nil

--- Set up FlexLove for your application's specific needs.
---@param config FlexLoveConfig?
function flexlove.init(config)
  config = config or {}

  flexlove._ErrorHandler = ErrorHandler.init({
    includeStackTrace = config.includeStackTrace,
    logLevel = config.reportingLogLevel,
    logTarget = config.errorLogTarget,
    logFile = config.errorLogFile,
    maxLogSize = config.errorLogMaxSize,
    maxLogFiles = config.maxErrorLogFiles,
    enableRotation = config.errorLogRotateEnabled,
  })

  flexlove._Performance = Performance.init({
    enabled = config.performanceMonitoring or true,
    hudEnabled = false,
    hudToggleKey = config.performanceHudKey or "f3",
    hudPosition = config.performanceHudPosition or { x = 10, y = 10 },
    warningThresholdMs = config.performanceWarningThreshold or 13.0,
    criticalThresholdMs = config.performanceCriticalThreshold or 16.67,
    logToConsole = config.performanceLogToConsole or false,
    logWarnings = config.performanceWarnings or false,
    warningsEnabled = config.performanceWarnings or false,
    memoryProfiling = config.memoryProfiling or false,
  }, { ErrorHandler = flexlove._ErrorHandler })

  ImageRenderer.init({ ErrorHandler = flexlove._ErrorHandler, utils = utils })
  ImageScaler.init({ ErrorHandler = flexlove._ErrorHandler })
  NinePatch.init({ ErrorHandler = flexlove._ErrorHandler })
  Blur.init({ ErrorHandler = flexlove._ErrorHandler, immediateModeOptimizations = false })

  Calc.init({ ErrorHandler = flexlove._ErrorHandler })
  Units.init({ Context = Context, ErrorHandler = flexlove._ErrorHandler, Calc = Calc })
  Color.init({ ErrorHandler = flexlove._ErrorHandler })
  utils.init({ ErrorHandler = flexlove._ErrorHandler })

  ImageCache.init({ ErrorHandler = flexlove._ErrorHandler })
  Animation.init({ ErrorHandler = flexlove._ErrorHandler, Color = Color })
  Theme.init({ ErrorHandler = flexlove._ErrorHandler, Color = Color, utils = utils })

  LayoutEngine.init({ ErrorHandler = flexlove._ErrorHandler, Performance = flexlove._Performance, utils = utils })
  EventHandler.init({
    ErrorHandler = flexlove._ErrorHandler,
    Performance = flexlove._Performance,
    InputEvent = InputEvent,
    utils = utils,
    Context = Context,
  })

  flexlove._gestureRecognizer = GestureRecognizer.new({}, { InputEvent = InputEvent, utils = utils })

  local keyboardConfig = config.keyboardNavigation
  if keyboardConfig == true or (type(keyboardConfig) == "table" and keyboardConfig.enabled ~= false) then
    KeyboardNavigation.init({
      Context = Context,
      Element = Element,
      ErrorHandler = flexlove._ErrorHandler,
      utils = utils,
      InputEvent = InputEvent,
    })
    FocusIndicator.init({ Context = Context, Color = Color })
    KeyboardNavigation.FocusIndicator = FocusIndicator
    EventHandler._FocusIndicator = FocusIndicator
    flexlove._applyKeyboardNavConfig(keyboardConfig)
  end

  flexlove._defaultDependencies = {
    Context = Context,
    Theme = Theme,
    Color = Color,
    Calc = Calc,
    Units = Units,
    Blur = Blur,
    ImageRenderer = ImageRenderer,
    ImageScaler = ImageScaler,
    NinePatch = NinePatch,
    RoundedRect = RoundedRect,
    ImageCache = ImageCache,
    utils = utils,
    Grid = Grid,
    InputEvent = InputEvent,
    GestureRecognizer = GestureRecognizer,
    TextEditor = TextEditor,
    LayoutEngine = LayoutEngine,
    Renderer = Renderer,
    EventHandler = EventHandler,
    ScrollManager = ScrollManager,
    ErrorHandler = flexlove._ErrorHandler,
    Performance = flexlove._Performance,
    Transform = Transform,
    Animation = Animation,
    ZIndex = ZIndex,
    Select = Select,
  }

  Element.init(flexlove._defaultDependencies)

  if config.baseScale then
    flexlove.baseScale = {
      width = config.baseScale.width or 1920,
      height = config.baseScale.height or 1080,
    }

    local currentWidth, currentHeight = Units.getViewport()
    flexlove.scaleFactors.x = currentWidth / flexlove.baseScale.width
    flexlove.scaleFactors.y = currentHeight / flexlove.baseScale.height
  end

  if config.theme then
    local success, err = pcall(function()
      if type(config.theme) == "string" then
        Theme.load(config.theme)
        Theme.setActive(config.theme)
        flexlove.defaultTheme = config.theme
      elseif type(config.theme) == "table" then
        local theme = Theme.new(config.theme)
        Theme.setActive(theme)
        flexlove.defaultTheme = theme.name
      end
    end)

    if not success then
      flexlove._ErrorHandler:warn("FlexLove", "THM_005", { error = tostring(err) })
    end
  end

  if config.gcStrategy then
    flexlove._gcConfig.strategy = config.gcStrategy
  end
  if config.gcMemoryThreshold then
    flexlove._gcConfig.memoryThreshold = config.gcMemoryThreshold
  end
  if config.gcInterval then
    flexlove._gcConfig.interval = config.gcInterval
  end
  if config.gcStepSize then
    flexlove._gcConfig.stepSize = config.gcStepSize
  end

  flexlove.initialized = true

  flexlove._debugDraw = config.debugDraw or false
  flexlove._debugDrawKey = config.debugDrawKey or nil
end

--- Apply keyboard navigation configuration (internal helper)
---@param config table
function flexlove._applyKeyboardNavConfig(config)
  if type(config) ~= "table" then
    return
  end

  if config.enabled ~= nil then
    KeyboardNavigation.config.enabled = config.enabled
  end
  if config.directionalNavigation ~= nil then
    KeyboardNavigation.config.directionalNavigation = config.directionalNavigation
  end
  if config.wrapAround ~= nil then
    KeyboardNavigation.config.wrapAround = config.wrapAround
  end
  if config.dropFocusOnSelection ~= nil then
    KeyboardNavigation.config.dropFocusOnSelection = config.dropFocusOnSelection
  end

  if config.focusIndicator then
    local fiConfig = config.focusIndicator
    if fiConfig.enabled ~= nil then
      FocusIndicator.config.enabled = fiConfig.enabled
    end
    if fiConfig.draw ~= nil then
      FocusIndicator.config.draw = fiConfig.draw
    end
    if fiConfig.color then
      FocusIndicator.setColor(
        fiConfig.color[1] or 0.2,
        fiConfig.color[2] or 0.6,
        fiConfig.color[3] or 1.0,
        fiConfig.color[4] or 0.8
      )
    end
    if fiConfig.lineWidth ~= nil then
      FocusIndicator.config.lineWidth = fiConfig.lineWidth
    end
    if fiConfig.pulseEnabled ~= nil then
      FocusIndicator.config.pulseEnabled = fiConfig.pulseEnabled
    end
  end
end

--- Enable keyboard navigation after initialization
---@param config KeyboardNavigationConfig?
function flexlove.enableKeyboardNavigation(config)
  config = config or {}

  if KeyboardNavigation.config and KeyboardNavigation._deps then
    flexlove._applyKeyboardNavConfig(config)
    return
  end

  KeyboardNavigation.init({
    Context = Context,
    Element = Element,
    ErrorHandler = flexlove._ErrorHandler,
    utils = utils,
    InputEvent = InputEvent,
  })

  FocusIndicator.init({ Context = Context, Color = Color })
  KeyboardNavigation.FocusIndicator = FocusIndicator
  EventHandler._FocusIndicator = FocusIndicator

  flexlove._applyKeyboardNavConfig(config)
end

--- Schedule a callback to run after canvas operations complete.
---@param callback function
function flexlove.deferCallback(callback)
  if type(callback) ~= "function" then
    flexlove._ErrorHandler:warn("FlexLove", "CORE_001")
    return
  end
  table.insert(flexlove._deferredCallbacks, callback)
end

--- Execute deferred callbacks.
function flexlove.executeDeferredCallbacks()
  if #flexlove._deferredCallbacks == 0 then
    return
  end

  local callbacks = flexlove._deferredCallbacks
  flexlove._deferredCallbacks = {}

  for _, callback in ipairs(callbacks) do
    local success, err = xpcall(callback, debug.traceback)
    if not success then
      flexlove._ErrorHandler:warn("FlexLove", "CORE_002", { error = tostring(err) })
    end
  end
end

--- Recalculate all UI layouts when the window size changes.
function flexlove.resize()
  local newWidth, newHeight = love.window.getMode()

  if flexlove.baseScale then
    flexlove.scaleFactors.x = newWidth / flexlove.baseScale.width
    flexlove.scaleFactors.y = newHeight / flexlove.baseScale.height
  end

  Blur.clearCache()

  if flexlove._gameCanvas then
    flexlove._gameCanvas:release()
  end
  if flexlove._backdropCanvas then
    flexlove._backdropCanvas:release()
  end

  flexlove._gameCanvas = nil
  flexlove._backdropCanvas = nil
  flexlove._canvasDimensions = { width = 0, height = 0 }

  for _, win in ipairs(flexlove.topElements) do
    win:resize(newWidth, newHeight)
  end
end

---@type love.Canvas?
flexlove._gameCanvas = nil
---@type love.Canvas?
flexlove._backdropCanvas = nil
---@type {width: number, height: number}
flexlove._canvasDimensions = { width = 0, height = 0 }

--- Recursively draw debug boundaries for an element and all its children.
---@param element Element
local function drawDebugElement(element)
  local color = element._debugColor
  if color then
    local bw = element._borderBoxWidth or (element.width + element.padding.left + element.padding.right)
    local bh = element._borderBoxHeight or (element.height + element.padding.top + element.padding.bottom)

    love.graphics.setColor(color[1], color[2], color[3], 0.5)
    love.graphics.rectangle("fill", element.x, element.y, bw, bh)

    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", element.x, element.y, bw, bh)
  end

  for _, child in ipairs(element.children) do
    drawDebugElement(child)
  end
end

--- Render the debug draw overlay for all elements in the tree.
function flexlove._renderDebugOverlay()
  local prevR, prevG, prevB, prevA = love.graphics.getColor()
  local prevLineWidth = love.graphics.getLineWidth()

  love.graphics.setScissor()

  for _, win in ipairs(flexlove.topElements) do
    drawDebugElement(win)
  end

  love.graphics.setColor(prevR, prevG, prevB, prevA)
  love.graphics.setLineWidth(prevLineWidth)
end

--- Render all UI elements with optional backdrop blur support.
---@param gameDrawFunc function|nil pass component draws that should be affected by a backdrop blur
---@param postDrawFunc function|nil pass component draws that should NOT be affected by a backdrop blur
function flexlove.draw(gameDrawFunc, postDrawFunc)
  local outerCanvas = love.graphics.getCanvas()
  local gameCanvas = nil

  if type(gameDrawFunc) == "function" then
    local width, height = love.graphics.getDimensions()

    if
      not flexlove._gameCanvas
      or flexlove._canvasDimensions.width ~= width
      or flexlove._canvasDimensions.height ~= height
    then
      if flexlove._gameCanvas then
        flexlove._gameCanvas:release()
      end
      if flexlove._backdropCanvas then
        flexlove._backdropCanvas:release()
      end

      flexlove._gameCanvas = love.graphics.newCanvas(width, height)
      flexlove._backdropCanvas = love.graphics.newCanvas(width, height)
      flexlove._canvasDimensions.width = width
      flexlove._canvasDimensions.height = height
    end

    gameCanvas = flexlove._gameCanvas

    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()
    gameDrawFunc()
    love.graphics.setCanvas(outerCanvas)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas, 0, 0)
  end

  table.sort(flexlove.topElements, function(a, b)
    return a.z < b.z
  end)

  local function hasBackdropBlur(element)
    if element.backdropBlur and element.backdropBlur.radius > 0 then
      return true
    end
    for _, child in ipairs(element.children) do
      if hasBackdropBlur(child) then
        return true
      end
    end
    return false
  end

  local needsBackdropCanvas = false
  for _, win in ipairs(flexlove.topElements) do
    if hasBackdropBlur(win) then
      needsBackdropCanvas = true
      break
    end
  end

  if needsBackdropCanvas and gameCanvas then
    local backdropCanvas = flexlove._backdropCanvas
    local prevColor = { love.graphics.getColor() }

    love.graphics.setCanvas(backdropCanvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas, 0, 0)

    love.graphics.setCanvas(outerCanvas)
    love.graphics.setColor(unpack(prevColor))

    for _, win in ipairs(flexlove.topElements) do
      local needsBackdrop = hasBackdropBlur(win)

      if needsBackdrop then
        win:draw(backdropCanvas)
      else
        win:draw(nil)
      end

      love.graphics.setCanvas(backdropCanvas)
      love.graphics.setColor(1, 1, 1, 1)
      win:draw(nil)
      love.graphics.setCanvas(outerCanvas)
    end
  else
    for _, win in ipairs(flexlove.topElements) do
      win:draw(nil)
    end
  end

  if type(postDrawFunc) == "function" then
    postDrawFunc()
  end

  flexlove._Performance:renderHUD()

  if KeyboardNavigation.config and KeyboardNavigation.config.enabled then
    FocusIndicator:draw()
  end

  if flexlove._debugDraw then
    flexlove._renderDebugOverlay()
  end

  love.graphics.setCanvas(outerCanvas)
end

--- Check if element is an ancestor of target.
---@param element Element
---@param target Element
---@return boolean
local function isAncestor(element, target)
  local current = target.parent
  while current do
    if current == element then
      return true
    end
    current = current.parent
  end
  return false
end

---@param element Element
---@param results Element[]
local function collectOpenSelects(element, results)
  if element._selectState and element._selectState.open then
    table.insert(results, element)
  end

  for _, child in ipairs(element.children) do
    collectOpenSelects(child, results)
  end
end

function flexlove._handleSelectPointerDismissal()
  local isLeftDown = love.mouse.isDown(1)
  local wasLeftDown = flexlove._mouseButtonStates[1] or false

  if isLeftDown and not wasLeftDown then
    local mx, my = love.mouse.getPosition()
    local target = flexlove.elementFromPoint(mx, my)
    local openSelects = {}

    for _, element in ipairs(flexlove.topElements) do
      collectOpenSelects(element, openSelects)
    end

    for _, selectParent in ipairs(openSelects) do
      local containsTarget = target and (target == selectParent or isAncestor(selectParent, target))
      if not containsTarget then
        selectParent:closeSelect()
      end
    end
  end

  flexlove._mouseButtonStates[1] = isLeftDown
end

--- Hit-test the UI element at a screen position.
---@param x number
---@param y number
---@return Element?
function flexlove.elementFromPoint(x, y)
  local candidates = {}
  local blockingElements = {}

  local function collectHits(element, scrollOffsetX, scrollOffsetY)
    scrollOffsetX = scrollOffsetX or 0
    scrollOffsetY = scrollOffsetY or 0

    local bx = element.x
    local by = element.y
    local bw = element._borderBoxWidth or (element.width + element.padding.left + element.padding.right)
    local bh = element._borderBoxHeight or (element.height + element.padding.top + element.padding.bottom)

    local adjustedX = x + scrollOffsetX
    local adjustedY = y + scrollOffsetY

    if adjustedX >= bx and adjustedX <= bx + bw and adjustedY >= by and adjustedY <= by + bh then
      if element.display == "none" then
        return
      end
      if element.visibility == "hidden" or element.opacity <= 0 then
        return
      end

      local isInteractive = element.onEvent
        or element.onClick
        or element.onMouseDown
        or element.onMouseUp
        or element.onMouseEnter
        or element.onMouseLeave
        or element.onMouseMove
        or element.onDrag
        or element.onContextMenu
        or element.onAuxClick
        or element.editable
        or element._selectState
        or element.selectOption
      if isInteractive and not element.disabled then
        table.insert(candidates, element)
      end

      if element.opacity > 0 then
        table.insert(blockingElements, element)
      end

      local overflowX = element.overflowX or element.overflow
      local overflowY = element.overflowY or element.overflow
      local hasScrollableOverflow = (
        overflowX == "scroll"
        or overflowX == "auto"
        or overflowY == "scroll"
        or overflowY == "auto"
        or overflowX == "hidden"
        or overflowY == "hidden"
      )

      local childScrollOffsetX = scrollOffsetX
      local childScrollOffsetY = scrollOffsetY
      if hasScrollableOverflow then
        childScrollOffsetX = childScrollOffsetX + (element._scrollX or 0)
        childScrollOffsetY = childScrollOffsetY + (element._scrollY or 0)
      end

      for _, child in ipairs(element.children) do
        collectHits(child, childScrollOffsetX, childScrollOffsetY)
      end
    end
  end

  for _, element in ipairs(flexlove.topElements) do
    collectHits(element)
  end

  table.sort(candidates, function(a, b)
    return a.z > b.z
  end)

  table.sort(blockingElements, function(a, b)
    return a.z > b.z
  end)

  if #candidates > 0 then
    local topCandidate = candidates[1]

    if #blockingElements > 0 then
      local topBlocker = blockingElements[1]
      if topBlocker.z > topCandidate.z and not isAncestor(topBlocker, topCandidate) then
        return topBlocker
      end
    end

    return topCandidate
  end

  return blockingElements[1]
end

--- Update all UI animations, interactions, and state changes.
---@param dt number
function flexlove.update(dt)
  flexlove._Performance:updateDeltaTime(dt)

  KeyboardNavigation:update(dt)

  flexlove._manageGC()

  local mx, my = love.mouse.getPosition()
  local topElement = flexlove.elementFromPoint(mx, my)

  flexlove._activeEventElement = topElement
  flexlove._handleSelectPointerDismissal()

  for _, win in ipairs(flexlove.topElements) do
    win:update(dt)
  end

  flexlove._activeEventElement = nil
end

--- Internal GC management.
function flexlove._manageGC()
  local strategy = flexlove._gcConfig.strategy

  if strategy == "disabled" then
    return
  end

  local currentMemory = collectgarbage("count") / 1024
  flexlove._gcState.lastMemory = currentMemory
  flexlove._gcState.framesSinceLastGC = flexlove._gcState.framesSinceLastGC + 1

  if currentMemory > flexlove._gcConfig.memoryThreshold then
    collectgarbage("collect")
    flexlove._gcState.gcCount = flexlove._gcState.gcCount + 1
    flexlove._gcState.framesSinceLastGC = 0
    return
  end

  if strategy == "periodic" then
    if flexlove._gcState.framesSinceLastGC >= flexlove._gcConfig.interval then
      collectgarbage("step", flexlove._gcConfig.stepSize)
      flexlove._gcState.gcCount = flexlove._gcState.gcCount + 1
      flexlove._gcState.framesSinceLastGC = 0
    end
  elseif strategy == "auto" then
    if flexlove._gcState.framesSinceLastGC >= 5 then
      collectgarbage("step", 50)
      flexlove._gcState.framesSinceLastGC = 0
    end
  end
end

--- Manually trigger garbage collection.
---@param mode? string "collect" for full GC, "step" for incremental (default: "collect")
---@param stepSize? number Work units for step mode (default: 200)
function flexlove.collectGarbage(mode, stepSize)
  mode = mode or "collect"
  stepSize = stepSize or 200

  if mode == "collect" then
    collectgarbage("collect")
    flexlove._gcState.gcCount = flexlove._gcState.gcCount + 1
    flexlove._gcState.framesSinceLastGC = 0
  elseif mode == "step" then
    collectgarbage("step", stepSize)
  elseif mode == "count" then
    return collectgarbage("count") / 1024
  end
end

--- Set garbage collection strategy.
---@param strategy string "auto", "periodic", "manual", or "disabled"
function flexlove.setGCStrategy(strategy)
  if strategy == "auto" or strategy == "periodic" or strategy == "manual" or strategy == "disabled" then
    flexlove._gcConfig.strategy = strategy
  else
    flexlove._ErrorHandler:warn("FlexLove", "CORE_003", { strategy = tostring(strategy) })
  end
end

--- Get garbage collection statistics.
---@return GCStats
function flexlove.getGCStats()
  return {
    gcCount = flexlove._gcState.gcCount,
    framesSinceLastGC = flexlove._gcState.framesSinceLastGC,
    currentMemoryMB = flexlove._gcState.lastMemory,
    strategy = flexlove._gcConfig.strategy,
    threshold = flexlove._gcConfig.memoryThreshold,
  }
end

--- Forward text input to focused editable elements.
---@param text string
function flexlove.textinput(text)
  local focusedElement = Context.getFocused()
  if focusedElement and not focusedElement.disabled then
    focusedElement:textinput(text)
  end
end

--- Handle keyboard input.
---@param key string
---@param scancode string
---@param isrepeat boolean
function flexlove.keypressed(key, scancode, isrepeat)
  flexlove._Performance:keypressed(key)
  if flexlove._debugDrawKey and key == flexlove._debugDrawKey then
    flexlove._debugDraw = not flexlove._debugDraw
  end

  if KeyboardNavigation.config and KeyboardNavigation.config.enabled then
    local focusedElement = Context.getFocused()
    local isTextInputMode = focusedElement and (focusedElement.editable or focusedElement._textEditor)

    local shouldHandleNav = not isTextInputMode
      or (
        isTextInputMode
        and not (
          love.keyboard.isDown("lctrl")
          or love.keyboard.isDown("rctrl")
          or love.keyboard.isDown("lalt")
          or love.keyboard.isDown("ralt")
        )
      )

    if shouldHandleNav then
      local handled = KeyboardNavigation:handleKeyPress(key, scancode, isrepeat)
      if handled then
        return
      end
    end
  end

  local focusedElement = Context.getFocused()
  if focusedElement and not focusedElement.disabled then
    focusedElement:keypressed(key, scancode, isrepeat)
  end
end

--- Handle mouse wheel scrolling.
---@param dx number
---@param dy number
function flexlove.wheelmoved(dx, dy)
  local mx, my = love.mouse.getPosition()
  local function findScrollableAtPosition(elements, x, y)
    for i = #elements, 1, -1 do
      local element = elements[i]
      if element.display ~= "none" then
        local bx = element.x
        local by = element.y
        local bw = element._borderBoxWidth or (element.width + element.padding.left + element.padding.right)
        local bh = element._borderBoxHeight or (element.height + element.padding.top + element.padding.bottom)

        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
          if #element.children > 0 then
            local childResult = findScrollableAtPosition(element.children, x, y)
            if childResult then
              return childResult
            end
          end

          local overflowX = element.overflowX or element.overflow
          local overflowY = element.overflowY or element.overflow
          if
            (overflowX == "scroll" or overflowX == "auto" or overflowY == "scroll" or overflowY == "auto")
            and (element._overflowX or element._overflowY)
          then
            return element
          end
        end
      end
    end

    return nil
  end

  local scrollableElement = findScrollableAtPosition(flexlove.topElements, mx, my)
  if scrollableElement then
    scrollableElement:_handleWheelScroll(dx, dy)
  end
end

--- Find the touch-interactive element at a given position.
---@param x number
---@param y number
---@return Element|nil
function flexlove._getTouchElementAtPosition(x, y)
  local candidates = {}

  local function collectTouchHits(element, scrollOffsetX, scrollOffsetY)
    scrollOffsetX = scrollOffsetX or 0
    scrollOffsetY = scrollOffsetY or 0

    local bx = element.x
    local by = element.y
    local bw = element._borderBoxWidth or (element.width + element.padding.left + element.padding.right)
    local bh = element._borderBoxHeight or (element.height + element.padding.top + element.padding.bottom)

    local adjustedX = x + scrollOffsetX
    local adjustedY = y + scrollOffsetY

    if adjustedX >= bx and adjustedX <= bx + bw and adjustedY >= by and adjustedY <= by + bh then
      if element.display == "none" then
        return
      end
      if
        element.touchEnabled
        and not element.disabled
        and (element.onEvent or element.onTouchEvent or element.onGesture)
      then
        table.insert(candidates, element)
      end

      local overflowX = element.overflowX or element.overflow
      local overflowY = element.overflowY or element.overflow
      local hasScrollableOverflow = (
        overflowX == "scroll"
        or overflowX == "auto"
        or overflowY == "scroll"
        or overflowY == "auto"
        or overflowX == "hidden"
        or overflowY == "hidden"
      )

      local childScrollOffsetX = scrollOffsetX
      local childScrollOffsetY = scrollOffsetY
      if hasScrollableOverflow then
        childScrollOffsetX = childScrollOffsetX + (element._scrollX or 0)
        childScrollOffsetY = childScrollOffsetY + (element._scrollY or 0)
      end

      for _, child in ipairs(element.children) do
        collectTouchHits(child, childScrollOffsetX, childScrollOffsetY)
      end
    end
  end

  for _, element in ipairs(flexlove.topElements) do
    collectTouchHits(element)
  end

  table.sort(candidates, function(a, b)
    return a.z > b.z
  end)

  return candidates[1]
end

--- Handle touch press events.
function flexlove.touchpressed(id, x, y, dx, dy, pressure)
  local touchId = tostring(id)
  pressure = pressure or 1.0

  local touchX, touchY = x, y
  if flexlove.baseScale then
    touchX = x / flexlove.scaleFactors.x
    touchY = y / flexlove.scaleFactors.y
  end

  local element = flexlove._getTouchElementAtPosition(touchX, touchY)

  if element then
    flexlove._touchOwners[touchId] = element

    local touchEvent = InputEvent.fromTouch(id, touchX, touchY, "began", pressure)
    element:handleTouchEvent(touchEvent)

    if flexlove._gestureRecognizer then
      local gestures = flexlove._gestureRecognizer:processTouchEvent(touchEvent)
      if gestures then
        for _, gesture in ipairs(gestures) do
          element:handleGesture(gesture)
        end
      end
    end

    if element._scrollManager then
      local overflowX = element.overflowX or element.overflow
      local overflowY = element.overflowY or element.overflow
      if overflowX == "scroll" or overflowX == "auto" or overflowY == "scroll" or overflowY == "auto" then
        element._scrollManager:handleTouchPress(touchX, touchY)
      end
    end
  end
end

--- Handle touch move events.
function flexlove.touchmoved(id, x, y, dx, dy, pressure)
  local touchId = tostring(id)
  pressure = pressure or 1.0

  local touchX, touchY = x, y
  if flexlove.baseScale then
    touchX = x / flexlove.scaleFactors.x
    touchY = y / flexlove.scaleFactors.y
  end

  local element = flexlove._touchOwners[touchId]
  if element then
    local touchEvent = InputEvent.fromTouch(id, touchX, touchY, "moved", pressure)
    element:handleTouchEvent(touchEvent)

    if flexlove._gestureRecognizer then
      local gestures = flexlove._gestureRecognizer:processTouchEvent(touchEvent)
      if gestures then
        for _, gesture in ipairs(gestures) do
          element:handleGesture(gesture)
        end
      end
    end

    if element._scrollManager then
      local overflowX = element.overflowX or element.overflow
      local overflowY = element.overflowY or element.overflow
      if overflowX == "scroll" or overflowX == "auto" or overflowY == "scroll" or overflowY == "auto" then
        element._scrollManager:handleTouchMove(touchX, touchY)
      end
    end
  end
end

--- Handle touch release events.
function flexlove.touchreleased(id, x, y, dx, dy, pressure)
  local touchId = tostring(id)
  pressure = pressure or 1.0

  local touchX, touchY = x, y
  if flexlove.baseScale then
    touchX = x / flexlove.scaleFactors.x
    touchY = y / flexlove.scaleFactors.y
  end

  local element = flexlove._touchOwners[touchId]
  if element then
    local touchEvent = InputEvent.fromTouch(id, touchX, touchY, "ended", pressure)
    element:handleTouchEvent(touchEvent)

    if flexlove._gestureRecognizer then
      local gestures = flexlove._gestureRecognizer:processTouchEvent(touchEvent)
      if gestures then
        for _, gesture in ipairs(gestures) do
          element:handleGesture(gesture)
        end
      end
    end

    if element._scrollManager then
      local overflowX = element.overflowX or element.overflow
      local overflowY = element.overflowY or element.overflow
      if overflowX == "scroll" or overflowX == "auto" or overflowY == "scroll" or overflowY == "auto" then
        element._scrollManager:handleTouchRelease()
      end
    end
  end

  flexlove._touchOwners[touchId] = nil
end

--- Number of currently active touches.
---@return number
function flexlove.getActiveTouchCount()
  local count = 0
  for _ in pairs(flexlove._touchOwners) do
    count = count + 1
  end
  return count
end

--- Get the element owning a specific touch.
---@param touchId string|lightuserdata
---@return Element|nil
function flexlove.getTouchOwner(touchId)
  return flexlove._touchOwners[tostring(touchId)]
end

--- Find an element by its ID anywhere in the tree.
---@param id string
---@return Element|nil
function flexlove.getElementById(id)
  if not id or id == "" then
    return nil
  end

  local function findElementById(element, targetId)
    if element.id == targetId then
      return element
    end

    for _, child in ipairs(element.children) do
      local result = findElementById(child, targetId)
      if result then
        return result
      end
    end

    return nil
  end

  for _, win in ipairs(flexlove.topElements) do
    local result = findElementById(win, id)
    if result then
      return result
    end
  end

  return nil
end

--- Tear down FlexLove state.
function flexlove.destroy()
  for _, win in ipairs(flexlove.topElements) do
    win:destroy()
  end
  flexlove.topElements = {}
  flexlove.baseScale = nil
  flexlove.scaleFactors = { x = 1.0, y = 1.0 }
  flexlove._cachedViewport = { width = 0, height = 0 }

  if flexlove._gameCanvas then
    flexlove._gameCanvas:release()
  end
  if flexlove._backdropCanvas then
    flexlove._backdropCanvas:release()
  end

  flexlove._gameCanvas = nil
  flexlove._backdropCanvas = nil
  flexlove._canvasDimensions = { width = 0, height = 0 }
  Context.clearFocus()

  flexlove._touchOwners = {}
  flexlove._mouseButtonStates = {}
  if flexlove._gestureRecognizer then
    flexlove._gestureRecognizer:reset()
  end
end

--- Create a new UI element.
---@param props ElementProps
---@return Element
function flexlove.new(props)
  if not flexlove.initialized then
    error("[FlexLove] FlexLove.init() must be called before FlexLove.new()")
  end
  return Element.new(props or {})
end

--- Create a calc() expression.
---@param expr string
---@return CalcObject
function flexlove.calc(expr)
  return Calc.new(expr)
end

--- Get the currently focused element.
---@return Element|nil
function flexlove.getFocusedElement()
  return Context.getFocused()
end

--- Programmatically focus a specific element.
---@param element Element|nil
function flexlove.setFocusedElement(element)
  Context.setFocused(element)
end

--- Clear focus.
function flexlove.clearFocus()
  Context.setFocused(nil)
end

--- Toggle the debug-draw overlay.
---@param enabled boolean
function flexlove.setDebugDraw(enabled)
  flexlove._debugDraw = enabled
end

--- Is the debug-draw overlay enabled?
---@return boolean
function flexlove.getDebugDraw()
  return flexlove._debugDraw
end

flexlove.Animation = Animation
flexlove.Color = Color
flexlove.Theme = Theme
flexlove.enums = enums

return flexlove
