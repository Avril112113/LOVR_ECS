lovr.filesystem.setRequirePath(lovr.filesystem.getRequirePath() .. ";libs/?.lua;libs/?/init.lua")
require "globals"

local Json = require "json"

local AssetLoader = require "AssetLoader"
local ECS = require "ECS"
local registerComponents = require "components"


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


---@type AssetLoader
local assetLoader
---@type ECSWorld
local world

function lovr.load()
	assetLoader = AssetLoader()
	world = ECS.World(assetLoader)
	registerComponents(world.componentDatabase)

	world:addSystem(require "ECS.systems.base.UpdateVelocity")
	world:addSystem(require "ECS.systems.rendering.world.DrawModel")

	-- TODO: This isn't getting rendered
	--       Probably related to archetypes
	local testEntity0 = world:addEntity(
		"Test boi 0",
		{"Position", "Velocity", "Orientation", "Model"},
		{
			Position={z=-4},
			Model={assetId="Torus"}
		}
	)
	local testEntity1 = world:addEntity(
		"Test boi 1",
		{"Position", "Model"},
		{
			Position={z=-5},
			Model={assetId="Creep_01"},
			-- Velocity={x=0.1}
		}
	)

	local f = io.open("world.json", "w")
	if f ~= nil then
		f:write(Json.encode(world:dbg_json()))
		f:close()
	end

	-- local archetype = world.componentDatabase:getArchetype({"Position", "Model"})
	-- print("Sigh:", table.concat(world.componentDatabase:getComponentNamesFromArchetype(archetype), ", "))
	-- local entites = world.componentDatabase:getEntitiesComponents(archetype)
	-- for i, v in ipairs(entites) do
	-- 	print(i, v)
	-- end
	-- for _, archetype in ipairs(world.componentDatabase:getFittingArchetypes(world.componentDatabase:getArchetype({"Position", "Model"}))) do
	-- 	print(toBits(archetype))
	-- end
end

function lovr.update(dt)
	assetLoader:update()
	world:update(dt)
end

function lovr.draw()
	world:draw()
end

require "designing_shtuff"
