---@class ECSSystem
---@field _name string @ Because of the way we create the class, PenLight gives us this field but EmmyLua doesn't know that
---@field SYSTEM_PHASE string
---@field SYSTEM_COMPONENT_NAMES string[]
---@field SYSTEM_ARCHETYPE number
---@field run fun(self,entities:table<number,table<string,table<string,any>>>[])
---@field each fun(self,entityId:number, ...:any)
---@field world ECSWorld
local System = class.System()
System.SYSTEM_PHASE = nil
System.SYSTEM_COMPONENT_NAMES = nil
System.run = nil
System.each = nil


---@param world ECSWorld
function System:_init(world)
	assert(self.SYSTEM_PHASE ~= nil, "ESCSystem " .. self._name .. " is missing field `SYSTEM_PHASE`")
	assert(self.SYSTEM_COMPONENT_NAMES ~= nil, "ESCSystem " .. self._name .. " is missing field `SYSTEM_COMPONENT_NAMES`")
	self.SYSTEM_ARCHETYPE = world.componentDatabase:getArchetype(self.SYSTEM_COMPONENT_NAMES)
	assert(self.run ~= nil or self.each, "ESCSystem " .. self._name .. " is missing either field `run()` and `each()`")
	self.world = world
end


return System
