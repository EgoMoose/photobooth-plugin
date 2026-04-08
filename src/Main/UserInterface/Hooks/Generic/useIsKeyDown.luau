--!strict

local UserInputService = game:GetService("UserInputService") :: UserInputService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local function checkIsKeyDown(...: Enum.KeyCode)
	for _, keyCode in { ... } do
		if UserInputService:IsKeyDown(keyCode) then
			return true
		end
	end
	return false
end

local function useIsKeyDown(...: Enum.KeyCode)
	local isKeyDown, setIsKeyDown = React.useState(checkIsKeyDown(...))

	local packed = table.pack(...)
	React.useEffect(function()
		setIsKeyDown(checkIsKeyDown(table.unpack(packed)))

		local inputSet = {}
		for i = 1, packed.n do
			inputSet[packed[i]] = true
		end

		local inputBegan = UserInputService.InputBegan:Connect(function(input)
			if inputSet[input.KeyCode] then
				setIsKeyDown(checkIsKeyDown(table.unpack(packed)))
			end
		end)

		local inputEnded = UserInputService.InputEnded:Connect(function(input)
			if inputSet[input.KeyCode] then
				setIsKeyDown(checkIsKeyDown(table.unpack(packed)))
			end
		end)

		return function()
			inputBegan:Disconnect()
			inputEnded:Disconnect()
		end
	end, { ... })

	return isKeyDown
end

return useIsKeyDown
