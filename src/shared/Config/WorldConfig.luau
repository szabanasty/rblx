--!strict
-- Original district layout. Building models are intentionally simple placeholders.
local names = {
    {"Residential", "Osiedle", "Residential"}, {"Downtown", "Centrum", "City"},
    {"Shopping", "Aleja sklepów", "City"}, {"Industrial", "Port przemysłowy", "MainRoad"},
    {"Suburbs", "Przedmieścia", "Residential"}, {"OldTown", "Stare miasto", "City"},
    {"Police", "Dzielnica policyjna", "City"}, {"Highway", "Węzeł autostrady", "Highway"},
    {"Hills", "Zielone wzgórza", "Residential"}, {"Park", "Park miejski", "Residential"},
    {"Race", "Strefa wyścigowa", "City"}, {"Beach", "Wybrzeże", "City"},
    {"Secret", "Stare magazyny", "MainRoad"},
}
local districts: {any} = {}
for index, entry in names do
    local column = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    table.insert(districts, table.freeze({
        Id = entry[1], Name = entry[2], RoadType = entry[3],
        X = -450 + column * 300, Z = -450 + row * 300,
        Color = {70 + column * 18, 85 + row * 12, 105 + (index % 3) * 18},
    }))
end
return table.freeze({
    Width = 1600, RoadLength = 1400, RoadWidth = 28, GridSpacing = 300,
    Districts = table.freeze(districts), SignalSeconds = 18, TrafficCount = 6,
    TrafficUpdateHz = 5, TrafficSpeedStuds = 18, DayLengthSeconds = 1200,
    Locations = table.freeze({
        Garage = table.freeze({X = 65, Z = 65, Radius = 22}),
        ScooterShop = table.freeze({X = 95, Z = 65, Radius = 22}),
        UpgradeShop = table.freeze({X = 65, Z = 95, Radius = 22}),
        DeliveryHub = table.freeze({X = 95, Z = 95, Radius = 22}),
        DeliveryTarget = table.freeze({X = 220, Z = -140, Radius = 20}),
    }),
})
