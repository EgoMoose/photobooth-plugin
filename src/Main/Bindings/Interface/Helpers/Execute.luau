--!strict

local ScriptEditorService = game:GetService("ScriptEditorService") :: ScriptEditorService

local execute
function execute(script: LuaSourceContainer)
	assert(game:GetService("CoreGui"), "This should only be run in the command line.")
	assert(typeof(script) == "Instance" and script:IsA("LuaSourceContainer"), "Not a LuaSourceContainer.")

	local content = ScriptEditorService:GetEditorSource(script)

	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = script.Name
	moduleScript.Archivable = false

	ScriptEditorService:UpdateSourceAsync(moduleScript, function()
		-- the formatting is crazy here, but we retain line numbers!
		return `return (function(script, require) {content} end)`
	end)

	local callback = require(moduleScript) :: (...any) -> ...any
	moduleScript:Destroy()
	return callback(script, execute)
end

return execute
