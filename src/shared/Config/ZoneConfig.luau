--!strict
-- Server zone detection and the original map use these same bounds.
return table.freeze({
    Enabled = true, WorldWidth = 2800, DetectionHz = 5,
    Areas = {
        SafeZone = {DisplayName = "SAFE • RIVERSIDE", Center = {0, 0, 0}, Size = {560, 80, 560}, DamageAllowed = false},
        CombatZone = {DisplayName = "COMBAT • IRON ISLAND", Center = {1050, 0, 0}, Size = {500, 80, 600}, DamageAllowed = true},
        FishingArea = {DisplayName = "FISHING • WILLOW LAKE", Center = {-340, 0, 355}, Size = {220, 80, 210}, DamageAllowed = false},
    },
})
