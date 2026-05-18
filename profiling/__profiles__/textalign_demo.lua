-- Flexible TextAlign Demo
-- Showcases all textAlign formats: simple strings, compound strings, and table syntax

local FlexLove = require("FlexLove")

local profile = {
  name = "TextAlign Demo",
  description = "Visual demo of all flexible textAlign formats",
}

local Color = FlexLove.Color

local BG_DARK = Color.new(0.08, 0.08, 0.12, 1)
local BG_CARD = Color.new(0.12, 0.12, 0.18, 1)
local BG_CELL = Color.new(0.18, 0.18, 0.25, 1)
local TEXT_LABEL = Color.new(0.5, 0.5, 0.6, 1)
local TEXT_VALUE = Color.new(0.3, 0.8, 1, 1)
local BORDER = Color.new(0.25, 0.25, 0.35, 1)
local HIGHLIGHT = Color.new(0.3, 0.6, 1, 0.15)

local function cellSize(index)
  return 160, 100
end

function profile.init()
  FlexLove.init({
    immediateMode = true,
  })
end

function profile.draw()
  FlexLove.beginFrame()

  local sw, sh = love.graphics.getDimensions()

  -- Root
  local root = FlexLove.new({
    width = sw,
    height = sh,
    backgroundColor = BG_DARK,
    positioning = "flex",
    flexDirection = "vertical",
    alignItems = "center",
    padding = { horizontal = 20, vertical = 16 },
  })

  -- Title
  FlexLove.new({
    parent = root,
    text = "Flexible TextAlign Demo",
    textSize = 28,
    textColor = TEXT_VALUE,
    textAlign = "center",
    width = "100%",
    margin = { bottom = 8 },
  })

  -- Subtitle
  FlexLove.new({
    parent = root,
    text = 'Compound strings ("top-left" → "bottom-right") | Table syntax ({horizontal, vertical})',
    textSize = 13,
    textColor = TEXT_LABEL,
    textAlign = "center",
    width = "100%",
    margin = { bottom = 16 },
    textWrap = "word",
  })

  -- Scrollable content area
  local content = FlexLove.new({
    parent = root,
    width = "100%",
    height = "100%",
    positioning = "flex",
    flexDirection = "vertical",
    gap = 8,
    overflowY = "scroll",
  })

  -- Helper: create a visual cell showing text alignment
  local function addAlignmentCell(parent, alignValue, label, note)
    local row = FlexLove.new({
      parent = parent,
      width = "100%",
      height = 100,
      positioning = "flex",
      flexDirection = "horizontal",
      gap = 12,
      alignItems = "center",
    })

    -- Label column
    local labelCol = FlexLove.new({
      parent = row,
      width = 220,
      height = "100%",
      positioning = "flex",
      flexDirection = "vertical",
      justifyContent = "center",
      padding = { left = 8 },
    })

    local alignStr
    if type(alignValue) == "table" then
      alignStr = "{h=" .. alignValue.horizontal .. ", v=" .. alignValue.vertical .. "}"
    else
      alignStr = '"' .. alignValue .. '"'
    end

    FlexLove.new({
      parent = labelCol,
      text = alignStr,
      textSize = 13,
      textColor = TEXT_VALUE,
      fontFamily = "mono",
    })

    if note then
      FlexLove.new({
        parent = labelCol,
        text = note,
        textSize = 11,
        textColor = TEXT_LABEL,
        margin = { top = 2 },
      })
    end

    -- Cell visual area (shows where text lands)
    local cell = FlexLove.new({
      parent = row,
      width = 160,
      height = 100,
      backgroundColor = BG_CELL,
      border = { all = true },
      borderColor = BORDER,
      text = "Abc",
      textSize = 14,
      textColor = TEXT_VALUE,
      textAlign = alignValue,
    })
  end

  -- Section: Simple strings (backward compat)
  FlexLove.new({
    parent = content,
    text = "Simple strings (backward compatible)",
    textSize = 16,
    textColor = TEXT_LABEL,
    margin = { top = 8, bottom = 4 },
  })

  addAlignmentCell(content, "start")
  addAlignmentCell(content, "center", '"center" now centers horizontally ONLY (fixed!)')
  addAlignmentCell(content, "end")

  -- Section: Compound strings
  FlexLove.new({
    parent = content,
    text = "Compound strings (9 combinations)",
    textSize = 16,
    textColor = TEXT_LABEL,
    margin = { top = 16, bottom = 4 },
  })

  addAlignmentCell(content, "top-left")
  addAlignmentCell(content, "top-center")
  addAlignmentCell(content, "top-right")
  addAlignmentCell(content, "center-left")
  addAlignmentCell(content, "center-center")
  addAlignmentCell(content, "center-right")
  addAlignmentCell(content, "bottom-left")
  addAlignmentCell(content, "bottom-center")
  addAlignmentCell(content, "bottom-right")

  -- Section: Table syntax
  FlexLove.new({
    parent = content,
    text = "Table syntax ({horizontal, vertical})",
    textSize = 16,
    textColor = TEXT_LABEL,
    margin = { top = 16, bottom = 4 },
  })

  addAlignmentCell(content, { horizontal = "start", vertical = "end" }, "top-right area")
  addAlignmentCell(content, { horizontal = "center", vertical = "center" }, "fully centered on both axes")
  addAlignmentCell(content, { horizontal = "end", vertical = "end" }, "bottom-right area")
  addAlignmentCell(content, { horizontal = "center", vertical = "start" }, "top-center (horizontal only)")

  -- Bottom spacer
  FlexLove.new({
    parent = content,
    height = 40,
    width = "100%",
  })

  FlexLove.endFrame()
  FlexLove.draw()
end

function profile.cleanup()
  FlexLove.destroy()
end

return profile
