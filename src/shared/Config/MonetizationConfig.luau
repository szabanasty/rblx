--!strict
-- Create these offers for THIS experience in Creator Dashboard. Zero never prompts/charges.
return table.freeze({
    Enabled = false,
    BaseGaragePresets = 1, VIPExtraPresets = 2, GarageExtraPresets = 3, MaxGaragePresets = 6,
    VIPXPBonus = 0.05, MaxUpgradeCredits = 1000000, MaxReceipts = 10000,
    Order = {"EliteScooter", "EliteWeapon", "VIP", "NeonStyle", "GarageSlots", "SeasonRiverside", "UpgradeCredit", "UpgradePack"},
    Offers = {
        EliteScooter = {Kind = "Pass", Id = 0, Name = "Volt Elite", Description = "65 km/h, acceleration 6, battery 160. Stała własność hulajnogi.", ScooterId = "volt_elite"},
        EliteWeapon = {Kind = "Pass", Id = 0, Name = "Flux Elite", Description = "22 damage, cooldown 0.32 s, 16 nabojów. Stała własność wyposażenia.", EquipmentId = "flux_elite"},
        VIP = {Kind = "Pass", Id = 0, Name = "VIP", Description = "Tag i kamizelka VIP, +5% XP, +2 zapisane konfiguracje garażu.", Cosmetics = {"Tag:vip", "Clothing:VIP"}},
        NeonStyle = {Kind = "Pass", Id = 0, Name = "Gold / Neon Style", Description = "Złoty kolor, światła i efekt hulajnogi, kamizelka oraz tag NEON.", Cosmetics = {"Color:Gold", "Lights:Gold", "Effects:Gold", "Clothing:Neon", "Tag:neon"}},
        GarageSlots = {Kind = "Pass", Id = 0, Name = "+3 presety garażu", Description = "Zapisuj i przywracaj wybór hulajnogi oraz jej kosmetyki."},
        SeasonRiverside = {Kind = "Pass", Id = 0, Name = "Karnet Riverside • premium", Description = "Premium nagrody sezonu Riverside 01. Poziomy zdobywasz grając.", SeasonId = "RIVERSIDE_01"},
        UpgradeCredit = {Kind = "Product", Id = 0, Name = "1 kredyt Workshop", Description = "Jedno ulepszenie bez kosztu Money. Wymagany Level i maksimum 5 pozostają.", Credits = 1},
        UpgradePack = {Kind = "Product", Id = 0, Name = "5 kredytów Workshop", Description = "Pięć kredytów na ulepszenia własnych hulajnóg.", Credits = 5},
    },
})
