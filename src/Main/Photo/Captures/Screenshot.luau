--!strict

local AssetService = game:GetService("AssetService") :: AssetService
local CaptureService = game:GetService("CaptureService") :: CaptureService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Context = require(pluginRoot.Utilities.Context)
local Future = require(pluginRoot.Utilities.Future)
local Image = require(pluginRoot.Utilities.Image)

local Screenshot = {}

local bilinearScaleContext = Context.new(nil :: Vector2?)

-- Private

local function captureEditableImage()
	local contentUriFuture = Future.raw() :: Future.Future<string>
	CaptureService:CaptureScreenshot(function(contentUri: string)
		-- this is a significant bottleneck for speed
		-- it can take roughly 0.3 seconds to complete
		contentUriFuture:complete(contentUri)
	end)

	local contentUri = contentUriFuture:expect()
	local editImage = AssetService:CreateEditableImageAsync(Content.fromUri(contentUri)) :: EditableImage

	return editImage, contentUri
end

local function screenshot(rect: Rect?)
	local editImage, contentUri = captureEditableImage()

	local bilinearScale = bilinearScaleContext:Use()
	if bilinearScale then
		editImage:DrawImageTransformed(Vector2.zero, bilinearScale, 0, editImage, {
			CombineType = Enum.ImageCombineType.Overwrite,
			SamplingMode = Enum.ResamplerMode.Default, -- Bilinear Interpolation
			PivotPoint = Vector2.zero,
		})
	end

	local img = Image.fromEditableImage(editImage, rect)

	if rect then
		editImage:Destroy()
	else
		img:SetTemplateUri(contentUri)
	end

	return img
end

local function validate(rect: Rect)
	-- first check if our target rect is greater than 1024x1024
	if rect.Width > 1024 or rect.Height > 1024 then
		return false
	end

	--[[
	-- DISABLED
	-- this is turned off due to OS scaling also needed to get the correct viewport size
	-- ultimately it is not needed b/c Image.fromEditableImage will clamp the rect 

	-- next check that our target rect is entirely contained in the viewport
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local function isInViewport(position: Vector2)
		return position.X >= 0 and position.X <= viewportSize.X and position.Y >= 0 and position.Y <= viewportSize.Y
	end

	return isInViewport(rect.Min) and isInViewport(rect.Max)
	--]]
	return true
end

-- Public

function Screenshot.calculateScaleOS()
	local editImage = captureEditableImage()
	local viewportSize = workspace.CurrentCamera.ViewportSize :: Vector2
	local scale = editImage.Size / viewportSize
	editImage:Destroy()
	return scale
end

function Screenshot.isViewportRect(rect: Rect)
	local viewportSize = workspace.CurrentCamera.ViewportSize :: Vector2
	return rect.Min == Vector2.zero and rect.Max == viewportSize
end

function Screenshot.rect(rect: Rect)
	if Screenshot.isViewportRect(rect) then
		return screenshot()
	else
		assert(
			validate(rect),
			"Capture target is being clipped by the viewport or is larger than 1024 in width / height."
		)

		return screenshot(rect)
	end
end

--

return Screenshot
