local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")

local UNIVERSE_ID = 9183591500
local PLACE_ID = 87864471469006

local function readWallyVersion()
	local wally = serde.decode("toml", fs.readFile("wally.toml"))
	return wally.package.version
end

local function updateDescription(universeId: number, placeId: number, description: string, apiKey: string)
	local response = net.request({
		url = `https://apis.roblox.com/cloud/v2/universes/{universeId}/places/{placeId}`,
		method = "PATCH",
		headers = {
			["x-api-key"] = apiKey,
			["Content-Type"] = "application/json",
		},
		body = serde.encode("json", {
			["description"] = description,
		}),
	})

	assert(response.ok and response.statusCode == 200, response.body)
end

updateDescription(UNIVERSE_ID, PLACE_ID, readWallyVersion(), process.args[1])
