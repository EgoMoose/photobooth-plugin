local Timeout = require(script.Parent.Timeout)
local Image = require(script.Parent.Image)

local IntegralImageStatic = {}

local IntegralImageClass = {}
IntegralImageClass.__index = IntegralImageClass
IntegralImageClass.ClassName = "IntegralImage"

export type IntegralImage = typeof(setmetatable(
	{} :: {
		buffer: buffer,
		width: number,
		height: number,
	},
	IntegralImageClass
))

function IntegralImageStatic.fromBuffer(imgBuffer: buffer, imgSize: Vector2, processImgRead: (number) -> number)
	local self = setmetatable({}, IntegralImageClass) :: IntegralImage

	local width, height = imgSize.X, imgSize.Y
	local integralBuffer = buffer.create(width * height * 4)

	local function read(x: number, y: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		return buffer.readu32(integralBuffer, i)
	end

	local function write(x: number, y: number, value: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		buffer.writeu32(integralBuffer, i, value)
	end

	local function readImage(x: number, y: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		return processImgRead(buffer.readu32(imgBuffer, i))
	end

	write(1, 1, readImage(1, 1))

	for x = 2, width do
		write(x, 1, readImage(x, 1) + read(x - 1, 1))
		Timeout.tryYield()
	end

	for y = 2, height do
		write(1, y, readImage(1, y) + read(1, y - 1))
		Timeout.tryYield()
	end

	for x = 2, width do
		for y = 2, height do
			write(x, y, readImage(x, y) + read(x, y - 1) + read(x - 1, y) - read(x - 1, y - 1))
			Timeout.tryYield()
		end
	end

	self.buffer = integralBuffer
	self.width = width
	self.height = height

	return self
end

function IntegralImageStatic.fromImage(img: Image.Image, processImgRead: (number) -> number)
	return IntegralImageStatic.fromBuffer(img.buffer, img.size, processImgRead)
end

function IntegralImageClass.read(self: IntegralImage, x: number, y: number)
	local cx = math.min(x, self.width)
	local cy = math.min(y, self.height)
	if cx > 0 and cy > 0 then
		local i = ((cx - 1) + (cy - 1) * self.width) * 4
		return buffer.readu32(self.buffer, i)
	end
	return 0
end

function IntegralImageClass.readRadius(self: IntegralImage, x: number, y: number, radius: number)
	return self:read(x + radius, y + radius)
		- self:read(x - radius - 1, y + radius)
		- self:read(x + radius, y - radius - 1)
		+ self:read(x - radius - 1, y - radius - 1)
end

return IntegralImageStatic
