---@type lovr
lovr = require "lovr"
lovr.thread = require "lovr.thread"
lovr.filesystem = require "lovr.filesystem"
lovr.data = require "lovr.data"

local ffi = require "ffi"
local Common = require "designing_shtuff_common"


local channel = lovr.thread.getChannel("designing_shtuff_thread")

local componentBlob = channel:pop(true)

local pointer = Common.CreateComponentPtr(Common.TestComponentDef, componentBlob)
print("from thread:", pointer.x, pointer.y, pointer.z, ffi.string(pointer.test))
pointer.x = 100
pointer.y = 200
pointer.z = 5500
pointer.test = "Threading things :D"
print("from thread, after change:", pointer.x, pointer.y, pointer.z, ffi.string(pointer.test))
