local Loader = require(game.ReplicatedStorage.Shared.Framework.loader)

Loader.LoadServer(script.Engines)

local Network = require(game.ReplicatedStorage.Shared.Framework.network)

Network.OnServerInvoke("Test", function(Player, Payload)
	local Result = "hey fuck you"

	return Result
end)
