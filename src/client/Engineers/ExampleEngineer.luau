local EngineerManager = require(game.ReplicatedStorage.Shared.Framework.EngineerManager)

local Engineer = EngineerManager.Create("ExampleEngineer")

function Engineer.Init()
	print("[ExampleEngineer] Init")
end

function Engineer.Start()
	print("[ExampleEngineer] Started")
end

return Engineer
