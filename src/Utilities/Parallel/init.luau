--!strict

local RunService = game:GetService("RunService") :: RunService

-- Class

local ParallelStatic = {}

local ParallelClass = {}
ParallelClass.__index = ParallelClass
ParallelClass.ClassName = "Parallel"

export type Required<T..., U...> = {
	script: ModuleScript,
	typecast: (T...) -> U...,
}

export type Parallel<T..., U...> = typeof(setmetatable(
	{} :: {
		ticket: number,
		actors: { Actor },
		schedules: { [Actor]: { () -> T... } },
		isWorking: boolean,

		required: Required<T..., U...>,

		moduleRef: ObjectValue,
		binding: BindableEvent,
	},
	ParallelClass
))

function ParallelStatic.new<T..., U...>(n: number, required: Required<T..., U...>)
	local self = setmetatable({}, ParallelClass) :: Parallel<T..., U...>

	self.ticket = 0
	self.actors = {}
	self.schedules = {}
	self.isWorking = false

	self.required = required

	self.moduleRef = Instance.new("ObjectValue")
	self.moduleRef.Name = `Parallel_{required.script.Name}`
	self.moduleRef.Value = required.script
	self.moduleRef.Archivable = false
	self.moduleRef.Parent = script

	self.binding = Instance.new("BindableEvent")
	self.binding.Name = "Binding"
	self.binding.Parent = self.moduleRef

	local workerModule = script.Worker:Clone()
	workerModule.Parent = self.moduleRef

	local actorFolder = Instance.new("Folder")
	actorFolder.Name = "Actors"
	actorFolder.Parent = self.moduleRef

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

	for _, actor in self.actors do
		while not actor:GetAttribute("IsReady") do
			actor:GetAttributeChangedSignal("IsReady"):Wait()
		end
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
			awaiting = {}
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

function ParallelClass.Clear<T..., U...>(self: Parallel<T..., U...>)
	self.ticket = 0
	for actor, _ in self.schedules do
		table.clear(self.schedules[actor])
	end
end

function ParallelClass.Work<T..., U...>(self: Parallel<T..., U...>)
	assert(not self.isWorking, "Already working!")
	self.isWorking = true

	local expectations = {}
	for i, actor in self.actors do
		local schedule = self.schedules[actor]
		for j, unpackArgs in schedule do
			local k = ((j - 1) * #self.actors) + i
			local complete, expect = quickFuture()
			expectations[k] = expect

			local connection
			connection = self.binding.Event:Connect(function(index: number, ...: any)
				if k == index then
					complete(packAsCallback(...) :: () -> U...)
					connection:Disconnect()
				end
			end)

			actor:SendMessage("Work", k, unpackArgs())
		end
	end

	self:Clear()

	local results = {}
	for i, expect in expectations do
		results[i] = expect()
	end

	self.isWorking = false
	return results
end

function ParallelClass.Destroy<T..., U...>(self: Parallel<T..., U...>)
	self.binding:Destroy()
	self.moduleRef:Destroy()
	self.actors = {}
	self.schedules = {}
end

--

return ParallelStatic
