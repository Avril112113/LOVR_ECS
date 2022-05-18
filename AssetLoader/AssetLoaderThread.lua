local MessagePack = require "MessagePack"

local AssetLoaderThread = class.AssetLoaderThread()
AssetLoaderThread.LOADERS = require "AssetLoader.loaders"


function AssetLoaderThread:_init(CHANNEL_NAME)
	self.CHANNEL_NAME = CHANNEL_NAME
	self.channel_input = lovr.thread.getChannel(self.CHANNEL_NAME .. "_toThread")
	self.channel_output = lovr.thread.getChannel(self.CHANNEL_NAME .. "_toMain")
end

---@param wait? number # How long to wait for a message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
---@return any message # The received message, or `nil` if nothing was received.
function AssetLoaderThread:read(wait)
	-- TODO: if `wait` and `result.userdata`, account for time
	local msg = self.channel_input:pop(wait)
	if msg ~= nil then
		local result = MessagePack.unpack(msg)
		if type(result) == "table" and result.userdata ~= nil then
			for _, field in ipairs(result.userdata) do
				result[field] = self.channel_input:pop(wait)
			end
		end
		return result
	end
	return nil
end

---@param message any # The message to push. (Any except `nil`)
---@param wait? number # How long to wait for the message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
----@return number id # The ID of the pushed message.
----@return boolean read # Whether the message was read by another thread before the wait timeout.
function AssetLoaderThread:write(message, wait)
	local userdata, userdataValues
	if type(message) == "table" and message.userdata ~= nil then
		userdata = message.userdata
		userdataValues = {}
		for _, field in ipairs(userdata) do
			table.insert(userdataValues, message[field])
			message[field] = nil
		end
	end
	self.channel_output:push(MessagePack.pack(message), wait)
	if userdataValues ~= nil then
		for _, value in ipairs(userdataValues) do
			self.channel_output:push(value, wait)
		end
	end
end

function AssetLoaderThread:loop()
	while true do
		local result = self:read(true)
		if result ~= nil then
			self:handle(result)
		end
	end
end

---@param message table
function AssetLoaderThread:handle(message)
	local handlerName = "handle_" .. message.task
	local f = self[handlerName]
	if f ~= nil then
		local ok, err = pcall(f, self, message)
		if not ok then
			print("AssetLoaderThread ERROR: Handler method `" .. handlerName .. "` raised an exception\n" .. err)
		end
	else
		print("AssetLoaderThread ERROR: Unable to handle task, missing handler method `" .. handlerName .. "`")
	end
end

---@param message table
function AssetLoaderThread:handle_loadAsset(message)
	self:write({
		task = "loadAsset",
		assetType = message.assetType,
		assetId = message.assetId,
		assetData = AssetLoaderThread.LOADERS[message.assetType].threadLoad(message.assetId),
		userdata = {
			"assetData"
		}
	})
end


return AssetLoaderThread
