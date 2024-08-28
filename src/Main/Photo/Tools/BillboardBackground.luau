--!strict

local BillboardBackgroundClass = {}
BillboardBackgroundClass.__index = BillboardBackgroundClass
BillboardBackgroundClass.ClassName = "BillboardBackground"

export type BillboardBackground = typeof(setmetatable(
	{} :: {
		part: BasePart,
		billboard: BillboardGui,
		frame: Frame,
	},
	BillboardBackgroundClass
))

-- Constructors

function BillboardBackgroundClass.new(parent: Instance): BillboardBackground
	local self = setmetatable({}, BillboardBackgroundClass) :: BillboardBackground

	self.part, self.billboard, self.frame = self:_createInstances()
	self.part.Parent = parent

	self:SetEnabled(false)
	self:Update()

	return self
end

-- Private

local function rayPlaneIntersection(ro: Vector3, rd: Vector3, po: Vector3, pn: Vector3)
	return -(ro - po):Dot(pn) / rd:Dot(pn)
end

local function getCorners(cframe: CFrame, size2: Vector3)
	local corners = {}
	for i = 0, 7 do
		-- stylua: ignore
		corners[i + 1] = cframe * (size2 * Vector3.new(
			2 * (math.floor(i / 4) % 2) - 1,
			2 * (math.floor(i / 2) % 2) - 1,
			2 * (i % 2) - 1
		))
	end
	return corners
end

local function getBoundsIntersection(cameraCF: CFrame)
	local sceneCF: CFrame, sceneSize: Vector3 = workspace:GetBoundingBox()

	local terrainRegion16 = workspace.Terrain.MaxExtents
	local terrainRegion = Region3.new(
		Vector3.new(terrainRegion16.Min.X, terrainRegion16.Min.Y, terrainRegion16.Min.Z),
		Vector3.new(terrainRegion16.Max.X, terrainRegion16.Max.Y, terrainRegion16.Max.Z)
	)

	-- stylua: ignore
	local iterable = { 
		{ CFrame = sceneCF, Size = sceneSize },
		{ CFrame = terrainRegion.CFrame, Size = terrainRegion.Size } 
	}

	local maxCorner: Vector3
	local cameraPos = cameraCF.Position
	local lookVector = -cameraCF.ZVector

	local maxDist = -math.huge
	for _, target in iterable do
		for _, corner in getCorners(target.CFrame, target.Size / 2) do
			local dist = (corner - cameraPos):Dot(lookVector)
			if dist > maxDist then
				maxCorner = corner
				maxDist = dist
			end
		end
	end

	local t = rayPlaneIntersection(cameraPos, lookVector, maxCorner, -lookVector)
	return cameraCF.Position + lookVector * math.max(0, t + 1)
end

function BillboardBackgroundClass._createInstances(self: BillboardBackground)
	local part = Instance.new("Part")
	part.CFrame = CFrame.identity
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.CanTouch = false
	part.CanQuery = false

	local billboard = Instance.new("BillboardGui")
	billboard.Enabled = false
	billboard.Size = UDim2.fromOffset(100_000, 100_000) -- assuming nobody has a monitor bigger than this...
	billboard.LightInfluence = 0
	billboard.Adornee = part
	billboard.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	return part, billboard, frame
end

-- Public

function BillboardBackgroundClass.Update(self: BillboardBackground)
	self.part.CFrame = CFrame.new(getBoundsIntersection(workspace.CurrentCamera.CFrame))
end

function BillboardBackgroundClass.SetEnabled(self: BillboardBackground, enabled: boolean)
	self.billboard.Enabled = enabled
end

function BillboardBackgroundClass.SetColor(self: BillboardBackground, color: Color3)
	self.frame.BackgroundColor3 = color
end

function BillboardBackgroundClass.Destroy(self: BillboardBackground)
	self.part:Destroy()
end

--

return BillboardBackgroundClass
