--!strict
local Rules = {}
local order = {"COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"}
function Rules.Value(fish: any, config: any): number?
    if type(fish) ~= "table" or type(fish.FishId) ~= "string" then return nil end
    local data = config.ById[fish.FishId]
    if not data or fish.Rarity ~= data.Rarity or type(fish.Weight) ~= "number" or fish.Weight ~= fish.Weight
        or fish.Weight < data.MinWeight or fish.Weight > data.MaxWeight then return nil end
    return math.max(1, math.floor(data.BaseValue * fish.Weight * config.RarityValueModifiers[data.Rarity]))
end
function Rules.Roll(rng: any, config: any): any?
    if rng:NextNumber() > config.SuccessChance then return nil end
    local sample = rng:NextNumber(0, 100)
    local rarity = "LEGENDARY"
    local cumulative = 0
    for _, id in order do
        cumulative += config.RarityWeights[id]
        if sample < cumulative then rarity = id; break end
    end
    local candidates: {string} = {}
    for id, fish in config.ById do if fish.Rarity == rarity then table.insert(candidates, id) end end
    table.sort(candidates)
    if #candidates == 0 then return nil end
    local id = candidates[rng:NextInteger(1, #candidates)]
    local data = config.ById[id]
    local weight = math.floor(rng:NextNumber(data.MinWeight, data.MaxWeight) * 100 + 0.5) / 100
    return {FishId = id, Weight = math.clamp(weight, data.MinWeight, data.MaxWeight), Rarity = rarity}
end
return table.freeze(Rules)
