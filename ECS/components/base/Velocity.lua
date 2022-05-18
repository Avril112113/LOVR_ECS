---@param componentDatabase ECSComponentDatabase
return function(componentDatabase)
	---@class VelocityComponent
	---@field x number
	---@field y number
	---@field z number
	componentDatabase:registerComponent("Velocity", {
		x=0,
		y=0,
		z=0,
	})
end
