--!nonstrict
return function(loadEquipment, loadCosmetics, loadEconomy, loadSeason, Rules, Schema, Validation, GameConfig,
    MonetizationConfig, SeasonConfig, EquipmentConfig, ScooterConfig, Cosmetics, Progression, LevelConfig, RewardConfig, EconomyConfig)
    local M = require("../RuntimeMocks")
    local world = M.World()
    local player = world.Player(123, 0)
    player.FindFirstChild = function() return nil end
    local profile = Schema.new(123, GameConfig)
    local ready, safe, near = true, true, true
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local ctx = {Config = {Monetization = MonetizationConfig, Season = SeasonConfig, Equipment = EquipmentConfig,
        Scooters = ScooterConfig, Cosmetics = Cosmetics, Levels = LevelConfig, Rewards = RewardConfig, Economy = EconomyConfig},
        CommerceRules = Rules, Validation = Validation, Progression = Progression, Notify = function() end,
        Services = {PlayerData = {GetProfile = function() return if ready then profile else nil end, IsReady = function() return ready end, MarkDirty = function() end},
            State = {IsAllowed = function() return safe end}, World = {IsNear = function() return near end},
            Scooter = {GetTelemetry = function() return {Riding = false} end, RefreshAppearance = function() end}}}
    local equipment = loadEquipment(world.Game, world.Clock); equipment:Init(ctx)
    local cosmetics = loadCosmetics(); cosmetics:Init(ctx)
    local before = profile.Money
    check(select(2, equipment:Buy(player, "flux_elite")) == "RobuxPurchaseRequired" and not profile.OwnedEquipment.flux_elite and profile.Money == before, "zero Money price cannot acquire paid weapon")
    check(not equipment:Equip(player, "PRIMARY", "flux_elite"), "paid weapon equip requires ownership")
    check(select(2, cosmetics:Buy(player, "Color", "Gold")) == "RobuxPurchaseRequired" and not profile.Cosmetics["Color:Gold"], "paid color cannot be bought for Money")
    check(select(2, cosmetics:Buy(player, "Clothing", "VIP")) == "RobuxPurchaseRequired", "zero-priced VIP clothing cannot bypass pass")
    check(select(2, cosmetics:Buy(player, "Tag", "vip")) == "RobuxPurchaseRequired", "zero-priced VIP tag cannot bypass pass")
    check(not cosmetics:Buy(player, "Clothing", "missing"), "invalid cosmetic safely rejected")
    Rules.Grant(profile, "EliteWeapon", MonetizationConfig.Offers.EliteWeapon, MonetizationConfig)
    check(equipment:Equip(player, "PRIMARY", "flux_elite"), "verified premium weapon can equip")
    local item = equipment:Consume(player)
    check(item == EquipmentConfig.ById.flux_elite and item.Damage == 22 and equipment:GetSnapshot(player).Ammo == 15, "actual weapon service consumes ammo and yields server-defined 22 damage")
    check(equipment:Consume(player) == nil, "premium weapon still respects authoritative cooldown")
    world.Tick(0.31); check(equipment:Consume(player) == nil, "premium cooldown cannot be bypassed early")
    world.Tick(0.02); check(equipment:Consume(player) == EquipmentConfig.ById.flux_elite, "configured 0.32 second premium cadence works")
    Rules.Grant(profile, "NeonStyle", MonetizationConfig.Offers.NeonStyle, MonetizationConfig)
    check(cosmetics:Buy(player, "Color", "Gold") and profile.ScooterCustomization[profile.SelectedScooter].Color == "Gold", "verified paid color equips")
    Rules.Grant(profile, "VIP", MonetizationConfig.Offers.VIP, MonetizationConfig)
    check(cosmetics:Buy(player, "Clothing", "VIP") and profile.EquippedClothing == "VIP", "verified VIP clothing equips")
    check(cosmetics:Buy(player, "Tag", "vip") and profile.EquippedTag == "vip", "verified VIP tag equips")
    check(profile.Money == before, "equipping paid owned cosmetics never adds or removes Money")
    ready = false
    check(select(2, equipment:Buy(player, "spark")) == "DataNotReady" and select(2, equipment:Equip(player, "PRIMARY", "flux_elite")) == "DataNotReady"
        and select(2, cosmetics:Buy(player, "Tag", "vip")) == "DataNotReady", "lost profile handled without runtime failure")
    ready = true
    local instance = {new = function(class)
        local value = {Name = "", Children = {}}
        function value:IsA(other) return class == other end
        function value:FindFirstChild(name) return self.Children[name] end
        return value
    end}
    local economy = loadEconomy(world.Game, instance); economy:Init(ctx)
    local season = loadSeason(os); season:Init(ctx)
    ctx.Services.Economy, ctx.Services.Season = economy, season
    check(economy:Reward(player, "PvP", 0, 200, 0, "verified-reward") and profile.RewardBudget.XP == 210 and profile.Season.XP == 210, "VIP adds 5% verified XP and same accepted amount progresses season")
    check(not economy:Reward(player, "PvP", 0, 200, 0, "verified-reward") and profile.Season.XP == 210, "reward replay cannot farm season XP")
    profile.Level = LevelConfig.MaxLevel; profile.XP = 0
    check(economy:Reward(player, "PvP", 0, 200, 0, "max-level") and profile.XP == 0 and profile.Season.XP == 420, "season remains playable at maximum character level")
    profile.RewardBudget.XP = RewardConfig.DailyXPCap
    check(not economy:Reward(player, "PvP", 0, 200, 0, "daily-cap") and profile.Season.XP == 420, "daily verified XP cap also prevents season farming")
    print("Paid catalog and XP integration checks passed: " .. checks)
end
