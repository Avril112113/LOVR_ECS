local Entity = require "Scene.Entity"


---@class SceneRoot : Entity
local SceneRoot = class.SceneRoot(Entity)


---@param scene Scene
function SceneRoot:_init(scene)
	self:super()
	self._scene = scene
end


return SceneRoot
