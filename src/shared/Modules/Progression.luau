--!strict
local Progression = {}
export type Config = {BaseXP: number, Growth: number, MaxLevel: number, LevelRewardMoney: number}
export type Profile = {Level: number, XP: number}
function Progression.XPToNextLevel(level: number, config: Config): number
    if level >= config.MaxLevel then return 0 end
    return config.BaseXP + config.Growth * (math.max(1, math.floor(level)) - 1)
end
function Progression.AddXP(profile: Profile, amount: number, config: Config): number
    assert(amount == amount and amount >= 0 and amount < math.huge and amount % 1 == 0, "Invalid XP")
    local gained = 0
    profile.XP += amount
    while profile.Level < config.MaxLevel do
        local required = Progression.XPToNextLevel(profile.Level, config)
        if profile.XP < required then break end
        profile.XP -= required
        profile.Level += 1
        gained += 1
    end
    if profile.Level >= config.MaxLevel then profile.XP = 0 end
    return gained
end
return table.freeze(Progression)
