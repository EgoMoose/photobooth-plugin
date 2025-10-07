--!strict

local CriticalSectionStatic = {}

local CriticalSectionClass = {}
CriticalSectionClass.__index = CriticalSectionClass
CriticalSectionClass.ClassName = "CriticalSection"

export type CriticalSection = typeof(setmetatable(
	{} :: {
		isCritical: boolean,
	},
	CriticalSectionClass
))

function CriticalSectionStatic.new() end

return CriticalSectionStatic
