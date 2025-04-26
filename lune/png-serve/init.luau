--!strict

local net = require("@lune/net")
local serde = require("@lune/serde")
local encode = require("./encoder")

local function ping(request: net.ServeRequest): net.ServeResponse
	return {
		status = 200,
		body = "pong!",
	}
end

local function send(request: net.ServeRequest): net.ServeResponse
	return {
		status = 200,
		body = "",
	}
end

-- serve handling

local handle = net.serve(8080, function(request)
	if request.path == "/ping" then
		return ping(request)
	elseif request.path == "/send" then
		return send(request)
	end

	return {
		status = 404,
		body = "",
	}
end)
