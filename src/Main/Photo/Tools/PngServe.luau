--!strict

local HttpService = game:GetService("HttpService") :: HttpService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Future = require(pluginRoot.Utilities.Future)
local Image = require(pluginRoot.Utilities.Image)

local BUFFER_ENCODE_MAX_LENGTH = 3_000_000

local PngServe = {}

-- Private

local function encodeBuffer(b: buffer)
	-- it is recommended to keep buffer size below 3mb when encoding
	-- https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/123

	local encoded: { { string } } = {}

	local bufferLength = buffer.len(b)
	local splitN = math.ceil(bufferLength / BUFFER_ENCODE_MAX_LENGTH)
	for i = 1, splitN do
		local from = (i - 1) * BUFFER_ENCODE_MAX_LENGTH
		local length = math.min(bufferLength, i * BUFFER_ENCODE_MAX_LENGTH) - from

		local splitBuffer = buffer.create(length)
		buffer.copy(splitBuffer, 0, b, from, length)

		local json = HttpService:JSONEncode(splitBuffer)

		local encodeType = "zbase64"
		local encodeValue = json:match([["zbase64":(%b"")]])
		if not encodeValue then
			encodeType = "base64"
			encodeValue = json:match([["base64":(%b"")]])
		end

		table.insert(encoded, { encodeType, (encodeValue :: string):sub(2, -2) })
	end

	return encoded
end

-- Public

function PngServe.ping(port: number, timeout: number?)
	local pingFuture = Future.raw()
	local timeoutFuture = Future.raw()

	if timeout and timeout > 0 then
		task.delay(timeout, function()
			timeoutFuture:complete(false)
		end)
	end

	local resultFuture = Future.race({
		pingFuture,
		timeoutFuture,
	}) :: Future.Future<boolean>

	task.spawn(function()
		local success, _err = pcall(function()
			local pingResult = HttpService:RequestAsync({
				Compress = Enum.HttpCompression.None,
				Url = `http://localhost:{port}/ping`,
				Method = "GET",
			})

			pingFuture:complete(pingResult.StatusCode == 200)
		end)

		if not success then
			pingFuture:complete(false)
		end
	end)

	return resultFuture
end

function PngServe.send(port: number, name: string, img: Image.Image, timeout: number?)
	local sendFuture = Future.raw()
	local timeoutFuture = Future.raw()

	local resultFuture = Future.race({
		sendFuture,
		timeoutFuture,
	}) :: Future.Future<boolean>

	if timeout and timeout > 0 then
		task.delay(timeout, function()
			timeoutFuture:complete(false)
		end)
	end

	task.spawn(function()
		local success, _err = pcall(function()
			local sendResult = HttpService:RequestAsync({
				Compress = Enum.HttpCompression.None,
				Headers = { ["content-type"] = "application/json" },
				Url = `http://localhost:{port}/send`,
				Method = "POST",
				Body = HttpService:JSONEncode({
					name = name,
					size = { img:GetWidth(), img:GetHeight() },
					buffer = encodeBuffer(img.buffer),
				}),
			})

			sendFuture:complete(sendResult.StatusCode == 200)
		end)

		if not success then
			sendFuture:complete(false)
		end
	end)

	return resultFuture
end

function PngServe.create(port: number)
	local pingFuture = Future.completed(false)
	if port > 0 then
		pingFuture = PngServe.ping(port, 0.025)
	end

	return function(name: string, img: Image.Image)
		local sendFuture = Future.raw()
		task.spawn(function()
			local result = false
			if pingFuture:expect() then
				result = PngServe.send(port, name, img):expect()
			end
			sendFuture:complete(result)
		end)
		return sendFuture
	end
end

--

return PngServe
