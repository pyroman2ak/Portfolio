local SoundPhysics = {}
SoundPhysics.__index = SoundPhysics

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Defaults = {
	RemoteEvent = nil,
	MaxWaves = 48,
	MaxEchoes = 2,
	Throttle = 0.05,
	MaxListeners = 16,
	SpeedOfSound = 343,
	Debug = false,
	SampleDistance = 100,
	DefaultMaxDistance = 1000,
}

local Materials = {
	Concrete = { volumeMul = 0.9, lowpass = 8000 },
	Wood = { volumeMul = 0.7, lowpass = 4000 },
	Grass = { volumeMul = 0.85, lowpass = 6000 },
	Metal = { volumeMul = 1.0, lowpass = 10000, extraReflect = 0.12 },
	Glass = { volumeMul = 0.95, lowpass = 9000, extraReflect = 0.08 },
	Default = { volumeMul = 0.85, lowpass = 6000 },
}

local function GetMaterialProperties(Material)
	local Name = tostring(Material)
	return Materials[Name] or Materials.Default
end

local function Now()
	return RunService:IsServer() and os.clock() or tick()
end

local Pool = {}
function Pool:Get()
	return table.remove(self) or {}
end

function Pool:Return(Table)
	for Key in pairs(Table) do
		Table[Key] = nil
	end
	table.insert(self, Table)
end

local function CreateRaycastParameters(IgnoreList)
	local Parameters = RaycastParams.new()
	Parameters.FilterType = Enum.RaycastFilterType.Exclude
	Parameters.FilterDescendantsInstances = IgnoreList or {}
	Parameters.IgnoreWater = true
	return Parameters
end

local function Cast(Origin, Direction, Parameters)
	local Result = Workspace:Raycast(Origin, Direction, Parameters)
	if not Result then
		return nil
	end
	local HitPosition = Result.Position
	local Distance = (HitPosition - Origin).Magnitude
	local Material = Result.Material
	local Normal = Result.Normal

	return {
		Position = HitPosition,
		Distance = Distance,
		Material = Material,
		Instance = Result.Instance,
		Normal = Normal,
	}
end

function SoundPhysics.EstimateRoom(Origin, SoundTable)
	SoundTable = SoundTable or {}
	local Waves = SoundTable.MaxWaves or Defaults.MaxWaves
	Waves = math.max(1, Waves)
	local sampleDist = SoundTable.SampleDistance or Defaults.SampleDistance
	local IgnoreList = SoundTable.IgnoreList or SoundTable.Ignore or {}
	local Parameters = CreateRaycastParameters(IgnoreList)
	local Total = 0
	local Count = 0

	for i = 1, Waves do
		local theta = math.acos(1 - 2 * (i / Waves))
		local phi = (i * 2.399963229728653) % (2 * math.pi)
		local dir = Vector3.new(math.sin(theta) * math.cos(phi), math.sin(theta) * math.sin(phi), math.cos(theta))
		local Path = dir * sampleDist
		local RayResult = Cast(Origin, Path, Parameters)
		if RayResult then
			Total = Total + RayResult.Distance
			Count = Count + 1
		end
	end
	if Count == 0 then
		return { Average = sampleDist, VolumeClass = "Open" }
	end
	local Average = Total / Count
	local VolumeClass = "Small"

	if Average > 40 then
		VolumeClass = "Large"
	elseif Average > 12 then
		VolumeClass = "Medium"
	end
	return { Average = Average, VolumeClass = VolumeClass }
end

function SoundPhysics.AnalyseForListener(EmitterPosition, ListenerPosition, SoundTable)
	SoundTable = SoundTable or {}
	local IgnoreList = SoundTable.IgnoreList or SoundTable.Ignore or {}
	local Parameters = CreateRaycastParameters(IgnoreList)

	local PathVec = EmitterPosition - ListenerPosition
	local RayResult = Cast(ListenerPosition, PathVec, Parameters)

	local Occluded = false
	local OcclusionStrength = 0
	local MaterialProperties = Materials.Default

	if RayResult then
		local hitInstance = RayResult.Instance
		if
			(hitInstance and hitInstance:IsA("BasePart") and (hitInstance.Position - EmitterPosition).Magnitude < 1)
			or (RayResult.Distance >= PathVec.Magnitude - 0.5)
		then
			Occluded = false
		else
			Occluded = true
			MaterialProperties = GetMaterialProperties(RayResult.Material)
			OcclusionStrength = math.clamp(RayResult.Distance / PathVec.Magnitude, 0.15, 0.95)
		end
	else
		Occluded = false
	end

	if Occluded then
		local Offsets = { Vector3.new(0.4, 0, 0), Vector3.new(-0.4, 0, 0), Vector3.new(0, 0.4, 0) }
		local OpenCount = 0
		for _, Offset in ipairs(Offsets) do
			local altOrigin = ListenerPosition + Offset
			local altDir = EmitterPosition - altOrigin
			local AlternateRay = Cast(altOrigin, altDir, Parameters)
			if AlternateRay and AlternateRay.Distance >= altDir.Magnitude - 0.5 then
				OpenCount = OpenCount + 1
			end
		end
		if OpenCount > 0 then
			OcclusionStrength = OcclusionStrength * (1 - (OpenCount / #Offsets) * 0.6)
		end
	end

	local Echoes = {}
	local function Reflect(Origin, Direction, Depth)
		local maxDepth = SoundTable.MaxEchoes or Defaults.MaxEchoes
		if Depth > maxDepth then
			return
		end
		local Hit = Cast(Origin, Direction, Parameters)
		if not Hit then
			return
		end

		table.insert(Echoes, {
			Position = Hit.Position,
			Distance = Hit.Distance,
			Material = Hit.Material,
			Depth = Depth,
		})

		local hitNormal = Hit.Normal
		if hitNormal and hitNormal.Magnitude > 0 then
			local Normal = hitNormal.Unit
			local Reflection = Direction - 2 * Direction:Dot(Normal) * Normal
			local nextOrigin = Hit.Position + Reflection.Unit * 0.01
			local nextDir = Reflection.Unit * (SoundTable.SampleDistance or 60)
			Reflect(nextOrigin, nextDir, Depth + 1)
		end
	end

	local SampleDirections = {
		Vector3.new(1, 0.2, 0),
		Vector3.new(-1, 0.1, 0.2),
		Vector3.new(0, 0.3, 1),
		Vector3.new(0.6, 0.2, -0.4),
	}

	for _, SampleDirection in ipairs(SampleDirections) do
		local dir = SampleDirection.Unit * (SoundTable.SampleDistance or 60)
		Reflect(EmitterPosition, dir, 1)
	end

	return {
		Occluded = Occluded,
		OcclusionStrength = OcclusionStrength,
		MaterialProperties = MaterialProperties,
		Echoes = Echoes,
	}
end

local function GetNearestListeners(Position, MaxCount)
	local Listeners = {}
	for _, Player in pairs(Players:GetPlayers()) do
		local Character = Player.Character
		if Character and Character.PrimaryPart then
			local Distance = (Character.PrimaryPart.Position - Position).Magnitude
			table.insert(Listeners, { Player = Player, Distance = Distance, Position = Character.PrimaryPart.Position })
		end
	end
	table.sort(Listeners, function(a, b)
		return a.Distance < b.Distance
	end)
	local Out = {}
	for i = 1, math.min(MaxCount, #Listeners) do
		Out[#Out + 1] = Listeners[i]
	end
	return Out
end

function SoundPhysics:Init(Settings)
	Settings = Settings or {}
	for Index, Value in pairs(Defaults) do
		if Settings[Index] == nil then
			Settings[Index] = Value
		end
	end

	self.Config = Settings
	assert(Settings.RemoteEvent, "SoundPhysics requires a RemoteEvent to function.")

	self.RemoteEvent = Settings.RemoteEvent
	self._emitters = {}
	return true
end

function SoundPhysics:CreateSound(Part, Settings)
	Settings = Settings or {}
	local Emitter = {
		Part = Part,
		Settings = Settings,
		SoundID = Settings.SoundID or "",
		LastUpdate = 0,
		Throttle = Settings.Throttle or self.Config.Throttle,
		Created = Now(),
		MaxDistance = Settings.MaxDistance or self.Config.DefaultMaxDistance,
		RemoteEvent = self.RemoteEvent,
		Config = self.Config,
	}
	setmetatable(
		Emitter,
		{
			__index = {
				Play = function(self, baseVolume)
					baseVolume = baseVolume or 1
					local CurrentTime = Now()
					if CurrentTime - self.LastUpdate < self.Throttle then
						self:_SendSimplePlay(baseVolume)
						return
					end
					self.LastUpdate = CurrentTime

					local Listeners = GetNearestListeners(self.Part.Position, self.Config.MaxListeners)

					for _, Listener in ipairs(Listeners) do
						local Analysis = SoundPhysics.AnalyseForListener(self.Part.Position, Listener.Position, {
							MaxEchoes = self.Config.MaxEchoes,
							IgnoreList = { self.Part },
							MaxWaves = self.Config.MaxWaves,
							SampleDistance = self.Config.SampleDistance,
						})

						local Room = SoundPhysics.EstimateRoom(self.Part.Position, {
							MaxWaves = math.floor(self.Config.MaxWaves / 3),
							IgnoreList = { self.Part },
							SampleDistance = self.Config.SampleDistance,
						})

						local distance = (Listener.Position - self.Part.Position).Magnitude
						local delay = distance / (self.Config.SpeedOfSound or Defaults.SpeedOfSound)

						local material = Analysis.MaterialProperties or Materials.Default
						local gain = baseVolume
							* (material.volumeMul or 1)
							* math.clamp(1 - (distance / (self.MaxDistance or self.Config.DefaultMaxDistance)), 0, 1)
						local lowpass = material.lowpass or Materials.Default.lowpass
						if Analysis.Occluded then
							gain = gain * (1 - Analysis.OcclusionStrength)
							lowpass = lowpass * (1 - Analysis.OcclusionStrength * 0.8)
						end

						local echoes = {}
						for _, Echo in ipairs(Analysis.Echoes) do
							local echoDelay = Echo.Distance / (self.Config.SpeedOfSound or Defaults.SpeedOfSound)
							local echoMat = GetMaterialProperties(Echo.Material)
							local echoGain = baseVolume * (echoMat.volumeMul or 1) * 0.25 / (1 + Echo.Distance / 20)
							local echoLow = echoMat.lowpass or Materials.Default.lowpass
							table.insert(echoes, { Delay = echoDelay, Gain = echoGain, LowpassFreq = echoLow })
						end

						local payload = {
							SoundID = self.SoundID,
							EmitterPosition = self.Part.Position,
							ListenerPosition = Listener.Position,
							BaseVolume = baseVolume,
							Distance = distance,
							Delay = delay,
							Gain = gain,
							LowpassFreq = lowpass,
							MaxDistance = self.MaxDistance,
							Occluded = Analysis.Occluded,
							Occlusion = Analysis.OcclusionStrength,
							Material = material,
							Reflections = echoes,
							RoomAvg = Room.Average,
							RoomClass = Room.VolumeClass,
							Timestamp = Now(),
						}

						if self.RemoteEvent then
							self.RemoteEvent:FireClient(Listener.Player, payload)
						end
					end
				end,
				_SendSimplePlay = function(self, baseVolume)
					local Listeners = GetNearestListeners(self.Part.Position, self.Config.MaxListeners)
					for _, Listener in ipairs(Listeners) do
						local payload = {
							SoundID = self.SoundID,
							EmitterPosition = self.Part.Position,
							ListenerPosition = Listener.Position,
							BaseVolume = baseVolume,
							Distance = (Listener.Position - self.Part.Position).Magnitude,
							Delay = 0,
							Gain = baseVolume,
							LowpassFreq = Materials.Default.lowpass,
							MaxDistance = self.MaxDistance,
							Occluded = false,
							Occlusion = 0,
							Material = Materials.Default,
							Echoes = {},
							RoomAvg = Defaults.SampleDistance,
							RoomClass = "Open",
							Timestamp = Now(),
						}

						if self.RemoteEvent then
							self.RemoteEvent:FireClient(Listener.Player, payload)
						end
					end
				end,
			},
		}
	)

	table.insert(self._emitters, Emitter)
	return Emitter
end

function SoundPhysics:Cleanup()
	self._emitters = {}
end

return setmetatable(SoundPhysics, { __index = SoundPhysics })
