--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local StudioComponents = require(pluginRoot.Packages.StudioComponents)
local React = require(pluginRoot.Packages.React)

local UploadDetails = require(script.UploadDetails)
local AssetResult = require(script.AssetResult)

export type UploadCallback = (UploadDetails.Details) -> (boolean, number | string)

export type Props = {
	PlaceholderTitle: string,
	EditableImage: EditableImage,
	OnConfirm: UploadCallback,
	CloseCallback: () -> (),
	Disabled: boolean,
}

local function LoadingOverlay(props: { ShowDots: boolean, ZIndex: number })
	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.7,
		ZIndex = props.ZIndex,
	}, {
		Sink = React.createElement("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = -1,
		}),
		Loading = React.createElement(StudioComponents.LoadingDots, {
			Size = UDim2.fromScale(1, 1),
		}),
	})
end

local function UploadPrompt(props: Props)
	local isLoading, setIsLoading = React.useState(false)
	local assetIdResult, setAssetIdResult = React.useState(nil :: {
		success: boolean,
		value: number | string,
	}?)

	return React.createElement(React.Fragment, nil, {
		LoadingOverlay = isLoading and React.createElement(LoadingOverlay, {
			ShowDots = not not assetIdResult,
			ZIndex = 3,
		}),

		Result = assetIdResult and React.createElement(AssetResult, {
			AssetId = if assetIdResult.success then assetIdResult.value :: number else nil,
			ErrorMsg = if not assetIdResult.success then assetIdResult.value :: string else nil,
			OnConfirm = function()
				setAssetIdResult(nil :: any)
				props.CloseCallback()
			end,
			Disabled = props.Disabled,
			ZIndex = 2,
		}),

		Details = React.createElement(UploadDetails, {
			PlaceholderTitle = props.PlaceholderTitle,
			PlaceholderDescription = "Generated with the Photobooth plugin.",

			EditableImage = props.EditableImage,

			OnCancel = props.CloseCallback,
			OnConfirm = function(details)
				setIsLoading(true)

				local success, result = props.OnConfirm(details)
				setAssetIdResult({
					success = success,
					value = result,
				})

				setIsLoading(false)
			end,

			Disabled = not not assetIdResult or isLoading or props.Disabled,
			ZIndex = 1,
		}),
	})
end

return UploadPrompt
