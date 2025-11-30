local EngineManager = require(game.ReplicatedStorage.Shared.Framework.EngineManager)

local Engine = EngineManager.Create("ExampleEngine")

function Engine.Init()
	print("[Engine] Init")
end

function Engine.Start()
	print("[Engine] Started")
end

return Engine
