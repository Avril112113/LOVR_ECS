local Entity = require "Scene.Entity"
local AssetsEntity = require "entities.assets"


---@class TestEntity : Entity
local TestEntity = class.TestEntity(Entity)


function TestEntity:awake()
	print("Awoke entity " .. self._name .. " with parent " .. tostring(self._parent))
end

function TestEntity:load()
	print("Loaded entity " .. self._name .. " with parent " .. tostring(self._parent))
	self.assets = self.scene:findChildOfType(AssetsEntity)
	---@type lovr.Texture
	self.up_arrow = lovr.graphics.newMaterial(self.assets:getAsset("Image", "up_arrow"))
	---@type lovr.Model
	self.monkey = self.assets:getAsset("Model", "Monkey")
	self.money_ay = 0

	---@type lovr.Shader
	self.world_shader = self.assets:getAsset("Shader", "world_shader")
end

function TestEntity:destroyed()
	print("Entity " .. self._name .. " destroyed... Cya!")
end

function TestEntity:update(dt)
	self.money_ay = (self.money_ay + dt) % (math.pi*2)
end

function TestEntity:draw()
	lovr.graphics.setShader(self.world_shader)
	self.world_shader:send("ambient_color", {0.2, 0.2, 0.2, 1.0})
	self.monkey:draw(0, -0.5, -3, nil, self.money_ay, 0, 1, 0)
end

function TestEntity:drawScreen()
	local imgSize = 200
	lovr.graphics.setColor(1, 1, 1, 1)
	lovr.graphics.plane(self.up_arrow, 300, 100, 0, imgSize, -imgSize)
	lovr.graphics.setColor(0, 0.2, 0.2, 1)
	lovr.graphics.circle("fill", 100, 100, 0, 100)
	lovr.graphics.setColor(1, 1, 1, 1)
	lovr.graphics.print("Test entity/scene.\nHello!", 100, 100, 0)

	lovr.graphics.setPointSize(20)
	lovr.graphics.setColor(1, 1, 1, 1)
	lovr.graphics.points(0, 0, 0)
	lovr.graphics.setColor(0, 1, 0, 1)
	lovr.graphics.points(50, 50, 0)
	lovr.graphics.setColor(1, 0, 0, 1)
	lovr.graphics.points(-50, -50, 0)
	lovr.graphics.points(-50, 50, 0)
	lovr.graphics.points(50, -50, 0)
	lovr.graphics.points(0, -50, 0)
	lovr.graphics.points(0, 50, 0)
	lovr.graphics.points(50, 0, 0)
	lovr.graphics.points(-50, 0, 0)
end


return TestEntity
