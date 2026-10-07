--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local QuestService = {}
local context: any
type Active = {Id: string, Token: string, Started: number, Baseline: number}
local active: {[Player]: Active} = {}
local startTimes: {[Player]: number} = {}
function QuestService:Init(ctx: any) context = ctx end
function QuestService:StartQuest(player: Player, id: string): (boolean, string)
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return false, "DataNotReady" end
    local quest = if type(id) == "string" then context.Config.Quests[id] else nil
    if not quest then return false, "InvalidQuest" end
    if active[player] then return false, "QuestAlreadyActive" end
    if profile.Level < quest.UnlockLevel then return false, "LevelTooLow" end
    if not context.Services.World:IsNear(player, quest.StartLocation) then return false, "VisitDeliveryHub" end
    if os.time() < (profile.QuestCooldowns[id] or 0) then return false, "QuestCooldown" end
    local now = os.clock()
    if now - (startTimes[player] or -math.huge) < 2 then return false, "QuestStartCooldown" end
    startTimes[player] = now
    active[player] = {Id = id, Token = HttpService:GenerateGUID(false), Started = now, Baseline = context.Services.Scooter:GetTelemetry(player).Distance}
    context.Notify(player)
    return true, "QuestStarted"
end
function QuestService:Cancel(player: Player): (boolean, string)
    if not active[player] then return false, "NoActiveQuest" end
    active[player] = nil
    context.Notify(player)
    return true, "QuestCancelled"
end
function QuestService:GetSnapshot(player: Player): any
    local state = active[player]
    if not state then return nil end
    local quest = context.Config.Quests[state.Id]
    local target = context.Services.World:GetLocation(quest.TargetLocation)
    if not target then return nil end
    local distance = math.max(0, context.Services.Scooter:GetTelemetry(player).Distance - state.Baseline)
    return {
        Id = quest.Id, Name = quest.Name, Description = quest.Description,
        RemainingSeconds = math.max(0, math.ceil(quest.TimeLimitSeconds - (os.clock() - state.Started))),
        DistanceMeters = math.floor(distance), RequiredDistance = quest.MinimumRideMeters,
        Target = {X = target.X, Y = target.Y, Z = target.Z},
    }
end
function QuestService:Check(player: Player)
    local state = active[player]
    local profile = context.Services.PlayerData:GetProfile(player)
    if not state or not profile then return end
    local quest = context.Config.Quests[state.Id]
    local elapsed = os.clock() - state.Started
    if elapsed > quest.TimeLimitSeconds then
        active[player] = nil
        context.Notify(player)
        return
    end
    local telemetry = context.Services.Scooter:GetTelemetry(player)
    if not telemetry.Riding or telemetry.Distance - state.Baseline < quest.MinimumRideMeters or elapsed < quest.MinimumSeconds then return end
    local position = context.Services.Scooter:GetPosition(player)
    local target = context.Services.World:GetLocation(quest.TargetLocation)
    if not position or not target then return end
    local dx, dy, dz = position.X - target.X, position.Y - target.Y, position.Z - target.Z
    local radius = context.Config.World.Locations[quest.TargetLocation].Radius
    if dx * dx + dy * dy + dz * dz > radius * radius then return end
    -- Completion is inferred from trusted server telemetry, never client claims.
    local success, reason = context.Services.Economy:Reward(player, "Delivery", quest.Money, quest.XP, quest.Reputation, "quest:" .. state.Token)
    active[player] = nil
    if success then
        profile.QuestCooldowns[state.Id] = os.time() + quest.CooldownSeconds
        profile.Statistics.DeliveriesCompleted = math.min(2000000000, profile.Statistics.DeliveriesCompleted + 1)
        context.Services.PlayerData:MarkDirty(player)
    end
    context.Remotes.Feedback:FireClient(player, {RequestId = 0, Success = success, Message = if success then "DeliveryCompleted" else reason})
    context.Notify(player)
end
function QuestService:Start()
    Players.PlayerRemoving:Connect(function(player: Player) active[player] = nil; startTimes[player] = nil end)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.5 then return end
        elapsed = 0
        for player in active do self:Check(player) end
    end)
end
return QuestService
