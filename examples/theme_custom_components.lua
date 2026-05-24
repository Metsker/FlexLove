-- Example: Theming and Custom Components
-- This demonstrates how to use themes and create custom components

local FlexLove = require("libs.FlexLove")

local ThemeExample = {}

function ThemeExample:new()
  local obj = {
    themeIndex = 1,
    themes = { "space", "metal" },
  }
  setmetatable(obj, { __index = self })
  return obj
end

function ThemeExample:render()
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
    text = "Theming and Custom Components Example",
    textAlign = "center",
    fontSize = "2xl",
    width = "100%",
    height = "10%",
  }))

  -- Theme selector
  local themeSelector = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "row",
    justifyContent = "space-between",
    alignItems = "center",
    width = "100%",
    height = "10%",
    backgroundColor = "#2d3748",
    borderRadius = 8,
    padding = { horizontal = 10 },
  }))

  themeSelector:appendChild(FlexLove.new({
    text = "Current Theme: " .. self.themes[self.themeIndex],
    textAlign = "left",
    fontSize = "md",
    width = "50%",
  }))

  themeSelector:appendChild(FlexLove.new({
    themeComponent = "buttonv2",
    text = "Switch Theme",
    textAlign = "center",
    width = "30%",
    onEvent = function(_, event)
      if event.type == "release" then
        self.themeIndex = (self.themeIndex % #self.themes) + 1
        -- In a real app, you'd update the theme here
        print("Theme switched to: " .. self.themes[self.themeIndex])
      end
    end,
  }))

  -- Custom component example - A styled card
  local customCard = flex:appendChild(FlexLove.new({
    display = "flex",
    flexDirection = "column",
    justifyContent = "center",
    alignItems = "center",
    width = "100%",
    height = "40%",
    themeComponent = "cardv2", -- Uses theme styling
    padding = { horizontal = 20, vertical = 20 },
    margin = { top = 10 },
  }))

  customCard:appendChild(FlexLove.new({
    text = "Custom Card Component",
    textAlign = "center",
    fontSize = "lg",
    width = "100%",
    height = "30%",
  }))

  customCard:appendChild(FlexLove.new({
    text = "This demonstrates how to create reusable components with theme support",
    textAlign = "center",
    fontSize = "sm",
    width = "100%",
    height = "50%",
    color = "#a0aec0", -- Light gray text
  }))

  -- Another custom component - Status indicator
  local statusIndicator = flex:appendChild(FlexLove.new({
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

  statusIndicator:appendChild(FlexLove.new({
    text = "Status: Active",
    textAlign = "left",
    fontSize = "md",
    width = "50%",
  }))

  local statusDot = statusIndicator:appendChild(FlexLove.new({
    display = "flex",
    width = 20,
    height = 20,
    backgroundColor = "#48bb78", -- Green dot
    borderRadius = 10, -- Circle
  }))

  return flex
end

return ThemeExample
