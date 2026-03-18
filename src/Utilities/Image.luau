--!strict
--!native
--!optimize 2

local AssetService = game:GetService("AssetService")

local ImageStatic = {}

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

local MAX_READ_WRITE_IMAGE_SIZE = Vector2.new(1024, 1024)
local MAX_READ_WRITE_IMAGE_WIDTH = MAX_READ_WRITE_IMAGE_SIZE.X
local MAX_READ_WRITE_IMAGE_HEIGHT = MAX_READ_WRITE_IMAGE_SIZE.Y

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

function ImageStatic.fromBuffer(buffer: buffer, size: Vector2)
	local self = setmetatable({}, ImageClass) :: Image

	self.buffer = buffer
	self.size = size

	return self
end

function ImageStatic.fromSize(size: Vector2)
	return ImageStatic.fromBuffer(buffer.create(size.X * size.Y * 4), size)
end

function ImageStatic.fromEditableImage(editableImage: EditableImage, crop: Rect?)
	local fullSize = editableImage.Size
	local origin = if crop then crop.Min:Min(fullSize) else Vector2.zero
	local cropSize = if crop then (crop.Max - crop.Min):Min(fullSize) else fullSize

	if cropSize.X > MAX_READ_WRITE_IMAGE_WIDTH or cropSize.Y > MAX_READ_WRITE_IMAGE_HEIGHT then
		-- if the input editable image is larger than MAX_READ_WRITE_IMAGE_SIZE then we get an error when trying to read the pixel buffer
		-- as a result we need to read the buffer in chunks and then put it together again into its full size (very cool, thanks Roblox)

		local resultBuffer = buffer.create(cropSize.X * cropSize.Y * 4)

		local dx = math.ceil(cropSize.X / MAX_READ_WRITE_IMAGE_WIDTH)
		local dy = math.ceil(cropSize.Y / MAX_READ_WRITE_IMAGE_HEIGHT)

		for x = 1, dx do
			for y = 1, dy do
				local offset = Vector2.new((x - 1) * MAX_READ_WRITE_IMAGE_WIDTH, (y - 1) * MAX_READ_WRITE_IMAGE_HEIGHT)
				local size = Vector2.new(
					math.min(MAX_READ_WRITE_IMAGE_WIDTH, cropSize.X - offset.X),
					math.min(MAX_READ_WRITE_IMAGE_HEIGHT, cropSize.Y - offset.Y)
				)

				local chunkBuffer = editableImage:ReadPixelsBuffer(origin + offset, size)
				for sourceY = 1, size.Y do
					local sourceOffset = (sourceY - 1) * size.X
					local targetOffset = offset.X + (offset.Y + sourceY - 1) * cropSize.X

					buffer.copy(resultBuffer, targetOffset * 4, chunkBuffer, sourceOffset * 4, size.X * 4)
				end
			end
		end

		return ImageStatic.fromBuffer(resultBuffer, cropSize)
	end

	local resultBuffer = editableImage:ReadPixelsBuffer(origin, cropSize)
	return ImageStatic.fromBuffer(resultBuffer, cropSize)
end

function ImageStatic.fromRGBA255(r: number, g: number, b: number, a: number, size: Vector2)
	local img = ImageStatic.fromBuffer(buffer.create(size.X * size.Y * 4), size)
	for x = 1, size.X do
		for y = 1, size.Y do
			local pixelIndex = img:GetPixelIndex(x, y)
			img:SetRGBA255(pixelIndex, r, g, b, a)
		end
	end
	return img
end

function ImageStatic.fromRGBA(r: number, g: number, b: number, a: number, size: Vector2)
	return ImageStatic.fromRGBA255(r * 255, g * 255, b * 255, a * 255, size)
end

-- Public Methods

function ImageClass.Clone(self: Image)
	local copyBuffer = buffer.create(buffer.len(self.buffer))
	buffer.copy(copyBuffer, 0, self.buffer, 0)
	local copy = ImageStatic.fromBuffer(copyBuffer, self.size)
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

	return ImageStatic.fromBuffer(targetBuffer, Vector2.new(clampedWidth, clampedHeight))
end

function ImageClass.GetSize(self: Image)
	return self.size
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

function ImageClass.IterateNeighbors(self: Image, pixelIndex: number)
	local width = self.size.X
	local height = self.size.Y
	local x, y = self:GetXYFromPixelIndex(pixelIndex)

	local i = 0
	return function()
		while true do
			i = i + 1
			local offset = NEIGHBOR_OFFSETS[i]

			if offset then
				local xn = x + offset[1]
				local yn = y + offset[2]

				if not (xn < 1 or xn > width or yn < 1 or yn > height) then
					return i, self:GetPixelIndex(xn, yn)
				end
			else
				return table.unpack({})
			end
		end
	end
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

	local dx = math.ceil(size.X / MAX_READ_WRITE_IMAGE_WIDTH)
	local dy = math.ceil(size.Y / MAX_READ_WRITE_IMAGE_HEIGHT)

	for x = 1, dx do
		for y = 1, dy do
			local offset = Vector2.new((x - 1) * MAX_READ_WRITE_IMAGE_WIDTH, (y - 1) * MAX_READ_WRITE_IMAGE_HEIGHT)
			local cropSize = Vector2.new(
				math.min(MAX_READ_WRITE_IMAGE_WIDTH, size.X - offset.X),
				math.min(MAX_READ_WRITE_IMAGE_HEIGHT, size.Y - offset.Y)
			)
			local cropImage = self:Crop(Rect.new(offset, offset + cropSize))
			editableImage:WritePixelsBuffer(position + offset, cropSize, cropImage.buffer)
		end
	end
end

function ImageClass.Split(self: Image, n: number, yPadding: number?)
	local width = self.size.X
	local height = self.size.Y

	local yPad = yPadding or 0
	local linesPerWorker = math.max(1, math.floor(height / n))

	local chunks = {}
	for i = 1, n do
		local start = ((i - 1) * linesPerWorker) + 1
		local finish = math.min(height, if i == n then height else (i * linesPerWorker))

		if start <= finish then
			local startPadded = math.max(1, start - yPad)
			local finishPadded = math.min(height, finish + yPad)

			local minIndex = self:GetPixelIndex(1, startPadded)
			local maxIndex = self:GetPixelIndex(width, finishPadded)

			local chunkLen = (maxIndex - minIndex + 1) * 4
			local chunkBuffer = buffer.create(chunkLen)
			local chunkSize = Vector2.new(width, (finishPadded - startPadded) + 1)
			buffer.copy(chunkBuffer, 0, self.buffer, (minIndex - 1) * 4, chunkLen)

			local cropMinY = start - startPadded
			local crop = Rect.new(0, cropMinY, width, cropMinY + finish - start + 1)

			table.insert(chunks, {
				minIndex = minIndex,
				maxIndex = maxIndex,

				buffer = chunkBuffer,
				size = chunkSize,

				crop = crop,
			})
		end
	end

	return chunks
end

function ImageClass.SetTemplateUri(self: Image, uri: string)
	self.templateUri = uri
end

function ImageClass.Save(self: Image)
	if self.templateUri then
		local editImage = AssetService:CreateEditableImageAsync(Content.fromUri(self.templateUri)) :: EditableImage
		self:WriteToEditableImage(editImage, Vector2.zero, self.size)
		return editImage
	end

	local editableImage = AssetService:CreateEditableImage({
		Size = self.size,
	}) :: EditableImage

	self:WriteToEditableImage(editableImage, Vector2.zero, self.size)

	return editableImage
end

function ImageClass.Destroy(_self: Image) end

--

return ImageStatic
