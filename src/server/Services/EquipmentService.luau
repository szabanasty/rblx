--!strict
local Players = game:GetService("Players")
local Service = {}
local context: any
local sessions: {[Player]: any} = {}
function Service:Init(ctx: any) context = ctx end
function Service:EnsureStarter(player: Player)
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return end
    local id = context.Config.Equipment.StarterEquipmentId
    if not profile.OwnedEquipment[id] then
        profile.OwnedEquipment[id] = true
        if not profile.EquippedLoadout.PRIMARY then profile.EquippedLoadout.PRIMARY = id end
        context.Services.PlayerData:MarkDirty(player)
    end
end
local function session(player: Player): any
    if not sessions[player] then sessions[player] = {Slot = "PRIMARY", Ammo = {}, ReloadUntil = 0, LastFire = -math.huge, Item = nil} end
    return sessions[player]
end
function Service:GetItem(player: Player): (any?, any)
    local state = session(player)
    local profile = context.Services.PlayerData:GetProfile(player)
    local id = if profile then profile.EquippedLoadout[state.Slot] else nil
    local item = if id and profile.OwnedEquipment[id] then context.Config.Equipment.ById[id] else nil
    if state.Item ~= id then state.ReloadUntil = 0; state.Item = id end
    if item and state.Ammo[id] == nil then state.Ammo[id] = item.Capacity end
    if item and state.ReloadUntil > 0 and os.clock() >= state.ReloadUntil then state.Ammo[id] = item.Capacity; state.ReloadUntil = 0 end
    return item, state
end
function Service:GetMobility(player: Player): number
    local item = self:GetItem(player)
    return if item then item.MobilityModifier else 1
end
function Service:Equip(player: Player, slot: string, id: string): (boolean, string)
    if slot ~= "PRIMARY" and slot ~= "SECONDARY" and slot ~= "UTILITY" then return false, "InvalidEquipment" end
    if not context.Services.State:IsAllowed(player, "Trade") then return false, "VisitSafeZone" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if id ~= "" and (not context.Config.Equipment.ById[id] or not profile.OwnedEquipment[id]) then return false, "EquipmentNotOwned" end
    -- One item cannot occupy several slots, preserving ammo across switch/equip.
    for other, equipped in profile.EquippedLoadout do if equipped == id then profile.EquippedLoadout[other] = nil end end
    profile.EquippedLoadout[slot] = if id == "" then nil else id
    context.Services.PlayerData:MarkDirty(player)
    context.Notify(player)
    return true, "EquipmentEquipped"
end
function Service:Switch(player: Player, slot: string): (boolean, string)
    if slot ~= "PRIMARY" and slot ~= "SECONDARY" and slot ~= "UTILITY" then return false, "InvalidEquipment" end
    if not context.Services.State:IsAllowed(player, "Drive") then return false, "StateBlocked" end
    local state = session(player)
    if state.ReloadUntil > os.clock() then return false, "Reloading" end
    state.Slot = slot
    self:GetItem(player)
    context.Notify(player)
    return true, "EquipmentSwitched"
end
function Service:Buy(player: Player, id: string): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Trade") or not context.Services.World:IsNear(player, "EquipmentShop") then return false, "VisitShop" end
    local item = context.Config.Equipment.ById[id]
    local profile = context.Services.PlayerData:GetProfile(player)
    if not item then return false, "InvalidEquipment" end
    if profile.OwnedEquipment[id] then return false, "AlreadyOwned" end
    if item.Price > 0 then local ok, reason = context.Services.Economy:Spend(player, item.Price); if not ok then return false, reason end end
    profile.OwnedEquipment[id] = true
    context.Services.PlayerData:MarkDirty(player); context.Notify(player)
    return true, "EquipmentPurchased"
end
function Service:Reload(player: Player): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Drive") or context.Services.Scooter:GetTelemetry(player).Riding then return false, "StateBlocked" end
    local item: any, state: any = self:GetItem(player)
    if not item then return false, "NoEquipment" end
    if state.ReloadUntil > 0 then return false, "Reloading" end
    if state.Ammo[item.EquipmentId] >= item.Capacity then return false, "MagazineFull" end
    state.ReloadUntil = os.clock() + item.ReloadDuration
    context.Notify(player)
    return true, "Reloading"
end
function Service:Consume(player: Player): (any?, string)
    local item: any, state: any = self:GetItem(player)
    if not item then return nil, "NoEquipment" end
    if state.ReloadUntil > 0 then return nil, "Reloading" end
    if os.clock() - state.LastFire < item.Cooldown then return nil, "FireCooldown" end
    if state.Ammo[item.EquipmentId] <= 0 then return nil, "ReloadRequired" end
    state.Ammo[item.EquipmentId] -= 1
    state.LastFire = os.clock()
    return item, "Fired"
end
function Service:GetSnapshot(player: Player): any
    local item: any, state: any = self:GetItem(player)
    return {Slot = state.Slot, EquipmentId = if item then item.EquipmentId else nil,
        Ammo = if item then state.Ammo[item.EquipmentId] else 0, Capacity = if item then item.Capacity else 0,
        ReloadSeconds = math.max(0, state.ReloadUntil - os.clock())}
end
function Service:Start()
    local function observe(player: Player)
        player.CharacterAdded:Connect(function() sessions[player] = nil end)
    end
    Players.PlayerAdded:Connect(observe)
    Players.PlayerRemoving:Connect(function(player: Player) sessions[player] = nil end)
    for _, player in Players:GetPlayers() do observe(player) end
end
return Service
