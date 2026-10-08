--!nonstrict
return function(loadService, Schema, GameConfig, ScooterConfig, UpgradeConfig, Stats)
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local profile = Schema.new(123, GameConfig)
    local ready, near, riding = true, true, false
    local charged, refreshed, dirty = {}, 0, 0
    local ctx = {
        Config = {Scooters = ScooterConfig, Upgrades = UpgradeConfig}, Stats = Stats,
        Notify = function() end,
        Services = {
            PlayerData = {GetProfile = function() return if ready then profile else nil end, MarkDirty = function() dirty += 1 end},
            World = {IsNear = function() return near end},
            Scooter = {GetTelemetry = function() return {Riding = riding} end, RefreshStats = function() refreshed += 1 end},
            Economy = {Spend = function(_, _, price)
                table.insert(charged, price)
                if profile.Money < price then return false, "InsufficientMoney" end
                profile.Money -= price
                return true, "Paid"
            end},
        },
    }
    local shop = loadService()
    shop:Init(ctx)
    local player = {}
    check(not shop:BuyScooter(player, "fake"), "unknown catalog ID rejected")
    check(not shop:BuyScooter(player, {}), "invalid ID rejected")
    check(select(2, shop:BuyScooter(player, "kukirin_g2")) == "AlreadyOwned", "starter cannot be bought twice")
    check(select(2, shop:BuyScooter(player, "kukirin_g3")) == "LevelTooLow", "unlock level checked")
    profile.Level = 8
    check(select(2, shop:BuyScooter(player, "kukirin_g3")) == "InsufficientMoney", "insufficient funds leave ownership unchanged")
    check(not profile.OwnedScooters.kukirin_g3 and profile.Money == 100, "failed payment cannot grant scooter")
    profile.Money = 50000
    near = false
    check(select(2, shop:BuyScooter(player, "kukirin_g3")) == "VisitShop", "proximity checked on server")
    near, riding = true, true
    check(select(2, shop:BuyScooter(player, "kukirin_g3")) == "DismountFirst", "mounted purchase blocked")
    riding = false
    check(shop:BuyScooter(player, "kukirin_g3"), "valid purchase succeeds")
    check(profile.Money == 50000 - ScooterConfig.ById.kukirin_g3.Price and profile.OwnedScooters.kukirin_g3, "server price and collection applied")
    local afterBuy = profile.Money
    check(not shop:BuyScooter(player, "kukirin_g3") and profile.Money == afterBuy, "duplicate request cannot charge again")
    check(not shop:Upgrade(player, "kukirin_g4", "Motor"), "unowned upgrade rejected")
    check(not shop:Upgrade(player, "kukirin_g3", "Money"), "unknown category rejected")
    check(shop:Upgrade(player, "kukirin_g3", "Battery") and profile.ScooterUpgrades.kukirin_g3.Battery == 1, "battery capacity upgrade is now available")
    profile.Level = 1
    check(shop:Upgrade(player, "kukirin_g3", "Motor"), "first upgrade succeeds")
    check(charged[#charged] == UpgradeConfig.Categories.Motor.BasePrice and refreshed == 2, "upgrade uses configured price and refreshes physics stats")
    check(select(2, shop:Upgrade(player, "kukirin_g3", "Motor")) == "LevelTooLow", "next upgrade has higher required level")
    profile.Level = 8
    check(shop:Upgrade(player, "kukirin_g3", "Motor"), "second upgrade succeeds")
    check(shop:Upgrade(player, "kukirin_g3", "Motor"), "third upgrade succeeds")
    profile.Level = 14
    check(shop:Upgrade(player, "kukirin_g3", "Motor"), "fourth upgrade succeeds")
    check(shop:Upgrade(player, "kukirin_g3", "Motor"), "fifth upgrade succeeds")
    check(not shop:Upgrade(player, "kukirin_g3", "Motor"), "max level cannot be exceeded")
    check(profile.ScooterUpgrades.kukirin_g3.Motor == 5 and dirty == 7, "all successful purchases saved")
    local balance = profile.Money
    check(select(2, shop:BuyScooter(player, "volt_elite")) == "RobuxPurchaseRequired" and not profile.OwnedScooters.volt_elite and profile.Money == balance, "zero Money price cannot bypass paid scooter ownership")
    profile.UpgradeCredits = 2
    check(not shop:Upgrade(player, "volt_elite", "Motor", true) and profile.UpgradeCredits == 2, "credits cannot upgrade unowned models")
    check(not shop:Upgrade(player, "kukirin_g3", "Motor", true) and profile.UpgradeCredits == 2, "credits cannot bypass maximum upgrade")
    riding = true
    check(not shop:Upgrade(player, "kukirin_g3", "Brakes", true) and profile.UpgradeCredits == 2, "credit redemption needs dismount")
    riding = false; near = false
    check(not shop:Upgrade(player, "kukirin_g3", "Brakes", true) and profile.UpgradeCredits == 2, "credit redemption needs Workshop proximity")
    near = true
    check(shop:Upgrade(player, "kukirin_g3", "Brakes", true) and profile.UpgradeCredits == 1 and profile.Money == balance, "credit replaces Money charge and applies real upgrade")
    profile.Level = 1
    check(select(2, shop:Upgrade(player, "kukirin_g3", "Brakes", true)) == "LevelTooLow" and profile.UpgradeCredits == 1, "credits cannot bypass required player level")
    profile.Level = 14; profile.UpgradeCredits = 0
    check(select(2, shop:Upgrade(player, "kukirin_g3", "Brakes", true)) == "NoUpgradeCredits", "empty wallet cannot redeem")
    ready = false
    check(select(2, shop:Upgrade(player, "kukirin_g3", "Brakes")) == "DataNotReady", "unready data cannot be charged")
    print("Shop checks passed: " .. checks)
end
