--!strict
-- Original fictional equipment. No Tool, model or animation is assumed to exist.
return table.freeze({
    Enabled = true, StarterEquipmentId = "spark", Slots = {"PRIMARY", "SECONDARY", "UTILITY"},
    ById = {
        spark = {EquipmentId = "spark", DisplayName = "Spark", Category = "LIGHT", Damage = 12, Cooldown = 0.25,
            EffectiveRange = 90, Accuracy = 0.85, MobilityModifier = 1, Capacity = 12, ReloadDuration = 1.8, Price = 0, Rarity = "COMMON"},
        pulse = {EquipmentId = "pulse", DisplayName = "Pulse", Category = "STANDARD", Damage = 20, Cooldown = 0.4,
            EffectiveRange = 130, Accuracy = 0.9, MobilityModifier = 0.95, Capacity = 10, ReloadDuration = 2, Price = 1500, Rarity = "UNCOMMON"},
        prism = {EquipmentId = "prism", DisplayName = "Prism", Category = "CLOSE RANGE", Damage = 30, Cooldown = 0.8,
            EffectiveRange = 35, Accuracy = 0.75, MobilityModifier = 0.95, Capacity = 6, ReloadDuration = 2.2, Price = 2000, Rarity = "RARE"},
        focus = {EquipmentId = "focus", DisplayName = "Focus", Category = "PRECISION", Damage = 35, Cooldown = 1.2,
            EffectiveRange = 180, Accuracy = 0.98, MobilityModifier = 0.85, Capacity = 5, ReloadDuration = 2.5, Price = 2500, Rarity = "RARE"},
        nova = {EquipmentId = "nova", DisplayName = "Nova", Category = "HEAVY", Damage = 40, Cooldown = 1.5,
            EffectiveRange = 80, Accuracy = 0.8, MobilityModifier = 0.8, Capacity = 4, ReloadDuration = 2.8, Price = 3000, Rarity = "EPIC"},
    },
})
