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
local ImageCache = require("modules.ImageCache")

local function makeMockImage()
  local img = {}
  img.getDimensions = function()
    return 50, 50
  end
  img.release = function() end
  return img
end

TestDeferredImageLoading = {}

function TestDeferredImageLoading:setUp()
  FlexLove.destroy()
  FlexLove.init({})
  ImageCache.clear()
end

function TestDeferredImageLoading:tearDown()
  FlexLove.destroy()
  ImageCache.clear()
end

-- Constructor should not call ImageCache.load (non-cached path = nil _loadedImage)
function TestDeferredImageLoading:test_constructor_does_not_load_image()
  local onLoadCalled = false
  local element = FlexLove.new({
    width = 100,
    height = 100,
    imagePath = "nonexistent/test.png",
    onImageLoad = function()
      onLoadCalled = true
    end,
  })
  luaunit.assertNotNil(element)
  luaunit.assertNil(element._loadedImage, "Image should not be loaded in constructor")
  luaunit.assertFalse(onLoadCalled, "onImageLoad should not fire in constructor")
end

-- Cached image: _loadedImage set immediately, callback fires after update
function TestDeferredImageLoading:test_cached_image_loaded_immediately_callback_deferred()
  local mockImage = makeMockImage()
  ImageCache._cache["test/cached.png"] = {
    image = mockImage,
    imageData = nil,
  }

  local onLoadCalled = false
  local element = FlexLove.new({
    width = 100,
    height = 100,
    imagePath = "test/cached.png",
    onImageLoad = function(el, img)
      onLoadCalled = true
    end,
  })

  luaunit.assertEquals(element._loadedImage, mockImage, "Cached image should be available immediately")
  luaunit.assertFalse(onLoadCalled, "onImageLoad should not fire in constructor")

  element:update(0)

  luaunit.assertTrue(onLoadCalled, "onImageLoad should fire after update")
end

-- Non-cached image: _loadedImage nil, callback fires after update (error)
function TestDeferredImageLoading:test_non_cached_image_triggers_error_after_update()
  local onErrorCalled = false
  local errorMsg = nil
  local element = FlexLove.new({
    width = 100,
    height = 100,
    imagePath = "nonexistent/bad.png",
    onImageError = function(el, err)
      onErrorCalled = true
      errorMsg = err
    end,
  })

  luaunit.assertFalse(onErrorCalled, "onImageError should not fire in constructor")
  luaunit.assertNil(element._loadedImage)

  element:update(0)

  luaunit.assertTrue(onErrorCalled, "onImageError should fire after update")
  luaunit.assertNotNil(errorMsg)
  luaunit.assertNil(element._loadedImage)
end

-- Direct image prop works synchronously (no I/O needed)
function TestDeferredImageLoading:test_direct_image_works_synchronously()
  local mockImage = makeMockImage()

  local onLoadCalled = false
  local element = FlexLove.new({
    width = 100,
    height = 100,
    image = mockImage,
    onImageLoad = function(el, img)
      onLoadCalled = true
    end,
  })

  luaunit.assertEquals(element._loadedImage, mockImage)
  luaunit.assertTrue(onLoadCalled, "onImageLoad should fire for direct image in constructor")
end

-- Constructor does not crash with imagePath and no callbacks
function TestDeferredImageLoading:test_imagePath_does_not_crash()
  local element = FlexLove.new({
    width = 100,
    height = 100,
    imagePath = "nonexistent/image.png",
  })
  luaunit.assertNotNil(element)
  luaunit.assertNil(element._loadedImage)
end

-- Immediate mode: image loads after endFrame
function TestDeferredImageLoading:test_immediate_mode_image_loading()
  ImageCache.clear()
  FlexLove.destroy()
  FlexLove.init({})
  FlexLove.setMode("immediate")

  local mockImage = makeMockImage()

  FlexLove.beginFrame()

  local onLoadCalled = false
  local element = FlexLove.new({
    width = 100,
    height = 100,
    imagePath = "test/immediate.png",
    onImageLoad = function()
      onLoadCalled = true
    end,
  })

  luaunit.assertNil(element._loadedImage, "Image should not be loaded during construction")
  luaunit.assertFalse(onLoadCalled, "onImageLoad should not fire in constructor")

  -- Pre-populate cache so _loadImage finds it during endFrame update
  ImageCache._cache["test/immediate.png"] = {
    image = mockImage,
    imageData = nil,
  }

  FlexLove.endFrame()

  luaunit.assertEquals(element._loadedImage, mockImage, "Image should be loaded after endFrame")
  luaunit.assertTrue(onLoadCalled, "onImageLoad should fire after endFrame")

  FlexLove.setMode("retained")
end

if not _G.RUNNING_ALL_TESTS then
  os.exit(luaunit.LuaUnit.run())
end
