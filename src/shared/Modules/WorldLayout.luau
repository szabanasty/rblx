--!strict
local Layout = {}
export type Road = {RoadId: string, X: number, Z: number, Width: number, Length: number, Axis: string, SpeedLimit: number, RoadType: string, District: string, PoliceEnabled: boolean}
function Layout.CreateRoads(config: any, catalog: any): {Road}
    local roads: {Road} = {}
    for _, axis in {"X", "Z"} do
        for index = -2, 2 do
            local coordinate = index * config.GridSpacing
            local kind = if axis == "Z" and index == 2 then "Highway" elseif index == 0 then "MainRoad" elseif index == -1 then "Residential" else "City"
            local template = catalog[kind]
            table.insert(roads, {
                RoadId = axis .. "_" .. tostring(index),
                X = if axis == "X" then coordinate else 0,
                Z = if axis == "Z" then coordinate else 0,
                Axis = axis, Width = config.RoadWidth, Length = config.RoadLength,
                SpeedLimit = template.SpeedLimit, RoadType = template.RoadType,
                District = "CityGrid", PoliceEnabled = template.PoliceEnabled,
            })
        end
    end
    return roads
end
function Layout.GetRoadAt(roads: {Road}, x: number, z: number): Road?
    local selected: Road? = nil
    for _, road in roads do
        local dx, dz = math.abs(x - road.X), math.abs(z - road.Z)
        local inside = if road.Axis == "X" then dx <= road.Width / 2 and dz <= road.Length / 2
            else dz <= road.Width / 2 and dx <= road.Length / 2
        if inside and (not selected or road.SpeedLimit < selected.SpeedLimit) then selected = road end
    end
    return selected
end
function Layout.GetDistrictAt(districts: {any}, x: number, z: number): string
    for _, district in districts do
        if math.abs(x - district.X) < 150 and math.abs(z - district.Z) < 150 then return district.Name end
    end
    return "Droga miejska"
end
function Layout.IsBuildingClear(x: number, z: number, width: number, depth: number, locations: any): boolean
    -- Reserve the full interaction radius plus walking space, not only the marker.
    for _, location in locations do
        if math.abs(x - location.X) < width / 2 + location.Radius + 8
            and math.abs(z - location.Z) < depth / 2 + location.Radius + 8 then return false end
    end
    return true
end
return table.freeze(Layout)
