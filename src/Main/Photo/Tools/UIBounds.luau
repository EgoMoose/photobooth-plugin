--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local RectHelper = require(pluginRoot.Utilities.RectHelper)

local ALWAYS_CLIPPED = true
local ALWAYS_CLIP_TEXT = true

-- Class

local UIBoundsClass = {}
UIBoundsClass.__index = UIBoundsClass
UIBoundsClass.ClassName = "UIBounds"

export type UIBounds = typeof(setmetatable(
	{} :: {
		scale: Vector2,
		surfaceGui: SurfaceGui,
		surfacePart: BasePart,
		aabbFrame: Frame,
		canvas: CanvasGroup,
	},
	UIBoundsClass
))

-- Constructors

function UIBoundsClass.new(parent: Instance, subject: GuiObject, scale: Vector2): UIBounds
	local self = setmetatable({}, UIBoundsClass) :: UIBounds

	self.scale = scale
	self.surfaceGui, self.surfacePart = self:_createSurface(parent)
	self.aabbFrame, self.canvas = self:_createAABBCanvas(subject)
	self.aabbFrame.Parent = self.surfaceGui

	return self
end

-- Private

function UIBoundsClass._createSurface(self: UIBounds, parent: Instance)
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local aspect = viewportSize.X / viewportSize.Y
	local distance = 0.5 / math.tan(math.rad(camera.FieldOfView / 2))

	local surfacePart = Instance.new("Part")
	surfacePart.Anchored = true
	surfacePart.CFrame = camera.CFrame * CFrame.new(0, 0, -(distance + 0.5))
	surfacePart.Size = Vector3.new(aspect, 1, 1)
	surfacePart.Parent = parent

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.AlwaysOnTop = true
	surfaceGui.Face = Enum.NormalId.Back
	surfaceGui.Name = "UIBounds"
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.CanvasSize = viewportSize * self.scale
	surfaceGui.Adornee = surfacePart

	surfaceGui.Parent = surfacePart
	surfacePart.Parent = parent

	return surfaceGui, surfacePart
end

local function isClipped(frame: GuiObject, root: GuiObject): boolean
	local parent: Instance = frame
	while parent ~= root do
		parent = parent.Parent :: Instance

		if parent:IsA("GuiObject") and (ALWAYS_CLIPPED or parent.ClipsDescendants) then
			-- if the ancestor is a canvas group it's for sure clipped
			-- if not, then the ancestor must have not have any rotation for clipping to work
			if parent:IsA("CanvasGroup") or parent.AbsoluteRotation == 0 then
				return true
			end
		end
	end

	return false
end

local function getQualified(root: GuiObject): { GuiObject }
	local qualified = {}
	local stack: { Instance } = { root }

	while #stack > 0 do
		local popped = table.remove(stack) :: Instance

		if popped:IsA("GuiObject") then
			if popped.Visible and not isClipped(popped, root) then
				table.insert(qualified, popped)
			else
				continue
			end
		elseif popped:IsA("ScreenGui") then
			if not popped.Enabled then
				continue
			end
		elseif not popped:IsA("Folder") then
			continue
		end

		for _, child in popped:GetChildren() do
			table.insert(stack, child)
		end
	end

	return qualified
end

local function isTextFrame(frame: GuiObject): boolean
	return frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("TextBox")
end

local function getCorners(frame: GuiObject): { Vector2 }
	local absSize = frame.AbsoluteSize
	local absPosition = frame.AbsolutePosition
	local absRotation = frame.AbsoluteRotation

	local center = absPosition + absSize / 2
	local rotator = CFrame.fromEulerAnglesXYZ(0, 0, math.rad(absRotation))

	local corners = {}
	for w = 0, 1 do
		for h = 0, 1 do
			local delta = (absPosition + absSize * Vector2.new(w, h)) - center
			local rDelta = rotator * Vector3.new(delta.X, delta.Y, 0)
			local newCorner = center + Vector2.new(rDelta.X, rDelta.Y)
			table.insert(corners, newCorner)
		end
	end

	return corners
end

local function getTextBoundsCorners(textFrame: TextLabel | TextButton | TextBox)
	local anchorX = 1
	if textFrame.TextXAlignment == Enum.TextXAlignment.Left then
		anchorX = 0
	elseif textFrame.TextXAlignment == Enum.TextXAlignment.Center then
		anchorX = 0.5
	end

	local anchorY = 1
	if textFrame.TextYAlignment == Enum.TextYAlignment.Top then
		anchorY = 0
	elseif textFrame.TextYAlignment == Enum.TextYAlignment.Center then
		anchorY = 0.5
	end

	local absSize = textFrame.AbsoluteSize
	local absPosition = textFrame.AbsolutePosition
	local absRotation = textFrame.AbsoluteRotation

	local center = absPosition + absSize / 2
	local rotator = CFrame.fromEulerAnglesXYZ(0, 0, math.rad(absRotation))

	local textBounds = textFrame.TextBounds
	local anchor = Vector2.new(anchorX, anchorY)
	local tlc = (absSize - textBounds) * anchor

	local corners = {}
	for w = 0, 1 do
		for h = 0, 1 do
			local delta = (absPosition + tlc + textBounds * Vector2.new(w, h)) - center
			local rDelta = rotator * Vector3.new(delta.X, delta.Y, 0)
			local newCorner = center + Vector2.new(rDelta.X, rDelta.Y)
			table.insert(corners, newCorner)
		end
	end

	return corners
end

local function getBoundingRect(qualified: { GuiObject }): Rect
	local corners = {}
	for _, frame in qualified do
		for _, corner in getCorners(frame) do
			table.insert(corners, corner)
		end

		if not ALWAYS_CLIP_TEXT and not frame.ClipsDescendants and isTextFrame(frame) then
			for _, corner in getTextBoundsCorners(frame :: TextLabel) do
				table.insert(corners, corner)
			end
		end
	end

	local max = corners[1]
	local min = corners[1]
	for i = 2, #corners do
		max = max:Max(corners[i])
		min = min:Min(corners[i])
	end

	return RectHelper.fromAbs(min, max - min)
end

local function getMinZIndex(qualified: { GuiObject }): number
	local minZIndex = math.huge
	for _, frame in qualified do
		minZIndex = math.max(minZIndex, frame.ZIndex)
	end
	return minZIndex
end

function UIBoundsClass._createAABBCanvas(_self: UIBounds, subject: GuiObject)
	local qualified = getQualified(subject)
	local aabbRect = getBoundingRect(qualified)

	local boundingFrame = Instance.new("Frame")
	boundingFrame.ZIndex = getMinZIndex(qualified) - 1
	boundingFrame.Size = UDim2.fromOffset(aabbRect.Width, aabbRect.Height)
	boundingFrame.BorderSizePixel = 0

	local canvas = Instance.new("CanvasGroup")
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.Parent = boundingFrame

	local subjectAbsSize = subject.AbsoluteSize
	local subjectAbsPosition = subject.AbsolutePosition

	-- stylua: ignore
	local subjectAABBOffset = UDim2.fromOffset(
		subjectAbsPosition.X - aabbRect.Min.X, 
		subjectAbsPosition.Y - aabbRect.Min.Y
	)

	local subjectCopy = subject:Clone()
	subjectCopy.AnchorPoint = Vector2.zero
	subjectCopy.Size = UDim2.fromOffset(subjectAbsSize.X, subjectAbsSize.Y)
	subjectCopy.Rotation = subject.AbsoluteRotation
	subjectCopy.Position = subjectAABBOffset
	subjectCopy.Parent = canvas

	return boundingFrame, canvas
end

-- Public

function UIBoundsClass.GetRect(self: UIBounds)
	return RectHelper.fromAbs(self.aabbFrame.AbsolutePosition, self.aabbFrame.AbsoluteSize)
end

function UIBoundsClass.SetColor(self: UIBounds, color: Color3)
	self.aabbFrame.BackgroundColor3 = color
end

function UIBoundsClass.SetImageColor(self: UIBounds, color: Color3)
	self.canvas.GroupColor3 = color
end

function UIBoundsClass.Destroy(self: UIBounds)
	self.surfacePart:Destroy()
end

--

return UIBoundsClass
