local Loader = {}
Loader._engines = {}
Loader._engineers = {}

Loader.DebugMode = true

local EngineManager = require(script.Parent:WaitForChild("EngineManager"))
local EngineerManager = require(script.Parent:WaitForChild("EngineerManager"))

local function _LoadModules(Folder)
	local Modules = {}
	for _, Module in ipairs(Folder:GetChildren()) do
		if Module:IsA("ModuleScript") then
			local success, result = pcall(require, Module)
			if success then
				Modules[Module.Name] = result
			else
				warn(`[Loader] Failed to load {Module.Name}: {result}`)
			end
		end
	end
	return Modules
end

function Loader.LoadServer(Folder)
	_LoadModules(Folder)
	EngineManager.InitAll()
	task.defer(EngineManager.StartAll)
end

function Loader.LoadClient(Folder)
	_LoadModules(Folder)
	EngineerManager.InitAll()
	task.defer(EngineerManager.StartAll)
end

return Loader
