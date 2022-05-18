---@param path string
---@return string
local function pathToModuleName(path)
	return (path:gsub("/$", ""):gsub("^/", ""):gsub("/", "."):gsub("%.lua$", ""))
end

---@param componentDatabase ECSComponentDatabase
---@param path string
local function initAllComponents(componentDatabase, path)
	for _, file in ipairs(lovr.filesystem.getDirectoryItems(path)) do
		if file:sub(-4) == ".lua" and file ~= "init.lua" then
			local Component = require(pathToModuleName(path .. file))
			Component(componentDatabase)
		elseif lovr.filesystem.isDirectory(path .. file) then
			initAllComponents(componentDatabase, path .. file .. "/")
		end
	end
end

---@param componentDatabase ECSComponentDatabase
return function(componentDatabase)
	initAllComponents(componentDatabase, "/ECS/components/")
	initAllComponents(componentDatabase, "/components/")
end
