---@param componentDatabase ECSComponentDatabase
return function(componentDatabase)
	---@class ModelComponent
	---@field assetId string
	componentDatabase:registerComponent("Model", {
		assetId="",
	})
end
