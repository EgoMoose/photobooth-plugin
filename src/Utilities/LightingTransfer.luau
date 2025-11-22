--!strict

local ReflectionService = game:GetService("ReflectionService") :: ReflectionService

local VERSION = 1
local ROOT_KEY = "LightingTransfer"

local LightingTransfer = {}

-- Private

type Content = {
	default: string,
	byKey: {
		[string]: string,
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
			content = {},
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

local function getLightingSaveFromCurrent(): string
	return ""
end

local function setLightingFromSave(save: string) end

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
		-- load the lighting save
	end
end

return LightingTransfer
