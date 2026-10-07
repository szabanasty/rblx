--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Service = {}
local context: any
local sessions: {[Player]: any} = {}
local revisions: {[Player]: number} = {}
local rng = Random.new()
function Service:Init(ctx: any) context = ctx end
local function revision(player: Player): number
    if not revisions[player] then revisions[player] = 1 end
    return revisions[player]
end
function Service:Stop(player: Player): (boolean, string)
    sessions[player] = nil
    local record = context.Services.State:GetRecord(player)
    if record then record.Fishing = false; context.Services.State:Changed(player) end
    return true, "FishingStopped"
end
local function eligible(player: Player): boolean
    return context.Services.State:IsAllowed(player, "Fish") and context.Services.World:IsNear(player, "FishingDock")
        and not context.Services.Scooter:GetTelemetry(player).Riding
end
function Service:Toggle(player: Player): (boolean, string)
    if sessions[player] then return self:Stop(player) end
    if not eligible(player) then return false, "VisitFishingDock" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if #profile.FishingInventory >= context.Config.Fishing.InventoryLimit then return false, "InventoryFull" end
    local now = os.clock()
    sessions[player] = {Id = HttpService:GenerateGUID(false), StartedAt = now, NextAt = now + rng:NextNumber(context.Config.Fishing.MinimumWaitSeconds, context.Config.Fishing.MaximumWaitSeconds), Sequence = 0}
    context.Services.State:GetRecord(player).Fishing = true
    context.Services.State:Changed(player)
    return true, "FishingStarted"
end
function Service:Sell(player: Player, index: number, expectedRevision: number): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Drive") or not context.Services.World:IsNear(player, "FishBuyer") then return false, "VisitFishBuyer" end
    local state = context.Services.State:GetRecord(player)
    if state.TaggedUntil > os.clock() or context.Services.Scooter:GetTelemetry(player).Riding then return false, "StateBlocked" end
    if expectedRevision ~= revision(player) then return false, "InventoryChanged" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if index > #profile.FishingInventory then return false, "InvalidFish" end
    local retained, amount, count = {}, 0, 0
    for position, fish in profile.FishingInventory do
        local value = context.FishingRules.Value(fish, context.Config.Fishing)
        if (index == 0 or index == position) and value then amount += value; count += 1
        else table.insert(retained, fish) end
    end
    if count == 0 then return false, "NoFish" end
    local key = "fish:" .. HttpService:GenerateGUID(false)
    -- Credit and inventory replacement are nonyielding and share one saved profile.
    local success, message = context.Services.Economy:Credit(player, amount, "Fishing", key)
    if not success then return false, message end
    profile.FishingInventory = retained
    revisions[player] = revision(player) + 1
    context.Services.PlayerData:MarkDirty(player)
    context.Services.Economy:Reward(player, "FishingSaleXP", 0, count * 5, 0, "xp:" .. key)
    context.Notify(player)
    return true, "FishSold"
end
function Service:GetSnapshot(player: Player): any
    local profile = context.Services.PlayerData:GetProfile(player)
    local fish: {any} = {}
    if profile then
        for index, entry in profile.FishingInventory do
            table.insert(fish, {Index = index, FishId = entry.FishId, Weight = entry.Weight, Rarity = entry.Rarity,
                Value = context.FishingRules.Value(entry, context.Config.Fishing) or 0})
        end
    end
    local session = sessions[player]
    return {Active = session ~= nil, WaitSeconds = if session then math.max(0, math.ceil(session.NextAt - os.clock())) else 0,
        LastCatch = if session then session.LastCatch else nil, Revision = revision(player), Inventory = fish, Limit = context.Config.Fishing.InventoryLimit}
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) sessions[player], revisions[player] = nil, nil end)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.5 then return end
        elapsed = 0
        for player, session in sessions do
            local profile = context.Services.PlayerData:GetProfile(player)
            if not profile or not eligible(player) or os.clock() - session.StartedAt >= context.Config.Fishing.MaximumSessionSeconds then self:Stop(player); continue end
            if #profile.FishingInventory >= context.Config.Fishing.InventoryLimit then self:Stop(player); context.Feedback(player, false, "InventoryFull"); continue end
            if os.clock() < session.NextAt then continue end
            session.Sequence += 1
            session.NextAt = os.clock() + rng:NextNumber(context.Config.Fishing.MinimumWaitSeconds, context.Config.Fishing.MaximumWaitSeconds)
            local fish = context.FishingRules.Roll(rng, context.Config.Fishing)
            if fish then
                session.LastCatch = fish
                table.insert(profile.FishingInventory, fish)
                revisions[player] = revision(player) + 1
                context.Services.PlayerData:MarkDirty(player)
                context.Feedback(player, true, "FishCaught")
                context.Notify(player)
            else context.Feedback(player, true, "FishingMiss") end
        end
    end)
end
return Service
