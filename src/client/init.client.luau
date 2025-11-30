local Loader = require(game.ReplicatedStorage.Shared.Framework.loader)

Loader.LoadClient(script.Engineers)

local Network = require(game.ReplicatedStorage.Shared.Framework.network)

Network.ClientListen()

Network.InvokeServer("Test", "Payload"):andThen(function(result)
	print(result)
end)
