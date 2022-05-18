---@param componentDatabase ECSComponentDatabase
return function(componentDatabase)
	---@class OrientationComponent
	---@field x number
	---@field y number
	---@field z number
	--- TODO: this is probably gonna want to be a quaternion :fearful:
	componentDatabase:registerComponent("Orientation", {
		x=0,
		y=0,
		z=0,
	})
end
