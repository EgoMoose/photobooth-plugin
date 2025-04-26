local net = require("@lune/net")
local serde = require("@lune/serde")
local encode = require("./encoder")

local handle = net.serve(8080, function(request)
	print(request)

	return {
		status = 200,
		body = "Echo:\n" .. request.body,
	}
end)
