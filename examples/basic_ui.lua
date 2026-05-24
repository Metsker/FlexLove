--[[
  Example: basic_ui.lua
  Demonstrates the CSS-style retained-mode API:
    - display: flex | grid | block | none
    - position: relative | absolute
    - children: build trees declaratively, either with prop tables OR
      pre-constructed Element instances
    - direct mutation of backgroundColor, opacity, onEvent, etc. takes
      effect on the next frame without setProperty()

  Pair with main.lua hooks:
    function love.load()  require("examples.basic_ui") end
    function love.update(dt) FlexLove.update(dt) end
    function love.draw()  FlexLove.draw() end
    function love.mousepressed(x, y, button) ... end   -- forward to FlexLove
]]

local FlexLove = require("FlexLove")
local Color = FlexLove.Color

FlexLove.init()

local pressCount = 0
local button -- forward declaration: we mutate the button below

-- Build a small UI tree in one declaration. `children` accepts either
-- prop tables (constructed in place) or pre-built Element instances.
local root = FlexLove.new({
  id = "root",
  display = "flex",
  flexDirection = "vertical",
  justifyContent = "center",
  alignItems = "center",
  gap = 12,
  width = "100vw",
  height = "100vh",
  backgroundColor = Color.fromHex("#101418"),
  children = {
    {
      id = "title",
      text = "FlexLove - retained mode",
      textColor = Color.new(1, 1, 1, 1),
      textSize = "2vh",
    },
    {
      id = "counter",
      text = "Pressed 0 times",
      textColor = Color.new(0.7, 0.85, 1, 1),
      textSize = "3vh",
    },
  },
})

-- Build the button standalone, then attach it via the children prop of a
-- separate row. This is the recommended pattern for any component you
-- want to refer back to from your own code.
button = FlexLove.new({
  id = "press-me",
  width = 160,
  height = 40,
  backgroundColor = Color.fromHex("#3a78ff"),
  cornerRadius = 6,
  text = "Press me",
  textColor = Color.new(1, 1, 1, 1),
  onEvent = function(self, event)
    if event.type == "release" then
      pressCount = pressCount + 1
      -- Direct mutation: no setProperty() call required.
      FlexLove.getById("counter").text = string.format("Pressed %d times", pressCount)
      -- Toggle background color on the button itself.
      if pressCount % 2 == 0 then
        self.backgroundColor = Color.fromHex("#3a78ff")
      else
        self.backgroundColor = Color.fromHex("#ff6a3a")
      end
    end
  end,
})

-- Reparent the standalone button into the root by reusing the children prop
-- with an already-built Element instance.
FlexLove.new({
  id = "button-row",
  display = "flex",
  flexDirection = "horizontal",
  justifyContent = "center",
  width = "100%",
  children = { button },
})

-- The above row was created without a parent so it sat in topElements;
-- attaching it under root keeps the tree clean.
root:addChild(FlexLove.getById("button-row"))

return root
