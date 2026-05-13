--!strict

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Timeout = require(pluginRoot.Utilities.Timeout)
local Image = require(pluginRoot.Utilities.Image)

local Constants = require(pluginRoot.Constants)

local PlantSeeds = require(script.PlantSeeds)
local JFAPasses = require(script.JFAPasses)
local Bleed = require(script.Bleed)

--[[
Some principals to understand about this code and how it's optimized for roblox's parallel luau system.

Ultimately the algo we're implementing here is the jump-flood algorithm (JFA). In other languages / frameworks
it is easier to have data shared between parallel actors - this isn't really the case for Roblox. Typically when
we send data to an actor it's done through one of two methods:

1. Arguments passed to `actor:SendMessage(...)` - For our case we'd typically want to send a buffer, but buffers get deep-cloned
when they're sent this way which isn't ideal. We want to pass a pointer to data, not fully copy it.

2. SharedTable - Again not really possible because we want to use a buffer which shared tables don't support.

So what are we to do? Luckily we can send an editable image which is an instance (and thus a pointer) and we can read the buffer from
said editable image b/c `:ReadPixelsBuffer()` can be used in parallel.
--]]

local function getCropRegions(imgEdit: EditableImage, nSlices: number)
	local imgSize = imgEdit.Size
	local imgWidth, imgHeight = imgSize.X, imgSize.Y

	local regions = {}
	local stepY = math.floor(imgHeight / nSlices)
	for dy = 1, nSlices do
		local y0 = (dy - 1) * stepY
		local y1 = if dy == nSlices then imgHeight else dy * stepY
		table.insert(regions, Rect.new(0, y0, imgWidth, y1))
	end

	return regions
end

local function alphaBleedJFA(img: Image.Image)
	local imgEdit = img:Save()
	local voronoiEdit = img:Save()

	local cropRegions = getCropRegions(imgEdit, Constants.JFAActorCount)

	local nBleedPixels = PlantSeeds(imgEdit, voronoiEdit, cropRegions)
	local nPasses = JFAPasses(imgEdit, voronoiEdit, cropRegions, nBleedPixels)

	local resultImg = img
	if nPasses > 0 then
		local bledBuffer = Bleed(imgEdit, voronoiEdit, cropRegions)

		local bledImg = Image.fromBuffer(bledBuffer, img.size)
		bledImg.templateUri = img.templateUri
		resultImg = bledImg
	end

	imgEdit:Destroy()
	voronoiEdit:Destroy()

	return resultImg
end

return alphaBleedJFA
