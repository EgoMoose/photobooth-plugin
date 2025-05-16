--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")

local PngEncoder = require("@self/png-encoder")
local Base64 = require("@root/src/Utilities/Base64")
local Constants = require("@root/src/Constants")

type ImageJSON = {
	name: string,
	size: { number },
	buffer: { { string } },
}

local function processPng(request: net.ServeRequest): net.ServeResponse
	local imgJSON = serde.decode("json", request.body) :: ImageJSON

	for _, b in imgJSON.buffer do
		print(b[1])
	end

	return {
		status = 200,
		body = "Success",
	}
end

local function init()
	net.serve(Constants.ServePort, function(request)
		if request.path == "/ping" then
			return {
				status = 200,
				body = "Pong",
			}
		elseif request.path == "/send" then
			return processPng(request)
		end

		return {
			status = 404,
			body = "Not Found",
		}
	end)

	print(`Serving on port {Constants.ServePort}`)
	print("Press ctrl + c to cancel")
end

init()
