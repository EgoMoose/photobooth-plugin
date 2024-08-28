--!strict

local ScriptEditorService = game:GetService("ScriptEditorService")

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local gt = require(pluginRoot.Packages.GreenTea)

local BindingExporterClass = {}
BindingExporterClass.__index = BindingExporterClass
BindingExporterClass.ClassName = "BindingExporter"

type Entry<T..., U...> = {
	typechecker: (T...) -> U...,
	parameters: { string },
	returnTypes: { string },
}

type ProcessedEntry = {
	name: string,
	parameters: { string },
	returnTypes: { string },
	callback: (...any) -> ...any,
	typechecker: gt.Type,
}

export type BindingExporter = typeof(setmetatable(
	{} :: {
		exported: boolean,
		header: string,
		footer: string,
		entries: { ProcessedEntry },
	},
	BindingExporterClass
))

function BindingExporterClass.new()
	local self = setmetatable({}, BindingExporterClass) :: BindingExporter

	self.exported = false
	self.header = ""
	self.footer = ""
	self.entries = {}

	return self
end

function BindingExporterClass.SetHeader(self: BindingExporter, lines: { string })
	self.header = table.concat(lines, "\n")
end

function BindingExporterClass.Add<T..., U...>(self: BindingExporter, entry: Entry<T..., U...>, callback: (T...) -> U...)
	assert(not self.exported, "Already exported.")

	local built = gt.build(entry.typechecker)
	assert(built.kind == "function", "Invalid GreenTea type.")

	table.insert(self.entries, {
		name = debug.info(callback, "n"),
		callback = callback,
		typechecker = built,
		parameters = entry.parameters,
		returnTypes = entry.returnTypes,
	})
end

function BindingExporterClass.Create(self: BindingExporter)
	self.exported = true

	local binding = Instance.new("BindableFunction")
	binding.Name = "Binding"
	binding.OnInvoke = function(id: number, ...: any)
		local entry = assert(typeof(id) == "number" and self.entries[id], "Invalid binding id.")
		local typechecker = entry.typechecker :: any
		local success, _err = typechecker.fn.args:matches(...)
		assert(success, "Typechecking failed.")
		return entry.callback(...)
	end

	local interface = Instance.new("ModuleScript")
	interface.Name = "BindingInterface"

	local formatted = {}
	for i, entry in self.entries do
		local argNames = { tostring(i) }
		for i, parameter in entry.parameters do
			argNames[i + 1] = parameter:split(":")[1]
		end

		local args = table.concat(argNames, ", ")
		local params = table.concat(entry.parameters, ", ")
		local returns = table.concat(entry.returnTypes, ", ")

		formatted[i] = `function Bindings.{entry.name}({params}): ({returns})\n\treturn binding:Invoke({args})\nend`
	end

	ScriptEditorService:UpdateSourceAsync(interface, function()
		return table.concat({
			"--!strict\n",
			"local Bindings = {}",
			'local binding = assert(script:FindFirstChild("Binding") :: BindableFunction?)\n',
			`{self.header}\n`,
			table.concat(formatted, "\n\n"),
			"\nreturn Bindings",
		}, "\n")
	end)

	binding.Parent = interface
	return interface
end

return BindingExporterClass
