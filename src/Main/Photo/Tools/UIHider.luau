--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local PLAYER_GUI: PlayerGui? = Players.LocalPlayer and Players.LocalPlayer.PlayerGui

local UIHiderClass = {}
UIHiderClass.__index = UIHiderClass
UIHiderClass.ClassName = "UIHider"

export type UIHider = typeof(setmetatable(
	{} :: {
		ticket: number,
		trove: Trove.Trove,
		isValidLayerCollector: (LayerCollector) -> boolean,
		exclusionList: { LayerCollector },
		watchTroves: { [LayerCollector]: Trove.Trove },
	},
	UIHiderClass
))

local globalTicket = 0
local globalExclusionsChanged = Instance.new("BindableEvent")
local globalExclusions: { [LayerCollector]: { [number]: boolean } } = {}

-- Constructor

function UIHiderClass.new(
	exclusionsList: { LayerCollector },
	isValidLayerCollector: ((LayerCollector) -> boolean)?
): UIHider
	local self = setmetatable({}, UIHiderClass) :: UIHider

	globalTicket = globalTicket + 1

	self.ticket = globalTicket
	self.trove = Trove.new()

	self.isValidLayerCollector = isValidLayerCollector or function()
		return true
	end

	self.watchTroves = {}
	self.exclusionList = table.clone(exclusionsList)

	for _, exclusion in exclusionsList do
		if not globalExclusions[exclusion] then
			globalExclusions[exclusion] = {}
		end

		globalExclusions[exclusion][self.ticket] = true

		self.trove:Add(function()
			globalExclusions[exclusion][self.ticket] = nil

			if not next(globalExclusions[exclusion]) then
				globalExclusions[exclusion] = nil
			end
		end)
	end

	if #exclusionsList > 0 then
		globalExclusionsChanged:Fire()
	end

	for _, uiSource in { CoreGui, StarterGui, PLAYER_GUI } do
		self.trove:Add(uiSource.DescendantAdded:Connect(function(child)
			self:_attemptWatch(child)
		end))

		self.trove:Add(uiSource.DescendantRemoving:Connect(function(child)
			self:_attemptStopWatch(child)
		end))

		for _, child in uiSource:GetDescendants() do
			self:_attemptWatch(child)
		end
	end

	self.trove:Add(workspace.DescendantAdded:Connect(function(child)
		self:_attemptWatch(child)
	end))

	self.trove:Add(workspace.DescendantRemoving:Connect(function(child)
		self:_attemptStopWatch(child)
	end))

	for _, child in workspace:GetDescendants() do
		self:_attemptWatch(child)
	end

	return self
end

-- Private

local function isExcluded(layerCollector: LayerCollector): boolean
	return not not next(globalExclusions[layerCollector] or {})
end

function UIHiderClass._watch(self: UIHider, layerCollector: LayerCollector)
	local trove = Trove.new()
	local wasEnabled = layerCollector.Enabled

	-- signal behavior deferred...
	local function refreshEnabled()
		if isExcluded(layerCollector) then
			layerCollector.Enabled = wasEnabled
		else
			layerCollector.Enabled = false
		end
	end

	local enabledChanged = layerCollector:GetPropertyChangedSignal("Enabled"):Connect(function()
		refreshEnabled()
	end)

	local exclusionsChanged = globalExclusionsChanged.Event:Connect(function()
		refreshEnabled()
	end)

	trove:Add(function()
		enabledChanged:Disconnect()
		exclusionsChanged:Disconnect()
		layerCollector.Enabled = wasEnabled
	end)

	self.watchTroves[layerCollector] = trove
	refreshEnabled()
end

function UIHiderClass._stopWatching(self: UIHider, layerCollector: LayerCollector)
	local trove = self.watchTroves[layerCollector]
	if trove then
		self.watchTroves[layerCollector] = nil
		trove:Destroy()
	end
end

function UIHiderClass._attemptWatch(self: UIHider, child: Instance)
	if child:IsA("LayerCollector") and self.isValidLayerCollector(child) and not self.watchTroves[child] then
		self:_watch(child)
	end
end

function UIHiderClass._attemptStopWatch(self: UIHider, child: Instance)
	if child:IsA("LayerCollector") and self.watchTroves[child] then
		self:_stopWatching(child)
	end
end

-- Public

function UIHiderClass.Destroy(self: UIHider)
	self.trove:Destroy()
	for layerCollector, _ in self.watchTroves do
		self:_stopWatching(layerCollector)
	end
end

--

return UIHiderClass
