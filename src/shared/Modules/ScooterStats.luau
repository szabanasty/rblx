--!strict
local Stats = {}
function Stats.Get(base: any, levels: any, config: any): any
    local result: any = table.clone(base)
    if type(levels) ~= "table" then return result end
    for category, data in config.Categories do
        local level = levels[category]
        if type(level) == "number" and level == level and level % 1 == 0 and level >= 0 and level <= config.MaxLevel then
            for stat, bonus in data.Effects do result[stat] += bonus * level end
        end
    end
    result.TopSpeed = math.clamp(result.TopSpeed, 10, 80)
    result.Acceleration = math.clamp(result.Acceleration, 1, 10)
    result.Handling = math.clamp(result.Handling, 30, 200)
    result.Braking = math.clamp(result.Braking, 1, 15)
    result.Jump = math.clamp(result.Jump, 1, 8)
    result.Battery = math.clamp(result.Battery, 25, 300)
    result.Stability = math.clamp(result.Stability, 0.5, 3)
    return result
end
function Stats.NextUpgrade(category: string, currentLevel: number, config: any): (number?, number?)
    local data = config.Categories[category]
    if not data or currentLevel ~= currentLevel or currentLevel % 1 ~= 0 or currentLevel < 0 or currentLevel >= config.MaxLevel then return nil, nil end
    return data.BasePrice * config.PriceGrowth ^ currentLevel, config.RequiredLevel + config.RequiredLevelStep * currentLevel
end
return table.freeze(Stats)
