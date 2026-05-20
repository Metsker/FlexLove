-- Display Toggle Stress Profile
-- Tests mass toggling of the display property across varying element counts and depths.
-- Measures toggle operation time to identify performance bottlenecks in the layout cache
-- invalidation and re-layout pipeline.
--
-- Controls:
--   1/2/3  : Toggle display on 20 / 50 / 100 elements at leaf depth
--   Q/W/E  : Toggle display on 20 / 50 / 100 elements at mid depth
--   A/D/Z  : Toggle display on 20 / 50 / 100 elements at root depth (affects entire subtrees)
--   +/-    : Increase / decrease total element count by 50
--   R      : Reset to default (200 elements)
--   SPACE  : Toggle auto-toggle (automatically cycles batches)
--   F1     : Toggle profiler overlay on/off (global)

local FlexLove = require("FlexLove")
local Color = FlexLove.Color

local profile = {
  elementCount = 200,
  elementPool = {},
  toggledElements = {},
  toggleState = false,
  autoToggle = false,
  autoTimer = 0,

  -- Batch sizes triggered by keys
  batchSizes = { 20, 50, 100 },

  -- Track timing for overlay display
  lastToggleTime = nil,
  lastToggleCount = 0,
  lastToggleDepth = "none",
}

-- Generate a deterministic-ish color from an index
local function getColor(i, total)
  local hue = (i - 1) / math.max(total, 1)
  return Color.new(
    0.3 + 0.5 * math.sin(hue * math.pi * 2),
    0.3 + 0.5 * math.sin((hue + 0.33) * math.pi * 2),
    0.3 + 0.5 * math.sin((hue + 0.66) * math.pi * 2),
    1
  )
end

-- Build the full element tree
function profile.buildLayout()
  profile.elementPool = {}
  profile.toggledElements = {}
  profile.toggleState = false

  profile.root = FlexLove.new({
    width = "100%",
    height = "100%",
    backgroundColor = Color.new(0.05, 0.05, 0.1, 1),
    positioning = "flex",
    flexDirection = "vertical",
    overflowY = "scroll",
    padding = { horizontal = 20, vertical = 20 },
    gap = 8,
  })

  -- Title bar
  FlexLove.new({
    parent = profile.root,
    text = "Display Toggle Stress Profile",
    textSize = "3xl",
    textColor = Color.new(0.3, 0.8, 1, 1),
  })

  -- Layout: create rows of elements with varying depths
  local elementsPerRow = math.floor(math.sqrt(profile.elementCount))
  local rows = math.ceil(profile.elementCount / elementsPerRow)
  local totalElements = 0

  for r = 1, rows do
    local row = FlexLove.new({
      parent = profile.root,
      positioning = "flex",
      flexDirection = "horizontal",
      gap = 6,
      flexWrap = "wrap",
    })

    local itemsInRow = math.min(elementsPerRow, profile.elementCount - (r - 1) * elementsPerRow)
    for c = 1, itemsInRow do
      totalElements = totalElements + 1
      local color = getColor(totalElements, profile.elementCount)

      -- Leaf-depth element (no children, standalone)
      local leaf = FlexLove.new({
        parent = row,
        width = 60,
        height = 60,
        backgroundColor = color,
        borderRadius = 6,
      })
      table.insert(profile.elementPool, leaf)

      -- Mid-depth element (has one child)
      local mid = FlexLove.new({
        parent = row,
        width = 60,
        height = 60,
        backgroundColor = Color.new(color.r * 0.85, color.g * 0.85, color.b * 0.85, 1),
        borderRadius = 6,
        positioning = "flex",
        justifyContent = "center",
        alignItems = "center",
      })
      table.insert(profile.elementPool, mid)

      local midChild = FlexLove.new({
        parent = mid,
        width = "60%",
        height = "60%",
        backgroundColor = Color.new(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1),
        borderRadius = 4,
      })
      table.insert(profile.elementPool, midChild)

      -- Root-depth element (two levels of nesting)
      local rootElem = FlexLove.new({
        parent = row,
        width = 60,
        height = 60,
        backgroundColor = Color.new(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1),
        borderRadius = 6,
        positioning = "flex",
        justifyContent = "center",
        alignItems = "center",
      })
      table.insert(profile.elementPool, rootElem)

      local rootChild = FlexLove.new({
        parent = rootElem,
        width = "70%",
        height = "70%",
        backgroundColor = Color.new(color.r * 0.55, color.g * 0.55, color.b * 0.55, 1),
        borderRadius = 4,
        positioning = "flex",
        justifyContent = "center",
        alignItems = "center",
      })
      table.insert(profile.elementPool, rootChild)

      local rootGrandchild = FlexLove.new({
        parent = rootChild,
        width = "60%",
        height = "60%",
        backgroundColor = Color.new(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1),
        borderRadius = 3,
      })
      table.insert(profile.elementPool, rootGrandchild)
    end
  end

  -- Build the info/controls panel
  profile.buildControls()
end

function profile.buildControls()
  -- Controls panel at the top
  local controls = FlexLove.new({
    parent = profile.root,
    positioning = "flex",
    flexDirection = "horizontal",
    flexWrap = "wrap",
    gap = 10,
    padding = { vertical = 10, horizontal = 10 },
    backgroundColor = Color.new(0.1, 0.12, 0.2, 0.9),
    borderRadius = 8,
  })

  -- Info text
  FlexLove.new({
    parent = controls,
    text = string.format("Elements: %d | Pool: %d", profile.elementCount, #profile.elementPool),
    textColor = Color.new(1, 1, 1, 1),
    textSize = "md",
  })

  if profile.autoToggle then
    FlexLove.new({
      parent = controls,
      text = "AUTO-TOGGLE ON",
      textColor = Color.new(0.3, 1, 0.3, 1),
      textSize = "md",
    })
  end
end

function profile.init()
  FlexLove.init({
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),
  })

  profile.buildLayout()
end

-- Toggle display on `count` elements at the given depth strategy
-- depth: "leaf" (standalone), "mid" (parent + 1 child), "root" (parent + children + grandchildren)
function profile.toggleDisplay(count, depth)
  count = math.min(count, #profile.elementPool)

  -- Select elements based on depth strategy
  local selected = {}
  local pool = profile.elementPool

  if depth == "leaf" then
    -- Last N elements (leaf-level boxes with no children affected)
    for i = math.max(1, #pool - count + 1), #pool do
      table.insert(selected, pool[i])
    end
  elseif depth == "mid" then
    -- Middle N elements (mid-depth parents)
    -- Each original element generates 6 pool entries in order: leaf(1), mid(2), midChild(3), root(4), rootChild(5), rootGrandchild(6)
    -- For "mid", we toggle the mid parent (index 2 in each group of 6)
    local totalGroups = math.floor(#pool / 6)
    local midStart = math.max(1, math.floor((totalGroups - count) / 2) + 1)
    for i = 1, count do
      local idx = (midStart + i - 2) * 6 + 2 -- index 2 in each group
      if idx >= 2 and idx <= #pool then
        table.insert(selected, pool[idx])
      end
    end
  elseif depth == "root" then
    -- First N root-depth elements (index 4 in each group of 6)
    for i = 1, count do
      local idx = (i - 1) * 6 + 4
      if idx <= #pool then
        table.insert(selected, pool[idx])
      end
    end
  end

  if #selected == 0 then
    return 0
  end

  local newState = not profile.toggleState
  local startTime = love.timer.getTime()

  -- Toggle display on selected elements
  for _, elem in ipairs(selected) do
    elem.display = newState
  end

  -- Force re-layout on root so display=false children are excluded from layout
  if profile.root then
    profile.root._dirty = true
    profile.root._childrenDirty = true
    profile.root:layoutChildren()
  end

  local elapsed = (love.timer.getTime() - startTime) * 1000

  profile.toggleState = newState
  profile.lastToggleTime = elapsed
  profile.lastToggleCount = #selected
  profile.lastToggleDepth = depth

  return #selected
end

function profile.update(dt)
  -- Auto-toggle support
  if profile.autoToggle then
    profile.autoTimer = profile.autoTimer + dt
    if profile.autoTimer >= 0.5 then -- Toggle every 500ms
      profile.autoTimer = 0
      profile.toggleDisplay(20, "leaf")
    end
  end
end

function profile.draw()
  if profile.root then
    profile.root:draw()
  end

  -- Draw profile info at bottom-left (below where profiler overlay will be)
  local screenH = love.graphics.getHeight()

  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 10, screenH - 160, 580, 150, 6)

  local y = screenH - 150
  love.graphics.setColor(0.3, 0.8, 1, 1)
  love.graphics.print("=== Display Toggle Profile ===", 20, y)
  y = y + 20

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(
    string.format("Element Pool: %d  |  Toggle State: %s", #profile.elementPool, tostring(profile.toggleState)),
    20,
    y
  )
  y = y + 20

  if profile.lastToggleTime then
    love.graphics.setColor(0.3, 1, 0.3, 1)
    love.graphics.print(
      string.format(
        "Last Toggle: %d elements (%s depth) in %.3f ms",
        profile.lastToggleCount,
        profile.lastToggleDepth,
        profile.lastToggleTime
      ),
      20,
      y
    )
    y = y + 20
  end

  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.print("1/2/3: leaf 20/50/100 | Q/W/E: mid 20/50/100 | A/D/Z: root 20/50/100", 20, y)
  y = y + 16
  love.graphics.print("+/-: count | SPACE: auto-toggle | R: reset | F1: toggle overlay", 20, y)
end

function profile.keypressed(key, profiler)
  -- Map keys to batch sizes and depths
  -- Avoid 's' (used by harness for save-report), 'r' (reset), 'escape' (menu), 'f11' (fullscreen)
  local depthMap = {
    -- Leaf depth (standalone elements, no children affected)
    ["1"] = { count = 20, depth = "leaf" },
    ["2"] = { count = 50, depth = "leaf" },
    ["3"] = { count = 100, depth = "leaf" },
    -- Mid depth (parent + 1 child affected together)
    ["q"] = { count = 20, depth = "mid" },
    ["w"] = { count = 50, depth = "mid" },
    ["e"] = { count = 100, depth = "mid" },
    -- Root depth (parent + children + grandchildren — entire subtree)
    ["a"] = { count = 20, depth = "root" },
    ["d"] = { count = 50, depth = "root" },
    ["z"] = { count = 100, depth = "root" },
  }

  local action = depthMap[key]
  if action then
    if profiler then
      profiler:markBegin("toggle_display")
    end

    local actualCount = profile.toggleDisplay(action.count, action.depth)

    if profiler then
      local elapsed = profiler:markEnd("toggle_display")
      profiler:recordMetric("toggled_count", actualCount)
      profiler:createSnapshot(string.format("%s x%d toggled (%.2fms)", action.depth, actualCount, elapsed or 0), {
        action = "toggle",
        count = actualCount,
        depth = action.depth,
        elapsedMs = elapsed,
      })
    end
    return
  end

  if key == "=" or key == "+" then
    profile.elementCount = math.min(1000, profile.elementCount + 50)
    profile.buildLayout()
    if profiler then
      profiler:createSnapshot(string.format("Layout rebuilt: %d", profile.elementCount), {
        action = "rebuild",
        elementCount = profile.elementCount,
      })
    end
  elseif key == "-" or key == "_" then
    profile.elementCount = math.max(20, profile.elementCount - 50)
    profile.buildLayout()
    if profiler then
      profiler:createSnapshot(string.format("Layout rebuilt: %d", profile.elementCount), {
        action = "rebuild",
        elementCount = profile.elementCount,
      })
    end
  elseif key == "space" then
    profile.autoToggle = not profile.autoToggle
    profile.autoTimer = 0
  end
end

function profile.resize(w, h)
  FlexLove.resize(w, h)
  profile.buildLayout()
end

function profile.reset()
  profile.elementCount = 200
  profile.autoToggle = false
  profile.autoTimer = 0
  profile.lastToggleTime = nil
  profile.toggleState = false
  profile.buildLayout()
end

function profile.cleanup()
  profile.root = nil
  profile.elementPool = {}
  profile.toggledElements = {}
end

return profile
