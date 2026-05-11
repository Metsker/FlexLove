local modulePath = (...):match("(.-)[^%.]+$")
local utils = require(modulePath .. "utils")
local enums = utils.enums

local Positioning = enums.Positioning
local AlignItems = enums.AlignItems

--- Grid layout with variable column widths / row heights
--- Supports px, %, fr, and auto track sizes
local Grid = {}

--- Parse a single track spec into {type, value}
---@param spec number|string Track specification: number (px), string ("100px", "50%", "1fr", "auto")
---@param availableSize number Container size for % resolution
---@return table {type: "px"|"fr"|"auto", value: number}
function Grid._parseTrack(spec, availableSize)
  if type(spec) == "number" then
    return { type = "px", value = spec }
  end

  if type(spec) == "string" then
    if spec == "auto" then
      return { type = "auto", value = 0 }
    end

    -- Match number + unit
    local numStr, unit = spec:match("^([%-]?[%d%.]+)(.*)$")
    if numStr then
      local num = tonumber(numStr)
      if num then
        if unit == "" or unit == "px" then
          return { type = "px", value = num }
        elseif unit == "%" then
          return { type = "px", value = (num / 100) * availableSize }
        elseif unit == "fr" then
          return { type = "fr", value = num }
        end
      end
    end
  end

  -- Default: 1fr
  return { type = "fr", value = 1 }
end

--- Build track list from template or fall back to equal 1fr tracks
---@param template table? Array of track specs (e.g., {"1fr", "2fr", "100px"})
---@param count number Fallback track count (from gridColumns/gridRows)
---@param availableSize number Container size for % resolution
---@return table Array of {type, value} track descriptors
function Grid._buildTracks(template, count, availableSize)
  if template and #template > 0 then
    local tracks = {}
    for i, spec in ipairs(template) do
      tracks[i] = Grid._parseTrack(spec, availableSize)
    end
    return tracks
  end
  -- Fallback: equal 1fr tracks
  local tracks = {}
  for i = 1, count do
    tracks[i] = { type = "fr", value = 1 }
  end
  return tracks
end

--- Measure intrinsic content sizes for auto tracks
--- Maps children to their tracks and computes each child's max-content contribution.
--- For children with explicit dimensions (units unit ~= "auto"), uses the original
--- explicit size. For auto-sized children, uses calculated content size.
--- Stores the max per auto track. Matches CSS Grid auto sizing where tracks size
--- to the max-content contribution of their grid items.
---@param tracks table Array of {type, value} track descriptors
---@param children table Array of grid child elements
---@param axis "width"|"height" Dimension axis to measure
function Grid._measureAutoTracks(tracks, children, axis)
  local trackSizes = {}
  local numTracks = #tracks

  for i, child in ipairs(children) do
    local index = i - 1
    local trackIdx = (index % numTracks) + 1

    local intrinsicSize
    if axis == "width" then
      local unit = child.units and child.units.width and child.units.width.unit
      if unit and unit ~= "auto" then
        -- Explicit width: use original value + padding (not stretched border-box)
        intrinsicSize = (child.units.width.value or 0) + child.padding.left + child.padding.right
      else
        -- Auto-sized: use calculated content size
        intrinsicSize = child:calculateAutoWidth()
      end
    else
      local unit = child.units and child.units.height and child.units.height.unit
      if unit and unit ~= "auto" then
        intrinsicSize = (child.units.height.value or 0) + child.padding.top + child.padding.bottom
      else
        intrinsicSize = child:calculateAutoHeight()
      end
    end

    if intrinsicSize > 0 then
      trackSizes[trackIdx] = math.max(trackSizes[trackIdx] or 0, intrinsicSize)
    end
  end

  -- Apply measured sizes to auto tracks
  for i, track in ipairs(tracks) do
    if track.type == "auto" and trackSizes[i] then
      track.value = trackSizes[i]
    end
  end
end

--- Resolve track sizes: auto (content) first, then px (fixed), then fr (remaining)
--- CSS Grid algorithm:
--- 1. auto tracks size to their content (max-content) — measured by _measureAutoTracks
--- 2. px tracks consume their fixed size
--- 3. fr tracks consume remaining free space proportionally
--- 4. If no fr tracks exist, auto tracks share remaining space equally
--- Mutates tracks in-place, converting all to {type="px", value=number}
---@param tracks table Array of {type, value} track descriptors
---@param availableSize number Total space available for tracks
---@param gap number Gap between tracks
function Grid._resolveTracks(tracks, availableSize, gap)
  local count = #tracks
  local totalGaps = (count > 1 and (count - 1) * gap) or 0
  local remaining = math.max(0, availableSize - totalGaps)

  -- Pass 1: Treat auto tracks as fixed (content-measured) and subtract
  for _, track in ipairs(tracks) do
    if track.type == "px" then
      remaining = remaining - track.value
    elseif track.type == "auto" then
      remaining = remaining - math.max(0, track.value)
    end
  end

  -- Pass 2: Count fr shares
  local totalFr = 0
  local autoCount = 0
  for _, track in ipairs(tracks) do
    if track.type == "fr" then
      totalFr = totalFr + track.value
    elseif track.type == "auto" then
      autoCount = autoCount + 1
    end
  end

  -- Pass 3: Distribute remaining space
  if totalFr > 0 then
    -- fr tracks consume all remaining free space
    local frUnit = remaining / totalFr
    for _, track in ipairs(tracks) do
      if track.type == "fr" then
        track.value = frUnit * track.value
        track.type = "px"
      end
    end
  elseif autoCount > 0 then
    -- No fr tracks: auto tracks share remaining space equally (grow beyond content)
    local extraPerAuto = math.max(0, remaining) / autoCount
    for _, track in ipairs(tracks) do
      if track.type == "auto" then
        track.value = track.value + extraPerAuto
        track.type = "px"
      end
    end
  end
end

--- Layout grid items within a grid container
--- Supports variable column widths and row heights via gridTemplateColumns/gridTemplateRows
--- Falls back to equal-sized cells via gridRows/gridColumns for backward compatibility
---@param element Element -- Grid container element
function Grid.layoutGridItems(element)
  -- Ensure valid row/column counts (must be at least 1 to avoid division by zero)
  local rows = element.gridRows and element.gridRows > 0 and element.gridRows or 1
  local columns = element.gridColumns and element.gridColumns > 0 and element.gridColumns or 1

  -- Calculate space reserved by absolutely positioned siblings
  local reservedLeft = 0
  local reservedRight = 0
  local reservedTop = 0
  local reservedBottom = 0

  for _, child in ipairs(element.children) do
    -- Only consider absolutely positioned children with explicit positioning
    if child.positioning == Positioning.ABSOLUTE and child._explicitlyAbsolute then
      -- BORDER-BOX MODEL: Use border-box dimensions for space calculations
      local childBorderBoxWidth = child:getBorderBoxWidth()
      local childBorderBoxHeight = child:getBorderBoxHeight()

      if child.left then
        reservedLeft = math.max(reservedLeft, child.left + childBorderBoxWidth)
      end
      if child.right then
        reservedRight = math.max(reservedRight, child.right + childBorderBoxWidth)
      end
      if child.top then
        reservedTop = math.max(reservedTop, child.top + childBorderBoxHeight)
      end
      if child.bottom then
        reservedBottom = math.max(reservedBottom, child.bottom + childBorderBoxHeight)
      end
    end
  end

  -- Calculate available space (accounting for padding and reserved space)
  -- BORDER-BOX MODEL: element.width and element.height are already content dimensions
  local availableWidth = element.width - reservedLeft - reservedRight
  local availableHeight = element.height - reservedTop - reservedBottom

  -- Get gaps
  local columnGap = element.columnGap or 0
  local rowGap = element.rowGap or 0

  -- Collect grid children (exclude explicitly absolute)
  local gridChildren = {}
  for _, child in ipairs(element.children) do
    if not (child.positioning == Positioning.ABSOLUTE and child._explicitlyAbsolute) then
      table.insert(gridChildren, child)
    end
  end

  -- Build tracks, measure auto tracks by content, then resolve sizes
  local colTracks = Grid._buildTracks(element.gridTemplateColumns, columns, availableWidth)
  local rowTracks = Grid._buildTracks(element.gridTemplateRows, rows, availableHeight)

  Grid._measureAutoTracks(colTracks, gridChildren, "width")
  Grid._measureAutoTracks(rowTracks, gridChildren, "height")

  Grid._resolveTracks(colTracks, availableWidth, columnGap)
  Grid._resolveTracks(rowTracks, availableHeight, rowGap)

  -- Compute column start positions (for positioning)
  local colStarts = {}
  local currentX = element.x + element.padding.left + reservedLeft
  for col = 1, #colTracks do
    colStarts[col] = currentX
    currentX = currentX + colTracks[col].value + columnGap
  end

  local rowStarts = {}
  local currentY = element.y + element.padding.top + reservedTop
  for row = 1, #rowTracks do
    rowStarts[row] = currentY
    currentY = currentY + rowTracks[row].value + rowGap
  end

  local effectiveAlignItems = element.alignItems or AlignItems.STRETCH

  for i, child in ipairs(gridChildren) do
    -- Calculate row and column (0-indexed for calculation)
    local index = i - 1
    local col = index % #colTracks
    local row = math.floor(index / #colTracks)

    if row >= #rowTracks then
      break
    end

    -- Get resolved cell position and size
    local colIdx = col + 1
    local rowIdx = row + 1
    local cellX = colStarts[colIdx]
    local cellY = rowStarts[rowIdx]
    local cellWidth = colTracks[colIdx].value
    local cellHeight = rowTracks[rowIdx].value

    -- Apply alignment within grid cell (default to stretch)
    -- BORDER-BOX MODEL: Set border-box dimensions, content area adjusts automatically
    if effectiveAlignItems == AlignItems.STRETCH or effectiveAlignItems == "stretch" then
      child.x = cellX
      child.y = cellY
      child._borderBoxWidth = cellWidth
      child._borderBoxHeight = cellHeight
      child.width = math.max(0, cellWidth - child.padding.left - child.padding.right)
      child.height = math.max(0, cellHeight - child.padding.top - child.padding.bottom)
      -- Disable auto-sizing when stretched by grid
      child.autosizing.width = false
      child.autosizing.height = false
    elseif effectiveAlignItems == AlignItems.CENTER or effectiveAlignItems == "center" then
      local childBorderBoxWidth = child:getBorderBoxWidth()
      local childBorderBoxHeight = child:getBorderBoxHeight()
      child.x = cellX + (cellWidth - childBorderBoxWidth) / 2
      child.y = cellY + (cellHeight - childBorderBoxHeight) / 2
    elseif
      effectiveAlignItems == AlignItems.FLEX_START
      or effectiveAlignItems == "flex-start"
      or effectiveAlignItems == "start"
    then
      child.x = cellX
      child.y = cellY
    elseif
      effectiveAlignItems == AlignItems.FLEX_END
      or effectiveAlignItems == "flex-end"
      or effectiveAlignItems == "end"
    then
      local childBorderBoxWidth = child:getBorderBoxWidth()
      local childBorderBoxHeight = child:getBorderBoxHeight()
      child.x = cellX + cellWidth - childBorderBoxWidth
      child.y = cellY + cellHeight - childBorderBoxHeight
    else
      child.x = cellX
      child.y = cellY
      child._borderBoxWidth = cellWidth
      child._borderBoxHeight = cellHeight
      child.width = math.max(0, cellWidth - child.padding.left - child.padding.right)
      child.height = math.max(0, cellHeight - child.padding.top - child.padding.bottom)
      -- Disable auto-sizing when stretched by grid
      child.autosizing.width = false
      child.autosizing.height = false
    end

    if #child.children > 0 then
      child:layoutChildren()
    end
  end
end

return Grid
