--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Signal = require(pluginRoot.Packages.Signal)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)

local SaveVersions = require(script.SaveVersions)

local PLUGIN_SAVED_KEY = "egomoose_photobooth_save"

local State = {}

local currentState: State
local currentStateReadOnly: State
local stateChanged = Signal.new()

-- Private

local function defaultTemporary()
	return {
		scaleOS = Vector2.one,

		isCapturing = false,
		isFullscreen = false,

		uiCaptureType = "NoBackground" :: Types.UICaptureTypes,
		viewportCaptureType = "NoSkybox2_Alpha" :: Types.ViewportCaptureTypes,
	}
end

local function readOnly<T>(tbl: T)
	return (setmetatable({}, {
		__index = tbl,
		__newindex = false,
	}) :: any) :: T
end

local function initState(saved: SaveVersions.Saved?)
	if not (saved and saved.version and saved.serialized) then
		saved = {
			version = SaveVersions.latest.version,
			serialized = {},
		}
	end

	currentState = {
		saved = SaveVersions.load(saved :: SaveVersions.Saved),
		temporary = defaultTemporary(),
	}

	currentStateReadOnly = {
		saved = readOnly(currentState.saved),
		temporary = readOnly(currentState.temporary),
	}
end

--

export type State = {
	saved: SaveVersions.Deserialized,
	temporary: typeof(defaultTemporary()),
}

function State.read()
	assert(currentState, "State has not been initialized.")
	return currentStateReadOnly
end

function State.mutate(callback: (state: State) -> ())
	assert(currentState, "State has not been initialized.")

	local tmpMutatedKeys = {}
	local tmpClone = table.clone(currentState.temporary)
	local tmpProxy = setmetatable({}, {
		__index = currentState.temporary,
		__newindex = function(_, key, value)
			if tmpClone[key] ~= value then
				tmpMutatedKeys[key] = true
			else
				tmpMutatedKeys[key] = nil
			end
			currentState.temporary[key] = value
		end,
	})

	local savedMutatedKeys = {}
	local savedClone = table.clone(currentState.saved)
	local savedProxy = setmetatable({}, {
		__index = currentState.saved,
		__newindex = function(_, key, value)
			if savedClone[key] ~= value then
				savedMutatedKeys[key] = true
			else
				savedMutatedKeys[key] = nil
			end
			currentState.saved[key] = value
		end,
	})

	callback({
		saved = savedProxy,
		temporary = tmpProxy,
	} :: any)

	for key, _ in savedMutatedKeys do
		stateChanged:Fire({ "saved", key }, currentState.saved[key], savedClone[key])
	end

	for key, _ in tmpMutatedKeys do
		stateChanged:Fire({ "temporary", key }, currentState.temporary[key], tmpClone[key])
	end
end

function State.onChanged(callback: (path: { string }, new: any, prev: any) -> ())
	local connection = stateChanged:Connect(callback)
	return function()
		connection:Disconnect()
	end
end

function State.setup(plugin: Plugin)
	local success, _err = pcall(function()
		local saved = plugin:GetSetting(PLUGIN_SAVED_KEY)
		initState(saved)
	end)

	if not success then
		initState(nil)
	end

	plugin.Unloading:Connect(function()
		local saved = SaveVersions.save(currentState.saved)
		plugin:SetSetting(PLUGIN_SAVED_KEY, saved)
	end)
end

function State.storybook()
	initState(nil)
end

return State
