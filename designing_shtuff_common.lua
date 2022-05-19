local ffi = require "ffi"


local LUA_TO_C_TYPE = {
	number="double",
	string="char",
	boolean="bool",

}
local function ComponentDefToCType(definition)
	local s = {"struct { "}
	local first = true
	for _, field in ipairs(definition) do
		table.insert(s,
		LUA_TO_C_TYPE[type(field.default)] .. " " .. field.field ..
		(type(field.default) == "string" and ("[" .. field.maxLength .. "]") or "")
		.. "; "
	)
	end
	table.insert(s, "}")
	print(table.concat(s))
	return ffi.typeof(table.concat(s)), ffi.typeof(table.concat(s) .. "*")
end
local function CreateComponentPtr(ComponentDef, blob)
	return ffi.cast(ComponentDef.ctypeptr, blob:getPointer())
end
local function CreateComponentBlob(ComponentDef)
	local blob = lovr.data.newBlob(ffi.sizeof(ComponentDef.ctype), "<Component: " .. ComponentDef.name .. ">")
	local ptr = CreateComponentPtr(ComponentDef, blob)
	for _, field in pairs(ComponentDef.definition) do
		ptr[field.field] = field.default
	end
	return blob, ptr
end

local TestComponentDef = {
	name = "TestComponentDef",
	definition = {
		{field="x", default=0},
		{field="y", default=0},
		{field="z", default=0},
		{field="test", default="", maxLength=64},
	}
}
TestComponentDef.ctype, TestComponentDef.ctypeptr = ComponentDefToCType(TestComponentDef.definition)

return {
	ComponentDefToCType = ComponentDefToCType,
	CreateComponentPtr = CreateComponentPtr,
	CreateComponentBlob = CreateComponentBlob,
	TestComponentDef = TestComponentDef,
}
