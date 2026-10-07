--!strict
-- Design coordinates only. Detection and actual geometry belong to PHASE 1.
return table.freeze({
    Enabled = false, WorldWidth = 800, DetectionHz = 5,
    Areas = {
        SafeZone = {DisplayName = "SAFE ZONE", Center = {0, 0, 0}, Size = {160, 60, 160}, DamageAllowed = false},
        CombatZone = {DisplayName = "COMBAT ZONE", Center = {220, 0, 0}, Size = {240, 60, 260}, DamageAllowed = true},
        FishingArea = {DisplayName = "FISHING AREA", Center = {-220, 0, 160}, Size = {130, 60, 130}, DamageAllowed = false},
    },
})
