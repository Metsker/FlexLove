---@module testing.test_helpers
---Test lifecycle helpers to reduce boilerplate in FlexLove test files.

local FlexLove = require("FlexLove")

local TestHelper = {}

---Set up FlexLove for a test: init + beginFrame + mode setup.
---@param mode string? "immediate" or "retained" (default: "retained")
function TestHelper.setup(mode)
  FlexLove.init()
  if mode then
    FlexLove.setMode(mode)
  end
  FlexLove.beginFrame()
end

---Tear down FlexLove after a test: endFrame + destroy.
function TestHelper.teardown()
  FlexLove.endFrame()
  FlexLove.destroy()
end

---Create an element within the current frame.
---@param props table? Element properties
---@return table element
function TestHelper.createElement(props)
  return FlexLove.Element.new(props or {})
end

return TestHelper
