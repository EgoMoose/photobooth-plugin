--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Trove = require(pluginRoot.Packages.Trove)
local State = require(pluginRoot.Main.State)

local Types = require(pluginRoot.Main.Bindings.Interface.Types)

local photoRoot = script:FindFirstAncestor("Photo")
local Screenshot = require(photoRoot.Captures.Screenshot)
local UIHider = require(photoRoot.Tools.UIHider)

local capturesRoot = script:FindFirstAncestor("Captures")
local Composers = require(capturesRoot.Composers)

local function hideUI(options: Types.CaptureViewportOptions, trove: Trove.Trove)
	local scaleOS = State.read().temporary.scaleOS

	local exclusions = {}
	if UIHider.ViewportApp and not Screenshot.isFullscreenRect(options.rect) and Screenshot.isUnitScaleOS(scaleOS) then
		table.insert(exclusions, UIHider.ViewportApp)
	end

	local uiHider = UIHider.new({
		exclusions = exclusions,
		hiddenClasses = { "ScreenGui" },
	})

	trove:Add(function()
		uiHider:Destroy()
	end)
end

local function operation(options: Types.CaptureViewportOptions, trove: Trove.Trove)
	hideUI(options, trove)

	local capture = Screenshot.rect(options.rect)
	if options.alphaBleed then
		capture = Composers.alphaBleed(capture)
	end

	return capture
end

return operation
