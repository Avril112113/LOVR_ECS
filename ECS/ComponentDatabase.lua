---@alias RegisteredComponent {name:string, id:number, archetypeBit:number, fields:table<string,string>}
---@alias Component table<string,any>
---@alias Components table<string,Component>
---@alias Archetype number @ bit-mask

---@class ECSComponentDatabase
---@field registeredComponents RegisteredComponent[]
---@field registeredComponentsByName table<string,RegisteredComponent>
---@field components table<Archetype,Components> @ table of archetype bitmasks, leading to a table of components indexed by the component name
local ComponentDatabase = class.ComponentDatabase()

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

function ComponentDatabase:_init()
	self.registeredComponents = {}
	self.registeredComponentsByName = {}

	self.components = {
		--[[
		-- `...` represents the components fields/data
		archetype = {
			<Archetype_Bitmask>={
				-- We can get away with just directly using the entities ID, as this is lua, these aren't arrays
				<Entity_id>={
					<Component_name_a>={...},
					<Component_name_b>={...},
				},
			},
		}
		]]
	}
end

---@param name string
---@param fields table<string, any>
function ComponentDatabase:registerComponent(name, fields)
	assert(self.registeredComponentsByName[name] == nil, "Attempt to register duplicate component \"" .. name .. "\"")
	-- TODO: validate fields
	local registeredComponent = {
		name=name,
		id=#self.registeredComponents+1,
		archetypeBit = bit.lshift(1,  #self.registeredComponents),  -- Intentionally without `+1`, because indexing starts at 1
		fields=fields,
	}
	table.insert(self.registeredComponents, registeredComponent)
	self.registeredComponentsByName[name] = registeredComponent
end

---@param componentNames string[]|number
---@return number @ Achetype bitmask
function ComponentDatabase:registerArchetype(componentNames)
	assert(componentNames ~= nil, "Assert error: componentNames ~= nil")
	local archetype
	if type(componentNames) == "number" then
		archetype = componentNames
	else
		archetype = self:getArchetype(componentNames)
	end
	if self.components[archetype] == nil then
		self.components[archetype] = self:getEntitiesComponents(archetype)
	end
	return archetype
end

---@param components string[]|Components @ componentNames|Components
---@return number @ Achetype bitmask
function ComponentDatabase:getArchetype(components)
	assert(components ~= nil, "Assert error: componentNames ~= nil")
	local archetype = 0
	for i, v in pairs(components) do
		local componentName = type(i) == "number" and v or i
		assert(self.registeredComponentsByName[componentName] ~= nil, "Invalid component name: " .. tostring(componentName))
		local archetypeBit = self.registeredComponentsByName[componentName].archetypeBit
		archetype = bit.bor(archetype, archetypeBit)
	end
	return archetype
end

function ComponentDatabase:getComponentNamesFromArchetype(archetype)
	local componentNames = {}
	for _, component in ipairs(self.registeredComponents) do
		if bit.band(archetype, component.archetypeBit) == component.archetypeBit then
			table.insert(componentNames, component.name)
		end
	end
	return componentNames
end

---@param targetArchetype number
---@return table<number,Components>
function ComponentDatabase:getEntitiesComponents(targetArchetype)
	local entities = {}
	for archetype, entitiesTbl in pairs(self.components) do
		if bit.band(archetype, targetArchetype) == targetArchetype then
			for entityId, entityComponents in pairs(entitiesTbl) do
				entities[entityId] = entityComponents
			end
		end
	end
	return entities
end

function ComponentDatabase:getEntitiesWithArchetype(targetArchetype)
	return self.components[targetArchetype] or {}
end

---@param targetArchetype number
---@return number[]
function ComponentDatabase:getFittingArchetypes(targetArchetype)
	local archetypeTypes = {}
	for archetype, entitiesTbl in pairs(self.components) do
		if bit.band(archetype, targetArchetype) == targetArchetype then
			table.insert(archetypeTypes, archetype)
		end
	end
	return archetypeTypes
end

---@param entityId number
---@param components Components
function ComponentDatabase:addEntity(entityId, components)
	local componentsNames = {}
	for componentName, componentData in pairs(components) do
		table.insert(componentsNames, componentName)
	end
	local archetypes = self:getFittingArchetypes(self:getArchetype(componentsNames))
	for _, archetype in ipairs(archetypes) do
		self.components[archetype][entityId] = components
	end
end


return ComponentDatabase
