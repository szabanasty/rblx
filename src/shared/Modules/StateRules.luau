--!strict
-- Pure state transitions; only server services mutate these records.
local Rules = {}
function Rules.New(maxHealth: number): any
    return {Health = maxHealth, MaxHealth = maxHealth, Ready = false, Area = "City", TaggedUntil = 0,
        DownedUntil = 0, ProtectedUntil = 0, Reviving = false, Fishing = false, Streak = 0}
end
function Rules.State(record: any, now: number): string
    if not record.Ready then return "RESPAWNING" end
    if record.DownedUntil > 0 then return "DOWNED" end
    if record.Reviving then return "REVIVING" end
    if record.Fishing then return "FISHING" end
    if record.TaggedUntil > now then return "COMBAT" end
    return if record.Area == "SafeZone" then "SAFE" else "ALIVE"
end
function Rules.CanAct(record: any, kind: string, now: number): boolean
    if not record or not record.Ready or record.DownedUntil > 0 or record.Health <= 0 then return false end
    if kind == "Target" then return record.ProtectedUntil <= now and (record.Area == "CombatZone" or record.TaggedUntil > now) end
    if kind == "Trade" then return record.Area == "SafeZone" and record.TaggedUntil <= now and not record.Fishing and not record.Reviving end
    if kind == "Fish" then return record.Area == "FishingArea" and record.TaggedUntil <= now and not record.Reviving end
    if kind == "Shoot" then return not record.Fishing and not record.Reviving and (record.Area == "CombatZone" or record.TaggedUntil > now) end
    if kind == "Drive" then return not record.Fishing and not record.Reviving end
    if kind == "Squad" then return record.TaggedUntil <= now and not record.Fishing and not record.Reviving end
    return false
end
function Rules.Damage(record: any, amount: number, now: number, config: any): boolean
    assert(amount == amount and amount > 0 and amount < math.huge, "Invalid server damage")
    record.Health = math.max(0, record.Health - amount)
    record.TaggedUntil = now + config.CombatTagSeconds
    if record.Health == 0 then
        record.DownedUntil = now + config.DownedSeconds
        record.Fishing, record.Reviving = false, false
        record.Streak = 0
        return true
    end
    return false
end
function Rules.Revive(record: any, now: number, config: any): boolean
    if not record.Ready or record.DownedUntil <= now then return false end
    record.DownedUntil = 0
    record.Health = config.ReviveHealth
    record.ProtectedUntil = now + config.ReviveProtectionSeconds
    record.TaggedUntil = now + config.CombatTagSeconds
    return true
end
return table.freeze(Rules)
