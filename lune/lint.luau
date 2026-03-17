--!strict

local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

type Options = {
	cwd: string?,
	env: { [string]: string }?,
}

local function run(program: string, params: { string }, options: Options?)
	stdio.write(stdio.style("bold"))
	print(`> {program} {table.concat(params, " ")}`)
	stdio.write(stdio.style("reset"))

	local result = process.exec(program, params, {
		shell = true,
		stdio = "forward",
		cwd = if options then options.cwd else nil,
		env = if options then options.env else nil,
	})

	if result.code ~= 0 then
		process.exit(result.code)
	end

	return result.stdout:gsub("\n$", "")
end

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
