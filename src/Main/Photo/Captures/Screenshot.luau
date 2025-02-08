--!strict

local AssetService = game:GetService("AssetService") :: AssetService
local CaptureService = game:GetService("CaptureService") :: CaptureService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Context = require(pluginRoot.Utilities.Context)
local Future = require(pluginRoot.Utilities.Future)
local Image = require(pluginRoot.Utilities.Image)

local Screenshot = {}

local ALLOW_FULLSCREEN = true

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

-- Public

function Screenshot.calculateScaleOS()
	local editImage = captureEditableImage()
	local viewportSize = workspace.CurrentCamera.ViewportSize :: Vector2
	local scale = editImage.Size / viewportSize
	editImage:Destroy()
	return scale
end

function Screenshot.isFullscreenAllowed()
	return ALLOW_FULLSCREEN
end

function Screenshot.isFullscreenRect(rect: Rect)
	local viewportSize = workspace.CurrentCamera.ViewportSize :: Vector2
	return ALLOW_FULLSCREEN and rect.Min == Vector2.zero and rect.Max == viewportSize
end

function Screenshot.rect(rect: Rect)
	if Screenshot.isFullscreenRect(rect) then
		return screenshot()
	else
		assert(
			not (rect.Width > Image.MAX_EDIT_IMAGE_SIZE.X or rect.Height > Image.MAX_EDIT_IMAGE_SIZE.Y),
			`Capture target is larger than {Image.MAX_EDIT_IMAGE_SIZE.X} x {Image.MAX_EDIT_IMAGE_SIZE.Y}.`
		)

		return screenshot(rect)
	end
end

--

return Screenshot
