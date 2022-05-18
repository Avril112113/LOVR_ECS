-- This is running in both a LOVR thread AND the main thread independently


---@class AssetLoaderBase
---@field _name string
local AssetLoaderBase = class.AssetLoaderBase()
---@type table<string, any>
AssetLoaderBase.assets = nil
AssetLoaderBase.extensions = {}
---@type {subpath: string, recursive: boolean}
AssetLoaderBase.autoload = nil

---@param assetManager AssetManager
function AssetLoaderBase:_init(assetManager)
	self.assetManager = assetManager
	self.assets = {}  -- Only used on main thread
end

--- Called when an asset is requested to be loaded
---@param assetPath string @ Full virtual path to the asset
---@return any, string @ assetData, assetId
function AssetLoaderBase:load(assetPath)
	error("AssetLoaderBase:load(assetPath) not implemented")
end

--- Optionally overridden to modify the asset now it's on the main thread
---@param asset any
---@param assetId string
function AssetLoaderBase:postLoad(asset, assetId)
	return asset
end

---@param assetId string
---@return any
function AssetLoaderBase:getAsset(assetId)
	return self.assets[assetId]
end

return AssetLoaderBase
