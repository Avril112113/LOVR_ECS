-- This is running in both a LOVR thread AND the main thread independently

---@class ComputeShaderLoader : AssetLoaderBase
---@diagnostic disable-next-line: undefined-global
local ComputeShaderLoader = class.ComputeShaderLoader(AssetLoaderBase)
---@type table<string, lovr.Texture>
ComputeShaderLoader.assets = nil
ComputeShaderLoader.extensions = {".comp"}
ComputeShaderLoader.autoload = {
	subpath = "shaders/",
	recursive = true
}

---@param assetPath string @ Full virtual path to the asset
---@return any, string @ asset, assetId
function ComputeShaderLoader:load(assetPath)
	return (lovr.filesystem.read(assetPath)), assetPath:match("([^/]*)%..+$")
end

---@param asset any
---@param assetId string
function ComputeShaderLoader:postLoad(asset, assetId)
	-- "\n" ensures it's ALWAYS seen as a file (It's in the LOVR docs, somewhere)
	return lovr.graphics.newComputeShader(asset .. "\n")
end

return ComputeShaderLoader
