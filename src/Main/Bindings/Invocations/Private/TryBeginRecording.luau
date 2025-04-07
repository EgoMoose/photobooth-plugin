--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService") :: ChangeHistoryService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

-- stylua: ignore
local typechecker = gt.fn(
	gt.args(),
	gt.returns(gt.string())
)

local identifier
local function callback()
	if identifier and ChangeHistoryService:IsRecordingInProgress(identifier) then
		ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
	end

	identifier = assert(
		ChangeHistoryService:TryBeginRecording("photobooth_binding", "Photobooth"),
		"Failed to begin recording. A recording may already be in progress."
	)

	return identifier :: string
end

return {
	identifier = "tryBeginRecording",
	callback = gt.wrapFn(typechecker, callback),
}
