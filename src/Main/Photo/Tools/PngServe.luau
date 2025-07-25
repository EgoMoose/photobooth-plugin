--!strict

local HttpService = game:GetService("HttpService") :: HttpService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Base64 = require(pluginRoot.Utilities.Base64)
local Future = require(pluginRoot.Packages.Future)
local Image = require(pluginRoot.Utilities.Image)

local BUFFER_ENCODE_MAX_LENGTH = 3_000_000

local PngServe = {}

-- Private

local function bufferToBase64Chunks(b: buffer)
	-- it is recommended to keep buffer size below 3mb when encoding
	-- https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/123

	local base64Chunks: { string } = {}

	local bufferLength = buffer.len(b)
	local splitN = math.ceil(bufferLength / BUFFER_ENCODE_MAX_LENGTH)
	for i = 1, splitN do
		local from = (i - 1) * BUFFER_ENCODE_MAX_LENGTH
		local length = math.min(bufferLength, i * BUFFER_ENCODE_MAX_LENGTH) - from

		local splitBuffer = buffer.create(length)
		buffer.copy(splitBuffer, 0, b, from, length)

		local buffer64 = Base64.encode(splitBuffer)
		local base64 = buffer.tostring(buffer64)

		table.insert(base64Chunks, base64)
	end

	return base64Chunks
end

-- Public

function PngServe.ping(port: number, timeout: number?)
	local pingFuture = Future.new()
	local timeoutFuture = Future.new()

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
	local sendFuture = Future.new()
	local timeoutFuture = Future.new()

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
					base64Chunks = bufferToBase64Chunks(img.buffer),
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
	local pingFuture: Future.Future<boolean> = Future.completed(false)
	if port > 0 then
		pingFuture = PngServe.ping(port, 1)
	end

	return function(name: string, img: Image.Image)
		local sendFuture = Future.new()
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
