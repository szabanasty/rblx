--!strict
local Players = game:GetService("Players")
local Service = {}
local context: any
local function prune(history: any)
    local count = 0
    for key, entry in history do
        if entry.Until <= os.time() then history[key] = nil else count += 1 end
    end
    while count >= 64 do
        local oldest: string? = nil
        local at = math.huge
        for key, entry in history do if entry.Until < at then oldest, at = key, entry.Until end end
        if not oldest then break end
        history[oldest] = nil
        count -= 1
    end
end
function Service:Init(ctx: any) context = ctx end
local function profile(player: Player): any return context.Services.PlayerData:GetProfile(player) end
local function increment(player: Player, field: string)
    local data = profile(player)
    if data then data[field] = math.min(2000000000, data[field] + 1); context.Services.PlayerData:MarkDirty(player) end
end
local function pay(player: Player, amount: number, source: string, key: string)
    if amount > 0 then context.Services.Economy:Credit(player, amount, source, key) end
end
function Service:Settle(encounter: any)
    if encounter.Settled then return end
    encounter.Settled = true
    local cfg = context.Config.PvPRewards
    local victim, attacker = Players:GetPlayerByUserId(encounter.Victim), Players:GetPlayerByUserId(encounter.Attacker)
    if victim then increment(victim, "Deaths") end
    if not attacker or not profile(attacker) then return end
    local now = os.time()
    local history = profile(attacker).PvPOpponents
    local targetKey = tostring(encounter.Victim)
    local pair = history[targetKey]
    if not pair or pair.Until <= now then
        prune(history)
        pair = {Until = now + cfg.SameOpponentWindowSeconds, Count = 0}
        history[targetKey] = pair
    end
    pair.Count = math.min(4, pair.Count + 1)
    local multiplier = cfg.SameOpponentMultipliers[math.min(pair.Count, #cfg.SameOpponentMultipliers)]
    increment(attacker, "Kills")
    local record = context.Services.State:GetRecord(attacker)
    local bonus = 0
    if record and record.Ready and record.DownedUntil == 0 then
        record.Streak += 1
        local data = profile(attacker)
        data.BestStreak = math.max(data.BestStreak, record.Streak)
        data.CurrentStreak = record.Streak
        bonus = cfg.StreakMilestones[record.Streak] or 0
    end
    local bounty = 0
    for threshold, amount in cfg.Bounty do if encounter.VictimStreak >= threshold then bounty = math.max(bounty, amount) end end
    pay(attacker, math.floor((cfg.EliminationMoney + bonus + bounty) * multiplier), "PvP", "kill:" .. encounter.Id)
    if multiplier > 0 then context.Services.Economy:Reward(attacker, "PvPXP", 0, math.floor(40 * multiplier), 0, "xp:" .. encounter.Id) end
    for id, contribution in encounter.Contributions do
        if id == encounter.Attacker or id == encounter.Victim or encounter.At - contribution.At > cfg.AssistWindowSeconds then continue end
        local assistant = Players:GetPlayerByUserId(id)
        if assistant and profile(assistant) then
            increment(assistant, "Assists")
            pay(assistant, math.floor(cfg.AssistMoney * multiplier), "PvP", "assist:" .. encounter.Id .. ":" .. id)
            context.Notify(assistant)
        end
    end
    context.Notify(attacker)
    if victim then context.Notify(victim) end
end
function Service:Revive(player: Player, target: Player, encounterId: string)
    local data = profile(player)
    if not data then return end
    local key = tostring(target.UserId)
    local now = os.time()
    increment(player, "Revives")
    local history = data.ReviveHistory
    if not history[key] or history[key].Until <= now then
        prune(history)
        history[key] = {Until = now + context.Config.PvPRewards.RevivePairCooldownSeconds, Count = 1}
        pay(player, context.Config.PvPRewards.ReviveMoney, "Revive", "revive:" .. encounterId)
    end
    context.Notify(player)
end
function Service:Start() end
return Service
