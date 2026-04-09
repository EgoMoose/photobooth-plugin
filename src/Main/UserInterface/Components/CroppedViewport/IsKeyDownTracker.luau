--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

export type Props = {
	AnchorPoint: Vector2?,
	Position: UDim2?,
	Size: UDim2?,

	KeyCodeSet: { [Enum.KeyCode]: boolean },
	OnKeyDownChanged: (boolean) -> (),

	ZIndex: number?,
}

local function IsKeyDownTracker(props: Props)
	local state = Hooks.useConstant(function()
		return {
			isKeyDown = false,
			connectionsByKeyCode = {} :: { [Enum.KeyCode]: RBXScriptConnection },
		}
	end)

	React.useEffect(function()
		for keyCode, _ in state.connectionsByKeyCode do
			if not props.KeyCodeSet[keyCode] then
				state.connectionsByKeyCode[keyCode]:Disconnect()
				state.connectionsByKeyCode[keyCode] = nil
			end
		end

		local isKeyDown = not not next(state.connectionsByKeyCode)
		if isKeyDown ~= state.isKeyDown then
			state.isKeyDown = isKeyDown
			props.OnKeyDownChanged(state.isKeyDown)
		end
	end, { props.KeyCodeSet })

	React.useEffect(function()
		return function()
			-- cleanup code if the component is deleted
			for keyCode, _ in state.connectionsByKeyCode do
				state.connectionsByKeyCode[keyCode]:Disconnect()
				state.connectionsByKeyCode[keyCode] = nil
			end

			state.isKeyDown = false
			props.OnKeyDownChanged(state.isKeyDown)
		end
	end, {})

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		ZIndex = props.ZIndex,

		[React.Event.InputBegan] = React.useCallback(function(_rbx, input: InputObject)
			if props.KeyCodeSet[input.KeyCode] and not state.connectionsByKeyCode[input.KeyCode] then
				state.connectionsByKeyCode[input.KeyCode] = input
					:GetPropertyChangedSignal("UserInputState")
					:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							state.connectionsByKeyCode[input.KeyCode]:Disconnect()
							state.connectionsByKeyCode[input.KeyCode] = nil

							local isKeyDown = not not next(state.connectionsByKeyCode)
							if isKeyDown ~= state.isKeyDown then
								state.isKeyDown = isKeyDown
								props.OnKeyDownChanged(state.isKeyDown)
							end
						end
					end)

				local isKeyDown = not not next(state.connectionsByKeyCode)
				if isKeyDown ~= state.isKeyDown then
					state.isKeyDown = isKeyDown
					props.OnKeyDownChanged(state.isKeyDown)
				end
			end
		end, { props.KeyCodeSet }),
	})
end

return React.memo(IsKeyDownTracker)
