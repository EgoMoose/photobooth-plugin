local pluginRoot = script:FindFirstAncestor("PluginRoot")
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local ROOT_FOLDER = Instance.new("Folder")

-- This feels cursed, but I can't find another way to do this...?
local function useBindingValue<T>(binding: React.Binding<T>)
	local value, setValue = React.useState(binding:getValue())

	React.useEffect(function()
		setValue(binding:getValue())

		local root = ReactRoblox.createRoot(ROOT_FOLDER)
		root:render(React.createElement("Frame", {
			Visible = binding:map(function(mapped)
				setValue(mapped)
				return false
			end),
		}))

		return function()
			root:unmount()
		end
	end, { binding })

	return value
end

return useBindingValue
