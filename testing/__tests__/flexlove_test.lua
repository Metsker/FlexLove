package.path = package.path .. ";./?.lua"
local originalSearchers = package.searchers or package.loaders
table.insert(originalSearchers, 2, function(modname)
  if modname == "FlexLove" then
    return loadfile("./init.lua")
  end
  if modname:match("^FlexLove%.modules%.") then
    local moduleName = modname:gsub("^FlexLove%.modules%.", "")
    return function()
      return require("modules." .. moduleName)
    end
  end
end)

local luaunit = require("testing.luaunit")
require("testing.loveStub")
local FlexLove = require("FlexLove")
local Color = FlexLove.Color
local Theme = FlexLove.Theme

TestFlexLove = {}

function TestFlexLove:setUp()
  FlexLove.destroy()
  FlexLove.init()
end

function TestFlexLove:tearDown()
  FlexLove.destroy()
end

function TestFlexLove:testModuleLoads()
  luaunit.assertNotNil(FlexLove)
  luaunit.assertNotNil(FlexLove._VERSION)
  luaunit.assertNotNil(FlexLove._DESCRIPTION)
  luaunit.assertNotNil(FlexLove._URL)
  luaunit.assertNotNil(FlexLove._LICENSE)
end

function TestFlexLove:testInitNoConfig()
  FlexLove.init()
  luaunit.assertTrue(FlexLove.initialized)
end

function TestFlexLove:testInitEmptyConfig()
  FlexLove.init({})
  luaunit.assertTrue(FlexLove.initialized)
end

function TestFlexLove:testInitWithBaseScale()
  FlexLove.init({
    baseScale = { width = 1920, height = 1080 },
  })
  luaunit.assertEquals(FlexLove.baseScale.width, 1920)
  luaunit.assertEquals(FlexLove.baseScale.height, 1080)
end

function TestFlexLove:testInitWithTableTheme()
  FlexLove.init({
    theme = { name = "custom", components = {} },
  })
  luaunit.assertEquals(FlexLove.defaultTheme, "custom")
end

function TestFlexLove:testNewElement()
  local el = FlexLove.new({ id = "root", width = 50, height = 50 })
  luaunit.assertNotNil(el)
  luaunit.assertEquals(el.id, "root")
  luaunit.assertEquals(el.width, 50)
  luaunit.assertEquals(el.height, 50)
end

function TestFlexLove:testGetById()
  FlexLove.new({ id = "alpha", width = 10, height = 10 })
  FlexLove.new({ id = "beta", width = 10, height = 10 })
  local alpha = FlexLove.getElementById("alpha")
  luaunit.assertNotNil(alpha)
  luaunit.assertEquals(alpha.id, "alpha")
end

function TestFlexLove:testGetByIdNotFound()
  luaunit.assertNil(FlexLove.getElementById("never"))
end

function TestFlexLove:testCalcReturnsCalcObject()
  local c = FlexLove.calc("50% - 10px")
  luaunit.assertNotNil(c)
end

function TestFlexLove:testDeferCallback()
  local fired = 0
  FlexLove.deferCallback(function()
    fired = fired + 1
  end)
  luaunit.assertEquals(fired, 0)
  FlexLove.executeDeferredCallbacks()
  luaunit.assertEquals(fired, 1)
end

function TestFlexLove:testDestroyClearsTopElements()
  FlexLove.new({ id = "a", width = 10, height = 10 })
  luaunit.assertEquals(#FlexLove.topElements, 1)
  FlexLove.destroy()
  luaunit.assertEquals(#FlexLove.topElements, 0)
  FlexLove.init()
end

function TestFlexLove:testFocusAPI()
  local el = FlexLove.new({ id = "f", width = 10, height = 10, editable = true })
  FlexLove.setFocusedElement(el)
  luaunit.assertEquals(FlexLove.getFocusedElement(), el)
  FlexLove.clearFocus()
  luaunit.assertNil(FlexLove.getFocusedElement())
end

function TestFlexLove:testSetDebugDraw()
  FlexLove.setDebugDraw(true)
  luaunit.assertTrue(FlexLove.getDebugDraw())
  FlexLove.setDebugDraw(false)
  luaunit.assertFalse(FlexLove.getDebugDraw())
end

function TestFlexLove:testColorIsExposed()
  luaunit.assertNotNil(FlexLove.Color)
  local c = Color.new(1, 0, 0, 1)
  luaunit.assertNotNil(c)
end

function TestFlexLove:testThemeIsExposed()
  luaunit.assertNotNil(FlexLove.Theme)
  local t = Theme.new({ name = "test1", components = {} })
  luaunit.assertEquals(t.name, "test1")
end

function TestFlexLove:testCSSDisplayDefaultsToFlex()
  local el = FlexLove.new({ width = 10, height = 10 })
  luaunit.assertEquals(el.display, "flex")
end

function TestFlexLove:testCSSDisplayBlock()
  local el = FlexLove.new({ display = "block", width = 10, height = 10 })
  luaunit.assertEquals(el.display, "block")
end

function TestFlexLove:testCSSDisplayFlex()
  local el = FlexLove.new({ display = "flex", width = 100, height = 100 })
  luaunit.assertEquals(el.display, "flex")
  luaunit.assertEquals(el.display, "flex")
end

function TestFlexLove:testCSSDisplayGrid()
  local el = FlexLove.new({ display = "grid", width = 100, height = 100, gridColumns = 2, gridRows = 2 })
  luaunit.assertEquals(el.display, "grid")
  luaunit.assertEquals(el.display, "grid")
end

function TestFlexLove:testCSSDisplayNone()
  local el = FlexLove.new({ display = "none", width = 10, height = 10 })
  luaunit.assertEquals(el.display, "none")
end

function TestFlexLove:testCSSPositionAbsolute()
  local el = FlexLove.new({ position = "absolute", x = 100, y = 50, width = 10, height = 10 })
  luaunit.assertEquals(el.position, "absolute")
end

function TestFlexLove:testCSSPositionRelative()
  local el = FlexLove.new({ position = "relative", width = 10, height = 10 })
  luaunit.assertEquals(el.position, "relative")
end

function TestFlexLove:testChildrenAcceptsPropTables()
  local parent = FlexLove.new({
    display = "flex",
    width = 200,
    height = 100,
    children = {
      { width = 30, height = 30 },
      { width = 30, height = 30 },
    },
  })
  luaunit.assertEquals(#parent.children, 2)
end

function TestFlexLove:testAppendNewResolvesPercentageAgainstParent()
  -- Construction-time path: percentage width resolved against the parent's
  -- 1000px width, not the viewport.
  local parent = FlexLove.new({ width = 1000, height = 500 })
  local child = parent:appendNew({ width = "50%", height = "50%" })
  luaunit.assertEquals(child.width, 500)
  luaunit.assertEquals(child.height, 250)
  luaunit.assertEquals(child.parent, parent)
end

function TestFlexLove:testParentPropWarnsAndIsIgnored()
  -- Legacy `parent =` in props no longer attaches; the constructor warns and
  -- the element stays at the top level.
  local container = FlexLove.new({ id = "tc", width = 100, height = 100 })
  local before = #FlexLove.topElements
  local stray = FlexLove.new({ parent = container, width = 10, height = 10 })
  luaunit.assertNil(stray.parent)
  luaunit.assertEquals(#FlexLove.topElements, before + 1)
end

function TestFlexLove:testChildrenAcceptsElementInstances()
  local childA = FlexLove.new({ id = "ca", width = 20, height = 20 })
  local childB = FlexLove.new({ id = "cb", width = 20, height = 20 })
  luaunit.assertEquals(#FlexLove.topElements, 2)

  local parent = FlexLove.new({
    display = "flex",
    width = 200,
    height = 100,
    children = { childA, childB },
  })
  luaunit.assertEquals(#parent.children, 2)
  luaunit.assertEquals(parent.children[1].id, "ca")
  luaunit.assertEquals(parent.children[2].id, "cb")
  -- Children are reparented out of topElements
  luaunit.assertEquals(#FlexLove.topElements, 1)
end

function TestFlexLove:testDirectAssignmentBackgroundColor()
  -- Direct mutation of backgroundColor must take effect without setProperty.
  local el = FlexLove.new({ width = 10, height = 10, backgroundColor = Color.new(1, 0, 0, 1) })
  el.backgroundColor = Color.new(0, 1, 0, 1)
  luaunit.assertEquals(el.backgroundColor.g, 1)
end

function TestFlexLove:testDirectAssignmentOnEvent()
  local fired = false
  local el = FlexLove.new({ width = 10, height = 10 })
  el.onEvent = function()
    fired = true
  end
  luaunit.assertEquals(type(el.onEvent), "function")
  el.onEvent(el, { type = "click" })
  luaunit.assertTrue(fired)
end

function TestFlexLove:testBorderShorthandString()
  local el = FlexLove.new({ width = 10, height = 10, border = "3px solid #ff0000" })
  luaunit.assertEquals(el.border.top, 3)
  luaunit.assertEquals(el.border.right, 3)
  luaunit.assertEquals(el.border.bottom, 3)
  luaunit.assertEquals(el.border.left, 3)
  luaunit.assertEquals(el.borderStyle, "solid")
  luaunit.assertEquals(el.borderColor.r, 1)
  luaunit.assertEquals(el.borderColor.g, 0)
  luaunit.assertEquals(el.borderColor.b, 0)
end

function TestFlexLove:testBorderShorthandPerSide()
  local el = FlexLove.new({ width = 10, height = 10, borderTop = "2px solid #00ff00", borderLeft = "4px" })
  luaunit.assertEquals(el.border.top, 2)
  luaunit.assertEquals(el.border.left, 4)
  luaunit.assertEquals(el.border.right, false)
  luaunit.assertEquals(el.border.bottom, false)
end

function TestFlexLove:testTransitionShorthandSingle()
  local el = FlexLove.new({ width = 10, height = 10, transition = "opacity 300ms ease-in-out" })
  luaunit.assertNotNil(el.transitions)
  luaunit.assertNotNil(el.transitions.opacity)
  luaunit.assertEquals(el.transitions.opacity.duration, 0.3)
  luaunit.assertEquals(el.transitions.opacity.easing, "easeInOutCubic")
end

function TestFlexLove:testOnClickProp()
  local fired = 0
  local el = FlexLove.new({
    width = 10,
    height = 10,
    onClick = function()
      fired = fired + 1
    end,
  })
  -- Simulate a click event through the EventHandler's invocation path.
  el._eventHandler:_invokeCallback(el, { type = "click", button = 1 })
  luaunit.assertEquals(fired, 1)
end

function TestFlexLove:testOnMouseEnterAndLeave()
  local enters, leaves = 0, 0
  local el = FlexLove.new({
    width = 10,
    height = 10,
    onMouseEnter = function()
      enters = enters + 1
    end,
    onMouseLeave = function()
      leaves = leaves + 1
    end,
  })
  el._eventHandler:_invokeCallback(el, { type = "hover" })
  el._eventHandler:_invokeCallback(el, { type = "unhover" })
  luaunit.assertEquals(enters, 1)
  luaunit.assertEquals(leaves, 1)
end

function TestFlexLove:testFlexDirectionRowReverse()
  local parent = FlexLove.new({
    id = "rr-parent",
    display = "flex",
    flexDirection = "row-reverse",
    justifyContent = "flex-start",
    width = 300,
    height = 50,
    children = {
      { id = "rr-a", width = 50, height = 50 },
      { id = "rr-b", width = 50, height = 50 },
      { id = "rr-c", width = 50, height = 50 },
    },
  })
  local a, b, c = parent.children[1], parent.children[2], parent.children[3]
  -- With row-reverse + flex-start, the first child sits flush against the right edge.
  luaunit.assertEquals(a.x, parent.x + parent.width - a.width)
  luaunit.assertEquals(b.x, a.x - b.width)
  luaunit.assertEquals(c.x, b.x - c.width)
  -- Cross axis unchanged.
  luaunit.assertEquals(a.y, parent.y)
end

function TestFlexLove:testFlexDirectionColumnReverse()
  local parent = FlexLove.new({
    id = "cr-parent",
    display = "flex",
    flexDirection = "column-reverse",
    justifyContent = "flex-start",
    width = 50,
    height = 300,
    children = {
      { id = "cr-a", width = 50, height = 50 },
      { id = "cr-b", width = 50, height = 50 },
      { id = "cr-c", width = 50, height = 50 },
    },
  })
  local a, b, c = parent.children[1], parent.children[2], parent.children[3]
  -- With column-reverse + flex-start, the first child sits flush against the bottom edge.
  luaunit.assertEquals(a.y, parent.y + parent.height - a.height)
  luaunit.assertEquals(b.y, a.y - b.height)
  luaunit.assertEquals(c.y, b.y - c.height)
  -- Cross axis unchanged.
  luaunit.assertEquals(a.x, parent.x)
end

function TestFlexLove:testFlexDirectionRowReverseShiftsDescendants()
  local parent = FlexLove.new({
    id = "rrd-parent",
    display = "flex",
    flexDirection = "row-reverse",
    width = 200,
    height = 50,
    children = {
      {
        id = "rrd-outer",
        width = 80,
        height = 50,
        display = "flex",
        flexDirection = "row",
        children = { { id = "rrd-inner", width = 40, height = 50 } },
      },
    },
  })
  local outer = parent.children[1]
  local inner = outer.children[1]
  -- outer should be on the right edge of parent
  luaunit.assertEquals(outer.x, parent.x + parent.width - outer.width)
  -- inner should be flush against outer's left edge (still row-direction inside)
  luaunit.assertEquals(inner.x, outer.x)
end

function TestFlexLove:testOnEventAndOnClickBothFire()
  local catchAll, typed = 0, 0
  local el = FlexLove.new({
    width = 10,
    height = 10,
    onEvent = function(_, e)
      if e.type == "click" then
        catchAll = catchAll + 1
      end
    end,
    onClick = function()
      typed = typed + 1
    end,
  })
  el._eventHandler:_invokeCallback(el, { type = "click", button = 1 })
  luaunit.assertEquals(catchAll, 1)
  luaunit.assertEquals(typed, 1)
end

function TestFlexLove:testTransitionShorthandMultiple()
  local el = FlexLove.new({
    width = 10,
    height = 10,
    transition = "opacity 0.5s linear, width 200ms ease-out 0.1s",
  })
  luaunit.assertEquals(el.transitions.opacity.duration, 0.5)
  luaunit.assertEquals(el.transitions.opacity.easing, "linear")
  luaunit.assertEquals(el.transitions.width.duration, 0.2)
  luaunit.assertEquals(el.transitions.width.easing, "easeOutCubic")
  luaunit.assertEquals(el.transitions.width.delay, 0.1)
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
