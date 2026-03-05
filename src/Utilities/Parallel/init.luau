--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Packages.Future)
local Trove = require(pluginRoot.Packages.Trove)

local MODULE_REF_FOLDER = Instance.new("Folder")
MODULE_REF_FOLDER.Name = "ModuleRefs"
MODULE_REF_FOLDER.Parent = script

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
		trove: Trove.Trove,

		ticket: number,
		isWorking: boolean,
		required: Required<T..., U...>,

		isReadyFuture: Future.Future<()>,

		actorEntries: {
			{
				actor: Actor,
				binding: BindableEvent,
				scheduled: { () -> T... },
			}
		},
	},
	ParallelClass
))

function ParallelStatic.new<T..., U...>(n: number, required: Required<T..., U...>)
	local self = setmetatable({}, ParallelClass) :: Parallel<T..., U...>

	self.trove = Trove.new()

	self.ticket = 0
	self.actorEntries = {}
	self.required = required

	self.isWorking = false
	self.isReadyFuture = Future.new()

	local moduleRef = Instance.new("ObjectValue")
	moduleRef.Name = `Parallel_{required.script.Name}`
	moduleRef.Value = required.script
	moduleRef.Archivable = false
	moduleRef.Parent = MODULE_REF_FOLDER
	self.trove:Add(moduleRef)

	local template = script.ClientWorker
	if script:FindFirstAncestorWhichIsA("Plugin") then
		template = script.PluginWorker
	elseif RunService:IsServer() then
		template = script.ServerWorker
	end

	for i = 1, n do
		local actor = Instance.new("Actor")
		actor.Name = tostring(i)
		actor.Parent = moduleRef

		local binding = Instance.new("BindableEvent")
		binding.Name = "Binding"
		binding.Parent = actor

		local worker = template:Clone()
		worker.Enabled = true
		worker.Parent = actor

		self.actorEntries[i] = {
			actor = actor,
			binding = binding,
			scheduled = {},
		}
	end

	task.spawn(function()
		for _, actorEntry in self.actorEntries do
			while not actorEntry.actor:GetAttribute("IsReady") do
				actorEntry.actor:GetAttributeChangedSignal("IsReady"):Wait()
			end
		end

		self.isReadyFuture:complete()
	end)

	return self
end

-- Public

function ParallelClass.WaitForReady<T..., U...>(self: Parallel<T..., U...>)
	self.isReadyFuture:expect()
end

function ParallelClass.GetActorCount<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReadyFuture:isCompleted(), "Not ready!")
	return #self.actorEntries
end

function ParallelClass.Schedule<T..., U...>(self: Parallel<T..., U...>, ...: T...)
	assert(self.isReadyFuture:isCompleted(), "Not ready!")

	self.ticket = self.ticket + 1
	local myTicket = self.ticket

	local actorIndex = ((myTicket - 1) % #self.actorEntries) + 1
	local actorEntry = self.actorEntries[actorIndex]

	table.insert(actorEntry.scheduled, Future.packAsCallback(...))
end

function ParallelClass.Clear<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReadyFuture:isCompleted(), "Not ready!")

	self.ticket = 0
	for _, actorEntry in self.actorEntries do
		table.clear(actorEntry.scheduled)
	end
end

function ParallelClass.Work<T..., U...>(self: Parallel<T..., U...>)
	assert(self.isReadyFuture:isCompleted(), "Not ready!")
	assert(not self.isWorking, "Already working!")
	self.isWorking = true

	local futures = {}
	for i, actorEntry in self.actorEntries do
		for j, unpackArgs in actorEntry.scheduled do
			local k = ((j - 1) * #self.actorEntries) + i
			local future = Future.new()
			futures[k] = future

			local connection
			connection = actorEntry.binding.Event:Connect(function(index: number, ...: any)
				if k == index then
					future:complete(Future.packAsCallback(...) :: () -> U...)
					connection:Disconnect()
				end
			end)

			actorEntry.actor:SendMessage("Work", k, unpackArgs())
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
	self.trove:Destroy()
	self.actorEntries = {}
end

--

return ParallelStatic
