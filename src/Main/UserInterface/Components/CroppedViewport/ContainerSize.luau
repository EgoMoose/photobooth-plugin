--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local containerSizeContext = React.createContext(Vector2.new(0, 0))

export type Props = {
	children: React.ReactNode,
}

local function useContainerSize()
	return React.useContext(containerSizeContext)
end

local function ContainerSize(props: Props)
	local containerSize, setContainerSize = React.useState(Vector2.new(0, 0))
	local containerRef = React.useRef(nil :: GuiObject?)

	React.useEffect(function()
		local frame = containerRef.current :: GuiObject
		setContainerSize(frame.AbsoluteSize)

		local connection = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setContainerSize(frame.AbsoluteSize)
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
	}, {
		React.createElement(containerSizeContext.Provider, {
			value = containerSize,
		}, props.children),
	})
end

return {
	Component = ContainerSize,
	useContainerSize = useContainerSize,
}
