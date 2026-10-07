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
        Messages = require(config:WaitForChild("MessageConfig")),
    },
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
    else {"UIController", "InputController", "MenuController", "MinimapController", "SettingsController", "ScooterController"}
for _, name in order do context.Controllers[name]:Init(context) end
for _, name in order do context.Controllers[name]:Start() end
context.Send("Sync", {})
local info = require(shared:WaitForChild("ProjectInfo"))
print(string.format("[%s][client] PHASE %d ready (version %s).", info.Name, context.Config.Game.Phase, info.Version))
