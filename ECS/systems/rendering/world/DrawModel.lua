local System = require "ECS.System"


---@class ECS_Rendering_world_DrawModel : ECSSystem
local DrawModel = class.DrawModel(System)
DrawModel.SYSTEM_PHASE = "draw_world"
DrawModel.SYSTEM_COMPONENT_NAMES = {"Position", "Model"}

---@param entityId number
---@param position PositionComponent
---@param model ModelComponent
function DrawModel:each(entityId, position, model)
	---@type lovr.Model
	local modelAsset = self.world.assetLoader:getAsset("Model", model.assetId)
	if modelAsset then
		modelAsset:draw(position.x, position.y, position.z)
	end
end


return DrawModel
