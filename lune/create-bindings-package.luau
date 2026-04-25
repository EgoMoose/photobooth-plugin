local fs = require("@lune/fs")
local serde = require("@lune/serde")

if fs.isDir("bindings-package") then
	fs.removeDir("bindings-package")
end

fs.copy("src/Main/Bindings/Interface", "bindings-package")
fs.copy("LICENSE", "bindings-package/LICENSE")

local wallyToml = serde.decode("toml", fs.readFile("wally.toml"))
local package = wallyToml.package
package.name = package.name:split("/")[1] .. "/photobooth-bindings"
package.description = "Bindings for use with the photobooth plugin."
package.private = nil
package.exclude = { "**" }
package.include = { "src", "src/**", "LICENSE", "wally.toml", "default.project.json" }
fs.writeFile("bindings-package/wally.toml", serde.encode("toml", { package = package }, false))

local defaultProject = serde.decode("json", fs.readFile("bindings-package/default.project.json"))
defaultProject.name = "photobooth-bindings"
defaultProject.tree.Wally["$path"] = "wally.toml"
defaultProject.tree.LICENSE["$path"] = "LICENSE"
defaultProject.syncRules[1].pattern = "LICENSE"
fs.writeFile("bindings-package/default.project.json", serde.encode("json", defaultProject, true))
