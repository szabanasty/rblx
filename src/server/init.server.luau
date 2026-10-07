--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local configFolder = shared:WaitForChild("Config")
local modules = shared:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local serviceFolder = script:WaitForChild("Services")

local context: any = {
    Config = {
        Game = require(configFolder:WaitForChild("GameConfig")),
        Levels = require(configFolder:WaitForChild("LevelConfig")),
        Scooters = require(configFolder:WaitForChild("ScooterConfig")),
        Rewards = require(configFolder:WaitForChild("RewardConfig")),
        Roads = require(configFolder:WaitForChild("RoadConfig")),
        World = require(configFolder:WaitForChild("WorldConfig")),
        Upgrades = require(configFolder:WaitForChild("UpgradeConfig")),
        Quests = require(configFolder:WaitForChild("QuestConfig")),
        Economy = require(configFolder:WaitForChild("EconomyConfig")),
        Combat = require(configFolder:WaitForChild("CombatConfig")),
        Equipment = require(configFolder:WaitForChild("EquipmentConfig")),
        PvPRewards = require(configFolder:WaitForChild("PvPRewardConfig")),
        Fishing = require(configFolder:WaitForChild("FishingConfig")),
        Zones = require(configFolder:WaitForChild("ZoneConfig")),
    },
    Schema = require(modules:WaitForChild("ProfileSchema")),
    Progression = require(modules:WaitForChild("Progression")),
    Validation = require(modules:WaitForChild("Validation")),
    RateLimiter = require(modules:WaitForChild("RateLimiter")),
    Layout = require(modules:WaitForChild("WorldLayout")),
    Stats = require(modules:WaitForChild("ScooterStats")),
    Services = {}, Remotes = {}, IsClosing = false,
}
for _, name in {"Action", "Input", "Snapshot", "Feedback"} do
    context.Remotes[name] = remotesFolder:WaitForChild(name) :: RemoteEvent
end
if context.Config.Game.FoundationOnly then
    context.Services = {
        PlayerData = require(serviceFolder:WaitForChild("PlayerDataService")),
        Economy = require(serviceFolder:WaitForChild("EconomyService")),
        PlayerState = require(serviceFolder:WaitForChild("PlayerStateService")),
        Network = require(serviceFolder:WaitForChild("NetworkService")),
        Snapshot = require(serviceFolder:WaitForChild("SnapshotService")),
    }
else
    context.Services = {
    World = require(serviceFolder:WaitForChild("WorldService")),
    Roads = require(serviceFolder:WaitForChild("RoadService")),
    Traffic = require(serviceFolder:WaitForChild("TrafficService")),
    DayCycle = require(serviceFolder:WaitForChild("DayCycleService")),
    Shop = require(serviceFolder:WaitForChild("ShopService")),
    Quests = require(serviceFolder:WaitForChild("QuestService")),
    PlayerData = require(serviceFolder:WaitForChild("PlayerDataService")),
    Economy = require(serviceFolder:WaitForChild("EconomyService")),
    Scooter = require(serviceFolder:WaitForChild("ScooterService")),
    Network = require(serviceFolder:WaitForChild("NetworkService")),
    Snapshot = require(serviceFolder:WaitForChild("SnapshotService")),
    }
end
context.Notify = function(player: Player)
    context.Services.Economy:OnDataChanged(player)
    context.Services.Snapshot:Send(player)
end
context.OpenMenu = function(player: Player, menu: string)
    context.Remotes.Feedback:FireClient(player, {RequestId = 0, Success = true, Message = "", OpenMenu = menu})
end
local order: {string} = if context.Config.Game.FoundationOnly then {"Economy", "PlayerState", "Network", "Snapshot", "PlayerData"}
    else {"World", "Roads", "Traffic", "DayCycle", "Network", "Snapshot", "Scooter", "Economy", "Shop", "Quests", "PlayerData"}
for _, key in order do context.Services[key]:Init(context) end
for _, key in order do context.Services[key]:Start() end
game:BindToClose(function()
    context.IsClosing = true
    if context.Services.Scooter then context.Services.Scooter:Shutdown() end
end)
local info = require(shared:WaitForChild("ProjectInfo"))
local saveMode = if RunService:IsStudio() and not context.Config.Game.UseStudioDataStore then "StudioMemory" else "DataStore"
print(string.format("[%s][server] PHASE %d ready (version %s). Save mode: %s", info.Name, context.Config.Game.Phase, info.Version, saveMode))
