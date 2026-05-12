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

TestElementMode = {}

function TestElementMode:setUp()
  FlexLove.init({ immediateMode = true })
  FlexLove.beginFrame()
end

function TestElementMode:tearDown()
  if FlexLove.getMode() == "immediate" then
    FlexLove.endFrame()
  end
  FlexLove.init({ immediateMode = false })
end

function TestElementMode:test_globalImmediateMode()
  luaunit.assertEquals(FlexLove.getMode(), "immediate")
  local element = FlexLove.new({ text = "Test" })
  luaunit.assertNotNil(element)
end

function TestElementMode:test_globalRetainedMode()
  FlexLove.endFrame()
  FlexLove.setMode("retained")
  luaunit.assertEquals(FlexLove.getMode(), "retained")
  local element = FlexLove.new({ text = "Test" })
  luaunit.assertNotNil(element)
end

function TestElementMode:test_switchToImmediateCreatesFrame()
  FlexLove.setMode("immediate")
  FlexLove.beginFrame()
  local element = FlexLove.new({ text = "Test" })
  luaunit.assertEquals(#FlexLove._currentFrameElements, 1)
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
