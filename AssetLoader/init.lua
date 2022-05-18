local MessagePack = require "MessagePack"

---@class AssetLoader
local AssetLoader = class.AssetLoader()
AssetLoader.CHANNEL_NAME = "AssetLoaderThread"
AssetLoader.LOADERS = require "AssetLoader.loaders"


function AssetLoader:_init()
	self.assets = {}
	self.assetLoadedCount = 0
	self.assetRequestedCount = 0

	self.thread = lovr.thread.newThread("AssetLoader/thread.lua")
	self.thread:start(self.CHANNEL_NAME)
	self.channel_input = lovr.thread.getChannel(self.CHANNEL_NAME .. "_toMain")
	self.channel_output = lovr.thread.getChannel(self.CHANNEL_NAME .. "_toThread")
end

---@param wait? number # How long to wait for a message to be popped, in seconds.  `true` can be used to wait forever and `false` can be used to avoid waiting.
---@return any message # The received message, or `nil` if nothing was received.
function AssetLoader:read(wait)
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
function AssetLoader:write(message, wait)
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

function AssetLoader:update()
	local message = self:read(false)
	if message ~= nil then
		self:handle(message)
	end
end

---@param message table
function AssetLoader:handle(message)
	local handlerName = "handle_" .. message.task
	local f = self[handlerName]
	if f ~= nil then
		local ok, err = pcall(f, self, message)
		if not ok then
			print("AssetLoader ERROR: Handler method `" .. handlerName .. "` raised an exception\n" .. err)
		end
	else
		print("AssetLoader ERROR: Unable to handle task, missing handler method `" .. handlerName .. "`")
	end
end

function AssetLoader:handle_loadAsset(message)
	self.assetRequestedCount = self.assetRequestedCount - 1
	self.assetLoadedCount = self.assetLoadedCount + 1
	self.assets[message.assetType][message.assetId] = self.LOADERS[message.assetType].postLoad(message.assetId, message.assetData)
	print("Loaded asset `" .. message.assetType .. ":" .. message.assetId .. "`")
end

---@param assetType string
---@param assetId string
function AssetLoader:loadAsset(assetType, assetId)
	assert(self.LOADERS[assetType] ~= nil, "Invalid asset type `" .. assetType .. "` (No loader)")
	print("Loading asset `" .. assetType .. ":" .. assetId .. "`")
	self.assets[assetType] = self.assets[assetType] or {}
	self.assets[assetType][assetId] = false
	self:write({
		task = "loadAsset",
		assetType = assetType,
		assetId = assetId
	})
	self.assetRequestedCount = self.assetRequestedCount + 1
end

---@param assetType string
---@param assetId string
---@return any # `false` if the asset is being loaded, otherwise it's the asset data
function AssetLoader:getAsset(assetType, assetId)
	local assets = self.assets[assetType]
	local asset
	if assets ~= nil then
		asset = assets[assetId]
	end
	if asset == nil then
		self:loadAsset(assetType, assetId)
	else
		return asset  -- Either `false` or the asset data
	end
	return false
end


return AssetLoader
