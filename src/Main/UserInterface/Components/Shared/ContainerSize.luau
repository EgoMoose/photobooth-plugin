--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

export type Props = {
	SetContainerSize: (Vector2) -> (),
	children: React.ReactNode,
}

local function ContainerSize(props: Props)
	local containerRef = React.useRef(nil :: GuiObject?)

	React.useEffect(function()
		local frame = containerRef.current :: GuiObject
		props.SetContainerSize(frame.AbsoluteSize)

		local connection = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			props.SetContainerSize(frame.AbsoluteSize)
		end)

		return function()
			connection:Disconnect()
		end
	end, { containerRef.current })

	return React.createElement("Frame", {
		Name = "ContainerSizeFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = containerRef,
	}, props.children)
end

return ContainerSize
