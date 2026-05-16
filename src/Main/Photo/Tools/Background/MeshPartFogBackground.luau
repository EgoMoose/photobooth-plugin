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
	self:_update()

	return self
end

function MeshPartFogBackgroundClass.neon(parent: Instance): MeshPartFogBackground
	local self = MeshPartFogBackgroundClass.new(parent)

	self.fogDistance = math.huge
	self.part.Material = Enum.Material.Neon

	return self
end

-- Private

local function getBoundsIntersection(cameraCF: CFrame)
	-- the logic here used to be much more complex
	-- originally, we'd try and calculate this based on the existing geometry relative to the camera
	-- however, it's much more consistent to pick a fixed distance that renders on all quality levels
	-- technically this means you can't capture things more than 90k studs away, but is that really an issue?
	return cameraCF * Vector3.new(0, 0, -90_000)
end

function MeshPartFogBackgroundClass._createInstances(_self: MeshPartFogBackground)
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

function MeshPartFogBackgroundClass._update(self: MeshPartFogBackground)
	local cameraCF = workspace.CurrentCamera.CFrame
	local intersection = getBoundsIntersection(cameraCF)
	self.part.CFrame = CFrame.new(intersection) * cameraCF.Rotation
	self.fogDistance = -cameraCF:PointToObjectSpace(intersection).Z - MARGIN_OF_ERROR_DISTANCE
end

-- Public

function MeshPartFogBackgroundClass.SetEnabled(self: MeshPartFogBackground, enabled: boolean)
	self.part.Transparency = if enabled then 0 else 1
	if enabled and self.fogDistance > 0 then
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
