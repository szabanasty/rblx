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
        Mode = if context.Config.Game.FoundationOnly then "Foundation" else "LegacyCity",
        Phase = context.Config.Game.Phase,
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
        snapshot.Kills = profile.Kills
        snapshot.Deaths = profile.Deaths
        snapshot.Assists = profile.Assists
        snapshot.Revives = profile.Revives
        snapshot.BestStreak = profile.BestStreak
        snapshot.FishingInventoryCount = #profile.FishingInventory
        snapshot.OwnedEquipment = context.Schema.deepCopy(profile.OwnedEquipment)
        snapshot.EquippedLoadout = table.clone(profile.EquippedLoadout)
        if context.Services.PlayerState then snapshot.PlayerState = context.Services.PlayerState:GetPublic(player) end
        if context.Services.Quests then snapshot.Quest = context.Services.Quests:GetSnapshot(player) end
        local telemetry = if context.Services.Scooter then context.Services.Scooter:GetTelemetry(player) else {Speed = 0, Distance = 0, Riding = false}
        snapshot.Telemetry = {Speed = telemetry.Speed, Distance = telemetry.Distance, ScooterId = telemetry.ScooterId, Riding = telemetry.Riding}
        local position = if context.Services.Scooter then context.Services.Scooter:GetPosition(player) else nil
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
