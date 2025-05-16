--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")

local PngEncoder = require("@self/png-encoder")
local Constants = require("@root/src/Constants")
local Base64 = require("@root/src/Utilities/Base64")

type ImageJSON = {
	name: string,
	size: { number },
	base64Chunks: { string },
}

local function relativePath(path: string)
	local root = debug.info(2, "s"):sub(10, -3):gsub("\\", "/")
	local splitRoot = string.split(root, "/")

	if not fs.isDir(table.concat(splitRoot, "/")) then
		table.remove(splitRoot)
	end

	for _, step in path:split("/") do
		local onlyDots = step:match("[%.]+") == step
		if onlyDots then
			for _ = 1, #step do
				table.remove(splitRoot)
			end
		else
			table.insert(splitRoot, step)
		end
	end

	return table.concat(splitRoot, "/")
end

local function processPng(request: net.ServeRequest): net.ServeResponse
	local imgJSON = serde.decode("json", request.body) :: ImageJSON

	local length = 0
	local chunks: { buffer } = {}
	for i, base64 in imgJSON.base64Chunks do
		local chunk = Base64.decode(buffer.fromstring(base64))
		length = length + buffer.len(chunk)
		chunks[i] = chunk
	end

	local offset = 0
	local imgBuffer = buffer.create(length)
	for _, chunk in chunks do
		buffer.copy(imgBuffer, offset, chunk)
		offset = offset + buffer.len(chunk)
	end

	local contents = PngEncoder.encode(imgJSON.size[1], imgJSON.size[2], imgBuffer)
	fs.writeFile(relativePath(`output/{imgJSON.name}.png`), contents)

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
