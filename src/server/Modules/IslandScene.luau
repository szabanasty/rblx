--!strict
local Island = {}
local steel = Color3.fromRGB(65, 88, 107)
local light = Color3.fromRGB(220, 227, 218)
function Island.Build(scene: any, config: any, zones: any)
    local bridge = config.Bridge
    local model = scene:Model("RiversideBridge")
    local top = bridge.DeckTop
    scene:Part(model, "Deck", Vector3.new(bridge.Length, 2, bridge.Width), CFrame.new(bridge.X, top - 1, bridge.Z), Color3.fromRGB(108, 121, 128), Enum.Material.Concrete, true)
    scene:Part(model, "Asphalt", Vector3.new(bridge.Length, 0.04, 30), CFrame.new(bridge.X, top + 0.025, bridge.Z), Color3.fromRGB(41, 46, 52), Enum.Material.Asphalt, false)
    for _, side in {-1, 1} do
        local z = bridge.Z + side * (bridge.Width / 2 - 1)
        scene:Part(model, "SafetyRail", Vector3.new(bridge.Length, 2.8, 0.6), CFrame.new(bridge.X, top + 1.8, z), steel, Enum.Material.Metal, true)
        scene:Part(model, "RailGlow", Vector3.new(bridge.Length, 0.15, 0.2), CFrame.new(bridge.X, top + 3.3, z), Color3.fromRGB(133, 209, 207), Enum.Material.Neon, false)
        for _, x in {bridge.X - 75, bridge.X + 75} do
            scene:Part(model, "Tower", Vector3.new(3, 33, 3), CFrame.new(x, top + 16.5, z), steel, Enum.Material.Metal, true)
            scene:Part(model, "BridgeSupport", Vector3.new(8, 20, 10), CFrame.new(x, -10, z), steel, Enum.Material.Concrete, true)
        end
        for index = 0, 12 do
            local x = bridge.X - 110 + index * 220 / 12
            local t = math.clamp((x - bridge.X + 75) / 150, 0, 1)
            local y = if x < bridge.X - 75 or x > bridge.X + 75 then 12 else 16 + 17 * (2 * t - 1)^2
            local nextX = math.min(bridge.X + 110, x + 220 / 12)
            local nextT = math.clamp((nextX - bridge.X + 75) / 150, 0, 1)
            local nextY = if nextX < bridge.X - 75 or nextX > bridge.X + 75 then 12 else 16 + 17 * (2 * nextT - 1)^2
            if nextX > x then scene:Beam(model, "SuspensionCable", Vector3.new(x, y, z), Vector3.new(nextX, nextY, z), 0.45, light) end
            scene:Beam(model, "Suspender", Vector3.new(x, top + 3, z), Vector3.new(x, y, z), 0.2, light)
        end
    end
    for _, x in {bridge.X - 75, bridge.X + 75} do
        scene:Part(model, "TowerCrossbeam", Vector3.new(3, 3, bridge.Width), CFrame.new(x, top + 31, bridge.Z), steel, Enum.Material.Metal, false)
    end
    for x = bridge.X - 100, bridge.X + 100, 25 do
        scene:Part(model, "Lane", Vector3.new(10, 0.03, 0.4), CFrame.new(x, top + 0.06, bridge.Z), Color3.fromRGB(235, 215, 160), Enum.Material.SmoothPlastic, false)
    end
    for _, x in {395, 650, 755} do
        scene:Sign(scene.Root, if x < bridge.X then "IRON ISLAND →\nPRZEJAZD PRZEZ MOST" else "COMBAT ZONE →\nWALKA TYLKO ZA BRAMĄ", CFrame.new(x, 9, 31) * CFrame.Angles(0, math.pi, 0), Vector3.new(36, 7, 0.5), Color3.fromRGB(247, 199, 111))
    end
    local arena = zones.Areas.CombatZone
    local x, z = arena.Center[1], arena.Center[3]
    local entryX = x - arena.Size[1] / 2
    local ground = scene:Model("IronIslandArena")
    scene:Part(ground, "ArenaPaving", Vector3.new(arena.Size[1], 0.12, arena.Size[3]), CFrame.new(x, 0.07, z), Color3.fromRGB(72, 77, 81), Enum.Material.Concrete, false)
    -- Fence boundaries are physical, with a wide western entrance facing the bridge.
    for _, side in {-1, 1} do
        scene:Part(ground, "NorthSouthWall", Vector3.new(arena.Size[1], 10, 1), CFrame.new(x, 5, z + side * arena.Size[3] / 2), steel, Enum.Material.Metal, true)
    end
    scene:Part(ground, "EastWall", Vector3.new(1, 10, arena.Size[3]), CFrame.new(x + arena.Size[1] / 2, 5, z), steel, Enum.Material.Metal, true)
    for _, side in {-1, 1} do
        scene:Part(ground, "WestWall", Vector3.new(1, 10, arena.Size[3] / 2 - 35), CFrame.new(x - arena.Size[1] / 2, 5, z + side * (arena.Size[3] / 4 + 17.5)), steel, Enum.Material.Metal, true)
        scene:Part(ground, "GateColumn", Vector3.new(4, 17, 4), CFrame.new(entryX, 8.5, z + side * 34), Color3.fromRGB(179, 121, 56), Enum.Material.Concrete, true)
    end
    scene:Part(ground, "GateHeader", Vector3.new(4, 4, 72), CFrame.new(entryX, 17, z), steel, Enum.Material.Metal, false)
    scene:Sign(ground, "IRON ISLAND\nCOMBAT ZONE", CFrame.new(entryX - 2, 17, z) * CFrame.Angles(0, -math.pi / 2, 0), Vector3.new(65, 3.6, 0.2), Color3.fromRGB(255, 188, 104))
    for index, position in {Vector3.new(x - 170, 0, z - 190), Vector3.new(x + 140, 0, z - 190), Vector3.new(x - 170, 0, z + 190), Vector3.new(x + 140, 0, z + 190)} do
        local warehouse = scene:Model("Warehouse_" .. index)
        scene:Part(warehouse, "Back", Vector3.new(82, 24, 2), CFrame.new(position + Vector3.new(0, 12, -25)), steel, Enum.Material.CorrodedMetal, true)
        for _, side in {-1, 1} do scene:Part(warehouse, "Side", Vector3.new(2, 24, 52), CFrame.new(position + Vector3.new(side * 41, 12, 0)), steel, Enum.Material.Metal, true) end
        scene:Part(warehouse, "Roof", Vector3.new(88, 2, 57), CFrame.new(position + Vector3.new(0, 25, 0)), Color3.fromRGB(47, 58, 66), Enum.Material.Metal, true)
        scene:Sign(warehouse, "SECTOR 0" .. index, CFrame.new(position + Vector3.new(0, 19, 26)), Vector3.new(45, 5, 0.3), light)
    end
    for index, position in {Vector3.new(x - 130, 0, z - 85), Vector3.new(x + 70, 0, z + 95), Vector3.new(x - 60, 0, z + 145), Vector3.new(x + 130, 0, z - 95), Vector3.new(x - 150, 0, z + 70), Vector3.new(x - 30, 0, z - 150)} do
        local container = scene:Model("Container_" .. index)
        local color = if index % 2 == 0 then Color3.fromRGB(159, 107, 64) else Color3.fromRGB(62, 115, 122)
        scene:Part(container, "Container", Vector3.new(38, 12, 15), CFrame.new(position + Vector3.new(0, 6, 0)), color, Enum.Material.Metal, true)
        for rib = -16, 16, 8 do
            for _, side in {-1, 1} do scene:Part(container, "Rib", Vector3.new(0.35, 11, 0.2), CFrame.new(position + Vector3.new(rib, 6, side * 7.6)), light, Enum.Material.Metal, false) end
        end
    end
    for _, px in {x - 90, x + 40, x + 150} do
        for _, pz in {-40, 45} do
            local cover = scene:Model("LowCover")
            scene:Part(cover, "Barrier", Vector3.new(16, 4, 3), CFrame.new(px, 2, pz), Color3.fromRGB(171, 158, 113), Enum.Material.Concrete, true)
            scene:Part(cover, "Stripe", Vector3.new(16, 0.5, 0.1), CFrame.new(px, 3.4, pz + 1.55), Color3.fromRGB(232, 188, 95), Enum.Material.Neon, false)
        end
    end
    for _, px in {x - 200, x + 200} do
        local ramp = scene:Part(ground, "Ramp", Vector3.new(16, 1, 30), CFrame.new(px, 4.2, 100) * CFrame.Angles(math.rad(-15), 0, 0), steel, Enum.Material.Metal, true)
        ramp:SetAttribute("Rideable", true)
    end
    local objective = config.Objective
    scene:Part(ground, "ControlPoint", Vector3.new(42, 0.15, 42), CFrame.new(objective.X, 0.2, objective.Z), Color3.fromRGB(125, 151, 131), Enum.Material.Slate, false)
    scene:Sign(ground, "CONTROL POINT\n2+ TEAMMATES • HOLD 30s", CFrame.new(objective.X, 10, -30), Vector3.new(28, 5, 0.3), Color3.fromRGB(158, 249, 192))
    for _, px in {x - 210, x - 50, x + 150, x + 230} do
        for _, pz in {-260, 260} do scene:Lamp(Vector3.new(px, 0, pz)) end
    end
end
return Island
