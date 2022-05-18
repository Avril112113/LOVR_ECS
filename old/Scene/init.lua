---@class Scene
---@field root Entity
local Scene = class.Scene()
Scene.Entity = require "Scene.Entity"
Scene.SceneRoot = require "Scene.SceneRoot"


function Scene:_init()
	self.root = self.SceneRoot(self)
	---@type Entity[][]
	self._toSpawn = {}
	---@type Entity[]
	self._toDestroy = {}
	---@type Entity[]
	self._toLoad = {}

	self.worldFont = lovr.graphics.getFont()
	self.screenFont = lovr.graphics.newFont(16)
	self.screenFont:setPixelDensity(1)
	---@diagnostic disable-next-line: undefined-field
	self.screenFont:setFlipEnabled(true)  -- Hmm? Undocumented function https://lovr.org/docs/UI/Window_HUD
end

---@param entity Entity
---@param parent Entity
function Scene:_queueSpawn(entity, parent)
	assert(parent._scene == self, "Parent belongs to a different scene")
	table.insert(self._toSpawn, {entity, parent})  -- TODO: reduce garbage
end
---@param entity Entity
---@param parent Entity
function Scene:_spawnNow(entity, parent)
	assert(parent._scene == self, "Parent belongs to a different scene")
	entity:_setParentNow(parent)
	entity:awake()
	table.insert(self._toLoad, entity)
end

---@param entity Entity
function Scene:_queueDestroy(entity)
	assert(entity._scene == self, "Entity belongs to a different scene")
	-- Destroy the children before the main entity
	for i=#entity._children,1,-1 do
		local child = entity._children[i]
		child:destroy()
	end
	table.insert(self._toDestroy, entity)
end
---@param entity Entity
function Scene:_destroyNow(entity)
	assert(entity._scene == self, "Entity belongs to a different scene")
	entity:destroyed()
	entity:_setParentNow(nil)
	entity._isDestroyed = true
end

--- Finds the most immediate child of `className`, optionally recursive
--- Does not check for duplicates!
---@generic T : Entity @ Class<Entity>
---@param clazz T|string
---@param recursive boolean?
---@return T|Entity
function Scene:findChildOfType(clazz, recursive)
	return self.root:findChildOfType(clazz, recursive)
end
--- Finds all the children of `className`, optionally recursive
---@generic T : Entity @ Class<Entity>
---@param clazz T|string
---@param recursive boolean?
---@param children Entity[]? @ Used internally
---@return T|Entity
function Scene:findChildrenOfType(clazz, recursive, children)
	return self.root:findChildrenOfType(clazz, recursive, children)
end

function Scene:update(dt)
	self.root:updateRecur(dt)
	if #self._toDestroy > 0 then
		while #self._toDestroy > 0 do
			local entity = table.remove(self._toDestroy, 1)
			self:_destroyNow(entity)
		end
	end
	if #self._toSpawn > 0 then
		while #self._toSpawn > 0 do
			local pair = table.remove(self._toSpawn, 1)
			self:_spawnNow(pair[1], pair[2])
		end
	end
	if #self._toLoad > 0 then
		while #self._toLoad > 0 do
			local entity = table.remove(self._toLoad, 1)
			entity:load()
		end
	end
	self.root:_finishUpdate()
end

function Scene:draw()
	lovr.graphics.reset()
	lovr.graphics.setFont(self.worldFont)
	self.root:drawRecur()
end

--- Always draws to the desktop screen only, overlaying draw() if not in VR
function Scene:drawScreen()
	lovr.graphics.reset()
	local info = self:get2DInfo()
	lovr.graphics.setDepthTest()
	lovr.graphics.setShader()
	lovr.graphics.origin()
	lovr.graphics.setProjection(1, info.matrix)
	lovr.graphics.setFont(self.screenFont)
	self.root:drawScreenRecur()
end

function Scene:mirror()
	if lovr.headset then
		local texture = lovr.headset.getMirrorTexture()
		if texture then
			lovr.graphics.fill(texture)
		end
		self:drawScreen()
	else
		lovr.graphics.clear()
		self:draw()
		self:drawScreen()
	end
end

function Scene:replaceLovrEvents()
	lovr.load = function()
	end
	lovr.update = function(dt)
		self:update(dt)
	end
	lovr.draw = function()
		self:draw()
	end
	lovr.mirror = function()
		self:mirror()
	end
	if lovr.headset ~= nil then
		lovr.headset.renderTo(function()
			self:draw()
		end)
	end
end

-- https://github.com/mcclure/lovr-ent/blob/43237c24acd7c758426907a6c8e8b59f2a396357/lua/engine/flat.lua
function Scene:get2DInfo()
	local info = self._2dInfo or {}

	if info.width ~= lovr.graphics.getWidth() or info.height ~= lovr.graphics.getHeight() then
		info.width = lovr.graphics.getWidth()
		info.height = lovr.graphics.getHeight()
		info.aspect = info.height/info.width

		local left, right = 0, info.width
		local top, bottom = 0, info.height

		info.matrix = lovr.math.newMat4():orthographic(left, right, top, bottom, -64, 64)
	end

	self._2dInfo = info
	return info
end

local ENTITY_STR_FORMAT = "#%-3s %s\n"
---@param entity Entity?
---@param parts string[]? @ Mutated
---@param depth number?
function Scene:strSceneHierarchy(entity, parts, depth)
	entity = entity or self.root
	parts = parts or {}
	depth = depth or 1
	if depth == 1 then
		table.insert(parts, string.rep("\t", depth-1) .. ENTITY_STR_FORMAT:format("---", entity))
	end
	for i, child in ipairs(entity._children) do
		table.insert(parts, string.rep("\t", depth) .. ENTITY_STR_FORMAT:format(i, child))
		self:strSceneHierarchy(child, parts, depth+1)
	end
	if depth == 1 then
		return (table.concat(parts):gsub("\n$", ""))
	end
end

return Scene
