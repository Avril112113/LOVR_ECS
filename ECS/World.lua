local Worker = require "ECS.Worker"
local ComponentDatabase = require "ECS.ComponentDatabase"


---@class ECSWorld
---@field componentDatabase ECSComponentDatabase
---@field entities table<string,{name:string,archetype:number}>
---@field entityCounter number
---@field systems table<string, ECSSystem[]>
local World = class.World()
World.WORKER_COUNT = 1
World.DEFAULT_WORLD_FONT = lovr.graphics.getFont()
World.DEFAULT_SCREEN_FONT = lovr.graphics.getFont()
World.DEFAULT_SCREEN_FONT:setPixelDensity(1)
---@diagnostic disable-next-line: undefined-field
World.DEFAULT_SCREEN_FONT:setFlipEnabled(true)  -- Hmm? Undocumented function https://lovr.org/docs/UI/Window_HUD

---@param assetLoader AssetLoader
function World:_init(assetLoader)
	self.assetLoader = assetLoader
	self.componentDatabase = ComponentDatabase()
	self.entities = {}
	self.entityCounter = 0
	self.systems = {}
	self:registerSystemPhase("update")
	self:registerSystemPhase("draw_world")
	self:registerSystemPhase("draw_screen")

	self.workers = {}
	for i=1,self.WORKER_COUNT do
		table.insert(self.workers, Worker(i))
	end
end

function World:update(dt)
	self.dt = dt
	self:triggerSystemPhase("update")
end

function World:draw()
	local width, height = lovr.graphics.getWidth(), lovr.graphics.getHeight()
	if self._screen_space == nil or self._screen_space.width ~= width or self._screen_space.height ~= height then
		self._screen_space = {
			matrix = lovr.math.newMat4():orthographic(0, width, 0, height, -64, 64),
			width = width, height = height
		}
	end

	lovr.graphics.setFont(self.DEFAULT_WORLD_FONT)
	self:triggerSystemPhase("draw_world")

	lovr.graphics.reset()
	lovr.graphics.setDepthTest()
	lovr.graphics.setShader()
	lovr.graphics.origin()
	lovr.graphics.setProjection(1, self._screen_space.matrix)
	lovr.graphics.setFont(self.DEFAULT_SCREEN_FONT)
	self:triggerSystemPhase("draw_screen")
	lovr.graphics.reset()
end

--- Make sure all components this system uses are already registered!
---@param systemClass ECSSystem
function World:addSystem(systemClass)
	local phaseSystems = self.systems[systemClass.SYSTEM_PHASE]
	assert(phaseSystems ~= nil, "System \"" .. systemClass._name .. "\" has invalid phase of \"" .. tostring(systemClass.SYSTEM_PHASE) .. "\"")
	local system = systemClass(self)
	self.componentDatabase:registerArchetype(system.SYSTEM_ARCHETYPE)
	table.insert(phaseSystems, system)
end
--- Triggers a system phase, scheduling all systems in that phase to be run this update
---@param phase string
function World:triggerSystemPhase(phase)
	local phaseSystems = self.systems[phase]
	for _, system in ipairs(phaseSystems) do
		local entities = self.componentDatabase:getEntitiesWithArchetype(system.SYSTEM_ARCHETYPE)
		if system.run ~= nil then
			system:run(entities)
		elseif system.each ~= nil then
			for entityId, components in ipairs(entities) do
				local orderedComponents = {}
				for i, componentName in ipairs(system.SYSTEM_COMPONENT_NAMES) do
					orderedComponents[i] = components[componentName]
				end
				system:each(entityId, unpack(orderedComponents))
			end
		end
	end
end
--- Creates a new phase that can be triggered using @see World:triggerSystemPhase
---@param phase string
function World:registerSystemPhase(phase)
	self.systems[phase] = {}
end

---@param name string
---@param componentNames string[]
---@return number
function World:addEntity(name, componentNames, components)
	local entityId = self.entityCounter
	self.entityCounter = self.entityCounter + 1
	self.entities[entityId] = {
		name = name,
		archetype = self.componentDatabase:registerArchetype(componentNames),
	}
	components = components or {}
	for _, componentName in ipairs(componentNames) do
		if components[componentName] == nil then
			components[componentName] = {}
		end
		local component = components[componentName]
		assert(component ~= nil, "component == nil")
		for fieldName, fieldDefault in pairs(self.componentDatabase.registeredComponentsByName[componentName].fields) do
			if component[fieldName] == nil then
				component[fieldName] = fieldDefault
			end
		end
	end
	self.componentDatabase:addEntity(entityId, components)
	return entityId
end
---@param entityId number
---@return string
function World:getEntityName(entityId)
	return self.entities[entityId].name
end
---@param entityId number
---@return string
function World:getEntityArchetype(entityId)
	return self.entities[entityId].archetype
end

function World:dbg_json()
	local function toBits(num)
		-- returns a table of bits, least significant first.
		local t={} -- will contain the bits
		while num>0 do
			local rest=math.fmod(num,2)
			t[#t+1]=rest
			num=(num-rest)/2
		end
		return table.concat(t)
	end

	local data = {
		entities = {},
		components = {},
		systems = {}
	}
	for entityId, entity in pairs(self.entities) do
		data.entities[tostring(entityId)] = {name=entity.name, archetype=toBits(entity.archetype)}
	end
	for _, component in pairs(self.componentDatabase.registeredComponents) do
		local fittingArchetypes = {}
		for i, archetype in ipairs(self.componentDatabase:getFittingArchetypes(component.archetypeBit)) do
			fittingArchetypes[i] = toBits(archetype)
		end
		-- local entities = {}
		-- for i, v in pairs(self.componentDatabase:getEntitiesWithArchetype(component.archetypeBit)) do
		-- 	entities[]
		-- end
		data.components[component.name] = {
			archetypeBit = toBits(component.archetypeBit),
			fittingArchetypes = fittingArchetypes,
			-- entities = entities,
		}
	end
	for phase, systems in pairs(self.systems) do
		data.systems[phase] = {}
		for i, system in ipairs(systems) do
			data.systems[phase][i] = {
				name = system._name,
				archetype = toBits(system.SYSTEM_ARCHETYPE),
			}
		end
	end
	return data
end


return World
