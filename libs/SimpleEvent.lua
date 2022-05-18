-- Created by Dude112113

---@alias Handler fun(...)

---@class SimpleEvent
---@field handlers Handler[]
---@field removeAfterHandled boolean
local SimpleEvent = {}
SimpleEvent.__index = SimpleEvent


---@param removeAfterHandled boolean? @ defaults `false`
---@return SimpleEvent
function SimpleEvent.new(removeAfterHandled)
	if removeAfterHandled == nil then
		removeAfterHandled = false
	end
	return setmetatable({
		removeAfterHandled = removeAfterHandled,
		handlers = {}
	}, SimpleEvent)
end

function SimpleEvent:fire(...)
	local handlerExists = false
	for _, handler in pairs(self.handlers) do
		handler(...)
		handlerExists = true
	end
	if handlerExists and self.removeAfterHandled == true then
		self.handlers = {}  -- TODO: Reduce garbage?
	end
end

---@param f fun(...)
function SimpleEvent:subscribe(f)
	self.handlers[f] = f
end

function SimpleEvent:unsubscribe(f)
	self.handlers[f] = nil
end


return SimpleEvent
