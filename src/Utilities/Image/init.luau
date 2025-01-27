--!strict

local AssetService = game:GetService("AssetService")

local ImageClass = {}
ImageClass.__index = ImageClass
ImageClass.ClassName = "Image"

export type Image = typeof(setmetatable(
	{} :: {
		buffer: buffer,
		size: Vector2,
		templateUri: string?,
	},
	ImageClass
))

-- CONSTANTS

local NEIGHBOR_OFFSETS: { { number } } = {
	{ -1, -1 },
	{ 0, -1 },
	{ 1, -1 },
	{ -1, 0 },
	{ 1, 0 },
	{ -1, 1 },
	{ 0, 1 },
	{ 1, 1 },
}

-- Constructors

function ImageClass.fromBuffer(buffer: buffer, size: Vector2)
	local self = setmetatable({} :: any, ImageClass) :: Image

	self.buffer = buffer
	self.size = size

	return self
end

function ImageClass.fromSize(size: Vector2)
	return ImageClass.fromBuffer(buffer.create(size.X * size.Y * 4), size)
end

function ImageClass.fromEditableImage(editableImage: EditableImage, crop: Rect?)
	local fullSize = editableImage.Size
	local origin = if crop then crop.Min:Min(fullSize) else Vector2.zero
	local cropSize = if crop then (crop.Max - crop.Min):Min(fullSize) else fullSize

	if cropSize.X > 1024 or cropSize.Y > 1024 then
		-- if the input editable image is larger than 1024 x 1024 then we get an error when trying to read the pixel buffer
		-- as a result we need to read the buffer in chunks and then put it together again into its full size (very cool, thanks Roblox)

		local resultBuffer = buffer.create(cropSize.X * cropSize.Y * 4)

		local dx = math.ceil(cropSize.X / 1024)
		local dy = math.ceil(cropSize.Y / 1024)

		for x = 1, dx do
			for y = 1, dy do
				local offset = Vector2.new((x - 1) * 1024, (y - 1) * 1024)
				local size = Vector2.new(math.min(1024, cropSize.X - offset.X), math.min(1024, cropSize.Y - offset.Y))

				local chunkBuffer = editableImage:ReadPixelsBuffer(origin + offset, size)
				for sourceY = 1, size.Y do
					local sourceOffset = (sourceY - 1) * size.X
					local targetOffset = offset.X + (offset.Y + sourceY - 1) * cropSize.X

					buffer.copy(resultBuffer, targetOffset * 4, chunkBuffer, sourceOffset * 4, size.X * 4)
				end
			end
		end

		return ImageClass.fromBuffer(resultBuffer, cropSize)
	end

	local resultBuffer = editableImage:ReadPixelsBuffer(origin, cropSize)
	return ImageClass.fromBuffer(resultBuffer, cropSize)
end

function ImageClass.fromRGBA255(r: number, g: number, b: number, a: number, size: Vector2)
	local img = ImageClass.fromBuffer(buffer.create(size.X * size.Y * 4), size)
	for x = 1, size.X do
		for y = 1, size.Y do
			local pixelIndex = img:GetPixelIndex(x, y)
			img:SetRGBA255(pixelIndex, r, g, b, a)
		end
	end
	return img
end

function ImageClass.fromRGBA(r: number, g: number, b: number, a: number, size: Vector2)
	return ImageClass.fromRGBA255(r * 255, g * 255, b * 255, a * 255, size)
end

-- Public Methods

function ImageClass.Clone(self: Image)
	local copyBuffer = buffer.create(buffer.len(self.buffer))
	buffer.copy(copyBuffer, 0, self.buffer, 0)
	local copy = ImageClass.fromBuffer(copyBuffer, self.size)
	copy.templateUri = self.templateUri
	return copy
end

function ImageClass.Crop(self: Image, rect: Rect)
	local size = rect.Max - rect.Min

	local clampedWidth = math.min(rect.Min.X + size.X, self.size.X) - rect.Min.X
	local clampedHeight = math.min(rect.Min.Y + size.Y, self.size.Y) - rect.Min.Y
	local targetBuffer = buffer.create(clampedWidth * clampedHeight * 4)

	for y = 1, clampedHeight do
		local sourceOffset = rect.Min.X + (rect.Min.Y + y - 1) * self.size.X
		local targetOffset = (y - 1) * clampedWidth
		buffer.copy(targetBuffer, targetOffset * 4, self.buffer, sourceOffset * 4, clampedWidth * 4)
	end

	return ImageClass.fromBuffer(targetBuffer, Vector2.new(clampedWidth, clampedHeight))
end

function ImageClass.GetWidth(self: Image)
	return self.size.X
end

function ImageClass.GetHeight(self: Image)
	return self.size.Y
end

function ImageClass.GetNumberOfPixels(self: Image)
	return self.size.X * self.size.Y
end

function ImageClass.GetPixelIndex(self: Image, x: number, y: number)
	return (y - 1) * self.size.X + x
end

function ImageClass.GetXYFromPixelIndex(self: Image, pixelIndex: number)
	local y = math.floor((pixelIndex - 1) / self.size.X) + 1
	local x = pixelIndex - ((y - 1) * self.size.X)
	return x, y
end

function ImageClass.GetNeighbors(self: Image, pixelIndex: number)
	local width = self.size.X
	local height = self.size.Y

	local x, y = self:GetXYFromPixelIndex(pixelIndex)

	local neighbors = {}
	for _, offset in NEIGHBOR_OFFSETS do
		local xn = x + offset[1]
		local yn = y + offset[2]

		if xn < 1 or xn > width or yn < 1 or yn > height then
			continue
		end

		table.insert(neighbors, self:GetPixelIndex(xn, yn))
	end

	return neighbors
end

function ImageClass.GetRGBA255(self: Image, pixelIndex: number): (number, number, number, number)
	local i = ((pixelIndex - 1) * 4)
	return buffer.readu8(self.buffer, i + 0),
		buffer.readu8(self.buffer, i + 1),
		buffer.readu8(self.buffer, i + 2),
		buffer.readu8(self.buffer, i + 3)
end

function ImageClass.SetRGBA255(self: Image, pixelIndex: number, r: number, g: number, b: number, a: number)
	local i = ((pixelIndex - 1) * 4)
	buffer.writeu8(self.buffer, i + 0, r)
	buffer.writeu8(self.buffer, i + 1, g)
	buffer.writeu8(self.buffer, i + 2, b)
	buffer.writeu8(self.buffer, i + 3, a)
end

function ImageClass.GetRGBA(self: Image, pixelIndex: number)
	local r, g, b, a = self:GetRGBA255(pixelIndex)
	return r / 255, g / 255, b / 255, a / 255
end

function ImageClass.SetRGBA(self: Image, pixelIndex: number, r: number, g: number, b: number, a: number)
	self:SetRGBA255(pixelIndex, r * 255, g * 255, b * 255, a * 255)
end

function ImageClass.WriteToEditableImage(self: Image, editableImage: EditableImage, position: Vector2, size: Vector2)
	size = (position + size):Max(editableImage.Size) - position

	local dx = math.ceil(size.X / 1024)
	local dy = math.ceil(size.Y / 1024)

	for x = 1, dx do
		for y = 1, dy do
			local offset = Vector2.new((x - 1) * 1024, (y - 1) * 1024)
			local cropSize = Vector2.new(math.min(1024, size.X - offset.X), math.min(1024, size.Y - offset.Y))
			local cropImage = self:Crop(Rect.new(offset, offset + cropSize))
			editableImage:WritePixelsBuffer(position + offset, cropSize, cropImage.buffer)
		end
	end
end

function ImageClass.Split(self: Image, n: number)
	local width = self.size.X
	local height = self.size.Y
	local linesPerWorker = math.ceil(height / n)

	local chunks = {}
	for i = 1, n do
		local start = ((i - 1) * linesPerWorker) + 1
		local finish = math.min(height, (i * linesPerWorker))

		if start <= finish then
			local fromPixelIndex = self:GetPixelIndex(1, start)
			local toPixelIndex = self:GetPixelIndex(width, finish)

			local chunkLen = (toPixelIndex - fromPixelIndex + 1) * 4
			local chunkBuffer = buffer.create(chunkLen)
			buffer.copy(chunkBuffer, 0, self.buffer, (fromPixelIndex - 1) * 4, chunkLen)

			table.insert(chunks, ImageClass.fromBuffer(chunkBuffer, Vector2.new(width, (finish - start) + 1)))
		end
	end

	return chunks
end

function ImageClass.SetTemplateUri(self: Image, uri: string)
	self.templateUri = uri
end

function ImageClass.Save(self: Image)
	if self.templateUri then
		local editImage = AssetService:CreateEditableImageAsync(Content.fromUri(self.templateUri))
		self:WriteToEditableImage(editImage, Vector2.zero, self.size)
		return editImage
	end

	local editableImage = AssetService:CreateEditableImage({
		Size = self.size,
	})

	editableImage:WritePixelsBuffer(Vector2.zero, self.size, self.buffer)

	return editableImage :: EditableImage
end

function ImageClass.Destroy(_self: Image) end

--

return ImageClass
