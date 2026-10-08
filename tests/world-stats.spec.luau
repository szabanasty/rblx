--!nonstrict
return function(Layout, Stats, WorldConfig, RoadConfig, ScooterConfig, UpgradeConfig)
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local roads = Layout.CreateRoads(WorldConfig, RoadConfig)
    check(#roads == 10, "bounded road count")
    local ids = {}
    for _, road in roads do
        check(not ids[road.RoadId] and road.SpeedLimit > 0 and road.Length <= WorldConfig.Width, "road identity and limits valid")
        ids[road.RoadId] = true
    end
    check(Layout.GetRoadAt(roads, -300, 0).SpeedLimit == 30, "intersection chooses stricter limit")
    check(Layout.GetRoadAt(roads, 150, 600).SpeedLimit == 90, "highway limit configurable")
    check(Layout.GetRoadAt(roads, 150, 150) == nil, "off road has no invented limit")
    check(Layout.GetRoadAt(roads, 0, 800) == nil, "road length bounded")
    check(#WorldConfig.Districts == 13, "all district placeholders configured")
    check(not Layout.IsBuildingClear(80, 85, 57, 47, WorldConfig.Locations), "building may not cover spawn shops and garage")
    check(Layout.IsBuildingClear(-520, -515, 57, 47, WorldConfig.Locations), "unreserved building remains")
    for _, district in WorldConfig.Districts do
        for _, offset in {{-70,-65},{70,-65},{-70,65},{70,65}} do
            local x,z = district.X + offset[1], district.Z + offset[2]
            if Layout.IsBuildingClear(x,z,57,47,WorldConfig.Locations) then
                for _,location in WorldConfig.Locations do
                    check(math.abs(x-location.X)>=28.5+location.Radius+8 or math.abs(z-location.Z)>=23.5+location.Radius+8,"all rendered buildings leave interaction areas clear")
                end
            end
        end
    end
    local base = ScooterConfig.ById.kukirin_g2
    local stats = Stats.Get(base, {Motor = 2, Brakes = 1, Tires = 3, Battery = 1}, UpgradeConfig)
    check(stats.TopSpeed == base.TopSpeed + 4 and stats.Braking > base.Braking and stats.Battery > base.Battery, "configured stat upgrades applied")
    check(base.TopSpeed == 35 and stats ~= base, "catalog never mutated")
    for _, value in {-1, 6, 0.5, 0/0, math.huge, "99", {}} do
        check(Stats.Get(base, {Motor = value}, UpgradeConfig).TopSpeed == base.TopSpeed, "invalid saved upgrade ignored")
    end
    check(Stats.NextUpgrade("Motor", 0, UpgradeConfig) == 75, "starter can afford first motor upgrade")
    check(Stats.NextUpgrade("Motor", 1, UpgradeConfig) == 150, "scaled upgrade price")
    check(Stats.NextUpgrade("Motor", 5, UpgradeConfig) == nil and Stats.NextUpgrade("Fake", 0, UpgradeConfig) == nil, "max and unknown category rejected")
    print("World and scooter-stat checks passed: " .. checks)
end
