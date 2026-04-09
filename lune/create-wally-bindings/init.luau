--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

if fs.isDir("lune/create-wally-bindings/src") then
	fs.removeDir("lune/create-wally-bindings/src")
end
fs.copy("src/Main/Bindings/Interface", "lune/create-wally-bindings/src")

if fs.isFile("lune/create-wally-bindings/LICENSE") then
	fs.removeFile("lune/create-wally-bindings/LICENSE")
end
fs.copy("LICENSE", "lune/create-wally-bindings/LICENSE")

local rootToml = serde.decode("toml", fs.readFile("wally.toml"))
local wallyToml = serde.decode("toml", fs.readFile("lune/create-wally-bindings/wally.toml"))
wallyToml.package.version = rootToml.package.version
fs.writeFile("lune/create-wally-bindings/wally.toml", serde.encode("toml", wallyToml, false))

local project = serde.decode("json", fs.readFile("lune/create-wally-bindings/default.project.json"))
project.tree["$properties"].Attributes.PackageVersion.String = rootToml.package.version
fs.writeFile("lune/create-wally-bindings/default.project.json", serde.encode("json", project, true))

-- cd lune/bindings
-- build as rbxm or publish
