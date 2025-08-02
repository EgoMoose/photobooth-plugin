--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)
local Trove = require(pluginRoot.Packages.Trove)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

export type UploadInfo = {
	EditableImageInfos: { Hooks.EditableImageInfo },
}

type CompletedUploads = { { Name: string, AssetId: number } }

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	UploadInfo: UploadInfo,
	SetUploadInfo: (UploadInfo?) -> (),

	TryUpload: (number, string, EditableImage) -> number?,
	OnUploadComplete: (CompletedUploads) -> (),

	OnCancel: () -> (),

	Disabled: boolean,
}

local function UploadWindow(props: Props)
	local theme = StudioComponents.useTheme()
	local trove = Hooks.useConstant(function()
		return Trove.new()
	end)

	local containerRef = React.useRef(nil :: GuiObject?)
	local isUploading, setIsUploading = React.useState(false)
	local completedUploads, setCompletedUploads = React.useState(nil :: CompletedUploads?)

	local uploadCount, setUploadCount = React.useState(0)
	local uploadSuccessCount, setUploadSuccessCount = React.useState(0)

	local uploadPercentGoal, setUploadPercentGoal = React.useBinding(0)
	local uploadPercent, setUploadPercent = React.useState(uploadPercentGoal:getValue())
	local uploadPercentBinding = Hooks.useSpring(uploadPercentGoal, {
		onUpdate = function(value: number)
			setUploadPercent(value)
		end,
	})

	React.useEffect(function()
		return function()
			-- need to cleanup a potential in progress upload in the event that
			-- this element stops rendering (e.g. the user closes the widget)
			trove:Destroy()
		end
	end, {})

	local nUploads = #props.UploadInfo.EditableImageInfos
	local uploadFailCount = uploadCount - uploadSuccessCount

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		ref = containerRef,
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 4),
		}),
		UploadContainer = React.createElement("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 1, -36),
			BackgroundTransparency = 1,
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			Title = React.createElement("TextLabel", {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.5, -8),

				Text = if not isUploading then "Waiting..." else "Uploading...",
				Font = StudioComponents.Constants.DefaultFont,
				TextSize = StudioComponents.Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			}),
			Progress = React.createElement(StudioComponents.ProgressBar, {
				Max = 1,
				Value = uploadPercent,
				Formatter = function()
					return ""
				end,

				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, 0, 0, 8),
				LayoutOrder = 2,
			}),
			StatusLabel = React.createElement("TextLabel", {
				LayoutOrder = 3,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.5, -6),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),

				Text = if uploadFailCount > 0
					then `{uploadSuccessCount} / {nUploads} uploaded - {uploadFailCount} failed`
					else `{uploadSuccessCount} / {nUploads} uploaded`,
				Font = StudioComponents.Constants.DefaultFont,
				TextSize = StudioComponents.Constants.DefaultTextSize - 1,
				TextColor3 = theme:GetColor(
					Enum.StudioStyleGuideColor.MainText,
					Enum.StudioStyleGuideModifier.Disabled
				),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}),

		Buttons = React.createElement("Frame", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),

			Cancel = React.createElement(StudioComponents.Button, {
				LayoutOrder = 1,
				Size = UDim2.new(0.5, -2, 0, 28),
				Text = if completedUploads then "Close" else "Cancel",
				OnActivated = function()
					trove:Clean()
					props.OnCancel()
				end,
				Disabled = props.Disabled,
			}),

			Confirm = React.createElement(StudioComponents.MainButton, {
				LayoutOrder = 2,
				Size = UDim2.new(0.5, -2, 0, 28),
				Text = if completedUploads then "Open" else "Confirm",
				OnActivated = function()
					if completedUploads then
						props.OnUploadComplete(completedUploads)
						trove:Clean()
						return
					end

					setIsUploading(true)

					local thread = task.spawn(function()
						local completed = {}
						for i = 1, nUploads do
							local info = props.UploadInfo.EditableImageInfos[i]
							local assetId = props.TryUpload(i, info.Name, info.EditableImage)

							if assetId then
								table.insert(completed, {
									Name = info.Name,
									AssetId = assetId,
								})
								setUploadSuccessCount(#completed)
							end

							setUploadCount(i)
							setUploadPercentGoal(i / nUploads)
						end

						repeat
							task.wait()
						until uploadPercentBinding:getValue() >= 1

						setCompletedUploads(completed)
						setIsUploading(false)
					end)

					trove:Add(function()
						if coroutine.status(thread) == "suspended" then
							task.cancel(thread)
						end
						setIsUploading(false)
						props.SetUploadInfo(nil)
					end)
				end,
				Disabled = props.Disabled or isUploading,
			}),
		}),
	})
end

return UploadWindow
