--!strict
local Rules = {}
function Rules.Contains(position: any, area: any): boolean
    return math.abs(position.X - area.Center[1]) <= area.Size[1] / 2
        and math.abs(position.Y - area.Center[2]) <= area.Size[2] / 2
        and math.abs(position.Z - area.Center[3]) <= area.Size[3] / 2
end
function Rules.At(position: any, config: any): string
    for _, id in {"SafeZone", "FishingArea", "CombatZone"} do
        if Rules.Contains(position, config.Areas[id]) then return id end
    end
    return "City"
end
return table.freeze(Rules)
