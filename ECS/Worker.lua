local MessagePack = require "MessagePack"
local CONSTS = require "ECS.consts"

local WORKER_THREAD_FILE = "ECS/worker_thread.lua"


---@class ECSWorker
---@field workerId number
---@field channels {input:lovr.Channel,output:lovr.Channel}
---@field thread lovr.Thread
local Worker = class.Worker()

function Worker:_init(workerId)
	assert(workerId ~= nil)
	self.workerId = workerId
	self.channels = {
		input = lovr.thread.getChannel(CONSTS.WORKER_CHANNEL_THREAD_TO_MAIN:format(workerId)),
		output = lovr.thread.getChannel(CONSTS.WORKER_CHANNEL_MAIN_TO_THREAD:format(workerId)),
	}
	self.thread = lovr.thread.newThread(WORKER_THREAD_FILE)
	self.thread:start(workerId)
end

---@param data table # Jsonable table
---@param wait? number # How long to wait for the message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
function Worker:send(data, wait)
	return self.channels.output:push(MessagePack.pack(data), wait)
end

---@param wait? number # How long to wait for a message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
---@return table data # The received data, or `nil` if nothing was received.
function Worker:get(wait)
	local data = self.channels.input:pop(wait)
	return data == nil and nil or MessagePack.unpack(data)
end


return Worker
