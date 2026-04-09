--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

if fs.isDir("lune/bindings/src") then
	fs.removeDir("lune/bindings/src")
end
fs.copy("src/Main/Bindings/Interface", "lune/bindings/src")

if fs.isFile("lune/bindings/LICENSE") then
	fs.removeFile("lune/bindings/LICENSE")
end
fs.copy("LICENSE", "lune/bindings/LICENSE")

local rootToml = serde.decode("toml", fs.readFile("wally.toml"))
local wallyToml = serde.decode("toml", fs.readFile("lune/bindings/wally.toml"))
wallyToml.package.version = rootToml.package.version
fs.writeFile("lune/bindings/wally.toml", serde.encode("toml", wallyToml, false))

local project = serde.decode("json", fs.readFile("lune/bindings/default.project.json"))
project.tree["$properties"].Attributes.PackageVersion.String = rootToml.package.version
fs.writeFile("lune/bindings/default.project.json", serde.encode("json", project, true))

-- cd lune/bindings
-- build as rbxm or publish
