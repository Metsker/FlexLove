--[[
  Example: Advanced Layout with Flexbox and Grid
  This example demonstrates advanced layout techniques using both flexbox and grid layouts
]]

local FlexLove = require("libs.FlexLove")
local Color = FlexLove.Color
local Theme = FlexLove.Theme

-- Create the main window
local window = FlexLove.new({
  x = "10%",
  y = "10%",
  width = "80%",
  height = "80%",
  themeComponent = "framev3",
  display = "flex",
  flexDirection = "column",
  gap = 20,
  padding = { horizontal = 20, vertical = 20 },
})

-- Title
window:appendChild(FlexLove.new({
  text = "Advanced Layout Example",
  textAlign = "center",
  fontSize = "3xl",
  width = "100%",
}))

-- Flex container with complex layout
local flexContainer = window:appendChild(FlexLove.new({
  display = "flex",
  flexDirection = "row",
  justifyContent = "space-between",
  alignItems = "stretch",
  gap = 15,
  height = "70%",
}))

-- Left panel - True Grid Layout
local leftPanel = flexContainer:appendChild(FlexLove.new({
  width = "40%",
  display = "flex",
  flexDirection = "column",
  gap = 10,
  padding = { horizontal = 10, vertical = 10 },
}))

leftPanel:appendChild(FlexLove.new({
  text = "True Grid Layout (3x3)",
  textAlign = "center",
  fontSize = "lg",
  width = "100%",
}))

-- Grid container using display = "grid"
local gridContainer = leftPanel:appendChild(FlexLove.new({
  display = "grid",
  gridRows = 3,
  gridColumns = 3,
  columnGap = 5,
  rowGap = 5,
  height = "80%",
  alignItems = "stretch",
}))

-- Grid items (will auto-flow into cells)
for i = 1, 9 do
  gridContainer:appendChild(FlexLove.new({
    themeComponent = "buttonv2",
    text = "Cell " .. i,
    textAlign = "center",
    fontSize = "md",
    onEvent = function(_, event)
      if event.type == "release" then
        print("Grid cell " .. i .. " clicked")
      end
    end,
  }))
end

-- Right panel - Grid with Headers (like a schedule)
local rightPanel = flexContainer:appendChild(FlexLove.new({
  width = "55%",
  display = "flex",
  flexDirection = "column",
  gap = 10,
}))

rightPanel:appendChild(FlexLove.new({
  text = "Grid with Headers (4x4)",
  textAlign = "center",
  fontSize = "lg",
  width = "100%",
}))

-- Example data for schedule-like grid
local columnHeaders = { "Mon", "Tue", "Wed" }
local rowHeaders = { "Task A", "Task B", "Task C" }

-- Calculate grid dimensions: +1 for header row and column
local numRows = #rowHeaders + 1 -- +1 for header row
local numColumns = #columnHeaders + 1 -- +1 for row labels column

local scheduleGrid = rightPanel:appendChild(FlexLove.new({
  display = "grid",
  gridRows = numRows,
  gridColumns = numColumns,
  columnGap = 2,
  rowGap = 2,
  height = "80%",
  alignItems = "stretch",
}))

local accentColor = Theme.getColor("primary")
local color = Theme.getColor("text")

-- Top-left corner cell (empty)
scheduleGrid:appendChild(FlexLove.new({
}))

-- Column headers
for _, header in ipairs(columnHeaders) do
  scheduleGrid:appendChild(FlexLove.new({
    text = header,
    color = color,
    textAlign = "center",
    backgroundColor = Color.new(0, 0, 0, 0.3),
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = accentColor,
    fontSize = 12,
  }))
end

-- Data rows
for i, rowHeader in ipairs(rowHeaders) do
  -- Row header
  scheduleGrid:appendChild(FlexLove.new({
    text = rowHeader,
    backgroundColor = Color.new(0, 0, 0, 0.3),
    color = color,
    textAlign = "center",
    border = { top = true, right = true, bottom = true, left = true },
    borderColor = accentColor,
    fontSize = 10,
  }))

  -- Data cells
  for j = 1, #columnHeaders do
    local value = (i * j) % 5
    scheduleGrid:appendChild(FlexLove.new({
      text = tostring(value),
      textAlign = "center",
      border = { top = true, right = true, bottom = true, left = true },
      borderColor = Color.new(0.5, 0.5, 0.5, 1.0),
      fontSize = 12,
      themeComponent = "buttonv2",
      onEvent = function(elem, event)
        if event.type == "click" then
          local newValue = (tonumber(elem.text) + 1) % 10
          elem:updateText(tostring(newValue))
          print("Cell [" .. i .. "," .. j .. "] clicked, new value: " .. newValue)
        end
      end,
    }))
  end
end

-- Footer with progress bar
local footer = window:appendChild(FlexLove.new({
  display = "flex",
  flexDirection = "row",
  justifyContent = "space-between",
  alignItems = "center",
  gap = 15,
  height = "20%",
}))

footer:appendChild(FlexLove.new({
  text = "Progress:",
  textAlign = "start",
  fontSize = "md",
}))

local progressContainer = footer:appendChild(FlexLove.new({
  width = "60%",
  height = "30%",
  themeComponent = "framev3",
  display = "flex",
  flexDirection = "row",
  alignItems = "center",
  gap = 5,
}))

-- Progress bar fill
local progressFill = progressContainer:appendChild(FlexLove.new({
  width = "70%",
  height = "100%",
  themeComponent = "buttonv1",
}))

footer:appendChild(FlexLove.new({
  text = "70%",
  textAlign = "end",
  fontSize = "md",
}))
