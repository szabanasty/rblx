--!strict
local Service = {}
local context: any
function Service:Init(ctx: any)
    local cfg = ctx.Config.Season
    assert(ctx.Validation.IsInteger(cfg.Tiers, 1, 64) and ctx.Validation.IsInteger(cfg.XPPerTier, 1, 1000000), "Invalid season progression")
    assert(cfg.Tiers * cfg.XPPerTier <= 1000000 and ctx.Validation.IsInteger(cfg.DailyXPCap, 1, 1000000), "Season XP must fit the saved schema")
    local offer = ctx.Config.Monetization.Offers[cfg.PremiumOfferKey]
    assert(offer and offer.Kind == "Pass" and offer.SeasonId == cfg.Id, "Each season needs its own matching premium pass key")
    context = ctx
end
function Service:Start() end
local function state(player: Player): (any?, any?)
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return nil, nil end
    local changed = profile.Season.Id ~= context.Config.Season.Id
    local season = context.CommerceRules.Season(profile, context.Config.Season)
    if changed then context.Services.PlayerData:MarkDirty(player) end
    return profile, season
end
function Service:AddXP(player: Player, amount: number)
    local cfg = context.Config.Season
    if not context.Validation.IsInteger(amount, 1, 1000000) or not context.CommerceRules.Active(cfg, os.time()) then return end
    local profile, season = state(player)
    if not profile or not season then return end
    local day = math.floor(os.time() / 86400)
    if season.Day ~= day then season.Day, season.DailyXP = day, 0 end
    local granted = math.min(amount, math.max(0, cfg.DailyXPCap - season.DailyXP), math.max(0, cfg.Tiers * cfg.XPPerTier - season.XP))
    if granted <= 0 then return end
    season.XP += granted; season.DailyXP += granted
    context.Services.PlayerData:MarkDirty(player)
end
function Service:Claim(player: Player, tier: number, track: string): (boolean, string)
    local cfg = context.Config.Season
    if not context.CommerceRules.Active(cfg, os.time()) then return false, "SeasonEnded" end
    if not context.Validation.IsInteger(tier, 1, cfg.Tiers) or (track ~= "Free" and track ~= "Premium") then return false, "InvalidSeasonReward" end
    if not context.Services.State:IsAllowed(player, "Trade") then return false, "VisitSafeZone" end
    local profile, season = state(player)
    if not profile or not season then return false, "DataNotReady" end
    if track == "Premium" and not profile.Entitlements[cfg.PremiumOfferKey] then return false, "PremiumSeasonRequired" end
    if season.XP < tier * cfg.XPPerTier then return false, "SeasonLevelTooLow" end
    local claims = if track == "Free" then season.FreeClaims else season.PremiumClaims
    if claims[tostring(tier)] then return false, "AlreadyClaimed" end
    local reward = cfg.Rewards[tier][track]
    if reward.Money then
        local ok, reason = context.Services.Economy:Credit(player, reward.Money, "Season", "season:" .. cfg.Id .. ":" .. track .. ":" .. tier)
        if not ok then return false, reason end
    elseif reward.Credits then
        if profile.UpgradeCredits + reward.Credits > context.Config.Monetization.MaxUpgradeCredits then return false, "CreditLimit" end
        profile.UpgradeCredits += reward.Credits
    elseif reward.Cosmetic then profile.Cosmetics[reward.Cosmetic] = true
    else return false, "InvalidSeasonReward" end
    claims[tostring(tier)] = true
    context.Services.PlayerData:MarkDirty(player); context.Notify(player)
    return true, "SeasonRewardClaimed"
end
function Service:GetSnapshot(player: Player): any
    local profile, season = state(player)
    if not profile or not season then return nil end
    local cfg = context.Config.Season
    return {Id = cfg.Id, Name = cfg.Name, Active = context.CommerceRules.Active(cfg, os.time()), EndsAt = cfg.EndsAt,
        XP = season.XP, Level = math.min(cfg.Tiers, math.floor(season.XP / cfg.XPPerTier)), Tiers = cfg.Tiers,
        XPPerTier = cfg.XPPerTier, Premium = profile.Entitlements[cfg.PremiumOfferKey] == true,
        FreeClaims = table.clone(season.FreeClaims), PremiumClaims = table.clone(season.PremiumClaims)}
end
return Service
