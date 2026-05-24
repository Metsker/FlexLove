local modulePath = (...):match("(.-)[^%.]+$")
local function req(name)
  return require(modulePath .. name)
end

local utils = req("utils")

-- ErrorHandler will be injected via init
local ErrorHandler = nil

---@class ImageCache
---@field _cache table<string, {image: love.Image, imageData: love.ImageData?}>
local ImageCache = {}
ImageCache._cache = {}

--- Initialize ImageCache with dependencies
---@param deps table Dependencies table with ErrorHandler
function ImageCache.init(deps)
  if deps and deps.ErrorHandler then
    ErrorHandler = deps.ErrorHandler
  end
end

--- Load an image from file path with caching
--- Returns cached image if already loaded, otherwise loads and caches it
---@param backgroundImage string -- Path to image file
---@param loadImageData boolean? -- Optional: also load ImageData for pixel access (default: false)
---@return love.Image|nil -- Image object or nil on error
---@return string|nil -- Error message if loading failed
function ImageCache.load(backgroundImage, loadImageData)
  if not backgroundImage or type(backgroundImage) ~= "string" or backgroundImage == "" then
    return nil, "Invalid image path: path must be a non-empty string"
  end

  local normalizedPath = utils.normalizePath(backgroundImage)

  if ImageCache._cache[normalizedPath] then
    return ImageCache._cache[normalizedPath].image, nil
  end

  local success, imageOrError = pcall(love.graphics.newImage, normalizedPath)
  if not success then
    if ErrorHandler then
      ErrorHandler:warn("ImageCache", "RES_004", {
        resourceType = "image",
        path = backgroundImage,
        error = tostring(imageOrError),
      })
    end
    return nil, string.format("Failed to load image '%s': %s", backgroundImage, tostring(imageOrError))
  end

  local image = imageOrError
  local imgData = nil

  if loadImageData then
    local dataSuccess, dataOrError = pcall(love.image.newImageData, normalizedPath)
    if dataSuccess then
      imgData = dataOrError
    elseif ErrorHandler then
      ErrorHandler:warn("ImageCache", "RES_004", {
        resourceType = "image data",
        path = backgroundImage,
        error = tostring(dataOrError),
      })
    end
  end

  ImageCache._cache[normalizedPath] = {
    image = image,
    imageData = imgData,
  }

  return image, nil
end

--- Get a cached image without loading
---@param backgroundImage string -- Path to image file
---@return love.Image|nil -- Cached image or nil if not found
function ImageCache.get(backgroundImage)
  if not backgroundImage or type(backgroundImage) ~= "string" then
    return nil
  end

  local normalizedPath = utils.normalizePath(backgroundImage)
  local cached = ImageCache._cache[normalizedPath]
  return cached and cached.image or nil
end

--- Get cached ImageData for an image
---@param backgroundImage string -- Path to image file
---@return love.ImageData|nil -- Cached ImageData or nil if not found
function ImageCache.getImageData(backgroundImage)
  if not backgroundImage or type(backgroundImage) ~= "string" then
    return nil
  end

  local normalizedPath = utils.normalizePath(backgroundImage)
  local cached = ImageCache._cache[normalizedPath]
  return cached and cached.imageData or nil
end

--- Remove a specific image from cache
---@param backgroundImage string -- Path to image file to remove
---@return boolean -- True if image was removed, false if not found
function ImageCache.remove(backgroundImage)
  if not backgroundImage or type(backgroundImage) ~= "string" then
    return false
  end

  local normalizedPath = utils.normalizePath(backgroundImage)
  if ImageCache._cache[normalizedPath] then
    local cached = ImageCache._cache[normalizedPath]
    if cached.image then
      cached.image:release()
    end
    if cached.imageData then
      cached.imageData:release()
    end
    ImageCache._cache[normalizedPath] = nil
    return true
  end
  return false
end

--- Clear all cached images
function ImageCache.clear()
  for path, cached in pairs(ImageCache._cache) do
    if cached.image then
      cached.image:release()
    end
    if cached.imageData then
      cached.imageData:release()
    end
  end
  ImageCache._cache = {}
end

--- Get cache statistics
---@return {count: number, memoryEstimate: number} -- Cache stats
function ImageCache.getStats()
  local count = 0
  local memoryEstimate = 0

  for path, cached in pairs(ImageCache._cache) do
    count = count + 1
    if cached.image then
      local w, h = cached.image:getDimensions()
      -- Estimate: 4 bytes per pixel (RGBA)
      memoryEstimate = memoryEstimate + (w * h * 4)
    end
  end

  return {
    count = count,
    memoryEstimate = memoryEstimate,
  }
end

return ImageCache
