-- This is running in both a LOVR thread AND the main thread independently

---@class ModelLoader : AssetLoaderBase
---@diagnostic disable-next-line: undefined-global
local ModelLoader = class.ModelLoader(AssetLoaderBase)
---@type table<string, lovr.Texture>
ModelLoader.assets = nil
ModelLoader.extensions = {".obj", ".stl", ".gltf", ".glb"}
ModelLoader.autoload = {
	subpath = "models/",
	recursive = true
}

---@param assetPath string @ Full virtual path to the asset
---@return any, string @ asset, assetId
function ModelLoader:load(assetPath)
	return lovr.data.newModelData(assetPath), assetPath:match("([^/]*)%..+$")
end

---@param asset any
---@param assetId string
function ModelLoader:postLoad(asset, assetId)
	return lovr.graphics.newModel(asset)
end

return ModelLoader
