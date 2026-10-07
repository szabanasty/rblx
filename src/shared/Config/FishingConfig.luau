--!strict
-- Automatic server fishing. No minigame or client RNG.
return table.freeze({
    Enabled = true, InventoryLimit = 60,
    MinimumWaitSeconds = 18, MaximumWaitSeconds = 28, SuccessChance = 0.8,
    MaximumDistanceStuds = 12, MaximumSessionSeconds = 900,
    RarityWeights = {COMMON = 55, UNCOMMON = 25, RARE = 13, EPIC = 6, LEGENDARY = 1},
    RarityValueModifiers = {COMMON = 1, UNCOMMON = 1.15, RARE = 1.3, EPIC = 1.5, LEGENDARY = 1.75},
    ById = {
        river_fish = {FishId = "river_fish", DisplayName = "River Fish", Rarity = "COMMON", MinWeight = 0.3, MaxWeight = 2, BaseValue = 8},
        silver_carp = {FishId = "silver_carp", DisplayName = "Silver Carp", Rarity = "UNCOMMON", MinWeight = 0.5, MaxWeight = 3, BaseValue = 12},
        blue_pike = {FishId = "blue_pike", DisplayName = "Blue Pike", Rarity = "RARE", MinWeight = 0.8, MaxWeight = 4, BaseValue = 18},
        night_catfish = {FishId = "night_catfish", DisplayName = "Night Catfish", Rarity = "EPIC", MinWeight = 1, MaxWeight = 5, BaseValue = 25},
        golden_fish = {FishId = "golden_fish", DisplayName = "Golden Fish", Rarity = "LEGENDARY", MinWeight = 0.5, MaxWeight = 2, BaseValue = 40},
    },
})
