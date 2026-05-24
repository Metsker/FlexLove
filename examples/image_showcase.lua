-- Image Showcase Example
-- Demonstrates all image features in FlexLove

local FlexLove = require("libs.FlexLove")
local Color = FlexLove.Color
-- I use this to avoid lsp warnings
local lv = love

-- Set to immediate mode for this example
FlexLove.setMode("immediate")

function lv.load()
  -- Set window size
  lv.window.setMode(1200, 800, { resizable = true })
  lv.window.setTitle("FlexLove Image Showcase")
end

function lv.draw()
  local container = FlexLove.new({
    width = "100vw",
    height = "100vh",
    display = "flex",
    flexDirection = "column",
    gap = 20,
    backgroundColor = Color.new(0.95, 0.95, 0.95, 1),
    overflow = "scroll",
    padding = { top = 20, right = 20, bottom = 20, left = 20 },
  })

  -- Title
  container:appendChild(FlexLove.new({
    text = "FlexLove Image Showcase",
    fontSize = "xxl",
    color = Color.new(0.2, 0.2, 0.2, 1),
    textAlign = "center",
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 0, right = 0, bottom = 20, left = 0 },
  }))

  -- Section 1: Object-Fit Modes
  local fitSection = container:appendChild(FlexLove.new({
    width = "100%",
    flexDirection = "column",
    gap = 10,
  }))

  fitSection:appendChild(FlexLove.new({
    text = "Object-Fit Modes",
    fontSize = "lg",
    color = Color.new(0.3, 0.3, 0.3, 1),
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 5, right = 0, bottom = 5, left = 0 },
  }))

  local fitRow = fitSection:appendChild(FlexLove.new({
    width = "100%",
    display = "flex",
    flexDirection = "row",
    gap = 15,
    justifyContent = "space-between",
    alignItems = "flex-start",
    padding = { top = 30 },
  }))

  local fitModes = { "fill", "contain", "cover", "scale-down", "none" }
  local fitSizes = {
    { width = 200, height = 140, imgWidth = 180, imgHeight = 100 },
    { width = 160, height = 120, imgWidth = 140, imgHeight = 80 },
    { width = 220, height = 160, imgWidth = 200, imgHeight = 120 },
    { width = 180, height = 130, imgWidth = 160, imgHeight = 90 },
    { width = 190, height = 150, imgWidth = 170, imgHeight = 110 },
  }

  for i, mode in ipairs(fitModes) do
    local size = fitSizes[i]
    local fitBox = fitRow:appendChild(FlexLove.new({
      width = size.width,
      height = size.height,
      display = "flex",
      flexDirection = "column",
      gap = 5,
      backgroundColor = Color.new(1, 1, 1, 1),
      borderRadius = 8,
      padding = { top = 10, right = 10, bottom = 10, left = 10 },
    }))

    fitBox:appendChild(FlexLove.new({
      width = size.imgWidth,
      height = size.imgHeight,
      backgroundColor = Color.new(0.9, 0.9, 0.9, 1),
      backgroundImage = "sample.jpg",
      backgroundSize = mode,
    }))

    fitBox:appendChild(FlexLove.new({
      text = mode,
      fontSize = "sm",
      color = Color.new(0.4, 0.4, 0.4, 1),
      textAlign = "center",
      textWrap = "word",
      width = "100%",
      z = 1000,
      padding = { top = 3, right = 0, bottom = 3, left = 0 },
    }))
  end

  -- Section 2: Object-Position
  local posSection = container:appendChild(FlexLove.new({
    width = "100%",
    flexDirection = "column",
    gap = 10,
  }))

  posSection:appendChild(FlexLove.new({
    text = "Object-Position",
    fontSize = "lg",
    color = Color.new(0.3, 0.3, 0.3, 1),
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 5, right = 0, bottom = 5, left = 0 },
  }))

  local posRow = posSection:appendChild(FlexLove.new({
    width = "100%",
    display = "flex",
    flexDirection = "row",
    gap = 15,
    justifyContent = "space-between",
    alignItems = "flex-start",
    padding = { top = 30 },
  }))

  local positions = { "top left", "center center", "bottom right", "50% 20%", "left center" }
  local posSizes = {
    { width = 170, height = 130, imgWidth = 150, imgHeight = 90 },
    { width = 210, height = 150, imgWidth = 190, imgHeight = 110 },
    { width = 180, height = 140, imgWidth = 160, imgHeight = 100 },
    { width = 195, height = 135, imgWidth = 175, imgHeight = 95 },
    { width = 185, height = 145, imgWidth = 165, imgHeight = 105 },
  }

  for i, pos in ipairs(positions) do
    local size = posSizes[i]
    local posBox = posRow:appendChild(FlexLove.new({
      width = size.width,
      height = size.height,
      display = "flex",
      flexDirection = "column",
      gap = 5,
      backgroundColor = Color.new(1, 1, 1, 1),
      borderRadius = 8,
      padding = { top = 10, right = 10, bottom = 10, left = 10 },
    }))

    posBox:appendChild(FlexLove.new({
      width = size.imgWidth,
      height = size.imgHeight,
      backgroundColor = Color.new(0.9, 0.9, 0.9, 1),
      backgroundImage = "sample.jpg",
      backgroundSize = "none",
      backgroundPosition = pos,
    }))

    posBox:appendChild(FlexLove.new({
      text = pos,
      fontSize = "xs",
      color = Color.new(0.4, 0.4, 0.4, 1),
      textAlign = "center",
      textWrap = "word",
      width = "100%",
      z = 1000,
      padding = { top = 3, right = 0, bottom = 3, left = 0 },
    }))
  end

  -- Section 3: Image Tiling/Repeat
  local tileSection = container:appendChild(FlexLove.new({
    width = "100%",
    flexDirection = "column",
    gap = 10,
  }))

  tileSection:appendChild(FlexLove.new({
    text = "Image Tiling (Repeat Modes)",
    fontSize = "lg",
    color = Color.new(0.3, 0.3, 0.3, 1),
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 5, right = 0, bottom = 5, left = 0 },
  }))

  local tileRow = tileSection:appendChild(FlexLove.new({
    width = "100%",
    display = "flex",
    flexDirection = "row",
    gap = 20,
    justifyContent = "space-between",
    alignItems = "flex-start",
    padding = { top = 30 },
  }))

  local repeatModes = { "no-repeat", "repeat", "repeat-x", "repeat-y" }
  local tileSizes = {
    { width = 260, height = 140, imgWidth = 240, imgHeight = 100 },
    { width = 240, height = 130, imgWidth = 220, imgHeight = 90 },
    { width = 280, height = 150, imgWidth = 260, imgHeight = 110 },
    { width = 250, height = 135, imgWidth = 230, imgHeight = 95 },
  }

  for i, mode in ipairs(repeatModes) do
    local size = tileSizes[i]
    local tileBox = tileRow:appendChild(FlexLove.new({
      width = size.width,
      height = size.height,
      display = "flex",
      flexDirection = "column",
      gap = 5,
      backgroundColor = Color.new(1, 1, 1, 1),
      borderRadius = 8,
      padding = { top = 10, right = 10, bottom = 10, left = 10 },
    }))

    tileBox:appendChild(FlexLove.new({
      width = size.imgWidth,
      height = size.imgHeight,
      backgroundColor = Color.new(0.9, 0.9, 0.9, 1),
      backgroundImage = "sample.jpg",
      backgroundRepeat = mode,
    }))

    tileBox:appendChild(FlexLove.new({
      text = mode,
      fontSize = "sm",
      color = Color.new(0.4, 0.4, 0.4, 1),
      textAlign = "center",
      textWrap = "word",
      width = "100%",
      z = 1000,
      padding = { top = 3, right = 0, bottom = 3, left = 0 },
    }))
  end

  -- Section 4: Image Tinting and Opacity
  local tintSection = container:appendChild(FlexLove.new({
    width = "100%",
    flexDirection = "column",
    gap = 10,
  }))

  tintSection:appendChild(FlexLove.new({
    text = "Image Tinting & Opacity",
    fontSize = "lg",
    color = Color.new(0.3, 0.3, 0.3, 1),
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 5, right = 0, bottom = 5, left = 0 },
  }))

  local tintRow = tintSection:appendChild(FlexLove.new({
    width = "100%",
    display = "flex",
    flexDirection = "row",
    gap = 15,
    justifyContent = "space-between",
    alignItems = "flex-start",
    padding = { top = 30 },
  }))

  local tints = {
    { name = "No Tint", color = nil, opacity = 1 },
    { name = "Red Tint", color = Color.new(1, 0.5, 0.5, 1), opacity = 1 },
    { name = "Blue Tint", color = Color.new(0.5, 0.5, 1, 1), opacity = 1 },
    { name = "50% Opacity", color = nil, opacity = 0.5 },
    { name = "Green + 70%", color = Color.new(0.5, 1, 0.5, 1), opacity = 0.7 },
  }

  local tintSizes = {
    { width = 185, height = 135, imgWidth = 165, imgHeight = 95 },
    { width = 200, height = 145, imgWidth = 180, imgHeight = 105 },
    { width = 175, height = 130, imgWidth = 155, imgHeight = 90 },
    { width = 195, height = 140, imgWidth = 175, imgHeight = 100 },
    { width = 190, height = 150, imgWidth = 170, imgHeight = 110 },
  }

  for i, tint in ipairs(tints) do
    local size = tintSizes[i]
    local tintBox = tintRow:appendChild(FlexLove.new({
      width = size.width,
      height = size.height,
      display = "flex",
      flexDirection = "column",
      gap = 5,
      backgroundColor = Color.new(1, 1, 1, 1),
      borderRadius = 8,
      padding = { top = 10, right = 10, bottom = 10, left = 10 },
    }))

    tintBox:appendChild(FlexLove.new({
      width = size.imgWidth,
      height = size.imgHeight,
      backgroundColor = Color.new(0.9, 0.9, 0.9, 1),
      backgroundImage = "sample.jpg",
      imageTint = tint.color,
      backgroundOpacity = tint.opacity,
    }))

    tintBox:appendChild(FlexLove.new({
      text = tint.name,
      fontSize = "xs",
      color = Color.new(0.4, 0.4, 0.4, 1),
      textAlign = "center",
      textWrap = "word",
      width = "100%",
      z = 1000,
      padding = { top = 3, right = 0, bottom = 3, left = 0 },
    }))
  end

  -- Footer note
  container:appendChild(FlexLove.new({
    text = "Image showcase demonstrating various FlexLove image properties",
    fontSize = "xs",
    color = Color.new(0.5, 0.5, 0.5, 1),
    textAlign = "center",
    textWrap = "word",
    width = "100%",
    z = 1000,
    padding = { top = 10, right = 0, bottom = 10, left = 0 },
  }))
end

function lv.mousepressed(x, y, button)
  FlexLove.mousepressed(x, y, button)
end

function lv.mousereleased(x, y, button)
  FlexLove.mousereleased(x, y, button)
end

function lv.mousemoved(x, y, dx, dy)
  FlexLove.mousemoved(x, y, dx, dy)
end
