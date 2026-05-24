--[[
  Example: basic_ui.lua
  Shows the CSS/DOM-aligned retained-mode API:
    - display: flex | grid | block | none
    - position: relative | absolute
    - children: prop tables OR pre-built Element instances
    - DOM-style typed event handlers (onClick, onMouseEnter, ...)
    - border shorthand (`"2px solid #fff"`) and transition shorthand
      (`"backgroundColor 200ms ease-in-out"`)
    - direct mutation of backgroundColor / opacity / typed handlers takes
      effect on the next frame without setProperty()

  Pair with the standard LÖVE hooks (see README quick-start).
]]

local FlexLove = require("FlexLove")
local Color = FlexLove.Color

FlexLove.init()

local pressCount = 0
local button -- forward declaration; we attach it via `children` below

local root = FlexLove.new({
  id = "root",
  display = "flex",
  flexDirection = "column",
  justifyContent = "center",
  alignItems = "center",
  gap = 12,
  width = "100vw",
  height = "100vh",
  backgroundColor = Color.fromHex("#101418"),
  children = {
    {
      id = "title",
      text = "FlexLove",
      color = Color.new(1, 1, 1, 1),
      fontSize = "2vh",
    },
    {
      id = "counter",
      text = "Pressed 0 times",
      color = Color.new(0.7, 0.85, 1, 1),
      fontSize = "3vh",
    },
  },
})

-- Build the button standalone so we can reference it from event handlers.
-- Typed onClick is preferred over the catch-all onEvent for new code.
button = FlexLove.new({
  id = "press-me",
  width = 160,
  height = 40,
  backgroundColor = Color.fromHex("#3a78ff"),
  border = "2px solid #ffffff",
  borderRadius = 6,
  transition = "backgroundColor 200ms ease-out",
  text = "Press me",
  color = Color.new(1, 1, 1, 1),
  onClick = function(self)
    pressCount = pressCount + 1
    FlexLove.getElementById("counter").text = string.format("Pressed %d times", pressCount)
    if pressCount % 2 == 0 then
      self.backgroundColor = Color.fromHex("#3a78ff")
    else
      self.backgroundColor = Color.fromHex("#ff6a3a")
    end
  end,
  onMouseEnter = function(self)
    self.opacity = 0.85
  end,
  onMouseLeave = function(self)
    self.opacity = 1
  end,
})

-- Attach the standalone button under root via a row. Children accept Element
-- instances directly; reparenting from topElements is automatic.
local row = FlexLove.new({
  id = "button-row",
  display = "flex",
  flexDirection = "row",
  justifyContent = "center",
  width = "100%",
  children = { button },
})
root:appendChild(row)

return root
