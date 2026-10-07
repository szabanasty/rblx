--!strict
return table.freeze({
    Width = 2800, DayLengthSeconds = 1200,
    River = {X = 520, Width = 180, WaterY = -7},
    Bridge = {X = 520, Z = 0, Length = 220, Width = 46, DeckTop = 0.3},
    Spawn = {X = -25, Z = 60},
    Locations = {
        Garage = {X = -180, Z = -58, Radius = 60}, ScooterShop = {X = -80, Z = -58, Radius = 60},
        UpgradeShop = {X = 30, Z = -58, Radius = 60}, EquipmentShop = {X = 145, Z = -58, Radius = 60},
        CosmeticsShop = {X = -180, Z = 145, Radius = 60},
        FishingDock = {X = -340, Z = 355, Radius = 14}, FishBuyer = {X = -340, Z = 285, Radius = 55},
    },
    Objective = {X = 1050, Z = 0, Radius = 24, HoldSeconds = 30, CooldownSeconds = 180, MinimumMembers = 2, Reward = 150},
})
