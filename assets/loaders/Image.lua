return {
	-- Called in the asset loader thread, used to retrive and process the data
	threadLoad = function(assetId)
		return lovr.data.newImage("assets/images/" .. assetId .. ".glb")
	end,
	-- Called on the main thread, to finalize loading the asset and do processing that can not be done on a thread
	postLoad = function(assetId, asset)
		return lovr.graphics.newTexture(asset)
	end,
}