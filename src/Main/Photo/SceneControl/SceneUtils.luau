--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Sift = require(pluginRoot.Packages.Sift)

local SceneUtils = {}

-- Public

function SceneUtils.oneTimeCallback<T..., U...>(callback: (T...) -> U...)
	local hasRun = false
	return function(...: T...)
		if not hasRun then
			hasRun = true
			return callback(...)
		end
	end
end

function SceneUtils.filterInstancesMap(instances: { Instance }, map: { [string]: (Instance) -> boolean })
	local result = {}
	for name, callback in map do
		result[name] = {}
	end

	for _, instance in instances do
		for name, callback in map do
			if callback(instance) then
				table.insert(result[name], instance)
			end
		end
	end

	return result
end

function SceneUtils.filterInstances(instances: { Instance }, filter: (Instance) -> boolean)
	return SceneUtils.filterInstancesMap(instances, { result = filter }).result
end

function SceneUtils.setTemporaryProperties(instances: { Instance }, properties: { [string]: any })
	local storedByInstance = {}
	for _, instance in instances do
		local stored = {}
		local instanceAny = instance :: any
		for property, value in properties do
			stored[property] = if instanceAny[property] == nil then Sift.None else instanceAny[property]
			instanceAny[property] = if value == Sift.None then nil else value
		end
		storedByInstance[instance] = stored
	end

	return SceneUtils.oneTimeCallback(function()
		for instance, stored in storedByInstance do
			local instanceAny = instance :: any
			for property, value in stored do
				instanceAny[property] = if value == Sift.None then nil else value
			end
		end
	end)
end

function SceneUtils.isAny(instance: Instance, classNames: { string })
	for _, className in classNames do
		if instance:IsA(className) then
			return true
		end
	end
	return false
end

--

return SceneUtils
