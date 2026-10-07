--!strict
-- Speeds: km/h; acceleration/braking: m/s²; handling: degrees/s; jump: m/s.
-- These are original block placeholders, without brand logos or imported assets.
local byId = {
    kukirin_g2 = table.freeze({
        Id = "kukirin_g2", DisplayName = "KuKirin G2 — placeholder",
        Price = 0, TopSpeed = 35, Acceleration = 4, Handling = 110,
        Braking = 7, Jump = 5, Battery = 100, Stability = 1,
        Rarity = "Common", UnlockLevel = 1,
    }),
    kukirin_g3 = table.freeze({
        Id = "kukirin_g3", DisplayName = "KuKirin G3 — placeholder",
        Price = 12000, TopSpeed = 45, Acceleration = 4.5, Handling = 100,
        Braking = 8, Jump = 5, Battery = 125, Stability = 1.1,
        Rarity = "Rare", UnlockLevel = 8,
    }),
    kukirin_g4 = table.freeze({
        Id = "kukirin_g4", DisplayName = "KuKirin G4 — placeholder",
        Price = 45000, TopSpeed = 55, Acceleration = 5, Handling = 95,
        Braking = 9, Jump = 5, Battery = 150, Stability = 1.2,
        Rarity = "Epic", UnlockLevel = 20,
    }),
}
return table.freeze({ StarterId = "kukirin_g2", ById = table.freeze(byId) })
