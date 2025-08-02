--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Lucide = require(pluginRoot.Packages.Lucide)
local React = require(pluginRoot.Packages.React)

export type Props = {
	Disabled: boolean?,

	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	OnActivated: () -> ()?,

	GetColor: (Enum.StudioStyleGuideModifier) -> Color3,
	Icon: typeof(assert(Lucide.GetAsset(nil :: any, nil :: any))),
}

local function LucideButton(props: Props)
	local hovered, setHovered = React.useState(false)
	local pressed, setPressed = React.useState(false)
	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.Disabled then
		modifier = Enum.StudioStyleGuideModifier.Disabled
	elseif pressed and hovered then
		modifier = Enum.StudioStyleGuideModifier.Pressed
	elseif hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end

	local ref = React.useRef(nil :: ImageButton?)
	React.useEffect(function()
		local button = ref.current :: ImageButton
		local conn1 = button:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			setHovered(false)
		end)

		local conn2 = button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setHovered(false)
		end)

		return function()
			conn1:Disconnect()
			conn2:Disconnect()
		end
	end, {})

	return React.createElement("ImageButton", {
		BackgroundTransparency = 1,

		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		Image = props.Icon.Url,
		ImageRectSize = props.Icon.ImageRectSize,
		ImageRectOffset = props.Icon.ImageRectOffset,
		ImageColor3 = props.GetColor(modifier),

		[React.Event.InputBegan] = function(_, input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				setHovered(true)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				setPressed(true)
			end
		end,
		[React.Event.InputEnded] = function(_, input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				setHovered(false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				setPressed(false)
			end
		end,
		[React.Event.Activated] = function()
			if not props.Disabled and props.OnActivated then
				props.OnActivated()
			end
		end,

		ref = ref,
	})
end

return LucideButton
