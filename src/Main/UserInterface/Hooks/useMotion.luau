--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Ripple = require(pluginRoot.Packages.Ripple)
local React = require(pluginRoot.Packages.React)

local function useMotion(initialValue: Ripple.MotionGoal)
	local motion = React.useMemo(function()
		return Ripple.createMotion(initialValue)
	end, {})

	local binding, setValue = React.useBinding(initialValue)

	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function(dt)
			local value = motion:step(dt)
			if value ~= binding then
				setValue(value)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end)

	return binding, motion
end

return useMotion
