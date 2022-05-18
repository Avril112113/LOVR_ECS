---@class Entity
---@field _name string @ Because of the way we create the class, PenLight gives us this field but EmmyLua doesn't know that
---@field super fun(...) @ EmmyLua doesn't know about this method from PenLight
---@field scene Scene @ class.properties
---@field parent Entity @ class.properties
---@field children Entity[] @ class.properties (Hidden type, see `_children`)
---@field isDestroyed boolean @ class.properties
---@field _children Entity[]|table<Entity,number>
local Entity = class.Entity(class.properties)
Entity._isDestroyed = false
---@type Entity @ The only case where parent will be `nil` is when we are the root node, or the entity has not been spawned yet
Entity._parent = nil
---@type Entity
Entity._parentToBeSet = nil
---@type Scene
Entity._scene = nil


function Entity:_init()
	self._children = {}
	self._isDestroyed = false
end

---@param parent Entity
function Entity:spawn(parent)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	assert(self._scene == nil, "Already spawned in a scene")
	assert(parent ~= nil, "arg#1 `parent` == nil")
	self._scene = parent._scene
	self._scene:_queueSpawn(self, parent)
end
--- WARNING: This method should be avoided unless absolutely necessary
---          as it can explode during `update`, `draw` or other similar situations
---@param parent Entity
function Entity:spawnImmediately(parent)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	assert(self._scene == nil, "Already spawned in a scene")
	assert(parent ~= nil, "arg#1 `parent` == nil")
	self._scene = parent._scene
	self._scene:_spawnNow(self, parent)
end

--- NOTE: parent will only be changed at the end of current update
---@param parent Entity
function Entity:setParent(parent)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	self._parentToBeSet = parent
end
---@param parent Entity
function Entity:_setParentNow(parent)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	if self._parent ~= nil then
		self._parent:_removeChildNow(self)
	end
	if parent ~= nil then
		parent:_addChildNow(self)
	end
	self._parent = parent
end
---@param child Entity
function Entity:_removeChildNow(child)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	local idx = self._children[child]
	self._children[child] = nil
	table.remove(self._children, idx)
end
---@param child Entity
function Entity:_addChildNow(child)
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	table.insert(self._children, child)
	self._children[child] = #self._children
end

--- Finds the most immediate child of `className`, optionally recursive
--- Does not check for duplicates!
---@generic T : Entity @ Class<Entity>
---@param clazz T|string
---@param recursive boolean?
---@return T|Entity
function Entity:findChildOfType(clazz, recursive)
	if recursive == nil then recursive = false end
	for _, child in ipairs(self._children) do
		if child._name == clazz or getmetatable(child) == clazz then
			return child
		end
	end
	-- Recursive check is done separately to ensure order
	-- Closest to the top will always be found before any child
	if recursive then
		for _, child in ipairs(self._children) do
			local result = child:findChildOfType(clazz, recursive)
			if result ~= nil then
				return result
			end
		end
	end
	return nil
end
--- Finds all the children of `className`, optionally recursive
---@generic T : Entity @ Class<Entity>
---@param clazz T|string
---@param recursive boolean?
---@param children Entity[]? @ Used internally
---@return T|Entity
function Entity:findChildrenOfType(clazz, recursive, children)
	if recursive == nil then recursive = false end
	children = children or {}
	for _, child in ipairs(self._children) do
		if child._name == clazz or getmetatable(child) == clazz then
			table.insert(children, child)
		end
	end
	-- Recursive check is done separately to ensure order
	-- Closest to the top will always be found before any child
	if recursive then
		for _, child in ipairs(self._children) do
			child:findChildrenOfType(clazz, recursive, children)
		end
	end
	return children
end

function Entity:destroy()
	assert(self._isDestroyed == false, "Entity is already destroyed.")
	assert(self._scene ~= nil, "Not spawned in scene")
	self._scene:_queueDestroy(self)
end

function Entity:_finishUpdate()
	assert(self._isDestroyed == false, "Entity is destroyed, it can not be used anymore.")
	if self._parentToBeSet ~= nil then
		self:_setParentNow(self._parentToBeSet)
		self._parentToBeSet = nil
	end
end

-- Overrideable events

--- Called when the entity is just added to the scene at the end of an update
--- You probably should use `Entity:load()` instead
function Entity:awake()
end

--- Called after awake at the beginning of an update, after all other entities has been added to the scene
function Entity:load()
end

--- Called just before the entity is destroyed and removed from it's parent
function Entity:destroyed()
end

--- Called every frame during the update phase
function Entity:update(dt)
end
--- This method calls `self:update()`
--- By default, `self` is updated before the children
--- This method may be overridden to adjust update order
function Entity:updateRecur(dt)
	self:update(dt)
	for _, child in ipairs(self._children) do
		child:updateRecur(dt)
	end
end

--- Called every frame during the drawing phase
function Entity:draw()
end
--- This method calls `self:draw()`
--- By default, `self` is drawn before the children
--- This method may be overridden to adjust update order
function Entity:drawRecur()
	self:draw()
	for _, child in ipairs(self._children) do
		child:drawRecur()
	end
end

--- Called every frame during the drawing phase, only for the desktop window
--- If not in VR, this will draw over the top of draw()
function Entity:drawScreen()
end
--- This method calls `self:drawScreen()`
--- By default, `self` is drawn before the children
--- This method may be overridden to adjust update order
function Entity:drawScreenRecur()
	self:drawScreen()
	for _, child in ipairs(self._children) do
		child:drawScreenRecur()
	end
end


return Entity
