--[[
  network.luau
  bytenet wrapper
  replaces behaviour for remote events/ remote functions
  Source: https://github.com/ffrostfall/ByteNet
]]
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Network = {}
local PendingInvokes = {}
local Packets = require(script.Parent.Packets)
local Promise = require(script.Parent.Parent.Parent.Packages.Promise)

--Remote Events
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

--Remote Functions
function Network.InvokeClient(Client: Player, Request: string, Data)
	if RunService:IsServer() then
		local Packet = Network.GetPacket(Request)
		if not Packet or not Packet.sendTo then
			warn(`[Network] Invoke function: failed`)
			return Promise.reject("Invalid Invoke")
		end

		local RequestID = HttpService:GenerateGUID(false)
		local promise = Promise.new(function(resolve, reject)
			PendingInvokes[RequestID] = resolve
			Packet.sendTo({
				_RequestID = RequestID,
				Payload = Data,
			}, Client)
		end)

		return promise:timeout(5):catch(function()
			PendingInvokes[RequestID] = nil
			warn(`[Network] Invoke timeout: `, Request)
		end)
	end
end

function Network.InvokeServer(Request: string, Data)
	if RunService:IsClient() then
		local Packet = Packets[Request]
		if not Packet or not Packet.send then
			warn(`[Network] Invoke function: failed`)
			return Promise.reject("Invalid Invoke")
		end

		local RequestID = HttpService:GenerateGUID(false)
		local promise = Promise.new(function(resolve, reject)
			PendingInvokes[RequestID] = resolve
			Packet.send({
				_RequestID = RequestID,
				Payload = Data,
			})
		end)

		return promise:timeout(5):catch(function()
			PendingInvokes[RequestID] = nil
			warn(`[Network] Invoke timeout: `, Request)
		end)
	end
end

function Network.OnServerInvoke(Request, Callback)
	local Packet = Network.GetPacket(Request)
	if not Packet or not Packet.listen then
		warn(`[Network] Invoke function: failed`)
		return
	end

	Packet.listen(function(Data, Client)
		local RequestID = Data._RequestID
		local Result = Callback(Client, Data.Payload)

		local ResponsePacket = Network.GetPacket(Request .. "_Response")
		if ResponsePacket then
			ResponsePacket.sendTo({
				_RequestID = RequestID,
				Result = Result,
			}, Client)
		end
	end)
end

function Network.ClientListen()
	for name, packet in pairs(Packets) do
		if name:match("_Response$") and packet.listen then
			packet.listen(function(data)
				local id = data._RequestID
				local resolver = PendingInvokes[id]
				if resolver then
					PendingInvokes[id] = nil
					resolver(data.Result)
				end
			end)
		end
	end
end

return Network
