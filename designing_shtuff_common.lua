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
	local ctype = ffi.typeof(table.concat(s))
	---@diagnostic disable-next-line: redundant-parameter
	local ctypeptr = ffi.typeof("$ *", ctype)
	return ctype, ctypeptr
end
local function CreateComponentPtr(ComponentDef, blob)
	return setmetatable({
		_ptr=ffi.cast(ComponentDef.ctypeptr, blob:getPointer())
	}, {
		__newindex = function(self, index, value)
			local field = ComponentDef.definition[index]
			if field ~= nil and field.maxLength ~= nil and #value >= field.maxLength then
				error("Attempt to set string beyond maxLength of \"" .. tostring(index) .. "\". (note, string max length is field.maxLength-1)")
			end
			rawget(self, "_ptr")[index] = value
		end,
		__index = function (self, index)
			local field = ComponentDef.definition[index]
			local value = rawget(self, "_ptr")[index]
			if field ~= nil and field.maxLength ~= nil then
				value = ffi.string(value)
			end
			return value
		end
	})
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
for i, field in pairs(TestComponentDef.definition) do
	TestComponentDef.definition[field.field] = field
end
TestComponentDef.ctype, TestComponentDef.ctypeptr = ComponentDefToCType(TestComponentDef.definition)

return {
	ComponentDefToCType = ComponentDefToCType,
	CreateComponentPtr = CreateComponentPtr,
	CreateComponentBlob = CreateComponentBlob,
	TestComponentDef = TestComponentDef,
}
