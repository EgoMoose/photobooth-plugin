--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Utilities.Future)

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
		isReady: boolean,

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
	self.isReady = false

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

	task.spawn(function()
		for _, actor in self.actors do
			while not actor:GetAttribute("IsReady") do
				actor:GetAttributeChangedSignal("IsReady"):Wait()
			end
		end

		self.isReady = true
	end)

	return self
end

-- Public

function ParallelClass.GetActorCount<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReady, "Not ready!")
	return #self.actors
end

function ParallelClass.Schedule<T..., U...>(self: Parallel<T..., U...>, ...: T...)
	assert(self.isReady, "Not ready!")

	self.ticket = self.ticket + 1
	local myTicket = self.ticket

	local actorIndex = ((myTicket - 1) % #self.actors) + 1
	local actor = self.actors[actorIndex]

	table.insert(self.schedules[actor], Future.packAsCallback(...))
end

function ParallelClass.Clear<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReady, "Not ready!")

	self.ticket = 0
	for actor, _ in self.schedules do
		table.clear(self.schedules[actor])
	end
end

function ParallelClass.Work<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReady, "Not ready!")
	assert(not self.isWorking, "Already working!")
	self.isWorking = true

	local futures = {}
	for i, actor in self.actors do
		local schedule = self.schedules[actor]
		for j, unpackArgs in schedule do
			local k = ((j - 1) * #self.actors) + i
			local future = Future.new()
			futures[k] = future

			local connection
			connection = self.binding.Event:Connect(function(index: number, ...: any)
				if k == index then
					future:complete(Future.packAsCallback(...) :: () -> U...)
					connection:Disconnect()
				end
			end)

			actor:SendMessage("Work", k, unpackArgs())
		end
	end

	self:Clear()

	local results = {}
	for i, future in futures do
		local castedFuture = future :: Future.Future<() -> U...>
		results[i] = castedFuture:expect()
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
