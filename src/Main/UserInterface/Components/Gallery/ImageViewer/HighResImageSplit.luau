--!strict

local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local React = require(pluginRoot.Packages.React)

local Constants = require(pluginRoot.Constants)

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
		local sourceWidth = sourceEditableImage.Size.X
		local sourceHeight = sourceEditableImage.Size.Y

		local dx = math.ceil(sourceWidth / Constants.TileHighResImagesSize.X)
		local dy = math.ceil(sourceHeight / Constants.TileHighResImagesSize.Y)

		if dx > 1 or dy > 1 then
			local newSplit = {}
			local thread = task.spawn(function()
				for x = 1, dx do
					for y = 1, dy do
						local offset = Vector2.new(
							(x - 1) * Constants.TileHighResImagesSize.X,
							(y - 1) * Constants.TileHighResImagesSize.Y
						)

						local size = Vector2.new(
							math.min(Constants.TileHighResImagesSize.X, sourceWidth - offset.X),
							math.min(Constants.TileHighResImagesSize.Y, sourceHeight - offset.Y)
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
			end)

			return function()
				task.cancel(thread)
				for _, splitEntry in newSplit do
					splitEntry.EditableImage:Destroy()
				end
			end
		else
			setSplit({ {
				Position = Vector2.zero,
				EditableImage = sourceEditableImage,
			} })

			return nil :: any
		end
	end, { sourceEditableImage })

	return split
end

local function HighResImageSplit(props: Props)
	local split
	if Constants.TileHighResImagesEnabled then
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
