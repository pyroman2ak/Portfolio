--[[
  network.luau
  bytenet wrapper
  replaces behaviour for remote events/ remote functions
  Source: https://github.com/ffrostfall/ByteNet
]]
local Network = {}
local Packets = require(script.Parent.Packets)

function Network.Init(Folder: Folder)
	for _, Packet in ipairs(Folder:GetChildren()) do
		if Packet:IsA("ModuleScript") then
			local Success, Result = pcall(require, Packet)
			if Success and Result then
				Packets[Packet.Name] = Result
			else
				warn(`[Network] Failed to load packet {Packet.Name}: {Result}`)
			end
		end
	end
end

function Network.GetPacket(Name)
	return Packets[Name]
end

function Network.Send(Request: string, Data: any)
	local Packet = Packets[Request]
	if not Packet then
		warn(`[Network] Unknown Packet: {Request}`)
	end

	if Packet.send then
		Packet.send(Data)
	else
		warn(`[Network] Packet {Request} has no send function.`)
	end
end

function Network.SendTo(Client: Player, Request: string, Data: any)
	local Packet = Packets[Request]
	if not Packet then
		warn(`[Network] Unknown Packet: {Request}`)
	end

	if Packet.sendTo then
		Packet.sendTo(Data, Client)
	else
		warn(`[Network] Packet {Request} has no sendTo function.`)
	end
end

function Network.SendToAll(Request: string, Data: any)
	local Packet = Packets[Request]
	if not Packet then
		warn(`[Network] Unknown Packet: {Request}`)
	end

	if Packet.sendToAll then
		Packet.sendToAll(Data)
	else
		warn(`[Network] Packet {Request} has no sendToAll function.`)
	end
end

function Network.Listen(Request: string, Callback: (any, Player?) -> ())
	local Packet = Packets[Request]
	if not Packet then
		warn(`[Network] Unknown Packet: {Request}`)
	end

	if Packet.listen then
		Packet.listen(function(Data, Client)
			Callback(Client, Data)
		end)
	else
		warn(`[Network] Packet {Request} has no listen function.`)
	end
end

return Network
