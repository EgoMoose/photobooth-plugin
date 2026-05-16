--!strict

local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local ReactRoblox = require(pluginRoot.Packages.ReactRoblox)
local React = require(pluginRoot.Packages.React)

local uiRoot = script:FindFirstAncestor("UserInterface")
local Hooks = require(uiRoot.Hooks)

local function rgb255(color: Color3)
	local hex = color:ToHex()
	local r255 = tonumber(hex:sub(1, 2), 16) :: number
	local g255 = tonumber(hex:sub(3, 4), 16) :: number
	local b255 = tonumber(hex:sub(5, 6), 16) :: number
	return r255, g255, b255
end

local function rgbFloat(color: Color3)
	return color.R, color.G, color.B
end

local function srgbToLinear(c: number): number
	if c <= 0.04045 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

local function linearToSrgb(c: number): number
	if c <= 0.0031308 then
		return 12.92 * c
	end
	return 1.055 * c ^ (1 / 2.4) - 0.055
end

local function applyColorCorrection(buff: buffer, colorCorrection: ColorCorrectionEffect)
	local len = buffer.len(buff)
	local nBuffer = buffer.create(len)
	buffer.copy(nBuffer, 0, buff)
	local nPixels = len / 4

	local brightness = colorCorrection.Brightness
	local contrast = colorCorrection.Contrast + 1
	local saturation = colorCorrection.Saturation + 1
	local tint = { rgbFloat(colorCorrection.TintColor) }

	local channels = { 0, 0, 0 }

	for i = 1, nPixels do
		local j = (i - 1) * 4

		for k = 1, 3 do
			channels[k] = buffer.readu8(buff, j + (k - 1)) / 255
		end

		local gray = 0.345 * channels[1] + 0.553 * channels[2] + 0.114 * channels[3]

		for k = 1, 3 do
			local c = channels[k]

			c = c * saturation + (1 - saturation) * gray -- saturation
			-- c = (c - 0.5) * math.max(0, contrast) + 0.5 -- contrast
			-- c = c + brightness -- brightness
			-- c = c * tint[k] -- tint

			buffer.writeu8(nBuffer, j + (k - 1), math.clamp(c * 255, 0, 255))
		end
	end
	return nBuffer
end

local function useColorCorrected(editImage: EditableImage?)
	local newEditImage, setNewEditImage = React.useState(editImage)

	React.useEffect(function()
		if editImage then
			local img = AssetService:CreateEditableImage({ Size = editImage.Size })
			local imgBuffer = editImage:ReadPixelsBuffer(Vector2.zero, editImage.Size)

			local backup = Instance.new("ColorCorrectionEffect")
			local colorCorrection = game.Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect") or backup

			local function refresh()
				local b = applyColorCorrection(imgBuffer, colorCorrection)
				img:WritePixelsBuffer(Vector2.zero, editImage.Size, b)
			end

			refresh()
			local connection = colorCorrection.Changed:Connect(function()
				refresh()
			end)

			setNewEditImage(img)

			return function()
				connection:Disconnect()
				backup:Destroy()
				img:Destroy()
			end
		end

		setNewEditImage(nil :: any)
		return function() end
	end, { editImage })

	return newEditImage
end

return {
	react = React,
	reactRoblox = ReactRoblox,
	story = function()
		local selection = { game.StarterGui:FindFirstChildWhichIsA("MeshPart") }
		local editImageInfos = Hooks.useEditableImageInfos(selection)

		local editImage = editImageInfos[1] and editImageInfos[1].EditableImage
		local colorCorrected = useColorCorrected(editImage)

		return colorCorrected
			and React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(colorCorrected.Size.X, colorCorrected.Size.Y),
				ImageContent = Content.fromObject(colorCorrected),
			})
	end,
}
