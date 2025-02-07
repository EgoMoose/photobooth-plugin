--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Image = require(pluginRoot.Utilities.Image)
local Sift = require(pluginRoot.Packages.Sift)

local Configuration = require(script.Parent.Configuration)
local Composers = require(script.Composers)
local Types = require(script.Types)

-- Private

local ticket = 0
local ticketLookup = {}

local function wrap<T...>(callback: (T...) -> ...Image.Image)
	ticket = ticket + 1
	local myTicket = ticket

	local function wrapped(...: T...)
		local results = { callback(...) }
		if Configuration.get().AlphaBleedingEnabled then
			for i, img in results do
				results[i] = Composers.alphaBleed(img)
			end
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

export type UICaptureTypes = Types.UICaptureTypes
export type ViewportCaptureTypes = Types.ViewportCaptureTypes

local captureTypes = {
	UserInterface = {
		NoBackground = wrap(require(script.CaptureTypes.UserInterface.NoBackground)),
		AlphaMask = wrap(require(script.CaptureTypes.UserInterface.AlphaMask)),
	},
	Viewport = {
		Unmodified = wrap(require(script.CaptureTypes.Viewport.Unmodified)),
		NoSkybox = wrap(require(script.CaptureTypes.Viewport.NoSkybox)),
	},
}

return {
	UserInterface = {
		Order = getOrder(captureTypes.UserInterface),
		Processors = captureTypes.UserInterface,
	},
	Viewport = {
		Order = getOrder(captureTypes.Viewport),
		Processors = captureTypes.Viewport,
	},
}
