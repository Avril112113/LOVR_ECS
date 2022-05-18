local Entity = require "Scene.Entity"


---@class MainMenuEntity : Entity
local MainMenuEntity = class.MainMenuEntity(Entity)


function MainMenuEntity:awake()
	print("Awoke entity " .. self._name .. " with parent " .. tostring(self._parent))
end

function MainMenuEntity:load()
	print("Loaded entity " .. self._name .. " with parent " .. tostring(self._parent))
end

function MainMenuEntity:destroyed()
	print("Entity " .. self._name .. " destroyed... Cya!")
end

function MainMenuEntity:update(dt)
	
end

function MainMenuEntity:draw()
	
end


return MainMenuEntity
