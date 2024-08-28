--!strict

local Lighting = game:GetService("Lighting")

local SkyboxClass = {}
SkyboxClass.__index = SkyboxClass
SkyboxClass.ClassName = "Skybox"

SkyboxClass.Textures = {
	White = "rbxassetid://134137086491604",
	Black = "rbxassetid://116015770286707",
	Red = "rbxassetid://74376310462275",
	Green = "rbxassetid://104817323592681",
	Blue = "rbxassetid://110533416384567",
}

export type Skybox = typeof(setmetatable(
	{} :: {
		cameraCF: CFrame,
		offsetCF: CFrame,

		sky: Sky,
	},
	SkyboxClass
))

function SkyboxClass.new()
	local self = setmetatable({}, SkyboxClass) :: Skybox

	self.sky = Instance.new("Sky")
	self.sky.CelestialBodiesShown = false

	return self
end

function SkyboxClass.SetEnabled(self: Skybox, enabled: boolean)
	self.sky.Parent = if enabled then Lighting else nil
end

function SkyboxClass.SetTexture(self: Skybox, texture: string)
	self.sky.SkyboxBk = texture
	self.sky.SkyboxDn = texture
	self.sky.SkyboxFt = texture
	self.sky.SkyboxLf = texture
	self.sky.SkyboxRt = texture
	self.sky.SkyboxUp = texture
end

function SkyboxClass.Destroy(self: Skybox)
	if self.sky then
		self.sky:Destroy()
	end
end

return SkyboxClass
