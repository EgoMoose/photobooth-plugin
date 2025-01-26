--!strict

local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Ripple = require(pluginRoot.Packages.Ripple)
local React = require(pluginRoot.Packages.React)

local useMotion = require(script.Parent.useMotion)

local function useSpring<T>(goal: React.Binding<T & Ripple.MotionGoal>, options: Ripple.SpringOptions?)
	local binding, motion = useMotion(goal:getValue())
	local previousValue = React.useRef(goal:getValue())

	local function setPosition(position: T & Ripple.MotionGoal)
		previousValue.current = position
		motion:immediate(position)
	end

	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function(dt)
			local currentValue = goal:getValue()

			if currentValue ~= previousValue.current then
				previousValue.current = currentValue
				motion:spring(currentValue, options)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end)

	return binding, setPosition
end

return useSpring
