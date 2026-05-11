package.path = package.path .. ";./?.lua;./modules/?.lua"
local originalSearchers = package.searchers or package.loaders
table.insert(originalSearchers, 2, function(modname)
  if modname:match("^FlexLove%.modules%.") then
    local moduleName = modname:gsub("^FlexLove%.modules%.", "")
    return function()
      return require("modules." .. moduleName)
    end
  end
end)

require("testing.loveStub")
local luaunit = require("testing.luaunit")
local FlexLove = require("FlexLove")

TestGridLayout = {}

function TestGridLayout:setUp()
  -- Save viewport and reset to known state for viewport-dependent tests
  self._savedViewportW, self._savedViewportH = love.graphics.getDimensions()
  love.window.setMode(800, 600)
  FlexLove.init()
  FlexLove.beginFrame()
end

function TestGridLayout:tearDown()
  FlexLove.endFrame()
  love.window.setMode(self._savedViewportW, self._savedViewportH)
end

-- Test basic grid layout with default 1x1 grid
function TestGridLayout:test_default_grid_single_child()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 300,
    positioning = "grid",
    -- Default: gridRows=1, gridColumns=1
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50, -- Will be stretched by grid
    height = 50,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Child should be stretched to fill the entire grid cell
  luaunit.assertEquals(child.x, 0, "Child should be at x=0")
  luaunit.assertEquals(child.y, 0, "Child should be at y=0")
  luaunit.assertEquals(child.width, 400, "Child should be stretched to container width")
  luaunit.assertEquals(child.height, 300, "Child should be stretched to container height")
end

-- Test 2x2 grid layout
function TestGridLayout:test_2x2_grid_four_children()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  local children = {}
  for i = 1, 4 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
      width = 50,
      height = 50,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Each cell should be 200x200
  -- Child 1: top-left (0, 0)
  luaunit.assertEquals(children[1].x, 0, "Child 1 should be at x=0")
  luaunit.assertEquals(children[1].y, 0, "Child 1 should be at y=0")
  luaunit.assertEquals(children[1].width, 200, "Cell width should be 200")
  luaunit.assertEquals(children[1].height, 200, "Cell height should be 200")

  -- Child 2: top-right (200, 0)
  luaunit.assertEquals(children[2].x, 200, "Child 2 should be at x=200")
  luaunit.assertEquals(children[2].y, 0, "Child 2 should be at y=0")

  -- Child 3: bottom-left (0, 200)
  luaunit.assertEquals(children[3].x, 0, "Child 3 should be at x=0")
  luaunit.assertEquals(children[3].y, 200, "Child 3 should be at y=200")

  -- Child 4: bottom-right (200, 200)
  luaunit.assertEquals(children[4].x, 200, "Child 4 should be at x=200")
  luaunit.assertEquals(children[4].y, 200, "Child 4 should be at y=200")
end

-- Test grid with column and row gaps
function TestGridLayout:test_grid_with_gaps()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 420, -- 2 cells * 200 + 1 gap * 20
    height = 320, -- 2 cells * 150 + 1 gap * 20
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    columnGap = 20,
    rowGap = 20,
  })

  local children = {}
  for i = 1, 4 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
      width = 50,
      height = 50,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Cell size: (420 - 20) / 2 = 200, (320 - 20) / 2 = 150
  luaunit.assertEquals(children[1].width, 200, "Cell width should be 200")
  luaunit.assertEquals(children[1].height, 150, "Cell height should be 150")

  -- Child 2 should be offset by cell width + gap
  luaunit.assertEquals(children[2].x, 220, "Child 2 x = 200 + 20 gap")
  luaunit.assertEquals(children[2].y, 0, "Child 2 should be at y=0")

  -- Child 3 should be offset by cell height + gap
  luaunit.assertEquals(children[3].x, 0, "Child 3 should be at x=0")
  luaunit.assertEquals(children[3].y, 170, "Child 3 y = 150 + 20 gap")
end

-- Test grid with more children than cells (overflow)
function TestGridLayout:test_grid_overflow_children()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 200,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    -- Only 4 cells available
  })

  local children = {}
  for i = 1, 6 do -- 6 children, but only 4 cells
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
      width = 50,
      height = 50,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- First 4 children should be positioned
  luaunit.assertNotNil(children[1].x, "Child 1 should be positioned")
  luaunit.assertNotNil(children[4].x, "Child 4 should be positioned")

  -- Children 5 and 6 should NOT be positioned (or positioned at 0,0 by default)
  -- This tests the overflow behavior: row >= rows breaks the loop
end

-- Test grid with alignItems center
function TestGridLayout:test_grid_align_center()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    alignItems = "center",
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 100,
    height = 100,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Cell is 200x200, child is 100x100, should be centered
  -- Center position: (200 - 100) / 2 = 50
  luaunit.assertEquals(child.x, 50, "Child should be centered horizontally in cell")
  luaunit.assertEquals(child.y, 50, "Child should be centered vertically in cell")
  luaunit.assertEquals(child.width, 100, "Child width should not be stretched")
  luaunit.assertEquals(child.height, 100, "Child height should not be stretched")
end

-- Test grid with alignItems flex-start
function TestGridLayout:test_grid_align_flex_start()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    alignItems = "flex-start",
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 100,
    height = 100,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Child should be at top-left of cell
  luaunit.assertEquals(child.x, 0, "Child should be at left of cell")
  luaunit.assertEquals(child.y, 0, "Child should be at top of cell")
  luaunit.assertEquals(child.width, 100, "Child width should not be stretched")
  luaunit.assertEquals(child.height, 100, "Child height should not be stretched")
end

-- Test grid with alignItems flex-end
function TestGridLayout:test_grid_align_flex_end()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    alignItems = "flex-end",
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 100,
    height = 100,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Cell is 200x200, child is 100x100, should be at bottom-right
  luaunit.assertEquals(child.x, 100, "Child should be at right of cell (200 - 100)")
  luaunit.assertEquals(child.y, 100, "Child should be at bottom of cell (200 - 100)")
  luaunit.assertEquals(child.width, 100, "Child width should not be stretched")
  luaunit.assertEquals(child.height, 100, "Child height should not be stretched")
end

-- Test grid with padding
function TestGridLayout:test_grid_with_padding()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 500, -- Total width
    height = 500,
    padding = { top = 50, right = 50, bottom = 50, left = 50 },
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50,
    height = 50,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available space: 500 - 50 - 50 = 400
  -- Cell size: 400 / 2 = 200
  -- Child should be positioned at padding.left, padding.top
  luaunit.assertEquals(child.x, 50, "Child x should account for left padding")
  luaunit.assertEquals(child.y, 50, "Child y should account for top padding")
  luaunit.assertEquals(child.width, 200, "Cell width should be 200")
  luaunit.assertEquals(child.height, 200, "Cell height should be 200")
end

-- Test grid with absolutely positioned child (should be skipped in grid layout)
function TestGridLayout:test_grid_with_absolute_child()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  -- Regular child
  local child1 = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50,
    height = 50,
  })

  -- Absolutely positioned child (should be ignored by grid layout)
  local child2 = FlexLove.new({
    id = "child2",
    parent = container,
    positioning = "absolute",
    x = 10,
    y = 10,
    width = 30,
    height = 30,
  })

  -- Another regular child
  local child3 = FlexLove.new({
    id = "child3",
    parent = container,
    width = 50,
    height = 50,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- child1 should be in first grid cell (0, 0)
  luaunit.assertEquals(child1.x, 0, "Child 1 should be at x=0")
  luaunit.assertEquals(child1.y, 0, "Child 1 should be at y=0")

  -- child2 should keep its absolute position
  luaunit.assertEquals(child2.x, 10, "Absolute child should keep x=10")
  luaunit.assertEquals(child2.y, 10, "Absolute child should keep y=10")

  -- child3 should be in second grid cell (200, 0), not third
  luaunit.assertEquals(child3.x, 200, "Child 3 should be in second cell at x=200")
  luaunit.assertEquals(child3.y, 0, "Child 3 should be in second cell at y=0")
end

-- Test edge case: empty grid
function TestGridLayout:test_empty_grid()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
    -- No children
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Should not crash
  luaunit.assertEquals(#container.children, 0, "Grid should have no children")
end

-- Test edge case: grid with 0 columns or rows
function TestGridLayout:test_grid_zero_dimensions()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 0, -- Invalid: 0 rows
    gridColumns = 0, -- Invalid: 0 columns
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50,
    height = 50,
  })

  -- This might cause division by zero or other errors
  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Test passes if it doesn't crash
  luaunit.assertTrue(true, "Grid with 0 dimensions should not crash")
end

-- Test nested grids
function TestGridLayout:test_nested_grids()
  local outerGrid = FlexLove.new({
    id = "outer",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  -- First cell contains another grid
  local innerGrid = FlexLove.new({
    id = "inner",
    parent = outerGrid,
    width = 200,
    height = 200,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  -- Add children to inner grid
  for i = 1, 4 do
    FlexLove.new({
      id = "inner_child" .. i,
      parent = innerGrid,
      width = 25,
      height = 25,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Inner grid should be positioned in first cell of outer grid
  luaunit.assertEquals(innerGrid.x, 0, "Inner grid should be at x=0")
  luaunit.assertEquals(innerGrid.y, 0, "Inner grid should be at y=0")
  luaunit.assertEquals(#innerGrid.children, 4, "Inner grid should have 4 children")
end

-- Test grid with reserved space from absolute children
function TestGridLayout:test_grid_with_reserved_space()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 400,
    positioning = "grid",
    gridRows = 2,
    gridColumns = 2,
  })

  -- Absolute child with left positioning (reserves left space)
  FlexLove.new({
    id = "absolute_left",
    parent = container,
    positioning = "absolute",
    left = 0,
    top = 0,
    width = 50,
    height = 50,
  })

  -- Regular grid child
  local child1 = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50,
    height = 50,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Grid should account for reserved space
  -- Available width: 400 - 50 (reserved left) = 350
  -- Cell width: 350 / 2 = 175
  -- Child should start at x = reserved left = 50
  luaunit.assertEquals(child1.x, 50, "Child should be offset by reserved left space")
  luaunit.assertEquals(child1.width, 175, "Cell width should account for reserved space")
end

-- ======================================== --
-- Variable Column Width / Row Height Tests --
-- ======================================== --

-- Test gridTemplateColumns with mixed fr and px
function TestGridLayout:test_variable_column_widths_mixed()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 500,
    height = 300,
    positioning = "grid",
    gridTemplateColumns = { "1fr", "2fr", "100px" }, -- 3 cols: flex, 2x flex, fixed
    gridTemplateRows = { "1fr", "1fr" }, -- 2 equal rows
    columnGap = 0,
    rowGap = 0,
  })

  local children = {}
  for i = 1, 6 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available width: 500, total fr = 3, fr unit = (500 - 100) / 3 = 133.333...
  -- Col 1: 133.33, Col 2: 266.67, Col 3: 100
  -- Available height: 300, total fr = 2, fr unit = 300 / 2 = 150
  -- Row 1: 150, Row 2: 150

  luaunit.assertAlmostEquals(children[1].width, 400 / 3, 0.01, "Col 1 should be ~133.33")
  luaunit.assertAlmostEquals(children[2].width, 800 / 3, 0.01, "Col 2 should be ~266.67")
  luaunit.assertEquals(children[3].width, 100, "Col 3 should be 100px")

  -- Second row should start after first row
  luaunit.assertEquals(children[4].y, 150, "Child 4 should be at y=150 (row 2)")
  luaunit.assertEquals(children[5].y, 150, "Child 5 should be at y=150 (row 2)")

  -- Third column starts after col1 + col2
  local col1Width = 400 / 3
  local col2Width = 800 / 3
  local col3Start = col1Width + col2Width
  luaunit.assertAlmostEquals(children[3].x, col3Start, 0.01, "Child 3 should be at col1+col2")
end

-- Test variable row heights with mixed units
function TestGridLayout:test_variable_row_heights_mixed()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 500,
    positioning = "grid",
    gridTemplateColumns = { "1fr", "1fr" },
    gridTemplateRows = { "100px", "1fr", "2fr" }, -- fixed, flex, 2x flex
    rowGap = 0,
    columnGap = 0,
  })

  local children = {}
  for i = 1, 6 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available height: 500, Row 1: 100px fixed
  -- Remaining: 400, fr unit = 400 / 3 = 133.33
  -- Row 2: 133.33, Row 3: 266.67

  luaunit.assertEquals(children[1].height, 100, "Row 1 should be 100px")
  luaunit.assertAlmostEquals(children[3].height, 400 / 3, 0.01, "Row 2 should be ~133.33")
  luaunit.assertAlmostEquals(children[5].height, 800 / 3, 0.01, "Row 3 should be ~266.67")

  -- Row 2 starts after row 1
  luaunit.assertEquals(children[3].y, 100, "Child 3 (row 2) should be at y=100")
  -- Row 3 starts after row 1 + row 2
  luaunit.assertAlmostEquals(children[5].y, 100 + 400 / 3, 0.01, "Child 5 (row 3) should be after row 2")
end

-- Test all px tracks (no flexible units)
function TestGridLayout:test_variable_all_px()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 200,
    positioning = "grid",
    gridTemplateColumns = { 100, 200, 50 }, -- all px
    gridTemplateRows = { 100 },
    columnGap = 10,
  })

  local children = {}
  for i = 1, 3 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  luaunit.assertEquals(children[1].width, 100, "Col 1 should be 100px")
  luaunit.assertEquals(children[2].width, 200, "Col 2 should be 200px")
  luaunit.assertEquals(children[3].width, 50, "Col 3 should be 50px")

  luaunit.assertEquals(children[2].x, 110, "Col 2 should start at x=100+10gap")
  luaunit.assertEquals(children[3].x, 320, "Col 3 should start at x=100+10+200+10")
end

-- Test auto tracks
function TestGridLayout:test_variable_auto_tracks()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 600,
    height = 300,
    positioning = "grid",
    gridTemplateColumns = { "auto", "auto", "auto" }, -- 3 equal auto columns
    gridTemplateRows = { "auto", "auto" },
  })

  local children = {}
  for i = 1, 6 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available width: 600, 3 auto columns, 600/3 = 200 each
  luaunit.assertEquals(children[1].width, 200, "Auto col 1 should be 200")
  luaunit.assertEquals(children[2].width, 200, "Auto col 2 should be 200")
  luaunit.assertEquals(children[3].width, 200, "Auto col 3 should be 200")

  -- Available height: 300, 2 auto rows, 300/2 = 150 each
  luaunit.assertEquals(children[1].height, 150, "Auto row 1 should be 150")
  luaunit.assertEquals(children[4].height, 150, "Auto row 2 should be 150")
end

-- Test percentage tracks
function TestGridLayout:test_variable_percent_tracks()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 800,
    height = 400,
    positioning = "grid",
    gridTemplateColumns = { "25%", "50%", "25%" }, -- 200, 400, 200
    gridTemplateRows = { "100%" },
  })

  local children = {}
  for i = 1, 3 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  luaunit.assertEquals(children[1].width, 200, "25% col should be 200px")
  luaunit.assertEquals(children[2].width, 400, "50% col should be 400px")
  luaunit.assertEquals(children[3].width, 200, "25% col should be 200px")
end

-- Test gridTemplateColumns with gaps
function TestGridLayout:test_variable_with_gaps()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 500,
    height = 200,
    positioning = "grid",
    gridTemplateColumns = { "1fr", "1fr", "1fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 20,
  })

  local children = {}
  for i = 1, 3 do
    children[i] = FlexLove.new({
      id = "child" .. i,
      parent = container,
    })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available width: 500, 2 gaps = 40, remaining = 460
  -- Each col = 460/3 = 153.33
  local colWidth = 460 / 3
  luaunit.assertAlmostEquals(children[1].width, colWidth, 0.01, "Col with gap")
  luaunit.assertEquals(children[2].x, colWidth + 20, "Col 2 starts after col1 + gap")
  luaunit.assertEquals(children[3].x, 2 * (colWidth + 20), "Col 3 starts after col1+gap+col2+gap")
end

-- Test fallback: no gridTemplateColumns set, uses gridColumns
function TestGridLayout:test_variable_fallback_to_equal()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 300,
    height = 300,
    positioning = "grid",
    gridColumns = 3,
    gridRows = 3,
    -- No gridTemplateColumns/TemplateRows set -- fallback to equal 1fr
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- 3 equal 1fr columns = 100 each
  luaunit.assertEquals(child.width, 100, "Fallback col should be 100px equal")
  luaunit.assertEquals(child.height, 100, "Fallback row should be 100px equal")
end

-- Test alignment within variable-sized cells (center)
function TestGridLayout:test_variable_align_center()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 300,
    positioning = "grid",
    gridTemplateColumns = { "1fr", "2fr" },
    gridTemplateRows = { "1fr", "1fr" },
    alignItems = "center",
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 50,
    height = 30,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Cell 1: (~133.33, 150)
  -- Child: (50, 30), centered: ((133.33-50)/2, (150-30)/2)
  local cell1W = 400 / 3
  local cellH = 150
  luaunit.assertAlmostEquals(child.x, (cell1W - 50) / 2, 0.01, "Centered in var-width col")
  luaunit.assertAlmostEquals(child.y, (cellH - 30) / 2, 0.01, "Centered in var-height row")
end

-- Test auto tracks sized by content, fr tracks get remainder (CSS Grid behavior)
function TestGridLayout:test_variable_auto_content_sized()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 600,
    height = 200,
    positioning = "grid",
    -- auto track sizes to child content (100px), fr tracks split the remainder
    gridTemplateColumns = { "auto", "1fr", "2fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 0,
  })

  local children = {}
  children[1] = FlexLove.new({ id = "child1", parent = container, width = 100, height = 50 })
  children[2] = FlexLove.new({ id = "child2", parent = container })
  children[3] = FlexLove.new({ id = "child3", parent = container })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- auto track: child1 has width=100, so auto = 100
  -- remaining: 600 - 100 = 500, totalFr = 3
  -- col2 (1fr) = 500/3, col3 (2fr) = 1000/3
  luaunit.assertEquals(children[1].width, 100, "auto col sized to content (100)")
  luaunit.assertAlmostEquals(children[2].width, 500 / 3, 0.01, "1fr gets remainder/3")
  luaunit.assertAlmostEquals(children[3].width, 1000 / 3, 0.01, "2fr gets 2*remainder/3")
  luaunit.assertEquals(children[2].x, 100, "1fr col starts after auto col")
  luaunit.assertAlmostEquals(children[3].x, 100 + 500 / 3, 0.01, "2fr col starts after 1fr col")
end

-- Test auto track with no content (intrinsic = 0), fr tracks get all space
function TestGridLayout:test_variable_auto_no_content()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 600,
    height = 200,
    positioning = "grid",
    -- auto track has no content (intrinsic = 0), fr tracks get all space
    gridTemplateColumns = { "auto", "1fr", "2fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 0,
  })

  local children = {}
  for i = 1, 3 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- auto track: no content, intrinsic = 0
  -- remaining: 600 - 0 = 600, totalFr = 3
  -- col1 (auto) = 0, col2 (1fr) = 200, col3 (2fr) = 400
  luaunit.assertEquals(children[1].width, 0, "auto col with no content = 0")
  luaunit.assertEquals(children[2].width, 200, "1fr col gets 200")
  luaunit.assertEquals(children[3].width, 400, "2fr col gets 400")
  luaunit.assertEquals(children[2].x, 0, "1fr col starts right after 0-width auto col")
  luaunit.assertEquals(children[3].x, 200, "2fr col starts after 1fr col")
end

-- Test auto track takes max content when multiple children span the same column
function TestGridLayout:test_variable_auto_max_content()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 600,
    height = 400,
    positioning = "grid",
    gridTemplateColumns = { "auto", "1fr" },
    gridTemplateRows = { "1fr", "1fr" },
    columnGap = 0,
  })

  -- Children in col1: child1 (width=80), child3 (width=120) — auto should be 120
  local children = {}
  children[1] = FlexLove.new({ id = "child1", parent = container, width = 80, height = 50 })
  children[2] = FlexLove.new({ id = "child2", parent = container })
  children[3] = FlexLove.new({ id = "child3", parent = container, width = 120, height = 50 })
  children[4] = FlexLove.new({ id = "child4", parent = container })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- auto track: max(80, 120) = 120
  -- remaining: 600 - 120 = 480, totalFr = 1
  luaunit.assertEquals(children[1].width, 120, "auto col = max content (120)")
  luaunit.assertEquals(children[3].width, 120, "auto col row2 also 120")
  luaunit.assertEquals(children[2].width, 480, "1fr col gets all remaining (480)")
end

-- =================================================== --
-- Negative / Overflow Size Guard Tests               --
-- =================================================== --

-- Test that fr tracks don't get negative when px tracks exceed container size
function TestGridLayout:test_guard_negative_fr_tracks()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    positioning = "grid",
    gridTemplateColumns = { "200px", "1fr" }, -- px exceeds available width
    gridTemplateRows = { "1fr" },
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- col1 = 100px (clamped to availableWidth), col2 = 1fr = 0 (no space remaining)
  -- Track sizes should never be negative
  luaunit.assertNotNil(child.x, "Child should be positioned")
  luaunit.assertTrue(child.width >= 0, "Child width should never be negative, got " .. tostring(child.width))
end

-- Test that fr tracks handle all-px overflow gracefully
function TestGridLayout:test_guard_all_px_overflow()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 50,
    height = 50,
    positioning = "grid",
    gridTemplateColumns = { "100px", "100px" }, -- both exceed available
    gridTemplateRows = { "1fr" },
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  luaunit.assertTrue(child.width >= 0, "Child width should never be negative, got " .. tostring(child.width))
end

-- Test that large reserved space doesn't cause negative available space
function TestGridLayout:test_guard_negative_available_space()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 100,
    height = 100,
    positioning = "grid",
    gridRows = 1,
    gridColumns = 1,
  })

  -- Absolute child that reserves more space than container has
  FlexLove.new({
    id = "abs_child",
    parent = container,
    positioning = "absolute",
    left = 0,
    top = 0,
    width = 200, -- larger than container width
    height = 200, -- larger than container height
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Available space should be clamped to 0 (not negative)
  -- When available is 0, track = 0, child width/height = 0 or greater
  luaunit.assertTrue(child.width >= 0, "Child width should never be negative, got " .. tostring(child.width))
  luaunit.assertTrue(child.height >= 0, "Child height should never be negative, got " .. tostring(child.height))
end

-- Test that extreme values don't cause negative track sizes
function TestGridLayout:test_guard_extreme_overflow()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 10,
    height = 10,
    positioning = "grid",
    gridTemplateColumns = { "auto", "auto", "auto" },
    gridTemplateRows = { "auto", "auto" },
  })

  local child = FlexLove.new({
    id = "child1",
    parent = container,
    width = 500,
    height = 500,
  })

  FlexLove.endFrame()
  FlexLove.beginFrame()

  luaunit.assertTrue(child.width >= 0, "Child width should never be negative, got " .. tostring(child.width))
  luaunit.assertTrue(child.height >= 0, "Child height should never be negative, got " .. tostring(child.height))
end

-- ======================================== --
-- Unit Resolution Pipeline Tests          --
-- ======================================== --

-- Test vw units in gridTemplateColumns
function TestGridLayout:test_units_vw_columns()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 1000,
    height = 400,
    positioning = "grid",
    gridTemplateColumns = { "25vw", "1fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 0,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Viewport is 800x600 from loveStub, so 25vw = 200px
  -- Available width: 1000, col1 = 200, remaining = 800, col2 = 1fr = 800
  luaunit.assertEquals(children[1].width, 200, "25vw col should be 200px")
  luaunit.assertEquals(children[2].width, 800, "1fr col should fill remaining 800px")
  luaunit.assertEquals(children[2].x, 200, "1fr col starts after 25vw col")
end

-- Test vh units in gridTemplateRows
function TestGridLayout:test_units_vh_rows()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 1000,
    positioning = "grid",
    gridTemplateColumns = { "1fr" },
    gridTemplateRows = { "50vh", "1fr" },
    rowGap = 0,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Viewport is 800x600 from loveStub, so 50vh = 300px
  -- Available height: 1000, row1 = 300, remaining = 700, row2 = 1fr = 700
  luaunit.assertEquals(children[1].height, 300, "50vh row should be 300px")
  luaunit.assertEquals(children[2].height, 700, "1fr row should fill remaining 700px")
  luaunit.assertEquals(children[2].y, 300, "1fr row starts after 50vh row")
end

-- Test mixed vw/vh in both axes
function TestGridLayout:test_units_vw_vh_mixed()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 800,
    height = 600,
    positioning = "grid",
    gridTemplateColumns = { "10vw", "20vw" },
    gridTemplateRows = { "10vh" },
    columnGap = 0,
    rowGap = 0,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- 10vw = 80px, 20vw = 160px, 10vh = 60px
  luaunit.assertEquals(children[1].width, 80, "10vw col should be 80px")
  luaunit.assertEquals(children[1].height, 60, "10vh row should be 60px")
  luaunit.assertEquals(children[2].width, 160, "20vw col should be 160px")
  luaunit.assertEquals(children[2].x, 80, "2nd col starts after 10vw col")
end

-- Test calc() with viewport units in gridTemplateColumns
function TestGridLayout:test_units_calc_vw_columns()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 1000,
    height = 200,
    positioning = "grid",
    gridTemplateColumns = { FlexLove.calc("10vw + 50px"), "1fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 0,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- Viewport = 800x600, so 10vw = 80px, calc(80 + 50) = 130px
  -- col1 = 130, remaining = 870, col2 = 1fr = 870
  luaunit.assertEquals(children[1].width, 130, "calc(10vw + 50px) col should be 130px")
  luaunit.assertEquals(children[2].width, 870, "1fr col should fill remaining 870px")
  luaunit.assertEquals(children[2].x, 130, "1fr col starts after calc col")
end

-- Test calc() with percentage in gridTemplateColumns
function TestGridLayout:test_units_calc_percent_columns()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 400,
    height = 200,
    positioning = "grid",
    gridTemplateColumns = { FlexLove.calc("50% - 20px"), "1fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 0,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- col1: 50% of availableWidth(400) = 200, minus 20px = 180
  -- remaining = 400 - 180 = 220, col2 = 1fr = 220
  luaunit.assertEquals(children[1].width, 180, "calc(50% - 20px) col should be 180px")
  luaunit.assertEquals(children[2].width, 220, "1fr col should fill remaining 220px")
  luaunit.assertEquals(children[2].x, 180, "1fr col starts after calc col")
end

-- Test vw column combined with columnGap
function TestGridLayout:test_units_vw_with_gap()
  local container = FlexLove.new({
    id = "grid",
    x = 0,
    y = 0,
    width = 500,
    height = 200,
    positioning = "grid",
    gridTemplateColumns = { "10vw", "1fr" },
    gridTemplateRows = { "1fr" },
    columnGap = 20,
  })

  local children = {}
  for i = 1, 2 do
    children[i] = FlexLove.new({ id = "child" .. i, parent = container })
  end

  FlexLove.endFrame()
  FlexLove.beginFrame()

  -- 10vw = 80px, gap = 20, remaining = 500 - 80 - 20 = 400, col2 = 400
  luaunit.assertEquals(children[1].width, 80, "10vw col should be 80px with gap")
  luaunit.assertEquals(children[2].width, 400, "1fr col should be 400px with gap")
  luaunit.assertEquals(children[2].x, 100, "1fr col starts after vw col + gap")
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
