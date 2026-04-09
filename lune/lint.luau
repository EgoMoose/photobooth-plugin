--!strict

local fs = require("@lune/fs")
local run = require("@root/lune/utils/run")

pcall(function()
	run("wget", {
		"'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua'",
		"-O",
		"'globalTypes.d.lua'",
	})

	run("luau-lsp", {
		"analyze",
		"--sourcemap=sourcemap.json",
		"--definitions=globalTypes.d.lua",
		"--base-luaurc=.luaurc",
		"--settings=.vscode/settings.default.json",
		"--ignore=Packages/**",
		"src",
	})
end)

if fs.isFile("globalTypes.d.lua") then
	fs.removeFile("globalTypes.d.lua")
end
