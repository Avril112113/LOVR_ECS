lovr.filesystem.setRequirePath(lovr.filesystem.getRequirePath() .. ";libs/?.lua;libs/?/init.lua")

require "globals"
local Scene = require "Scene"


---@type Scene
local MainScene = Scene()

MainScene:replaceLovrEvents()


---@type AssetsEntity
local assetsEntity = require("entities.assets")()
assetsEntity:spawn(MainScene.root)

assetsEntity.assetsLoadedEvent:subscribe(function()
	assetsEntity.showingUI = false
	require "entities.test"():spawn(MainScene.root)
end)


function lovr.keypressed(key, scancode, _repeat)
	if key == "f10" then
		print(MainScene:strSceneHierarchy())
	end
end
