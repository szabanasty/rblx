--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local controllerFolder = script:WaitForChild("Controllers")
local context: any = {
    Config = {
        Game = require(config:WaitForChild("GameConfig")),
        Scooters = require(config:WaitForChild("ScooterConfig")),
        World = require(config:WaitForChild("WorldConfig")),
        Upgrades = require(config:WaitForChild("UpgradeConfig")),
        Quests = require(config:WaitForChild("QuestConfig")),
        Equipment = require(config:WaitForChild("EquipmentConfig")),
        Zones = require(config:WaitForChild("ZoneConfig")),
        Combat = require(config:WaitForChild("CombatConfig")),
        Cosmetics = require(config:WaitForChild("CosmeticConfig")),
        Messages = require(config:WaitForChild("MessageConfig")),
    },
    Player = game:GetService("Players").LocalPlayer,
    Controllers = {}, Remotes = {},
    Stats = require(shared:WaitForChild("Modules"):WaitForChild("ScooterStats")),
}
for _, name in {"Action", "Input", "Snapshot", "Feedback"} do
    context.Remotes[name] = remotes:WaitForChild(name) :: RemoteEvent
end
local nextId = 0
context.Send = function(action: string, payload: {[string]: any}?)
    nextId += 1
    context.Remotes.Action:FireServer({Action = action, Payload = payload or {}, RequestId = nextId})
end
if context.Config.Game.FoundationOnly then
    context.Controllers = {FoundationController = require(controllerFolder:WaitForChild("FoundationController"))}
elseif context.Config.Game.ZoneGame then
    context.Config.World = require(config:WaitForChild("ZoneWorldConfig"))
    context.Controllers = {
        UIController = require(controllerFolder:WaitForChild("ZoneUIController")), InputController = require(controllerFolder:WaitForChild("InputController")),
        CombatController = require(controllerFolder:WaitForChild("CombatController")), ReviveController = require(controllerFolder:WaitForChild("ReviveController")),
        SquadMarkerController = require(controllerFolder:WaitForChild("SquadMarkerController")), EffectsController = require(controllerFolder:WaitForChild("EffectsController")),
        ZoneClientController = require(controllerFolder:WaitForChild("ZoneClientController")),
    }
else
    context.Controllers = {
    UIController = require(controllerFolder:WaitForChild("UIController")),
    InputController = require(controllerFolder:WaitForChild("InputController")),
    MenuController = require(controllerFolder:WaitForChild("MenuController")),
    MinimapController = require(controllerFolder:WaitForChild("MinimapController")),
    SettingsController = require(controllerFolder:WaitForChild("SettingsController")),
    ScooterController = require(controllerFolder:WaitForChild("ScooterController")),
    }
end
local order: {string} = if context.Config.Game.FoundationOnly then {"FoundationController"}
    elseif context.Config.Game.ZoneGame then {"UIController", "InputController", "CombatController", "ReviveController", "SquadMarkerController", "EffectsController", "ZoneClientController"}
    else {"UIController", "InputController", "MenuController", "MinimapController", "SettingsController", "ScooterController"}
for _, name in order do context.Controllers[name]:Init(context) end
for _, name in order do context.Controllers[name]:Start() end
context.Send("Sync", {})
local info = require(shared:WaitForChild("ProjectInfo"))
print(string.format("[%s][client] PHASE %d ready (version %s).", info.Name, context.Config.Game.Phase, info.Version))
