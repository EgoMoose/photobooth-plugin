--!nocheck

--[[
	Instructions:
		1. Copy this template to the StarterGui.
		2. Place all the UI elements you'd like to capture in the CaptureFolder.
		3. Run `require(game.ServerStorage.PhotoboothBindings).execute(game.StarterGui.DropShadowUI.Action)` in the command bar.
		4. After completion your drop-shadows will be in a timestamped ScreenGui under the ServerStorage.
	
	BLUR_RADIUS
		> How much blurring will occur on the drop shadow. The blurring method used is box blur.
	
	BLUR_OFFSET
		> How much the drop shadow will be offset from the capture target. This can easily be changed after capture,
		> it's just here for convenience.
	
	BLUR_TRANSPARENCY
		> How transparent the drop shadow will be. This can easily be changed after capture, it's just here for convenience.
--]]

local BLUR_RADIUS = 5
local BLUR_OFFSET = Vector2.new(2, 2)
local BLUR_TRANSPARENCY = 0.7

local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")
local Photobooth = require(ServerStorage.PhotoboothBindings)

local screen = script.Parent
local folder = screen.CaptureFolder

-- Helpers

-- the box blur implementation in this code is based of the explanation in this video
-- https://www.youtube.com/watch?v=4Eh0y3LHTNU

local function summedBuffer(imgBuffer: buffer, width: number, height: number)
	-- we store the sums in a buffer filled with u32s
	-- this is okay b/c at worst the highest possible sum is 1024 * 1024 * 255
	local sumBuffer = buffer.create(width * height * 4 * 4)

	local function readImg(x: number, y: number, channel: number)
		local i = ((x - 1) + (y - 1) * width) * 4
		return buffer.readu8(imgBuffer, i + channel)
	end

	local function readSum(x: number, y: number, channel: number)
		local i = ((x - 1) + (y - 1) * width) * 4 * 4
		return buffer.readu32(sumBuffer, i + channel * 4)
	end

	local function writeSum(x: number, y: number, channel: number, value: number)
		local i = ((x - 1) + (y - 1) * width) * 4 * 4
		buffer.writeu32(sumBuffer, i + channel * 4, value)
	end

	for i = 0, 3 do
		writeSum(1, 1, i, readImg(1, 1, i))
	end

	for x = 2, width do
		for i = 0, 3 do
			writeSum(x, 1, i, readImg(x, 1, i) + readSum(x - 1, 1, i))
		end
	end

	for y = 2, height do
		for i = 0, 3 do
			writeSum(1, y, i, readImg(1, y, i) + readSum(1, y - 1, i))
		end
	end

	for x = 2, width do
		for y = 2, height do
			for i = 0, 3 do
				local sum = readImg(x, y, i) + readSum(x, y - 1, i) + readSum(x - 1, y, i) - readSum(x - 1, y - 1, i)

				writeSum(x, y, i, sum)
			end
		end
	end

	return sumBuffer
end

local function boxBlurBuffer(imgBuffer: buffer, width: number, height: number, radius: number)
	local nWidth = width + radius * 2
	local nHeight = height + radius * 2
	local newBuffer = buffer.create(nWidth * nHeight * 4)

	local sumBuffer = summedBuffer(imgBuffer, width, height)
	local function readSum(x: number, y: number, channel: number)
		local cx = math.min(x, width)
		local cy = math.min(y, height)

		if cx > 0 and cy > 0 then
			local i = ((cx - 1) + (cy - 1) * width) * 4 * 4
			return buffer.readu32(sumBuffer, i + channel * 4)
		end

		return 0
	end

	local area = math.pow(2 * radius + 1, 2)
	for nx = 1, nWidth do
		for ny = 1, nHeight do
			local i = ((nx - 1) + (ny - 1) * nWidth) * 4

			local x = nx - radius
			local y = ny - radius

			for channel = 0, 3 do
				local sum = readSum(x + radius, y + radius, channel)
					- readSum(x - radius - 1, y + radius, channel)
					- readSum(x + radius, y - radius - 1, channel)
					+ readSum(x - radius - 1, y - radius - 1, channel)

				buffer.writeu8(newBuffer, i + channel, sum / area)
			end
		end
	end

	return newBuffer
end

local function boxBlur(editImage: EditableImage, radius: number)
	local imgSize = editImage.Size
	local imgBuffer = editImage:ReadPixelsBuffer(Vector2.zero, imgSize)

	local blurredSize = imgSize + Vector2.new(radius * 2, radius * 2)
	local blurredBuffer = boxBlurBuffer(imgBuffer, imgSize.X, imgSize.Y, radius)
	local blurredImage = AssetService:CreateEditableImage({ Size = blurredSize })
	blurredImage:WritePixelsBuffer(Vector2.zero, blurredSize, blurredBuffer)

	return blurredImage
end

-- Capture

local function capture()
	local outputScreen = Instance.new("ScreenGui")
	for _, child in folder:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			local result = Photobooth.captureUI(child, "AlphaMask")
			local editImage = result.TextureContent.Object :: EditableImage
			local blurredImage = boxBlur(editImage, BLUR_RADIUS)
			editImage:Destroy()
			result:Destroy()

			local frame = Instance.new("Frame")
			frame.Name = child.Name
			frame.Size = child.Size
			frame.Position = child.Position
			frame.AnchorPoint = child.AnchorPoint
			frame.BackgroundTransparency = 1
			frame.ZIndex = child.ZIndex

			local shadow = Instance.new("ImageLabel")
			shadow.Name = "DropShadow"
			shadow.Size = UDim2.new(1, BLUR_RADIUS * 2, 1, BLUR_RADIUS * 2)
			shadow.Position = UDim2.new(0.5, BLUR_OFFSET.X, 0.5, BLUR_OFFSET.Y)
			shadow.AnchorPoint = Vector2.new(0.5, 0.5)
			shadow.ImageContent = Content.fromObject(blurredImage)
			shadow.ImageColor3 = Color3.new(0, 0, 0)
			shadow.ImageTransparency = BLUR_TRANSPARENCY
			shadow.BackgroundTransparency = 1
			shadow.ZIndex = child.ZIndex - 1
			shadow.Parent = frame

			local childCopy = child:Clone()
			childCopy.Name = "Body"
			childCopy.Size = UDim2.fromScale(1, 1)
			childCopy.Position = UDim2.fromScale(0, 0)
			childCopy.AnchorPoint = Vector2.new(0, 0)
			childCopy.Parent = frame

			frame.Parent = outputScreen
		end
	end
	return outputScreen
end

local _success, err = Photobooth.cancellable(script, function()
	local results = capture()
	results.Name = DateTime.now():ToIsoDate()
	results.Archivable = false
	results.Parent = ServerStorage
end)

if err then
	error("Photobooth: " .. err)
end
