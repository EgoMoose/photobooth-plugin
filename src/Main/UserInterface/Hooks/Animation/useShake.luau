local RunService = game:GetService("RunService") :: RunService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)
local React = require(pluginRoot.Packages.React)

local useConstant = require(script.Parent.Parent.Generic.useConstant)

local TAU = math.pi * 2

local function useShake()
	local trove = useConstant(function()
		return Trove.new()
	end)

	local shake, setShake = React.useState(Vector3.new(0, 0, 1))
	local makeShake = React.useCallback(function(length: number, frequency: Vector2, magnitude: Vector2)
		local startAt = os.clock()
		local fX, fY = frequency.X, frequency.Y
		local mX, mY = magnitude.X, magnitude.Y

		trove:Clean()
		trove:Add(task.spawn(function()
			while true do
				local dt = os.clock() - startAt
				local alpha = math.min(1, dt / length)
				local intensity = (1 - alpha * alpha)

				local offsetX = math.sin(alpha * TAU * fX) * intensity * mX
				local offsetY = math.sin(alpha * TAU * fY) * intensity * mY

				setShake(Vector3.new(offsetX, offsetY, alpha))

				if alpha >= 1 then
					break
				end

				RunService.RenderStepped:Wait()
			end
		end))
	end, {})

	return shake, makeShake
end

return useShake
