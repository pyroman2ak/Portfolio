--[[ 
  EngineerManager.luau
  Handles registration + retrieval of Engineers (client systems)
]]
local Signal = require(script.Parent.signal)

local Engineers = {}
local EngineerManager = {}

EngineerManager.OnStarted = Signal.new()

function EngineerManager.Create(name: string)
	assert(type(name) == "string", "Engineer name must be a string")
	assert(not Engineers[name], `[EngineerManager] Engineer {name} already exists.`)

	local Engineer = {
		Name = name,
		Init = function() end,
		Start = function() end,
		Client = {},
	}

	Engineers[name] = Engineer
	return Engineer
end

function EngineerManager.GetEngine(Name: string)
	return Engineers[Name]
end

function EngineerManager.GetAllEngines()
	return Engineers
end

function EngineerManager.InitAll()
	for _, Engineer in pairs(Engineers) do
		if Engineer.Init then
			task.spawn(Engineer.Init, Engineer)
		end
	end
end

function EngineerManager.StartAll()
	for _, Engineer in pairs(Engineers) do
		if Engineer.Start then
			task.spawn(Engineer.Start, Engineer)
		end
	end
	EngineerManager.OnStarted:Fire()
end

return EngineerManager
