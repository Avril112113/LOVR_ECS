---@type lovr
lovr = require "lovr"
lovr.thread = require "lovr.thread"
lovr.filesystem = require "lovr.filesystem"
lovr.data = require "lovr.data"

---@diagnostic disable-next-line: lowercase-global
class = require "pl.class"


local AssetLoaderThread = require "AssetLoader.AssetLoaderThread"

local assetLoaderThread = AssetLoaderThread(...)

assetLoaderThread:loop()
