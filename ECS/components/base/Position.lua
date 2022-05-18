---@param componentDatabase ECSComponentDatabase
return function(componentDatabase)
	---@class PositionComponent
	---@field x number
	---@field y number
	---@field z number
	componentDatabase:registerComponent("Position", {
		x=0,
		y=0,
		z=0,
	})
end
