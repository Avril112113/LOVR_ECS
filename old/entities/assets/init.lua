local Entity = require "Scene.Entity"
local AssetLoaderBase = require "entities.assets.AssetLoaderBase"


---@class AssetsEntity : Entity
---@field assetLoaders table<string, AssetLoaderBase>
local AssetsEntity = class.AssetsEntity(Entity)
AssetsEntity.loaderThreadFile = "/entities/assets/thread/main.lua"
AssetsEntity.loaderChannelName = "assetLoaderChannel"
AssetsEntity.assetsPath = "/assets/"
AssetsEntity.assetLoadersPath = AssetsEntity.assetsPath .. "loaders/"


function AssetsEntity:_init()
	self:super()
	self.queuedAssets = 0
	self.loadedAssets = 0
	self.assetLoaders = {}
	self.showingUI = true

	self.assetsLoadedEvent = SimpleEvent.new(true)
end

function AssetsEntity:load()
	if self.parent ~= self.scene.root then
		print("WARNING: Assets entity parent is not scene root entity. Was this intended?")
	end
	self.thread = lovr.thread.newThread(self.loaderThreadFile)
	self.outputChannel = lovr.thread.getChannel(self.loaderChannelName .. "_toThread")
	self.inputChannel = lovr.thread.getChannel(self.loaderChannelName .. "_fromThread")
	self.thread:start(self.loaderChannelName, self.assetsPath, self.assetLoadersPath)
	self:loadLoaders()
	self:queueLoadAllAssets()
end

function AssetsEntity:destroyed()
	print("WARNING: Assets Entity destroyed")
end

function AssetsEntity:drawScreen()
	-- TODO: move this into a dedicated entity for "asset loading screen"
	if self.showingUI then
		local loadedPercent = 1-self.queuedAssets/(self.loadedAssets+self.queuedAssets)
		lovr.graphics.setColor(0.2, 0.2, 0.2, 1)
		lovr.graphics.cylinder(0, -0.4, 0, 2, math.rad(90), nil, nil, nil, 0.1, 0.1)
		lovr.graphics.setColor(0, 0.7, 0, 1)
		lovr.graphics.cylinder(0, -0.4, 0, 2*loadedPercent, math.rad(90), nil, nil, nil, 0.09, 0.09)
		lovr.graphics.setColor(1, 1, 1, 1)
		lovr.graphics.print("Assets " .. self.loadedAssets .. "/" .. (self.loadedAssets+self.queuedAssets), 0, -0.4, 0, nil, nil, nil, nil, nil, nil, "left", "top")
	end
end

function AssetsEntity:update(dt)
	while true do
		local _, present = self.inputChannel:peek()
		if present then
			local threadData = self.inputChannel:pop()
			if self.input_co ~= nil then
				coroutine.resume(self.input_co, threadData)
				if coroutine.status(self.input_co) ~= "suspended" then
					self.input_co = nil
				end
			else
				if type(threadData) ~= "string" then
					print("Got unexpected data from thread (wasn't a string)", threadData)
				else
					local co = coroutine.create(self.processCommand)
					coroutine.resume(co, self, threadData)
					if coroutine.status(co) == "suspended" then
						self.input_co = co
					end
				end
			end
		else
			break
		end
	end
	if self.queuedAssets == 0 and self.loadedAssets > 0 then
		self.assetsLoadedEvent:fire()
	end
end

--- "load:<loaderId>:<assetId>" followed by the asset data
--- "queued:<queuedAssets>"
--- "error:<errMsg>"
---@param command string
function AssetsEntity:processCommand(command)
	local args = {}
	for arg in command:gmatch("([^:]+)") do
		table.insert(args, arg)
	end
	if args[1] == "loaded" then
		local loaderId = args[2]
		local assetId = args[3]
		local assetCount = tonumber(args[4])
		local asset
		if assetCount == 1 then
			asset = coroutine.yield()
		else
			asset = {}
			for i=1,assetCount do
				asset[i] = coroutine.yield()
			end
		end
		---@type AssetLoaderBase
		local loader = self.assetLoaders[loaderId]
		local ok, result = pcall(loader.postLoad, loader, asset, assetId)
		if not ok then
			print("ERROR Loading asset, " .. loader._name .. ":postLoad() threw an error:\n" .. tostring(result))
		else
			loader.assets[assetId] = result
			print("Loaded asset " .. loader._name .. " -> " .. assetId)
		end
		self.queuedAssets = math.max(self.queuedAssets - 1, 0)
		self.loadedAssets = self.loadedAssets + 1
	elseif args[1] == "queued" then
		self.queuedAssets = tonumber(args[2])
	elseif args[1] == "error" then
		print("Error from asset loading thread: " .. args[2])
	end
end

--- NOTE: this is equivalent to thread/AssetManager.lua
function AssetsEntity:loadLoaders()
	local loaderFiles = lovr.filesystem.getDirectoryItems(AssetsEntity.assetLoadersPath)
	for _, file in ipairs(loaderFiles) do
		local loaderFile = AssetsEntity.assetLoadersPath .. file
		if loaderFile:sub(-4) == ".lua" then
			local f = lovr.filesystem.load(loaderFile)
			debug.getfenv(f).AssetLoaderBase = AssetLoaderBase
			local loader = f()
			self.assetLoaders[loader._name] = loader(self)
		end
	end
end

--- Loads all assets
function AssetsEntity:queueLoadAllAssets()
	self.outputChannel:push("autoload")
end

---@param assetLoader string
---@param path string
function AssetsEntity:queueAssetLoad(assetLoader, path)
	self.outputChannel:push("load:" .. assetLoader .. ":" .. path)
end

---@param assetType string @ This is the loader name without the `Loader` suffix
---@param assetId string
function AssetsEntity:getAsset(assetType, assetId)
	local loaderId = assetType .. "Loader"
	return self.assetLoaders[loaderId]:getAsset(assetId) or error("Asset \"" .. assetId .. "\" not found from loader " .. loaderId)
end

---@param assetType string @ This is the loader name without the `Loader` suffix
---@param assetId string
function AssetsEntity:tryGetAsset(assetType, assetId)
	local loaderId = assetType .. "Loader"
	return self.assetLoaders[loaderId]:getAsset(assetId)
end


return AssetsEntity
