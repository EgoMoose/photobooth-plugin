--!strict

local ScriptEditorService = game:GetService("ScriptEditorService") :: ScriptEditorService

local CachelessRequire = {}

local function getExecutionCallback(script: LuaSourceContainer, params: { string })
	local tmpScript = Instance.new("ModuleScript")
	tmpScript.Name = script.Name
	tmpScript.Archivable = false

	local mergedParams = { "script", "require" }
	for _, param in params do
		table.insert(mergedParams, param)
	end

	local headers = {}
	local lines = ScriptEditorService:GetEditorSource(script):split("\n")
	for i = 1, #lines do
		local line = lines[i]
		if line:sub(1, 3) == "--!" then
			table.insert(headers, line .. "\n")
		end
	end

	local source = table.concat(lines, "\n", #headers + 1)
	ScriptEditorService:UpdateSourceAsync(tmpScript, function()
		-- The formatting is crazy here, but we retain line numbers
		return `{table.concat(headers)}return (function({table.concat(mergedParams, ", ")}) {source} end)`
	end)

	local callback = require(tmpScript) :: (...any) -> ...any
	tmpScript:Destroy()
	return callback
end

function CachelessRequire.execute(root: LuaSourceContainer, env: { [string]: any })
	assert(typeof(root) == "Instance" and root:IsA("LuaSourceContainer"), "Not a LuaSourceContainer.")

	local nEnv = 0
	local params, args = {}, {}
	for key, value in env do
		nEnv = nEnv + 1
		table.insert(params, key)
		table.insert(args, value)
	end

	local import
	local required = {}
	function import(module: ModuleScript)
		if not required[module] then
			local callback = getExecutionCallback(module, params)
			required[module] = table.pack(callback(module, import, table.unpack(args, 1, nEnv)))
		end
		local packed = required[module]
		return table.unpack(packed, 1, packed.n)
	end

	return getExecutionCallback(root, params)(root, import, table.unpack(args, 1, nEnv))
end

return CachelessRequire
