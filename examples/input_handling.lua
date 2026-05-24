-- Example: Input Handling System
-- This demonstrates how to handle various input events in FlexLove

local FlexLove = require("libs.FlexLove")

local InputExample = {}

function InputExample:new()
  local obj = {
    -- State variables for input handling example
    mousePosition = { x = 0, y = 0 },
    keyPressed = "",
    touchPosition = { x = 0, y = 0 },
    isMouseOver = false,
    hoverCount = 0,
  }
  setmetatable(obj, { __index = self })
  return obj
end

function InputExample:render()
  local flex = FlexLove.new({
    x = "10%",
    y = "10%",
    width = "80%",
    height = "80%",
    display = "flex",
    flexDirection = "column",
    gap = 10,
    padding = { horizontal = 10, vertical = 10 },
  })

  -- Title
  flex:appendChild(FlexLove.new({
    text = "Input Handling System Example",
    textAlign = "center",
    fontSize = "2xl",
    width = "100%",
    height = "10%",
  }))

  -- Mouse interaction section
  local mouseSection = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "space-between",
    alignItems = "center",
    width = "100%",
    height = "20%",
    backgroundColor = "#2d3748",
    borderRadius = 8,
    padding = { horizontal = 15 },
  }))

  mouseSection:appendChild(FlexLove.new({
    text = "Mouse Position: (" .. self.mousePosition.x .. ", " .. self.mousePosition.y .. ")",
    textAlign = "left",
    fontSize = "md",
    width = "60%",
  }))

  -- Hoverable area
  local hoverArea = mouseSection:appendChild(FlexLove.new({
    display = "flex",
    justifyContent = "center",
    alignItems = "center",
    width = "30%",
    height = "100%",
    backgroundColor = "#4a5568",
    borderRadius = 8,
    padding = { horizontal = 10 },
    onEvent = function(_, event)
      if event.type == "mousemoved" then
        self.mousePosition.x = event.x
        self.mousePosition.y = event.y
      elseif event.type == "mouseenter" then
        self.isMouseOver = true
        self.hoverCount = self.hoverCount + 1
      elseif event.type == "mouseleave" then
        self.isMouseOver = false
      end
    end,
  }))

  hoverArea:appendChild(FlexLove.new({
    text = "Hover over me!",
    textAlign = "center",
    fontSize = "md",
    width = "100%",
    height = "100%",
    color = self.isMouseOver and "#48bb78" or "#a0aec0", -- Green when hovered
  }))

  -- Keyboard input section
  local keyboardSection = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "space-between",
    alignItems = "center",
    width = "100%",
    height = "20%",
    backgroundColor = "#4a5568",
    borderRadius = 8,
    padding = { horizontal = 15 },
  }))

  keyboardSection:appendChild(FlexLove.new({
    text = "Last Key Pressed: " .. (self.keyPressed or "None"),
    textAlign = "left",
    fontSize = "md",
    width = "60%",
  }))

  -- Input field for typing
  local inputField = keyboardSection:appendChild(FlexLove.new({
    themeComponent = "inputv2",
    text = "",
    textAlign = "left",
    fontSize = "md",
    width = "30%",
    onEvent = function(_, event)
      if event.type == "textinput" then
        self.keyPressed = event.text
      elseif event.type == "keypressed" then
        self.keyPressed = event.key
      end
    end,
  }))

  -- Touch input section
  local touchSection = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "space-between",
    alignItems = "center",
    width = "100%",
    height = "20%",
    backgroundColor = "#2d3748",
    borderRadius = 8,
    padding = { horizontal = 15 },
  }))

  touchSection:appendChild(FlexLove.new({
    text = "Touch Position: (" .. self.touchPosition.x .. ", " .. self.touchPosition.y .. ")",
    textAlign = "left",
    fontSize = "md",
    width = "60%",
  }))

  -- Touchable area
  local touchArea = touchSection:appendChild(FlexLove.new({
    display = "flex",
    justifyContent = "center",
    alignItems = "center",
    width = "30%",
    height = "100%",
    backgroundColor = "#4a5568",
    borderRadius = 8,
    padding = { horizontal = 10 },
    onEvent = function(_, event)
      if event.type == "touch" then
        self.touchPosition.x = event.x
        self.touchPosition.y = event.y
      end
    end,
  }))

  touchArea:appendChild(FlexLove.new({
    text = "Touch me!",
    textAlign = "center",
    fontSize = "md",
    width = "100%",
    height = "100%",
  }))

  -- Status section showing interaction counts
  local statusSection = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "space-between",
    alignItems = "center",
    width = "100%",
    height = "20%",
    backgroundColor = "#4a5568",
    borderRadius = 8,
    padding = { horizontal = 15 },
  }))

  statusSection:appendChild(FlexLove.new({
    text = "Hover Count: " .. self.hoverCount,
    textAlign = "left",
    fontSize = "md",
    width = "30%",
  }))

  -- Reset button
  statusSection:appendChild(FlexLove.new({
    themeComponent = "buttonv2",
    text = "Reset All",
    textAlign = "center",
    width = "30%",
    onEvent = function(_, event)
      if event.type == "release" then
        self.mousePosition = { x = 0, y = 0 }
        self.keyPressed = ""
        self.touchPosition = { x = 0, y = 0 }
        self.hoverCount = 0
        self.isMouseOver = false
        print("All input states reset")
      end
    end,
  }))

  return flex
end

return InputExample
