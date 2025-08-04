--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

-- based off of this hook:
-- https://github.com/littensy/pretty-react-hooks/tree/master/src/use-binding-state

type BindingAPI<T> = {
	subscribe: (callback: (T) -> ()) -> () -> (),
	update: (T) -> (),
	getValue: () -> T,
}

local function getBindingAPI<T>(binding: React.Binding<T>): BindingAPI<T>?
	for key, value in binding :: any do
		local name = tostring(key)
		if name == "Symbol(BindingImpl)" then
			return value :: BindingAPI<T>
		end
	end
	return nil
end

local function useBindingState<T>(binding: React.Binding<T>): T
	local value, setValue = React.useState(binding:getValue())

	React.useEffect(function()
		setValue(binding:getValue())
		local api = getBindingAPI(binding)
		return if api then api.subscribe(setValue) else nil
	end, { binding })

	return value
end

return useBindingState
