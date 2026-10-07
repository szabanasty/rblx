--!strict
local ShopService = {}
local context: any
function ShopService:Init(ctx: any) context = ctx end
function ShopService:Start() end
local function eligible(player: Player, location: string): (any?, string)
    if context.Services.State and not context.Services.State:IsAllowed(player, "Trade") then return nil, "VisitSafeZone" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return nil, "DataNotReady" end
    if context.Services.Scooter:GetTelemetry(player).Riding then return nil, "DismountFirst" end
    if not context.Services.World:IsNear(player, location) then return nil, "VisitShop" end
    return profile, ""
end
function ShopService:BuyScooter(player: Player, id: string): (boolean, string)
    if type(id) ~= "string" then return false, "InvalidScooter" end
    local profile, message = eligible(player, "ScooterShop")
    if not profile then return false, message end
    local item = context.Config.Scooters.ById[id]
    if not item then return false, "InvalidScooter" end
    if profile.OwnedScooters[id] then return false, "AlreadyOwned" end
    if profile.Level < item.UnlockLevel then return false, "LevelTooLow" end
    if item.Price > 0 then
        local paid, reason = context.Services.Economy:Spend(player, item.Price)
        if not paid then return false, reason end
    end
    -- All operations above and below are nonyielding; purchase state is atomic.
    profile.OwnedScooters[id] = true
    profile.SelectedScooter = id
    context.Services.PlayerData:MarkDirty(player)
    context.Notify(player)
    return true, "ScooterPurchased"
end
function ShopService:Upgrade(player: Player, id: string, category: string): (boolean, string)
    if type(id) ~= "string" or type(category) ~= "string" then return false, "InvalidUpgrade" end
    local profile, message = eligible(player, "UpgradeShop")
    if not profile then return false, message end
    if not context.Config.Scooters.ById[id] or not profile.OwnedScooters[id] then return false, "ScooterNotOwned" end
    local categoryData = context.Config.Upgrades.Categories[category]
    if categoryData and categoryData.Enabled == false then return false, "UpgradeUnavailable" end
    local levels = profile.ScooterUpgrades[id]
    if type(levels) ~= "table" then levels = {} end
    local current = levels[category] or 0
    if type(current) ~= "number" then return false, "InvalidUpgradeState" end
    local price, requiredLevel = context.Stats.NextUpgrade(category, current, context.Config.Upgrades)
    if not price or not requiredLevel then return false, "UpgradeMaxOrInvalid" end
    if profile.Level < requiredLevel then return false, "LevelTooLow" end
    local paid, reason = context.Services.Economy:Spend(player, price)
    if not paid then return false, reason end
    levels[category] = current + 1
    profile.ScooterUpgrades[id] = levels
    context.Services.PlayerData:MarkDirty(player)
    context.Services.Scooter:RefreshStats(player)
    context.Notify(player)
    return true, "UpgradePurchased"
end
return ShopService
