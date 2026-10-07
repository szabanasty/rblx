--!strict
local Schema = {}
local DEFAULT = {StarterScooterId = "kukirin_g2", StartingMoney = 100, MaxCurrency = 2000000000, MaxPlayerLevel = 100}
local function finite(value: any): boolean
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function integer(value: any, fallback: number, low: number, high: number): number
    if not finite(value) then return fallback end
    return math.clamp(math.floor(value), low, high)
end
local function serialCopy(value: any, depth: number): any
    if depth > 6 then return nil end
    local kind = type(value)
    if kind == "number" then return if finite(value) then value else nil end
    if kind == "boolean" then return value end
    if kind == "string" then return string.sub(value, 1, 256) end
    if kind ~= "table" then return nil end
    local result: {[any]: any} = {}
    local count = 0
    for key, entry in value do
        if (type(key) == "string" and #key <= 128) or (type(key) == "number" and finite(key) and key >= 1 and key % 1 == 0 and key <= 256) then
            count += 1
            if count > 256 then break end
            result[key] = serialCopy(entry, depth + 1)
        end
    end
    return result
end
function Schema.deepCopy(value: any): any
    return serialCopy(value, 0)
end
function Schema.new(userId: number, config: any?): any
    local cfg = config or DEFAULT
    return {
        SchemaVersion = 1, UserId = userId, Money = cfg.StartingMoney, Level = 1, XP = 0,
        Reputation = 0, DriverScore = 100,
        OwnedScooters = {[cfg.StarterScooterId] = true}, SelectedScooter = cfg.StarterScooterId,
        ScooterUpgrades = {}, Pets = {}, Clothing = {}, Inventory = {}, Achievements = {}, QuestCooldowns = {},
        PoliceLevel = 1, PoliceXP = 0, PoliceReputation = 0, PoliceCredits = 0, PoliceRank = "Cadet",
        Statistics = {DistanceMeters = 0, RaceWins = 0, BestRaceTime = 0, TrickScore = 0, PoliceArrests = 0, DeliveriesCompleted = 0},
        Settings = {UIScale = 1, GraphicsQuality = 2, MusicVolume = 0.5, SFXVolume = 0.7, ReducedEffects = false},
        RewardBudget = {Day = math.floor(os.time() / 86400), Money = 0, XP = 0, Reputation = 0},
        IdempotencyLedger = {},
        ScooterCustomization = {}, ScooterBatteries = {}, ActivityBudget = {Day = 0, PvP = 0, Fishing = 0, Objective = 0, Revive = 0}, OwnedEquipment = {}, EquippedLoadout = {}, FishingInventory = {}, Cosmetics = {},
        PvPOpponents = {}, ReviveHistory = {}, CurrentStreak = 0, Kills = 0, Deaths = 0, Assists = 0, Revives = 0, BestStreak = 0, ZoneTime = 0,
    }
end
function Schema.sanitize(raw: any, config: any?): (any?, string?)
    local cfg = config or DEFAULT
    if type(raw) ~= "table" then return nil, "MalformedProfile" end
    local version = raw.SchemaVersion or 0
    if not finite(version) or version % 1 ~= 0 or version < 0 or version > 1 then return nil, "UnsupportedSchema" end
    if not finite(raw.Money) or not finite(raw.XP) or not finite(raw.Level) or not finite(raw.UserId) then
        return nil, "MalformedCoreFields"
    end
    local profile = Schema.new(raw.UserId, cfg)
    profile.Money = integer(raw.Money, cfg.StartingMoney, 0, cfg.MaxCurrency)
    profile.Level = integer(raw.Level, 1, 1, cfg.MaxPlayerLevel)
    profile.XP = integer(raw.XP, 0, 0, 10000000)
    if profile.Level == cfg.MaxPlayerLevel then profile.XP = 0 end
    for _, field in {"Reputation", "PoliceXP", "PoliceReputation", "PoliceCredits"} do
        profile[field] = integer(raw[field], 0, 0, cfg.MaxCurrency)
    end
    profile.DriverScore = integer(raw.DriverScore, 100, 0, 100)
    profile.PoliceLevel = integer(raw.PoliceLevel, 1, 1, 100)
    for _, field in {"Kills", "Deaths", "Assists", "Revives", "BestStreak", "ZoneTime"} do
        profile[field] = integer(raw[field], 0, 0, cfg.MaxCurrency)
    end
    for _, field in {"OwnedEquipment", "Cosmetics"} do
        if type(raw[field]) == "table" then
            local count = 0
            for id, owned in raw[field] do
                if type(id) == "string" and #id > 0 and #id <= 64 and owned == true then
                    profile[field][id] = true
                    count += 1
                    if count >= 100 then break end
                end
            end
        end
    end
    if type(raw.EquippedLoadout) == "table" then
        for _, slot in {"PRIMARY", "SECONDARY", "UTILITY"} do
            local id = raw.EquippedLoadout[slot]
            if type(id) == "string" and profile.OwnedEquipment[id] then profile.EquippedLoadout[slot] = id end
        end
    end
    if type(raw.FishingInventory) == "table" then
        local rarity = {COMMON = true, UNCOMMON = true, RARE = true, EPIC = true, LEGENDARY = true}
        for index = 1, 256 do
            local fish = raw.FishingInventory[index]
            if type(fish) == "table" and type(fish.FishId) == "string" and #fish.FishId > 0 and #fish.FishId <= 64
                and finite(fish.Weight) and fish.Weight > 0 and fish.Weight <= 1000
                and type(fish.Rarity) == "string" and rarity[fish.Rarity] then
                table.insert(profile.FishingInventory, {FishId = fish.FishId, Weight = fish.Weight, Rarity = fish.Rarity})
                if #profile.FishingInventory >= (cfg.MaxFishingInventory or 60) then break end
            end
        end
    end
    for _, field in {"PvPOpponents", "ReviveHistory"} do
        if type(raw[field]) == "table" then
            local count = 0
            for id, entry in raw[field] do
                if type(id) == "string" and #id > 0 and #id <= 32 and type(entry) == "table" and finite(entry.Until) then
                    profile[field][id] = {Until = integer(entry.Until, 0, 0, 100000000000), Count = integer(entry.Count, 0, 0, 4)}
                    count += 1
                    if count >= 64 then break end
                end
            end
        end
    end
    if type(raw.EquippedClothing) == "string" and #raw.EquippedClothing <= 64 then profile.EquippedClothing = raw.EquippedClothing end
    if type(raw.EquippedTag) == "string" and #raw.EquippedTag <= 64 then profile.EquippedTag = raw.EquippedTag end
    if type(raw.ActivityBudget) == "table" then
        for _, field in {"Day", "PvP", "Fishing", "Objective", "Revive"} do profile.ActivityBudget[field] = integer(raw.ActivityBudget[field], 0, 0, cfg.MaxCurrency) end
    end
    local ranks = {Cadet = true, Officer = true, ["Senior Officer"] = true, Sergeant = true, Lieutenant = true, Captain = true}
    if type(raw.PoliceRank) == "string" and ranks[raw.PoliceRank] then profile.PoliceRank = raw.PoliceRank end
    if type(raw.OwnedScooters) == "table" then
        local count = 0
        for id, owned in raw.OwnedScooters do
            if type(id) == "string" and #id <= 64 and owned == true then
                profile.OwnedScooters[id] = true
                count += 1
                if count >= 100 then break end
            end
        end
    end
    if type(raw.SelectedScooter) == "string" and profile.OwnedScooters[raw.SelectedScooter] then
        profile.SelectedScooter = raw.SelectedScooter
    end
    for _, field in {"ScooterUpgrades", "ScooterCustomization", "ScooterBatteries", "Pets", "Clothing", "Inventory", "Achievements"} do
        if type(raw[field]) == "table" then profile[field] = serialCopy(raw[field], 0) end
    end
    for _, field in {"EquippedPet", "CrewId"} do
        if type(raw[field]) == "string" and #raw[field] <= 64 then profile[field] = raw[field] end
    end
    if type(raw.Statistics) == "table" then
        for field, fallback in profile.Statistics do
            profile.Statistics[field] = integer(raw.Statistics[field], fallback, 0, 2000000000)
        end
    end
    if type(raw.Settings) == "table" then
        local boundsByName: {[string]: {number}} = {UIScale = {0.75, 1.5}, GraphicsQuality = {1, 3}, MusicVolume = {0, 1}, SFXVolume = {0, 1}}
        for field, bounds in boundsByName do
            if finite(raw.Settings[field]) then profile.Settings[field] = math.clamp(raw.Settings[field], bounds[1], bounds[2]) end
        end
        profile.Settings.GraphicsQuality = math.floor(profile.Settings.GraphicsQuality)
        if type(raw.Settings.ReducedEffects) == "boolean" then profile.Settings.ReducedEffects = raw.Settings.ReducedEffects end
    end
    if type(raw.RewardBudget) == "table" then
        profile.RewardBudget.Day = integer(raw.RewardBudget.Day, math.floor(os.time() / 86400), 0, 10000000)
        profile.RewardBudget.Money = integer(raw.RewardBudget.Money, 0, 0, cfg.MaxCurrency)
        profile.RewardBudget.XP = integer(raw.RewardBudget.XP, 0, 0, cfg.MaxCurrency)
        profile.RewardBudget.Reputation = integer(raw.RewardBudget.Reputation, 0, 0, cfg.MaxCurrency)
    end
    if type(raw.QuestCooldowns) == "table" then
        local count = 0
        for id, timestamp in raw.QuestCooldowns do
            if type(id) == "string" and #id <= 64 and finite(timestamp) then
                profile.QuestCooldowns[id] = integer(timestamp, 0, 0, 100000000000)
                count += 1
                if count >= 100 then break end
            end
        end
    end
    if type(raw.IdempotencyLedger) == "table" then
        local count = 0
        for key, stamp in raw.IdempotencyLedger do
            if type(key) == "string" and #key <= 128 and finite(stamp) then
                profile.IdempotencyLedger[key] = math.floor(stamp)
                count += 1
                if count >= 128 then break end
            end
        end
    end
    return profile, nil
end
return table.freeze(Schema)
