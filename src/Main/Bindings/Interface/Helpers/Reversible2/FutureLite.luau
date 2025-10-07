--!strict

local FutureLiteStatic = {}

local FutureLiteClass = {}
FutureLiteClass.__index = FutureLiteClass
FutureLiteClass.ClassName = "FutureLite"

export type FutureLite<T> = typeof(setmetatable(
	{} :: {
		status: "pending" | "completed",
		awaiting: { [thread]: boolean },
		value: T,
	},
	FutureLiteClass
))

function FutureLiteStatic.new<T>()
	local self = setmetatable({}, FutureLiteClass) :: FutureLite<T>

	self.status = "pending"
	self.awaiting = {}

	return self
end

function FutureLiteStatic.resolve<T>(value: T)
	local future = FutureLiteStatic.new()
	future:complete(value)
	return future
end

-- Methods

function FutureLiteClass.isComplete<T>(self: FutureLite<T>)
	return self.status == "completed"
end

function FutureLiteClass.complete<T>(self: FutureLite<T>, value: T)
	assert(self.status ~= "completed", "Cannot complete a future that is already completed")

	self.value = value
	self.status = "completed"

	local awaiting = self.awaiting
	self.awaiting = {}
	for thread, _ in awaiting do
		coroutine.resume(thread)
	end
end

function FutureLiteClass.expect<T>(self: FutureLite<T>)
	if self.status ~= "completed" then
		local thread = coroutine.running()
		self.awaiting[thread] = true
		coroutine.yield()
	end

	return self.value
end

--

return FutureLiteStatic
