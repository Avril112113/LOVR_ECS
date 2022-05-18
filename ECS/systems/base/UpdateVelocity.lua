local System = require "ECS.System"


---@class ECS_Base_UpdateVelocity : ECSSystem
local UpdateVelocity = class.UpdateVelocity(System)
UpdateVelocity.SYSTEM_PHASE = "update"
UpdateVelocity.SYSTEM_COMPONENT_NAMES = {"Position", "Velocity"}

---@param entityId number
---@param position PositionComponent
---@param velocity VelocityComponent
function UpdateVelocity:each(entityId, position, velocity)
	position.x = position.x + velocity.x * self.world.dt
	position.y = position.y + velocity.y * self.world.dt
	position.z = position.z + velocity.z * self.world.dt
end


return UpdateVelocity
