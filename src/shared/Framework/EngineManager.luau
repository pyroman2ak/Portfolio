--[[ 
  EngineManager.luau
  Handles registration + retrieval of Engines (server systems)
]]
local Engines = {}

local EngineManager = {}

function EngineManager.Create(name: string)
	assert(type(name) == "string", "Engine name must be a string")
	assert(not Engines[name], `[EngineManager] Engine {name} already exists.`)

	local Engine = {
		Name = name,
		Init = function() end,
		Start = function() end,
	}

	Engines[name] = Engine
	return Engine
end

function EngineManager.GetEngine(Name: string)
	return Engines[Name]
end

function EngineManager.GetAllEngines()
	return Engines
end

function EngineManager.InitAll()
	for _, Engine in pairs(Engines) do
		if Engine.Init then
			task.spawn(Engine.Init, Engine)
		end
	end
end

function EngineManager.StartAll()
	for _, Engine in pairs(Engines) do
		if Engine.Start then
			task.spawn(Engine.Start, Engine)
		end
	end
end

return EngineManager
