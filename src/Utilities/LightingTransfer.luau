--!strict

local Lighting = game:GetService("Lighting") :: Lighting
local EncodingService = game:GetService("EncodingService") :: EncodingService
local ReflectionService = game:GetService("ReflectionService") :: ReflectionService
local SerializationService = game:GetService("SerializationService") :: SerializationService

local VERSION = 1
local ROOT_KEY = "LightingTransfer"

local LightingTransfer = {}

-- Private

type LightingSave = string

type Content = {
	default: string?,
	byKey: {
		[string]: LightingSave,
	},
}

local function read(plugin: Plugin)
	local root = plugin:GetSetting(ROOT_KEY)
	local success = pcall(function()
		assert(root.version >= VERSION)
	end)

	if not success then
		root = {
			version = VERSION,
			content = {
				default = nil,
				byKey = {},
			},
		}
	end

	return root :: { version: number, content: Content }
end

local function mutate(plugin: Plugin, mutation: (Content) -> ())
	local content = read(plugin).content
	mutation(content)
	return plugin:SetSetting(ROOT_KEY, {
		version = VERSION,
		content = content,
	})
end

local function getLightingSaveFromCurrent(): LightingSave
	local instances: { Instance } = {}

	local postEffect = ReflectionService:GetClass("PostEffect")
	local effectSubClasses: { string } = if postEffect then postEffect.Subclasses else {}
	for _, className in effectSubClasses do
		local children = Lighting:QueryDescendants(`>{className}`)
		for i = #children, 1, -1 do
			local child = children[i]
			if child:IsA("PostEffect") and child.Enabled then
				table.insert(instances, child)
				break
			end
		end
	end

	local atmospheres = Lighting:QueryDescendants(">Atmosphere")
	local poppedAtmosphere = table.remove(atmospheres)
	if poppedAtmosphere and poppedAtmosphere:IsA("Atmosphere") then
		table.insert(instances, poppedAtmosphere)
	end

	local skys = Lighting:QueryDescendants(">Sky")
	local poppedSky = table.remove(skys)
	if poppedSky and poppedSky:IsA("Sky") then
		table.insert(instances, poppedSky)
	end

	local clouds = workspace.Terrain:QueryDescendants(">Clouds")
	for i = #clouds, 1, -1 do
		local cloud = clouds[i]
		if cloud:IsA("Clouds") and cloud.Enabled then
			table.insert(instances, cloud)
			break
		end
	end

	local lightingFolder = Instance.new("Folder")
	lightingFolder.Name = "Lighting"
	table.insert(instances, lightingFolder)

	for _, property in ReflectionService:GetPropertiesOfClass("Lighting") do
		if property.Serialized and property.Permits.Read and property.Permits.Write then
			pcall(function()
				lightingFolder:SetAttribute(property.Name, (Lighting :: any)[property.Name])
			end)
		end
	end

	local b = SerializationService:SerializeInstancesAsync(instances)
	local lightingSave = buffer.tostring(EncodingService:Base64Encode(b))
	lightingFolder:Destroy()

	return lightingSave
end

local function setLightingFromSave(lightingSave: LightingSave)
	-- clear the current lighting children
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- clear clouds from terrain
	for _, child in workspace.Terrain:QueryDescendants(">Clouds") do
		child:Destroy()
	end

	-- reset lighting to it's original settings
	for _, property in ReflectionService:GetPropertiesOfClass("Lighting") do
		if
			property.Serialized
			and property.Permits.Read
			and property.Permits.Write
			and Lighting:IsPropertyModified(property.Name)
		then
			Lighting:ResetPropertyToDefault(property.Name)
		end
	end

	local b = EncodingService:Base64Decode(buffer.fromstring(lightingSave))
	local instances = SerializationService:DeserializeInstancesAsync(b)

	for _, instance in instances do
		if instance:IsA("Folder") and instance.Name == "Lighting" then
			for attributeName, value in instance:GetAttributes() do
				pcall(function()
					(Lighting :: any)[attributeName] = value
				end)
			end
		elseif instance:IsA("Clouds") then
			instance.Parent = workspace.Terrain
		else
			(instance :: Instance).Parent = Lighting
		end
	end
end

-- Public

function LightingTransfer.save(plugin: Plugin, key: string?)
	-- figure out how to
	local lightingSave = getLightingSaveFromCurrent()
	mutate(plugin, function(content)
		if key then
			content.byKey[key] = lightingSave
		else
			content.default = lightingSave
		end
	end)
end

function LightingTransfer.load(plugin: Plugin, key: string?)
	local content = read(plugin).content
	local lightingSave = if key then content.byKey[key] else content.default
	if lightingSave then
		setLightingFromSave(lightingSave)
	end
end

function LightingTransfer.bindable(plugin: Plugin)
	-- this is a bit weird, but we have to interface through a bindable instance
	-- to ensure we have access to the plugin instance which is needed for saving

	local binding = Instance.new("BindableFunction")
	binding.Name = "Binding"
	binding.Parent = script

	binding.OnInvoke = function(name: string, key: string?)
		if name == "save" then
			return LightingTransfer.save(plugin, key)
		elseif name == "load" then
			return LightingTransfer.load(plugin, key)
		end
	end

	return {
		save = function(key: string?)
			binding:Invoke("save", key)
		end,
		load = function(key: string?)
			binding:Invoke("load", key)
		end,
	}
end

-- Bindable setup

--

return LightingTransfer
