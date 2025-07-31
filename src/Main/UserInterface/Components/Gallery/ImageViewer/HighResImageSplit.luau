--!strict

local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local Constants = require(pluginRoot.Constants)
local Image = require(pluginRoot.Utilities.Image)

local MAX_EDIT_IMAGE_WIDTH = Image.MAX_EDIT_IMAGE_SIZE.X
local MAX_EDIT_IMAGE_HEIGHT = Image.MAX_EDIT_IMAGE_SIZE.Y

export type Props = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2,

	EditableImage: EditableImage,

	ZIndex: number,
}

local function useHighResSplit(sourceEditableImage: EditableImage)
	local split, setSplit = React.useState({ {
		Position = Vector2.zero,
		EditableImage = sourceEditableImage,
	} })

	React.useEffect(function()
		local newSplit = {}
		local thread = task.spawn(function()
			local sourceWidth = sourceEditableImage.Size.X
			local sourceHeight = sourceEditableImage.Size.Y

			local dx = math.ceil(sourceWidth / MAX_EDIT_IMAGE_WIDTH)
			local dy = math.ceil(sourceHeight / MAX_EDIT_IMAGE_HEIGHT)

			if dx > 1 or dy > 1 then
				for x = 1, dx do
					for y = 1, dy do
						local offset = Vector2.new((x - 1) * MAX_EDIT_IMAGE_WIDTH, (y - 1) * MAX_EDIT_IMAGE_HEIGHT)
						local size = Vector2.new(
							math.min(MAX_EDIT_IMAGE_WIDTH, sourceWidth - offset.X),
							math.min(MAX_EDIT_IMAGE_HEIGHT, sourceHeight - offset.Y)
						)

						local chunkBuffer = sourceEditableImage:ReadPixelsBuffer(offset, size)
						local chunkEditImage = AssetService:CreateEditableImage({ Size = size })
						chunkEditImage:WritePixelsBuffer(Vector2.zero, size, chunkBuffer)

						table.insert(newSplit, {
							Position = offset,
							EditableImage = chunkEditImage,
						})
					end
				end
				setSplit(newSplit)
			end
		end)

		return function()
			task.cancel(thread)
			for _, splitEntry in newSplit do
				splitEntry.EditableImage:Destroy()
			end
		end
	end, { sourceEditableImage })

	return split
end

local function HighResImageSplit(props: Props)
	local split
	if Constants.SplitHighResViewerImages then
		split = useHighResSplit(props.EditableImage)
	else
		split = React.useMemo(function()
			return { {
				Position = Vector2.zero,
				EditableImage = props.EditableImage,
			} }
		end, { props.EditableImage })
	end

	local sourceSize = props.EditableImage.Size
	local labels: { [string]: React.Node } = {}
	for i, splitEntry in split do
		local uvSize = splitEntry.EditableImage.Size / sourceSize
		local uvPosition = splitEntry.Position / sourceSize

		labels[`ImageSplit{i}`] = React.createElement("ImageLabel", {
			ImageContent = Content.fromObject(splitEntry.EditableImage),
			Position = UDim2.fromScale(uvPosition.X, uvPosition.Y),
			Size = UDim2.fromScale(uvSize.X, uvSize.Y),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
	end

	return React.createElement("Frame", {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,

		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,

		ZIndex = props.ZIndex,
	}, labels)
end

return HighResImageSplit
