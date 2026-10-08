--!nonstrict
return function(loadSeason, loadGarage, Rules, Schema, Validation, GameConfig, SeasonConfig, MonetizationConfig, ScooterConfig, Cosmetics)
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local now = 864000
    local cfg = table.clone(SeasonConfig)
    local profile = Schema.new(123, GameConfig)
    local ready, safe, near, riding, paid = true, true, true, false, true
    local dirty, credited = 0, 0
    local ctx = {Config = {Season = cfg, Monetization = MonetizationConfig, Scooters = ScooterConfig, Cosmetics = Cosmetics},
        CommerceRules = Rules, Schema = Schema, Validation = Validation, Notify = function() end,
        Services = {PlayerData = {GetProfile = function() return if ready then profile else nil end, MarkDirty = function() dirty += 1 end},
            State = {IsAllowed = function() return safe end}, World = {IsNear = function() return near end},
            Scooter = {GetTelemetry = function() return {Riding = riding} end, RefreshAppearance = function() end,
                Select = function(_, _, id)
                    if not ScooterConfig.ById[id] or not profile.OwnedScooters[id] then return false, "ScooterNotOwned" end
                    profile.SelectedScooter = id; return true, "ScooterSelected"
                end},
            Economy = {Credit = function(_, _, amount, source)
                assert(source == "Season")
                if not paid then return false, "DailyLimit" end
                profile.Money += amount; credited += amount; return true, "Granted"
            end}}}
    local season = loadSeason({time = function() return now end}); season:Init(ctx)
    check(season:GetSnapshot({}).Level == 0 and profile.Season.Id == cfg.Id, "season initializes new profile")
    for _, amount in {0, -1, 0/0, math.huge, 1.2, "200"} do season:AddXP({}, amount) end
    check(profile.Season.XP == 0, "invalid trusted XP input ignored")
    check(select(2, season:Claim({}, 1, "Free")) == "SeasonLevelTooLow", "locked tier cannot claim")
    season:AddXP({}, 200)
    paid = false
    check(select(2, season:Claim({}, 1, "Free")) == "DailyLimit" and not profile.Season.FreeClaims["1"], "failed Money credit does not consume reward")
    paid = true
    check(season:Claim({}, 1, "Free") and profile.Season.FreeClaims["1"] and credited == 100, "free reward records claim only after successful grant")
    check(not season:Claim({}, 1, "Free") and credited == 100, "permanent tier claim blocks replay")
    check(select(2, season:Claim({}, 1, "Premium")) == "PremiumSeasonRequired", "premium track requires verified entitlement")
    profile.Entitlements[cfg.PremiumOfferKey] = true
    check(season:Claim({}, 1, "Premium") and profile.UpgradeCredits == 1, "premium tier grants upgrade credit")
    check(not season:Claim({}, 1, "Premium") and profile.UpgradeCredits == 1, "premium credit cannot claim twice")
    season:AddXP({}, 1000000); season:AddXP({}, 200)
    check(profile.Season.XP == cfg.DailyXPCap and profile.Season.DailyXP == cfg.DailyXPCap, "daily season XP cap")
    check(season:Claim({}, 4, "Free") and profile.Cosmetics["Color:Violet"], "free cosmetic grant")
    check(season:Claim({}, 4, "Premium") and profile.Cosmetics["Lights:Gold"], "premium cosmetic grant")
    safe = false
    check(select(2, season:Claim({}, 2, "Free")) == "VisitSafeZone", "season claim denied while trade blocked")
    safe = true
    profile.UpgradeCredits = MonetizationConfig.MaxUpgradeCredits
    check(select(2, season:Claim({}, 2, "Premium")) == "CreditLimit" and not profile.Season.PremiumClaims["2"], "full credit wallet retains claim")
    profile.UpgradeCredits = 1
    local snapshot = season:GetSnapshot({}); snapshot.FreeClaims["2"] = true
    check(not profile.Season.FreeClaims["2"], "public season snapshot cannot mutate private claims")
    now += 86400; season:AddXP({}, 1000000)
    now += 86400; season:AddXP({}, 1000000)
    check(profile.Season.XP == cfg.Tiers * cfg.XPPerTier and season:GetSnapshot({}).Level == cfg.Tiers, "season tier maximum enforced")
    check(season:Claim({}, 12, "Free") and profile.UpgradeCredits == 2, "final free tier credit")
    cfg.EndsAt = now
    local before = profile.Season.XP
    check(select(2, season:Claim({}, 2, "Free")) == "SeasonEnded", "expired season denies claims")
    season:AddXP({}, 100); check(profile.Season.XP == before, "expired season denies new XP")
    cfg.EndsAt = 0; cfg.Id = "RIVERSIDE_02"; cfg.PremiumOfferKey = "SeasonNext"
    snapshot = season:GetSnapshot({})
    check(snapshot.Level == 0 and not snapshot.Premium and next(snapshot.FreeClaims) == nil, "new season resets progress and does not reuse old premium key")
    ready = false
    check(season:GetSnapshot({}) == nil and select(2, season:Claim({}, 1, "Free")) == "DataNotReady", "missing data handled without runtime error")
    season:AddXP({}, 200); ready = true
    local garage = loadGarage(); garage:Init(ctx)
    profile.ScooterCustomization[profile.SelectedScooter] = {Color = "Mint"}; profile.Cosmetics["Color:Mint"] = true
    check(garage:GetSnapshot({}).Slots == 1 and garage:SavePreset({}, 1), "base garage preset available")
    check(select(2, garage:SavePreset({}, 2)) == "GarageSlotLocked", "extra slots server-gated")
    check(not garage:SavePreset({}, 0/0) and not garage:LoadPreset({}, 0), "invalid slot rejected")
    profile.ScooterCustomization[profile.SelectedScooter].Color = "Red"
    check(profile.GaragePresets["1"].Customization.Color == "Mint", "saved preset is detached from current appearance")
    check(garage:LoadPreset({}, 1) and profile.ScooterCustomization[profile.SelectedScooter].Color == "Mint", "preset restores owned cosmetics")
    profile.Entitlements.VIP = true
    check(garage:GetSnapshot({}).Slots == 3 and garage:SavePreset({}, 3), "VIP grants two functional presets")
    profile.Entitlements.GarageSlots = true
    check(garage:GetSnapshot({}).Slots == 6 and garage:SavePreset({}, 6), "stacked garage pass reaches six presets")
    near = false
    check(not garage:SavePreset({}, 1), "presets need garage proximity")
    near = true; riding = true
    check(select(2, garage:LoadPreset({}, 1)) == "DismountFirst", "preset load requires dismount")
    riding = false; safe = false
    check(not garage:SavePreset({}, 1), "combat tag prevents garage operations")
    safe = true; profile.GaragePresets["2"] = {ScooterId = "volt_elite", Customization = {Color = "Gold"}}
    check(not garage:LoadPreset({}, 2) and not profile.OwnedScooters.volt_elite, "preset cannot grant premium vehicle")
    profile.OwnedScooters.volt_elite = true
    check(garage:LoadPreset({}, 2) and profile.ScooterCustomization.volt_elite.Color == nil, "preset cannot grant unowned premium cosmetic")
    profile.Cosmetics["Color:Gold"] = true
    check(garage:LoadPreset({}, 2) and profile.ScooterCustomization.volt_elite.Color == "Gold", "verified paid appearance can load")
    snapshot = garage:GetSnapshot({}); snapshot.Presets["2"].Customization.Color = "Red"
    check(profile.GaragePresets["2"].Customization.Color == "Gold", "public garage snapshot detached")
    local raw = Schema.deepCopy(profile)
    raw.GaragePresets["2"].Customization = 99; raw.UpgradeCredits = 0/0; raw.Entitlements.VIP = "true"; raw.Season.XP = math.huge
    local restored = assert(Schema.sanitize(raw, GameConfig))
    check(type(restored.GaragePresets["2"].Customization) == "table" and restored.UpgradeCredits == 0
        and restored.Entitlements.VIP == nil and restored.Season.XP == 0, "malformed commerce data sanitized safely")
    print("Season and garage checks passed: " .. checks)
end
