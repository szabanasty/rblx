--!strict
local Rules = {}
function Rules.GarageSlots(profile: any, cfg: any): number
    return math.min(cfg.MaxGaragePresets, cfg.BaseGaragePresets
        + (if profile.Entitlements.VIP then cfg.VIPExtraPresets else 0)
        + (if profile.Entitlements.GarageSlots then cfg.GarageExtraPresets else 0))
end
function Rules.Grant(profile: any, key: string, offer: any, cfg: any): (boolean, string)
    if offer.Kind == "Product" then
        local count = offer.Credits
        if type(count) ~= "number" or count % 1 ~= 0 or count <= 0 or profile.UpgradeCredits + count > cfg.MaxUpgradeCredits then return false, "CreditLimit" end
        profile.UpgradeCredits += count
    elseif offer.Kind == "Pass" then
        profile.Entitlements[key] = true
        if offer.ScooterId then profile.OwnedScooters[offer.ScooterId] = true end
        if offer.EquipmentId then profile.OwnedEquipment[offer.EquipmentId] = true end
        for _, id in offer.Cosmetics or {} do profile.Cosmetics[id] = true end
    else return false, "InvalidOffer" end
    return true, "PurchaseGranted"
end
function Rules.Active(cfg: any, now: number): boolean
    return cfg.Enabled and (cfg.StartsAt == 0 or now >= cfg.StartsAt) and (cfg.EndsAt == 0 or now < cfg.EndsAt)
end
function Rules.Season(profile: any, cfg: any): any
    if profile.Season.Id ~= cfg.Id then
        profile.Season = {Id = cfg.Id, XP = 0, Day = 0, DailyXP = 0, FreeClaims = {}, PremiumClaims = {}}
    end
    return profile.Season
end
return table.freeze(Rules)
