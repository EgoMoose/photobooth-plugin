--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Sift = require(pluginRoot.Packages.Sift)

local composersRoot = script.Composers
local alphaBleed = require(composersRoot.Parallel.AlphaBleed)

-- Private

local ticket = 0
local ticketLookup = {}

local function wrap<T...>(callback: (T...) -> ...Image.Image)
	ticket = ticket + 1
	local myTicket = ticket

	local function wrapped(...: T...)
		local results = { callback(...) }
		for i, img in results do
			results[i] = alphaBleed(img)
		end
		return results
	end

	ticketLookup[wrapped] = myTicket
	return wrapped
end

local function getOrder<T...>(exported: { [string]: (T...) -> { Image.Image } })
	local order = Sift.Dictionary.keys(exported)
	table.sort(order, function(a, b)
		return ticketLookup[exported[a]] < ticketLookup[exported[b]]
	end)
	return order
end

-- Public

export type UICaptureTypes = "NoBackground" | "AlphaMask"
export type ViewportCaptureTypes = "Unmodified" | "AlphaMask" | "NoSkybox"

local captureTypes = {
	UserInterface = {
		NoBackground = wrap(require(script.UserInterface.ReverseBlend)),
		AlphaMask = wrap(require(script.UserInterface.AlphaMask)),
	},
	Viewport = {
		Unmodified = wrap(require(script.Viewport.Unmodified)),
		AlphaMask = wrap(require(script.Viewport.AlphaMask)),
		NoSkybox = wrap(require(script.Viewport.ReverseBlend)),

		-- FogAlpha = wrap(require(script.Viewport.FogAlpha)),
		-- ReverseBlend = wrap(require(script.Viewport.ReverseBlend)),
		-- LeastSquares = wrap(require(script.Viewport.LeastSquares)),
		-- ReverseBlendLeastSquares = wrap(require(script.Viewport.ReverseBlendLeastSquares)),
	},
}

return {
	UserInterface = {
		Default = "NoBackground" :: UICaptureTypes,
		Order = getOrder(captureTypes.UserInterface),
		Processors = captureTypes.UserInterface,
	},
	Viewport = {
		Default = "NoSkybox" :: ViewportCaptureTypes,
		Order = getOrder(captureTypes.Viewport),
		Processors = captureTypes.Viewport,
	},
}
