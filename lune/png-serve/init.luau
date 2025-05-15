local fs = require("@lune/fs")
local encoder = require("@self/png-encoder")

local width = 4096
local height = 4096
local rgba = buffer.create(width * height * 4)

for y = 1, height do
	for x = 1, width do
		local i = (y - 1) * width + x - 1
		local j = (i * 4)

		buffer.writeu8(rgba, j + 0, 255)
		buffer.writeu8(rgba, j + 1, 0)
		buffer.writeu8(rgba, j + 2, 0)
		buffer.writeu8(rgba, j + 3, 255)
	end
end

fs.writeFile("foo.png", encoder(width, height, rgba))
