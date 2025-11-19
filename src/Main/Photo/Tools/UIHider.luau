--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Signal = require(pluginRoot.Packages.Signal)
local Trove = require(pluginRoot.Packages.Trove)
local State = require(pluginRoot.Main.State)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local PLAYER_GUI: PlayerGui?
pcall(function()
	-- team create can cause there to be a player with no player gui
	PLAYER_GUI = Players.LocalPlayer and Players.LocalPlayer.PlayerGui
end)

local UIHiderStatic = {}

local UIHiderClass = {}
UIHiderClass.__index = UIHiderClass
UIHiderClass.ClassName = "UIHider"

export type UIHider = typeof(setmetatable(
	{} :: {
		trove: Trove.Trove,
		watchTroves: { [LayerCollector]: Trove.Trove },
		hiddenClasses: { string },
	},
	UIHiderClass
))

local globalExclusionsSet = {}
local globalExclusionsChanged = Signal.new()

-- Constructor

function UIHiderStatic.new(hiddenClasses: { string })
	local self = setmetatable({}, UIHiderClass) :: UIHider

	self.trove = Trove.new()
	self.watchTroves = {}
	self.hiddenClasses = table.clone(hiddenClasses)

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

-- Static

function UIHiderStatic.isViewportAppExcluded(rect: Rect)
	local scaleOS = State.read().temporary.scaleOS
	return not Screenshot.isFullscreenRect(rect) and Screenshot.isUnitScaleOS(scaleOS)
end

function UIHiderStatic.addExclusion(exclusion: LayerCollector)
	globalExclusionsSet[exclusion] = true
	globalExclusionsChanged:Fire()

	local hasCalled = false
	return function()
		if not hasCalled then
			hasCalled = true
			globalExclusionsSet[exclusion] = nil
			globalExclusionsChanged:Fire()
		end
	end
end

-- Private

local function isExcluded(layerCollector: LayerCollector): boolean
	return not not globalExclusionsSet[layerCollector]
end

function UIHiderClass._isValidLayerCollector(self: UIHider, layerCollector: LayerCollector)
	for _, className in self.hiddenClasses do
		if layerCollector:IsA(className) then
			return true
		end
	end
	return false
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

	local exclusionsChanged = globalExclusionsChanged:Connect(function()
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
	if child:IsA("LayerCollector") and self:_isValidLayerCollector(child) and not self.watchTroves[child] then
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

return UIHiderStatic
