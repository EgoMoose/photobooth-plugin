local fs = require("@lune/fs")
local run = require("@root/lune/utils/run")

run("wally", { "install" })
for _, folderName in { "Packages", "DevPackages", "ServerPackages" } do
	if not fs.isDir(folderName) then
		fs.writeDir(folderName)
	end
end

run("rojo", { "sourcemap", "analysis.project.json", "-o", "sourcemap.json" })

for _, folderName in { "Packages", "DevPackages", "ServerPackages" } do
	if fs.isDir(folderName) then
		run("wally-package-types", { "--sourcemap", "sourcemap.json", folderName })
	end
end
