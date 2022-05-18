-- This is running in a LOVR thread

---@type lovr
lovr = require "lovr"
lovr.thread = require "lovr.thread"
lovr.filesystem = require "lovr.filesystem"
lovr.data = require "lovr.data"

---@diagnostic disable-next-line: lowercase-global
class = require "pl.class"


local AssetManager = require "entities.assets.thread.AssetManager"

local loader = AssetManager(...)
loader:loop()
