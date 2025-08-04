--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local Signal = require(pluginRoot.Packages.Signal)
local Trove = require(pluginRoot.Packages.Trove)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local VerticalScroll = require(uiRoot.Components.Shared.VerticalScroll)
local Hooks = require(uiRoot.Hooks)

local UploadLineItem = require(script.UploadLineItem)

type Output = { { Name: string, AssetId: number } }
type UploadStatus = "Waiting" | "Queued" | "InProgress" | "Complete" | "Fail" | "Cancel"

export type Props = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,

	UploadInfos: { Hooks.EditableImageInfo },
	SetUploadInfos: ({ Hooks.EditableImageInfo }?) -> (),

	TryUpload: (number, string, EditableImage) -> number?,
	OnUploadComplete: (Output) -> (),

	OnCancel: () -> (),

	Disabled: boolean,
}

local STATUS_TEXT_MAP = {
	["Queued"] = nil,
	["InProgress"] = nil,
	["Complete"] = nil,

	["Waiting"] = "Waiting",
	["Fail"] = "Failed",
	["Cancel"] = "Canceled",
}

local function UploadWindow(props: Props)
	local theme = StudioComponents.useTheme()
	local creator, setCreator = React.useState("Me")

	local cancelSignal = Hooks.useConstant(function()
		return Signal.new() :: Signal.Signal<number>
	end)

	local closeTrove = Hooks.useConstant(function()
		return Trove.new()
	end)

	React.useEffect(function()
		return closeTrove:WrapClean()
	end, {})

	local assetIdRef = React.useRef({})
	local outputRef = React.useRef({})

	local uploadState, setIsUploadState = React.useState("NotStarted")
	local uploadStatusesBinding, setUploadStatuses =
		React.useBinding(table.create(#props.UploadInfos, "Waiting" :: UploadStatus))
	local uploadStatuses = Hooks.useBindingState(uploadStatusesBinding) :: { UploadStatus }

	local lines: { [string]: React.Node } = {}
	for i, info in props.UploadInfos do
		local status = uploadStatuses[i]

		lines[`Line{i}`] = React.createElement(UploadLineItem, {
			AnchorPoint = Vector2.zero,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(1, 0, 0, 64),

			Name = info.Name,
			EditableImage = info.EditableImage,

			AssetId = assetIdRef.current[i],
			Progress = if status == "Complete" then 1 elseif status == "InProgress" then 0.05 else 0,
			StatusText = STATUS_TEXT_MAP[status],
			OnCancel = function()
				cancelSignal:Fire(i)
			end,

			LayoutOrder = i,
			Disabled = not (status == "Queued" or status == "InProgress" or status == "Complete"),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
	}, {
		UISizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(0, 0),
			MaxSize = Vector2.new(350, 400),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),

		Title = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			Text = "Upload",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			Font = StudioComponents.Constants.DefaultFont,
			TextScaled = true,
			LayoutOrder = 1,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 0),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}),
		}),

		FileList = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -24 - 6 - 32 - 6),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			LayoutOrder = 2,
		}, {
			Scroll = React.createElement(VerticalScroll, {
				AnchorPoint = Vector2.zero,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),

				GradientColor = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				GradientHeight = 8,

				Disabled = props.Disabled,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 0),
				}),
			}, lines),
		}),

		BottomRow = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = 3,
		}, {
			Buttons = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 4),
				}),

				Confirm = React.createElement(StudioComponents.MainButton, {
					LayoutOrder = -1,
					Size = UDim2.new(0, 70, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Text = if uploadState == "Complete" then "Open" else "Upload",
					Disabled = props.Disabled or uploadState == "Uploading",
					OnActivated = function()
						if uploadState == "Complete" then
							props.OnUploadComplete(outputRef.current)
						else
							local cleanupTrove = Trove.new()
							closeTrove:Add(cleanupTrove)
							closeTrove:Add(task.spawn(function()
								setIsUploadState("Uploading")

								outputRef.current = {}

								local uploadThreads = {}
								local uploadCompleteSignal = Signal.new()

								cleanupTrove:Add(cancelSignal:Connect(function(i)
									local statuses = uploadStatusesBinding:getValue()
									if statuses[i] == "InProgress" then
										statuses[i] = "Cancel"
										setUploadStatuses(table.clone(statuses))

										local uploadThread = uploadThreads[i]
										if uploadThread and coroutine.status(uploadThread) == "suspended" then
											task.cancel(uploadThread)
										end

										uploadCompleteSignal:Fire(i, true)
									end
								end))

								local statuses = uploadStatusesBinding:getValue()
								for i, _info in props.UploadInfos do
									statuses[i] = "Queued"
								end
								setUploadStatuses(table.clone(statuses))

								for i, info in props.UploadInfos do
									if uploadStatusesBinding:getValue()[i] ~= "Queued" then
										continue
									end

									statuses = uploadStatusesBinding:getValue()
									statuses[i] = "InProgress"
									setUploadStatuses(table.clone(statuses))

									local assetId: number?
									uploadThreads[i] = cleanupTrove:Add(task.spawn(function()
										assetId = props.TryUpload(i, info.Name, info.EditableImage)
										uploadCompleteSignal:Fire(i, false)
									end))

									-- signal library has an annoying warn on cleanup so can't use signal:Wait()
									local isCancelled = false
									local myThread = coroutine.running()
									cleanupTrove:Add(uploadCompleteSignal:Connect(function(j, canceled)
										if i == j then
											isCancelled = canceled
											task.spawn(myThread)
										end
									end))

									coroutine.yield()

									if not isCancelled then
										statuses = uploadStatusesBinding:getValue()

										if assetId then
											assetIdRef.current[i] = assetId
											statuses[i] = "Complete"
											table.insert(outputRef.current, {
												Name = info.Name,
												AssetId = assetId,
											})
										else
											statuses[i] = "Fail"
										end

										setUploadStatuses(table.clone(statuses))
									end
								end

								cleanupTrove:Destroy()

								setIsUploadState("Complete")
							end))
						end
					end,
				}),
				Cancel = React.createElement(StudioComponents.Button, {
					LayoutOrder = -2,
					Size = UDim2.new(0, 70, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Text = if uploadState == "Complete" then "Close" else "Cancel",
					Disabled = props.Disabled,
					OnActivated = function()
						closeTrove:Clean()
						props.OnCancel()
					end,
				}),
			}),

			Creator = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -152, 1, 0),
				Position = UDim2.fromOffset(4, 0),
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 4),
				}),

				Label = React.createElement(StudioComponents.Label, {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 44, 1, 0),
					Text = "Creator:",
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					LayoutOrder = 1,
				}),

				Container = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -48, 0, StudioComponents.Constants.DefaultDropdownHeight),
					LayoutOrder = 2,
				}, {
					UISizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(70, math.huge),
					}),
					Dropdown = React.createElement(StudioComponents.Dropdown, {
						Size = UDim2.fromScale(1, 1),
						Items = { "Me", "Group1", "Group2", "Group3" },
						SelectedItem = creator,
						OnItemSelected = function(item)
							setCreator(item :: string)
						end,
					}),
				}),
			}),
		}),
	})
end

return UploadWindow
