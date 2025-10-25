local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bytenet = require(ReplicatedStorage.Packages.Bytenet)

local Packets = Bytenet.defineNamespace("Engine", function()
	return {}
end)

return Packets
