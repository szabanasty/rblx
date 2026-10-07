--!strict
-- Values for future services; this configuration does not enable combat.
return table.freeze({
    Enabled = false, MaxHealth = 100, CombatTagSeconds = 20,
    DownedSeconds = 60, ReviveSeconds = 5, ReviveRangeStuds = 10,
    ReviveHealth = 35, ReviveProtectionSeconds = 2,
    FriendlyFire = false, SquadSize = 4,
    MaximumAimPacketRate = 10,
})
