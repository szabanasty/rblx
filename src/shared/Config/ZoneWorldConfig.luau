--!strict
return table.freeze({
    Width = 800, DayLengthSeconds = 1200,
    Locations = {
        Garage = {X = -45, Z = -40, Radius = 22}, ScooterShop = {X = 45, Z = -40, Radius = 22},
        UpgradeShop = {X = 45, Z = 45, Radius = 22}, EquipmentShop = {X = -45, Z = 45, Radius = 22},
        CosmeticsShop = {X = 0, Z = 55, Radius = 18},
        FishingDock = {X = -220, Z = 160, Radius = 12}, FishBuyer = {X = -220, Z = 110, Radius = 18},
    },
    Objective = {X = 220, Z = 0, Radius = 24, HoldSeconds = 30, CooldownSeconds = 180, MinimumMembers = 2, Reward = 150},
})
