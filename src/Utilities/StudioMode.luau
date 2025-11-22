--!strict

local Players = game:GetService("Players") :: Players
local RunService = game:GetService("RunService") :: RunService

local StudioMode = {}

function StudioMode.isTeamCreate()
	return not not (
		RunService:IsStudio()
		and RunService:IsEdit()
		and Players.LocalPlayer
		and not Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
	)
end

return StudioMode
