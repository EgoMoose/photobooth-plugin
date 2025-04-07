--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(gt.string(), gt.EnumItem()),
	gt.returns()
)

local function callback(identifier: string, operation: EnumItem)
	assert(operation.EnumType == Enum.FinishRecordingOperation, "Invalid enum type.")
	if ChangeHistoryService:IsRecordingInProgress(identifier) then
		ChangeHistoryService:FinishRecording(identifier, operation :: Enum.FinishRecordingOperation)
	end
end

return {
	identifier = "finishRecording",
	callback = gt.wrapFn(typechecker, callback),
}
