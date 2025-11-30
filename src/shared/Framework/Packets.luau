local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bytenet = require(ReplicatedStorage.Packages.Bytenet)

local Packets = Bytenet.defineNamespace("Engine", function()
	return {
		Test = Bytenet.definePacket({
			value = Bytenet.struct({
				_RequestID = Bytenet.string,
				Payload = Bytenet.string,
			}),
		}),

		Test_Response = Bytenet.definePacket({
			value = Bytenet.struct({
				_RequestID = Bytenet.string,
				Result = Bytenet.string,
			}),
		}),
	}
end)

return Packets
