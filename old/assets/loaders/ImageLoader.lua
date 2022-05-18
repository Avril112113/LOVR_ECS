-- This is running in both a LOVR thread AND the main thread independently

---@class ImageLoader : AssetLoaderBase
---@diagnostic disable-next-line: undefined-global
local ImageLoader = class.ImageLoader(AssetLoaderBase)
---@type table<string, lovr.Texture>
ImageLoader.assets = nil
ImageLoader.extensions = {".png", ".jpg", ".jpeg", ".hdr", ".dds", ".ktx"}
ImageLoader.autoload = {
	subpath = "images/",
	recursive = true
}

---@param assetPath string @ Full virtual path to the asset
---@return any, string @ asset, assetId
function ImageLoader:load(assetPath)
	return lovr.data.newImage(assetPath), assetPath:match("([^/]*)%..+$")
end

---@param asset any
---@param assetId string
function ImageLoader:postLoad(asset, assetId)
	return lovr.graphics.newTexture(asset)
end

return ImageLoader
