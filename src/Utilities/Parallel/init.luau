--!strict

local RunService = game:GetService("RunService") :: RunService

-- Class

local ParallelClass = {}
ParallelClass.__index = ParallelClass
ParallelClass.ClassName = "Parallel"

export type Required<T..., U...> = {
	script: ModuleScript,
	callback: (T...) -> U...,
}

export type Parallel<T..., U...> = typeof(setmetatable(
	{} :: {
		ticket: number,
		actors: { Actor },
		schedules: { [Actor]: { () -> T... } },
		isWorking: boolean,

		callback: (T...) -> U...,

		module: ModuleScript,
		resultsBinding: BindableEvent,
	},
	ParallelClass
))

function ParallelClass.new<T..., U...>(n: number, required: Required<T..., U...>)
	local self = setmetatable({}, ParallelClass) :: Parallel<T..., U...>

	self.ticket = 0
	self.actors = {}
	self.schedules = {}
	self.isWorking = false

	self.callback = required.callback

	self.module = required.script:Clone()
	self.module.Name = "ParallelModule"
	self.module.Archivable = false
	self.module.Parent = script

	self.resultsBinding = Instance.new("BindableEvent")
	self.resultsBinding.Name = "Results"
	self.resultsBinding.Parent = self.module

	local workerModule = script.Worker:Clone()
	workerModule.Parent = self.module

	local actorFolder = Instance.new("Folder")
	actorFolder.Name = "Actors"
	actorFolder.Parent = self.module

	local template = script.ClientWorker
	if script:FindFirstAncestorWhichIsA("Plugin") then
		template = script.PluginWorker
	elseif RunService:IsServer() then
		template = script.ServerWorker
	end

	for i = 1, n do
		local actor = Instance.new("Actor")
		actor.Name = tostring(i)
		actor.Parent = actorFolder

		local worker = template:Clone()
		worker.Enabled = true
		worker.Parent = actor

		self.actors[i] = actor
		self.schedules[actor] = {}
	end

	return self
end

-- Private

local function quickFuture<T>()
	local result: T
	local isComplete = false
	local awaiting: { [thread]: boolean } = {}

	local function complete(value: T)
		if not isComplete then
			isComplete = true
			result = value
			for thread, _ in awaiting do
				task.spawn(thread)
			end
		end
	end

	local function expect()
		if not isComplete then
			local thread = coroutine.running()
			awaiting[thread] = true
			coroutine.yield()
		end
		return result
	end

	return complete, expect
end

local function packAsCallback<T...>(...: T...): () -> T...
	local n = select("#", ...)
	local packed = { select(1, ...) }
	return function()
		return unpack(packed, 1, n)
	end
end

local function work<T..., U...>(self: Parallel<T..., U...>)
	local expectations = {}
	for i, actor in self.actors do
		local schedule = self.schedules[actor]
		for j, unpackArgs in schedule do
			local k = ((j - 1) * #self.actors) + i
			local complete, expect = quickFuture()
			expectations[k] = expect

			local connection
			connection = self.resultsBinding.Event:Connect(function(index: number, ...: any)
				if k == index then
					complete(packAsCallback(...) :: () -> U...)
					connection:Disconnect()
				end
			end)

			actor:SendMessage("Work", k, unpackArgs())
		end
	end

	self.schedules = {}

	local results = {}
	for i, expect in expectations do
		results[i] = expect()
	end

	return results
end

-- Public

function ParallelClass.GetActorCount<T..., U...>(self: Parallel<T..., U...>)
	return #self.actors
end

function ParallelClass.Schedule<T..., U...>(self: Parallel<T..., U...>, ...: T...)
	self.ticket = self.ticket + 1
	local myTicket = self.ticket

	local actorIndex = ((myTicket - 1) % #self.actors) + 1
	local actor = self.actors[actorIndex]

	table.insert(self.schedules[actor], packAsCallback(...))
end

function ParallelClass.Work<T..., U...>(self: Parallel<T..., U...>)
	assert(not self.isWorking, "Already working!")
	self.isWorking = true

	local results = work(self)

	self.isWorking = false
	return results
end

function ParallelClass.WorkDeferred<T..., U...>(self: Parallel<T..., U...>)
	assert(not self.isWorking, "Already working!")
	self.isWorking = true

	local results
	local complete = false
	local thread = coroutine.running()
	task.defer(function()
		results = work(self)
		complete = true
		task.spawn(thread)
	end)

	while not complete do
		coroutine.yield()
	end

	self.isWorking = false
	return results
end

function ParallelClass.Destroy<T..., U...>(self: Parallel<T..., U...>)
	self.resultsBinding:Destroy()
	self.module:Destroy()
	self.actors = {}
	self.schedules = {}
end

--

return ParallelClass
