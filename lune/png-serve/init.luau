--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")

local PngEncoder = require("@self/png-encoder")
local Base64 = require("@root/src/Utilities/Base64")

local SERVE_PORT = 1816

type ImageJSON = {
	name: string,
	size: { number },
	buffer: { string },
}

local function processPng(request: net.ServeRequest): net.ServeResponse
	local imgJSON = serde.decode("json", request.body) :: ImageJSON

	local len = 0
	local buffers = {}
	for i, b64 in imgJSON.buffer do
		buffers[i] = Base64.decode(b64)
		len = len + buffer.len(buffers[i])
	end

	local offset = 0
	local imgBuffer = buffer.create(len)
	for _, b in buffers do
		buffer.copy(imgBuffer, offset, b)
		offset = offset + buffer.len(b)
	end

	local contents = PngEncoder.encode(imgJSON.size[1], imgJSON.size[2], imgBuffer)
	fs.writeFile(`@self/output/{imgJSON.name}.png`, contents)

	return {
		status = 200,
		body = "Success",
	}
end

local function init()
	net.serve(SERVE_PORT, function(request)
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

	print(`Serving on port {SERVE_PORT}`)
	print("Press ctrl + c to cancel")
end

init()
