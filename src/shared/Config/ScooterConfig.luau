--!strict
-- Speeds: km/h; acceleration/braking: m/s²; handling: degrees/s; jump: m/s.
-- These are original block placeholders, without brand logos or imported assets.
local byId = {
    kukirin_g2 = table.freeze({
        Id = "kukirin_g2", DisplayName = "Volt Starter — placeholder", Class = "STARTER", Weight = 22, UpgradeSlots = 6,
        Price = 0, TopSpeed = 35, Acceleration = 4, Handling = 110,
        Braking = 7, Jump = 5, Battery = 100, Stability = 1,
        Rarity = "COMMON", UnlockLevel = 1,
    }),
    kukirin_g3 = table.freeze({
        Id = "kukirin_g3", DisplayName = "Volt Sport — placeholder", Class = "SPORT", Weight = 27, UpgradeSlots = 6,
        Price = 12000, TopSpeed = 45, Acceleration = 4.5, Handling = 100,
        Braking = 8, Jump = 5, Battery = 125, Stability = 1.1,
        Rarity = "RARE", UnlockLevel = 8,
    }),
    kukirin_g4 = table.freeze({
        Id = "kukirin_g4", DisplayName = "Volt Pro — placeholder", Class = "PRO", Weight = 32, UpgradeSlots = 6,
        Price = 45000, TopSpeed = 55, Acceleration = 5, Handling = 95,
        Braking = 9, Jump = 5, Battery = 150, Stability = 1.2,
        Rarity = "LEGENDARY", UnlockLevel = 20,
    }),
    volt_city = table.freeze({
        Id = "volt_city", DisplayName = "Volt City — placeholder", Class = "CITY", Weight = 24, UpgradeSlots = 6,
        Price = 6000, TopSpeed = 38, Acceleration = 4.2, Handling = 125,
        Braking = 9, Jump = 5, Battery = 115, Stability = 1.1, Rarity = "UNCOMMON", UnlockLevel = 5,
    }),
    volt_dual = table.freeze({
        Id = "volt_dual", DisplayName = "Volt Dual — placeholder", Class = "DUAL MOTOR", Weight = 35, UpgradeSlots = 6,
        Price = 24000, TopSpeed = 50, Acceleration = 5.5, Handling = 95,
        Braking = 9, Jump = 5, Battery = 140, Stability = 1.2, Rarity = "EPIC", UnlockLevel = 14,
    }),
}
return table.freeze({ StarterId = "kukirin_g2", ById = table.freeze(byId) })
