--!strict

local RootModule = assert(script:FindFirstAncestorWhichIsA("ModuleScript") :: ModuleScript?)
local WorkerCallback = require(RootModule:FindFirstChild("Worker")) :: any

return WorkerCallback(script)
