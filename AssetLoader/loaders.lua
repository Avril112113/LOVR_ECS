---@type table<string, {threadLoad:(fun(assetId:string):any),postLoad:(fun(assetId:string, data:any):any)}>
local loaders = {}

local LOADERS_PATH = "/assets/loaders/"

for i, path in pairs(lovr.filesystem.getDirectoryItems(LOADERS_PATH)) do
	local assetType = path:gsub("%.lua", "")
	loaders[assetType] = lovr.filesystem.load(LOADERS_PATH .. path)()
end

return loaders
