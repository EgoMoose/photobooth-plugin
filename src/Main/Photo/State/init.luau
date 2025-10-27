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
		isCapturing = false,
		scaleOS = Vector2.one,
		uiCaptureType = "NoBackground" :: Types.UICaptureTypes,
		viewportCaptureType = "NoSkybox" :: Types.ViewportCaptureTypes,
	}
end

local function readOnly<T>(tbl: T)
	return (setmetatable({}, {
		__index = tbl,
		__newindex = false,
	}) :: any) :: T
end

--

export type State = {
	saved: SaveVersions.Deserialized,
	temporary: typeof(defaultTemporary()),
}

function State.read()
	return currentStateReadOnly
end

function State.mutate(callback: (State) -> ())
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
		stateChanged:Fire(key)
	end

	for key, _ in tmpMutatedKeys do
		stateChanged:Fire(key)
	end
end

function State.setTemp(key: string, value: any)
	State.mutate(function(state)
		state.temporary[key] = value
	end)
end

function State.setSaved(key: string, value: any)
	State.mutate(function(state)
		state.saved[key] = value
	end)
end

function State.setup(plugin: Plugin)
	local _success, _err = pcall(function()
		local serializedWrapped = plugin:GetSetting(PLUGIN_SAVED_KEY)
		local deserialized = SaveVersions.load(serializedWrapped)

		currentState = {
			saved = deserialized,
			temporary = defaultTemporary(),
		}

		currentStateReadOnly = {
			saved = readOnly(currentState.saved),
			temporary = readOnly(currentState.temporary),
		}
	end)

	plugin.Unloading:Connect(function()
		local saved = SaveVersions.save(currentState.saved)
		plugin:SetSetting(PLUGIN_SAVED_KEY, saved)
	end)
end

return State
