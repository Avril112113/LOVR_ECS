local System = require "ECS.System"


local VelocityUpdate = class.VelocityUpdate(System)
VelocityUpdate.SYSTEM_PHASE = "update"
VelocityUpdate.SYSTEM_COMPONENT_NAMES = {"Position"}

---@param entityId number
---@param position PositionComponent
function VelocityUpdate:each(entityId, position)
	print(("Entity: %s - Position<%s, %s, %s>"):format(entityId, position.x, position.y, position.z))
end


return VelocityUpdate
