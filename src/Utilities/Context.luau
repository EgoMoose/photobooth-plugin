--!strict

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

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

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

function ContextClass.With<T, U...>(self: Context<T>, value: T, callback: () -> U...)
	self.map[callback] = value
	local unpackResult = packAsCallback(callback())
	self.map[callback] = nil
	return unpackResult()
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
