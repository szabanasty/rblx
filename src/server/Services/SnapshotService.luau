--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SnapshotService = {}
local context: any
function SnapshotService:Init(ctx: any) context = ctx end
function SnapshotService:Send(player: Player)
    if player.Parent ~= Players then return end
    local data = context.Services.PlayerData
    local profile = data:GetProfile(player)
    local snapshot: any = {
        Ready = profile ~= nil,
        Status = data:GetStatus(player),
        SaveMode = if RunService:IsStudio() and not context.Config.Game.UseStudioDataStore then "StudioMemory" else "DataStore",
    }
    if profile then
        local owned: {string} = {}
        for id, isOwned in profile.OwnedScooters do
            if isOwned and context.Config.Scooters.ById[id] then table.insert(owned, id) end
        end
        table.sort(owned)
        snapshot.Money = profile.Money
        snapshot.Level = profile.Level
        snapshot.XP = profile.XP
        snapshot.XPToNextLevel = context.Progression.XPToNextLevel(profile.Level, context.Config.Levels)
        snapshot.Reputation = profile.Reputation
        snapshot.OwnedScooters = owned
        snapshot.SelectedScooter = profile.SelectedScooter
        snapshot.ScooterUpgrades = context.Schema.deepCopy(profile.ScooterUpgrades)
        snapshot.Settings = table.clone(profile.Settings)
        if context.Services.Quests then snapshot.Quest = context.Services.Quests:GetSnapshot(player) end
        local telemetry = context.Services.Scooter:GetTelemetry(player)
        snapshot.Telemetry = {Speed = telemetry.Speed, Distance = telemetry.Distance, ScooterId = telemetry.ScooterId, Riding = telemetry.Riding}
        local position = context.Services.Scooter:GetPosition(player)
        if position then
            local road = context.Services.Roads:GetRoadAt(position)
            snapshot.SpeedLimit = if road then road.SpeedLimit else 0
            snapshot.District = context.Services.Roads:GetDistrictAt(position)
        end
    end
    context.Remotes.Snapshot:FireClient(player, snapshot)
end
function SnapshotService:Start()
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 1 / context.Config.Game.SnapshotHz then return end
        elapsed = 0
        for _, player in Players:GetPlayers() do self:Send(player) end
    end)
end
return SnapshotService
