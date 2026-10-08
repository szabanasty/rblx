--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Service = {}
local context: any
local contributions: {[Player]: any} = {}
local encounters: {[Player]: any} = {}
local rng = Random.new()
function Service:Init(ctx: any) context = ctx end
function Service:Shoot(player: Player, payload: any): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Shoot") or context.Services.Scooter:GetTelemetry(player).Riding then return false, "CombatUnavailable" end
    local character = player.Character
    local head = if character then character:FindFirstChild("Head") else nil
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart") then return false, "CharacterNotReady" end
    -- Rig parts are client-simulated while walking; an origin must stay near the verified root.
    local rigOffset = (head.Position - root.Position).Magnitude
    if rigOffset ~= rigOffset or rigOffset > 8 then return false, "CharacterNotReady" end
    local item, reason = context.Services.Equipment:Consume(player)
    if not item then return false, reason end
    context.Services.State:Tag(player)
    local direction = Vector3.new(payload.X, payload.Y, payload.Z).Unit
    local spread = (1 - item.Accuracy) * (if payload.Aim then 0.12 else 0.3)
    direction = (direction + Vector3.new(rng:NextNumber(-spread, spread), rng:NextNumber(-spread, spread), rng:NextNumber(-spread, spread))).Unit
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character :: Model}
    local origin = head.Position
    local hit = Workspace:Raycast(origin, direction * item.EffectiveRange, params)
    local endpoint = if hit then hit.Position else origin + direction * item.EffectiveRange
    context.Remotes.Feedback:FireAllClients({RequestId = 0, Success = true, Message = "", Effect = "Shot", Owner = player.UserId,
        From = {X = origin.X, Y = origin.Y, Z = origin.Z}, To = {X = endpoint.X, Y = endpoint.Y, Z = endpoint.Z}})
    local target: Player? = nil
    if hit then
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        -- A valid character can contain accessory/armor Models. Stop only at its player model.
        while model do
            target = Players:GetPlayerFromCharacter(model)
            if target then break end
            model = model:FindFirstAncestorOfClass("Model")
        end
    end
    if not target or target == player or context.Services.Squad:Same(player, target) or not context.Services.State:IsAllowed(target, "Target") then return true, "Fired" end
    local record = context.Services.State:GetRecord(target)
    if not record then return true, "Fired" end
    local distance = (endpoint - origin).Magnitude
    local amount = item.Damage * (if item.Category == "CLOSE RANGE" then math.clamp(1 - distance / item.EffectiveRange * 0.6, 0.4, 1) else 1)
    local log = contributions[target]
    if not log then log = {}; contributions[target] = log end
    log[player.UserId] = {At = os.clock(), Damage = (if log[player.UserId] then log[player.UserId].Damage else 0) + amount}
    local streak = record.Streak
    local downed = context.StateRules.Damage(record, amount, os.clock(), context.Config.Combat)
    if downed then
        local profile = context.Services.PlayerData:GetProfile(target)
        if profile then profile.CurrentStreak = 0; context.Services.PlayerData:MarkDirty(target) end
        encounters[target] = {Id = HttpService:GenerateGUID(false), Attacker = player.UserId, Victim = target.UserId,
            VictimStreak = streak, Contributions = log, At = os.clock(), Paid = false}
        contributions[target] = nil
        context.Services.Scooter:Despawn(target)
        context.Services.Fishing:Stop(target)
        context.Services.Revive:CancelFor(target)
    end
    context.Services.State:Changed(target)
    context.Feedback(player, true, "HitConfirmed", {Effect = "Hit"})
    context.Feedback(target, false, "UnderAttack", {Effect = "Damage"})
    return true, "Fired"
end
function Service:Finalize(player: Player)
    local encounter = encounters[player]
    if not encounter or encounter.Paid then return end
    encounter.Paid = true
    context.Services.PvPRewards:Settle(encounter)
    encounters[player], contributions[player] = nil, nil
end
function Service:CancelEncounter(player: Player)
    encounters[player], contributions[player] = nil, nil
end
function Service:GetEncounter(player: Player): any return encounters[player] end
function Service:OnExit(player: Player)
    local record = context.Services.State:GetRecord(player)
    if record and record.Ready then
        if not encounters[player] and record.TaggedUntil > os.clock() and contributions[player] then
            local log = contributions[player]
            local latestId: number? = nil
            local latest = -math.huge
            for id, entry in log do if entry.At > latest then latestId, latest = id, entry.At end end
            if latestId and os.clock() - latest <= context.Config.PvPRewards.AssistWindowSeconds then
                encounters[player] = {Id = HttpService:GenerateGUID(false), Attacker = latestId, Victim = player.UserId,
                    VictimStreak = record.Streak, Contributions = log, At = os.clock(), Paid = false}
            end
        end
        self:Finalize(player)
        record.Streak = 0
        local profile = context.Services.PlayerData:GetProfile(player)
        if profile then profile.CurrentStreak = 0; context.Services.PlayerData:MarkDirty(player) end
    end
    contributions[player] = nil
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player)
        self:OnExit(player)
        encounters[player], contributions[player] = nil, nil
        for _, log in contributions do log[player.UserId] = nil end
    end)
end
return Service
