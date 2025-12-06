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
}

local Materials = {
	Concrete = { volumeMul = 0.9, lowpass = 8000 },
	Wood = { volumeMul = 0.7, lowpass = 4000 },
	Grass = { volumeMul = 0.85, lowpass = 6000 },
	Metal = { volumeMul = 1.0, lowpass = 10000, extraReflect = 0.12 },
	Glass = { volumeMul = 0.95, lowpass = 9000, extraReflect = 0.08 },
	Default = { volumeMul = 0.85, lowpass = 6000 },
}

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
	Parameters.FilterDescendantsInstances = IgnoreList
	Parameters.IgnoreWater = true
	return Parameters
end

local function Cast(Origin, Direction, Parameters)
	local Result = workspace:Raycast(Origin, Direction, Parameters)
	if not Result then
		return nil
	end
	local HitPosition = Result.Position
	local Distance = (HitPosition - Origin).Magnitude
	local Material = Result.Material
	return {
		Position = HitPosition,
		Distance = Distance,
		Material = Material,
		Instance = Result.Instance,
	}
end
