local ScriptEditorService = game:GetService("ScriptEditorService")

local Templates = {}

function Templates.create()
	local folder = Instance.new("Folder")
	folder.Name = "Templates"

	for _, template in script:GetChildren() do
		local copy = template:Clone()
		local actionModule = copy:FindFirstChild("Action")
		if actionModule and actionModule:IsA("LuaSourceContainer") then
			ScriptEditorService:UpdateSourceAsync(actionModule, function(content: string)
				local result = content:gsub("--!nocheck", "--!strict", 1)
				return result
			end)

			copy.Parent = folder
		end

		if not copy.Parent then
			copy:Destroy()
		end
	end

	return folder
end

return Templates
