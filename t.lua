package.path = package.path .. ";libs/?.lua;libs/?/init.lua"

require "globals"

local Foo = class.Foo(class.properties)
Foo.test = 1
function Foo:_init()
	print("Foo:_init()")
end
function Foo:get_potato()
	return self.test
end
local Bar = class.Bar(Foo)
function Bar:_init()
	self:super()
	print("Bar:_init()")
end

local foo = Bar()
print(foo.test)
foo.test = 2
print(foo.test)
print(foo.potato)
foo.potato = "POTATO!"
print(foo.potato)
print(foo.nah)
print("----------")
for i, v in pairs(foo) do
	print(i, v)
end
