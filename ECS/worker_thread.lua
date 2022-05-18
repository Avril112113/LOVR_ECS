-- This IS run in a LOVR thread!
---@type lovr
lovr = require "lovr"
lovr.thread = require "lovr.thread"
lovr.filesystem = require "lovr.filesystem"
lovr.data = require "lovr.data"

require "globals"

local MessagePack = require "MessagePack"
local CONSTS = require "ECS.consts"

local workerId = ...

print("Worker " .. workerId .. " started")

local channels = {
	input = lovr.thread.getChannel(CONSTS.WORKER_CHANNEL_MAIN_TO_THREAD:format(workerId)),
	output = lovr.thread.getChannel(CONSTS.WORKER_CHANNEL_THREAD_TO_MAIN:format(workerId)),
}
---@param data table # Jsonable table
---@param wait? number # How long to wait for the message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
function channels:send(data, wait)
	return self.output:push(MessagePack.pack(data), wait)
end
---@param wait? number # How long to wait for a message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
---@return table data # The received data, or `nil` if nothing was received.
---@return string data # The raw json data.
function channels:get(wait)
	local data = self.input:pop(wait)
	return data == nil and nil or MessagePack.unpack(data), data
end

while true do
	local msg = channels:get(true)
	print(msg)
end
