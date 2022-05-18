local ffi = require "ffi"
local Common = require "designing_shtuff_common"


local componentBlob, pointer = Common.CreateComponentBlob(Common.TestComponentDef)
print("default:", pointer.x, pointer.y, pointer.z, ffi.string(pointer.test))

pointer.x = 1
pointer.y = 2
pointer.z = 55
pointer.test = "Testing strings"
print("changed fields:", pointer.x, pointer.y, pointer.z, ffi.string(pointer.test))

local pointer2 = Common.CreateComponentPtr(Common.TestComponentDef, componentBlob)
---@diagnostic disable-next-line: undefined-field
print("different pointer:", pointer2.x, pointer2.y, pointer2.z, ffi.string(pointer2.test))

local thread = lovr.thread.newThread("designing_shtuff_thread.lua")
thread:start()
local channel = lovr.thread.getChannel("designing_shtuff_thread")
channel:push(componentBlob)
thread:wait()

print("after thread:", pointer.x, pointer.y, pointer.z, pointer.test)
