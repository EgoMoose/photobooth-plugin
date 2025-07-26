--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Packages.Future)

local ContextClass = {}
ContextClass.__index = ContextClass
ContextClass.ClassName = "Context"

export type Context<T> = typeof(setmetatable(
	{} :: {
		default: T,
		map: { [() -> ...any]: T },
	},
	ContextClass
))

function ContextClass.new<T>(default: T)
	local self = setmetatable({}, ContextClass) :: Context<T>

	self.default = default
	self.map = {}

	return self
end

-- Private

local function iterateFunctionStack(level: number)
	local stack = level
	return function()
		stack = stack + 1
		local foo = debug.info(stack, "f")
		if foo then
			return stack - level, foo
		end
		return nil :: any, nil :: any
	end
end

-- Public

function ContextClass.With<T, U...>(self: Context<T>, value: T, callback: () -> U...): U...
	self.map[callback] = value
	local packed = table.pack(callback)
	self.map[callback] = nil
	return table.unpack(packed :: { any }, 1, packed.n)
end

function ContextClass.Use<T>(self: Context<T>): T
	for i, func in iterateFunctionStack(2) do
		local value = self.map[func]
		if value then
			return value
		end
	end
	return self.default
end

--

return ContextClass
