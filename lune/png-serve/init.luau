local fs = require("@lune/fs")
local encoder = require("@self/png-encoder")

local width = 100
local height = 100
local rgba = table.create(width * height * 4)

for y = 1, height do
	for x = 1, width do
		local i = (y - 1) * width + x - 1
		local j = (i * 4) + 1

		rgba[j + 0] = 255
		rgba[j + 1] = 0
		rgba[j + 2] = 255
		rgba[j + 3] = 100
	end
end

fs.writeFile("foo.png", encoder(width, height, rgba))
