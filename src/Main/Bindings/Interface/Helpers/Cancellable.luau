--!strict

local Reversible = require(script.Parent.Reversible)

local function cancellable(script: LuaSourceContainer, callback: () -> ())
	local expectResult, reverse = Reversible(callback)

	script:SetAttribute("Cancel", false)
	local connection = script:GetAttributeChangedSignal("Cancel"):Connect(function()
		if script:GetAttribute("Cancel") then
			reverse()
		end
	end)

	local success, err = expectResult()
	connection:Disconnect()
	script:SetAttribute("Cancel", nil)

	return success, err
end

return cancellable
