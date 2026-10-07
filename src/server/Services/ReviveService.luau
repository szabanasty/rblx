--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Service = {}
local context: any
local holds: {[Player]: any} = {}
local reserved: {[Player]: Player} = {}
function Service:Init(ctx: any) context = ctx end
local function valid(player: Player, target: Player): boolean
    local source = context.Services.State:GetRecord(player)
    local victim = context.Services.State:GetRecord(target)
    if not source or not victim or not source.Ready or not victim.Ready or source.DownedUntil > 0 or victim.DownedUntil <= os.clock()
        or source.Fishing or context.Services.Scooter:GetTelemetry(player).Riding or not context.Services.Squad:Same(player, target) then return false end
    local a, b = context.Services.Movement:GetPosition(player), context.Services.Movement:GetPosition(target)
    if not a or not b or (a - b).Magnitude > context.Config.Combat.ReviveRangeStuds then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character :: Model, target.Character :: Model}
    return Workspace:Raycast(a, b - a, params) == nil
end
function Service:Cancel(player: Player)
    local hold = holds[player]
    if not hold then return end
    holds[player] = nil
    reserved[hold.Target] = nil
    local state = context.Services.State:GetRecord(player)
    if state then state.Reviving = false; context.Services.State:Changed(player) end
end
function Service:CancelFor(player: Player)
    self:Cancel(player)
    local owner = reserved[player]
    if owner then self:Cancel(owner) end
end
function Service:Hold(player: Player, targetId: number): (boolean, string)
    local target = Players:GetPlayerByUserId(targetId)
    if not target or player == target or not valid(player, target) then self:Cancel(player); return false, "ReviveUnavailable" end
    if reserved[target] and reserved[target] ~= player then return false, "ReviveBusy" end
    local hold = holds[player]
    if hold and hold.Target ~= target then self:Cancel(player); hold = nil end
    if not hold then
        hold = {Target = target, StartedAt = os.clock(), LastHold = os.clock()}
        holds[player], reserved[target] = hold, player
        context.Services.State:GetRecord(player).Reviving = true
    end
    hold.LastHold = os.clock()
    return true, "Reviving"
end
function Service:GetSnapshot(player: Player): any
    local hold = holds[player]
    local source = if hold then player else reserved[player]
    local active = if source then holds[source] else nil
    return if active then {Progress = math.clamp((os.clock() - active.StartedAt) / context.Config.Combat.ReviveSeconds, 0, 1), Target = active.Target.UserId} else nil
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) self:CancelFor(player) end)
    local elapsed = 0
    game:GetService("RunService").Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.1 then return end
        elapsed = 0
        for player, hold in holds do
            if os.clock() - hold.LastHold > 0.9 or not valid(player, hold.Target) then self:Cancel(player); continue end
            if os.clock() - hold.StartedAt < context.Config.Combat.ReviveSeconds then continue end
            local target = hold.Target
            local encounter = context.Services.Combat:GetEncounter(target)
            local state = context.Services.State:GetRecord(target)
            if state and encounter and context.StateRules.Revive(state, os.clock(), context.Config.Combat) then
                context.Services.Combat:CancelEncounter(target)
                context.Services.PvPRewards:Revive(player, target, encounter.Id)
                context.Services.State:Changed(target)
                context.Feedback(target, true, "Revived")
            end
            self:Cancel(player)
        end
    end)
end
return Service
