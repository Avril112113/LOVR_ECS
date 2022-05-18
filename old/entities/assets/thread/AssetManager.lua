local AssetLoaderBase = require "entities.assets.AssetLoaderBase"


---@class AssetManager
local AssetManager = class.AssetManager()

function AssetManager:_init(threadChannelName, assetsPath, assetLoadersPath)
	self.assetsPath = assetsPath
	self.assetLoadersPath = assetLoadersPath

	self.inputChannel = lovr.thread.getChannel(threadChannelName .. "_toThread")
	self.outputChannel = lovr.thread.getChannel(threadChannelName .. "_fromThread")

	self.queuedAssets = {}
	---@type table<string, AssetLoaderBase>
	self.assetLoaders = {}
	self:loadLoaders()
end

--- NOTE: this is equivalent to ../init.lua
function AssetManager:loadLoaders()
	local loaderFiles = lovr.filesystem.getDirectoryItems(self.assetLoadersPath)
	for _, file in ipairs(loaderFiles) do
		local loaderFile = self.assetLoadersPath .. file
		if loaderFile:sub(-4) == ".lua" then
			local f = lovr.filesystem.load(loaderFile)
			debug.getfenv(f).AssetLoaderBase = AssetLoaderBase
			local loader = f()
			self.assetLoaders[loader._name] = loader(self)
		end
	end
end

function AssetManager:loop()
	while true do
		local command = self.inputChannel:pop(#self.queuedAssets == 0)
		if command ~= nil then
			self:processCommand(command)
		end
		if #self.queuedAssets > 0 then
			local asset = table.remove(self.queuedAssets, 1)
			self:load(asset.loader, asset.path)
		end
	end
end

--- "autoload" Loads all assets according to each loaders autoload settings
--- "load:<Loader>:<full_path>"
---@param command string
function AssetManager:processCommand(command)
	local args = {}
	for arg in command:gmatch("([^:]+)") do
		table.insert(args, arg)
	end
	if args[1] == "autoload" then
		self:autoload()
	elseif args[1] == "load" then
		local assetLoader = self.assetLoaders[args[2]]
		if assetLoader == nil then
			self.outputChannel:push("error:invalid asset loader")
			return
		end
		table.insert(self.queuedAssets, {loader=assetLoader, path=args[3]})
		self.outputChannel:push("queued:" .. #self.queuedAssets)
	end
end

function AssetManager:autoload()
	---@param loader AssetLoaderBase
	---@param path string
	local function loadPath(loader, path)
		for _, file in ipairs(lovr.filesystem.getDirectoryItems(path)) do
			local filePath = path .. file
			if lovr.filesystem.isDirectory(filePath) and loader.autoload.recursive then
				loadPath(loader, filePath)
			else
				-- loader.extensionsMap[file:sub(-4)] ~= nil
				local foundPath = nil
				for _, ext in ipairs(loader.extensions) do
					-- A table means, if any of these exist, call the load once with the basePath
					if type(ext) == "table" then
						for _, realExt in ipairs(ext) do
							if file:sub(-#realExt) == realExt then
								foundPath = filePath:gsub(realExt:gsub("%.", "%%%.") .. "$", "")
								break
							end
						end
						if foundPath ~= nil then
							break
						end
					else
						if file:sub(-#ext) == ext then
							foundPath = filePath
							break
						end
					end
				end
				if foundPath ~= nil then
					table.insert(self.queuedAssets, {loader=loader, path=foundPath})
				end
			end
		end
	end
	for name, loader in pairs(self.assetLoaders) do
		if loader.autoload ~= nil then
			local assetsPath = self.assetsPath .. loader.autoload.subpath
			loadPath(loader, assetsPath)
		end
	end
	self.outputChannel:push("queued:" .. #self.queuedAssets)
end

---@param loader AssetLoaderBase
---@param assetPath string
function AssetManager:load(loader, assetPath)
	local result = {loader:load(assetPath)}
	assert(#result == 2, "Got " .. #result .. " retrun values instead of 2 from asset loader " .. loader._name)
	local asset = result[1]
	local assetId = result[2]
	self.outputChannel:push("loaded:" .. loader._name .. ":" .. assetId .. ":" .. (type(asset) ~= "table" and "1" or tostring(#asset)))
	if type(asset) == "table" then
		for i, v in ipairs(asset) do
			self.outputChannel:push(v)
		end
	else
		self.outputChannel:push(asset)
	end
end

return AssetManager
