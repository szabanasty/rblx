--!nonstrict
return function(loadSnapshot, Schema, Progression, GameConfig, ScooterConfig, LevelConfig, configs)
    local defaults = GameConfig
    GameConfig = table.clone(GameConfig)
    GameConfig.FoundationOnly, GameConfig.Phase = true, 0
    local checks = 0
    local function check(ok, message) assert(ok, message); checks += 1 end
    local old = Schema.new(123, GameConfig)
    old.Money, old.XP, old.Level = 825, 40, 5
    old.OwnedScooters.kukirin_g3 = true
    old.SelectedScooter = "kukirin_g3"
    old.ScooterUpgrades.kukirin_g3 = {Motor = 2}
    for _, name in {"OwnedEquipment", "EquippedLoadout", "FishingInventory", "Cosmetics", "ScooterCustomization", "Kills", "Deaths", "Assists", "Revives", "BestStreak", "ZoneTime"} do old[name] = nil end
    local profile = Schema.sanitize(old, GameConfig)
    check(profile and profile.Money == 825 and profile.Level == 5 and profile.XP == 40, "additive migration preserves progress")
    check(profile.OwnedScooters.kukirin_g3 and profile.SelectedScooter == "kukirin_g3" and profile.ScooterUpgrades.kukirin_g3.Motor == 2, "migration preserves vehicles and upgrades")
    check(profile.Kills == 0 and #profile.FishingInventory == 0 and next(profile.EquippedLoadout) == nil, "new fields initialize without pretending gameplay is implemented")
    profile.OwnedEquipment = {spark = true, fake = false, [42] = true}
    profile.EquippedLoadout = {PRIMARY = "spark", SECONDARY = "unowned", UTILITY = {}, ADMIN = "spark"}
    profile.Kills, profile.Deaths, profile.Assists = -20, math.huge, 4.8
    profile.FishingInventory = {{FishId = "golden_fish", Weight = 0/0, Rarity = "LEGENDARY"}}
    for index = 2, 150 do
        profile.FishingInventory[index] = {FishId = "river_fish", Weight = 1, Rarity = "COMMON", Value = 999999}
    end
    profile = Schema.sanitize(profile, GameConfig)
    check(profile.Kills == 0 and profile.Deaths == 0 and profile.Assists == 4, "pvp counters bounded and finite")
    check(profile.EquippedLoadout.PRIMARY == "spark" and profile.EquippedLoadout.SECONDARY == nil and profile.EquippedLoadout.UTILITY == nil and profile.EquippedLoadout.ADMIN == nil, "loadout accepts only owned IDs and known slots")
    check(#profile.FishingInventory == 60 and profile.FishingInventory[1].Weight == 1 and profile.FishingInventory[1].Value == nil, "fish inventory bounded, nonfinite weights and client-style prices stripped")
    local chance = 0
    for _, weight in configs.Fishing.RarityWeights do chance += weight end
    check(chance == 100 and configs.Fishing.InventoryLimit == GameConfig.MaxFishingInventory, "fishing draft has coherent weights and storage limit")
    for _, config in {configs.Fishing, configs.Combat, configs.Equipment, configs.PvPRewards, configs.Zones} do
        check(config.Enabled == defaults.ZoneGame, "gameplay activation agrees with selected game mode")
    end
    check(configs.Combat.DownedSeconds == 60 and configs.Combat.SquadSize == 4 and not configs.Combat.FriendlyFire, "requested core combat constants prepared")
    local players = {}
    local player = {Parent = players}
    local sent = nil
    local state = {State = "ALIVE", CurrentHealth = 80, MaxHealth = 100, HealthReady = true, AreaId = "UNASSIGNED", AreaName = "Strefy w PHASE 1", CurrentStreak = 0}
    local snapshot = loadSnapshot({GetService = function(_, name) return if name == "Players" then players else {IsStudio = function() return true end} end})
    snapshot:Init({Config = {Game = GameConfig, Scooters = ScooterConfig, Levels = LevelConfig}, Schema = Schema, Progression = Progression,
        Remotes = {Snapshot = {FireClient = function(_, _, value) sent = value end}},
        Services = {PlayerData = {GetProfile = function() return profile end, GetStatus = function() return "StudioMemory" end},
            PlayerState = {GetPublic = function() return table.clone(state) end}},
    })
    snapshot:Send(player)
    check(sent.Ready and sent.Mode == "Foundation" and sent.Phase == 0 and sent.PlayerState.CurrentHealth == 80, "foundation snapshot works without any gameplay service")
    check(not sent.Telemetry.Riding and sent.Quest == nil and sent.IdempotencyLedger == nil and sent.Session == nil, "foundation does not expose gameplay or private records")
    sent.OwnedEquipment.spark = false
    sent.PlayerState.CurrentHealth = 999
    check(profile.OwnedEquipment.spark and state.CurrentHealth == 80, "public copies cannot mutate source state")
    profile = nil
    snapshot:Send(player)
    check(not sent.Ready and sent.Kills == nil and sent.PlayerState == nil, "loading or lost session never invents data")
    print("Foundation schema and projection checks passed: " .. checks)
end
