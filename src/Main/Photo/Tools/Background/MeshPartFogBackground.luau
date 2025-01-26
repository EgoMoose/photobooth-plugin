--!strict

local Lighting = game:GetService("Lighting") :: Lighting

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)

local MARGIN_OF_ERROR_DISTANCE = 1000

local MeshPartFogBackgroundClass = {}
MeshPartFogBackgroundClass.__index = MeshPartFogBackgroundClass
MeshPartFogBackgroundClass.ClassName = "MeshPartBackground"

export type MeshPartFogBackground = typeof(setmetatable(
	{} :: {
		part: BasePart,
		mesh: SpecialMesh,
		fogDistance: number,
		fogTrove: Trove.Trove,
	},
	MeshPartFogBackgroundClass
))

-- Constructors

function MeshPartFogBackgroundClass.new(parent: Instance): MeshPartFogBackground
	local self = setmetatable({}, MeshPartFogBackgroundClass) :: MeshPartFogBackground

	self.part, self.mesh = self:_createInstances()
	self.part.Parent = parent

	self.fogDistance = -1
	self.fogTrove = Trove.new()

	self:SetEnabled(false)
	self:Update()

	return self
end

-- Private

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

	local radius = (maxCorner - cameraPos).Magnitude
	return cameraPos + lookVector * (radius + MARGIN_OF_ERROR_DISTANCE * 2)
end

function MeshPartFogBackgroundClass._createInstances(self: MeshPartFogBackground)
	local part = Instance.new("Part")
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = CFrame.identity
	part.Size = Vector3.new(1, 1, 1)
	part.Color = Color3.new(1, 1, 1)
	part.Transparency = 0
	part.CastShadow = false
	part.CanCollide = false
	part.Anchored = true
	part.CanTouch = false
	part.CanQuery = false
	part.Locked = true

	local mesh = Instance.new("SpecialMesh")
	mesh.Scale = Vector3.new(1_000_000_000, 1_000_000_000) -- we could calc, but why bother
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Parent = part

	return part, mesh
end

-- Public

function MeshPartFogBackgroundClass.Update(self: MeshPartFogBackground)
	local cameraCF = workspace.CurrentCamera.CFrame
	local intersection = getBoundsIntersection(cameraCF)
	self.part.CFrame = CFrame.new(intersection) * cameraCF.Rotation
	self.fogDistance = -cameraCF:PointToObjectSpace(intersection).Z - MARGIN_OF_ERROR_DISTANCE
end

function MeshPartFogBackgroundClass.SetEnabled(self: MeshPartFogBackground, enabled: boolean)
	self.part.Transparency = if enabled then 0 else 1
	if enabled then
		local color = Lighting.FogColor
		local fogStart = Lighting.FogStart
		local fogEnd = Lighting.FogEnd
		self.fogTrove:Add(function()
			Lighting.FogColor = color
			Lighting.FogStart = fogStart
			Lighting.FogEnd = fogEnd
		end)

		Lighting.FogColor = self.part.Color
		Lighting.FogStart = self.fogDistance
		Lighting.FogEnd = self.fogDistance
	else
		self.fogTrove:Clean()
	end
end

function MeshPartFogBackgroundClass.SetColor(self: MeshPartFogBackground, color: Color3)
	self.part.Color = color
	if self.part.Transparency == 0 then
		Lighting.FogColor = color
	end
end

function MeshPartFogBackgroundClass.Destroy(self: MeshPartFogBackground)
	self:SetEnabled(false)
	self.fogTrove:Destroy()
	self.part:Destroy()
end

--

return MeshPartFogBackgroundClass
