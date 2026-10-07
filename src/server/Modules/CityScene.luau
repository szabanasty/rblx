--!strict
local City = {}
local concrete = Color3.fromRGB(158, 163, 159)
local dark = Color3.fromRGB(35, 45, 54)
local glass = Color3.fromRGB(103, 159, 175)
function City.Shop(scene: any, id: string, location: any, title: string, accent: Color3): (Model, Part)
    local model = scene:Model(id)
    local x, z = location.X, location.Z - 36
    scene:Part(model, "Floor", Vector3.new(82, 0.45, 60), CFrame.new(x, 0.22, z), concrete, Enum.Material.Concrete, true)
    scene:Part(model, "Forecourt", Vector3.new(if id == "FishBuyer" then 70 else 84, 0.12, if id == "CosmeticsShop" then 36 else 44), CFrame.new(x, 0.07, location.Z + (if id == "CosmeticsShop" then 12 else 16)), Color3.fromRGB(171, 170, 155), Enum.Material.Slate, false)
    scene:Part(model, "BackWall", Vector3.new(82, 19, 1), CFrame.new(x, 9.5, z - 30), dark, Enum.Material.Concrete, true)
    for _, side in {-1, 1} do
        scene:Part(model, "SideWall", Vector3.new(1, 19, 60), CFrame.new(x + side * 41, 9.5, z), dark, Enum.Material.Concrete, true)
        local front = scene:Part(model, "ShopWindow", Vector3.new(30, 13, 0.4), CFrame.new(x + side * 26, 7, z + 30), glass, Enum.Material.Glass, true)
        front.Transparency = 0.65
        scene:Part(model, "Frame", Vector3.new(1, 16, 1), CFrame.new(x + side * 10, 8, z + 30), concrete, Enum.Material.Metal, true)
        scene:Part(model, "WindowSill", Vector3.new(30, 1, 2), CFrame.new(x + side * 26, 0.6, z + 30), concrete, Enum.Material.Concrete, true)
    end
    -- Twenty studs of clear entrance; no invisible glass or solid door crosses it.
    scene:Part(model, "Lintel", Vector3.new(82, 4, 1.5), CFrame.new(x, 17, z + 30), dark, Enum.Material.Metal, true)
    scene:Part(model, "Roof", Vector3.new(86, 1, 64), CFrame.new(x, 20, z), dark, Enum.Material.Metal, true)
    scene:Part(model, "Accent", Vector3.new(86, 0.4, 0.5), CFrame.new(x, 14.5, z + 31), accent, Enum.Material.Neon, false)
    scene:Sign(model, title, CFrame.new(x, 17, z + 31), Vector3.new(66, 3, 0.2), accent)
    scene:Part(model, "Counter", Vector3.new(18, 3.2, 6), CFrame.new(x + 25, 1.8, z + 7), dark, Enum.Material.Wood, true)
    scene:Part(model, "CounterTop", Vector3.new(19, 0.25, 7), CFrame.new(x + 25, 3.6, z + 7), accent, Enum.Material.SmoothPlastic, false)
    -- Friendly original static clerk, no humanoid AI or borrowed character asset.
    scene:Part(model, "ClerkBody", Vector3.new(2, 2.6, 1), CFrame.new(x + 25, 3.2, z + 2), accent, Enum.Material.SmoothPlastic, false)
    local head = scene:Part(model, "ClerkHead", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x + 25, 5.2, z + 2), Color3.fromRGB(213, 176, 138), Enum.Material.SmoothPlastic, false)
    head.Shape = Enum.PartType.Ball
    for _, side in {-1, 1} do
        scene:Part(model, "ClerkLeg", Vector3.new(0.75, 2, 0.8), CFrame.new(x + 25 + side * 0.6, 1.3, z + 2), dark, Enum.Material.SmoothPlastic, false)
        scene:Part(model, "ClerkArm", Vector3.new(0.5, 2, 0.6), CFrame.new(x + 25 + side * 1.2, 3.3, z + 2), accent, Enum.Material.SmoothPlastic, false)
        local eye = scene:Part(model, "ClerkEye", Vector3.new(0.12, 0.12, 0.1), CFrame.new(x + 25 + side * 0.25, 5.3, z + 2.68), dark, Enum.Material.SmoothPlastic, false)
        eye.Shape = Enum.PartType.Ball
    end
    scene:Sign(model, "E • " .. title, CFrame.new(x, 9, z - 29), Vector3.new(54, 5, 0.2), Color3.fromRGB(229, 239, 232))
    local marker = scene:Part(model, "Interaction", Vector3.new(5, 0.1, 5), CFrame.new(location.X, 0.5, location.Z), accent, Enum.Material.Neon, false)
    for index = 1, 3 do
        scene:Part(model, "DisplayShelf", Vector3.new(14, 0.5, 5), CFrame.new(x - 28, 2 + index * 3, z - 12), concrete, Enum.Material.Metal, false)
        scene:Part(model, "Merchandise", Vector3.new(3, 2, 2), CFrame.new(x - 28 + (index % 2) * 4, 3.3 + index * 3, z - 12), accent, Enum.Material.SmoothPlastic, false)
    end
    return model, marker
end
local function street(scene: any, name: string, x: number, z: number, length: number, alongX: boolean)
    local model = scene:Model(name)
    local roadSize = if alongX then Vector3.new(length, 0.16, 30) else Vector3.new(30, 0.16, length)
    scene:Part(model, "Asphalt", roadSize, CFrame.new(x, 0.08, z), Color3.fromRGB(41, 46, 52), Enum.Material.Asphalt, false)
    for _, side in {-1, 1} do
        local size = if alongX then Vector3.new(length, 0.2, 10) else Vector3.new(10, 0.2, length)
        local offset = if alongX then Vector3.new(0, 0.1, side * 20) else Vector3.new(side * 20, 0.1, 0)
        scene:Part(model, "Pavement", size, CFrame.new(Vector3.new(x, 0, z) + offset), concrete, Enum.Material.Concrete, false)
    end
    for offset = -length / 2 + 10, length / 2 - 10, 26 do
        local size = if alongX then Vector3.new(10, 0.04, 0.4) else Vector3.new(0.4, 0.04, 10)
        scene:Part(model, "Lane", size, CFrame.new(x + (if alongX then offset else 0), 0.19, z + (if alongX then 0 else offset)), Color3.fromRGB(231, 216, 168), Enum.Material.SmoothPlastic, false)
    end
end
function City.Build(scene: any, config: any)
    street(scene, "RiversideBoulevard", -120, 0, 1100, true)
    street(scene, "LakeStreet", -290, 155, 510, false)
    street(scene, "EastAvenue", 260, 0, 700, false)
    street(scene, "ParkLane", -130, 193, 440, true)
    street(scene, "IslandAvenue", 990, 0, 760, true)
    for _, position in {Vector3.new(-290, 0, 0), Vector3.new(260, 0, 0), Vector3.new(-290, 0, 193)} do
        local x, z = position.X, position.Z
        local crossing = scene:Model("Intersection")
        scene:Part(crossing, "IntersectionAsphalt", Vector3.new(50, 0.25, 50), CFrame.new(x, 0.13, z), Color3.fromRGB(41, 46, 52), Enum.Material.Asphalt, false)
        for stripe = -12, 12, 6 do
            for _, side in {-1, 1} do scene:Part(crossing, "Crosswalk", Vector3.new(3, 0.025, 8), CFrame.new(x + stripe, 0.275, z + side * 20), Color3.fromRGB(224, 223, 207), Enum.Material.SmoothPlastic, false) end
        end
    end
    local plaza = scene:Model("SpawnPlaza")
    scene:Part(plaza, "Paving", Vector3.new(175, 0.25, 140), CFrame.new(-25, 0.13, 90), Color3.fromRGB(186, 180, 164), Enum.Material.Slate, false)
    for index = -2, 2 do
        scene:Part(plaza, "PavingBand", Vector3.new(175, 0.03, 1), CFrame.new(-25, 0.28, 90 + index * 24), concrete, Enum.Material.Concrete, false)
    end
    local fountain = scene:Part(plaza, "FountainBasin", Vector3.new(23, 1.5, 23), CFrame.new(-25, 0.75, 115), concrete, Enum.Material.Marble, true)
    fountain.Shape = Enum.PartType.Cylinder; fountain.CFrame *= CFrame.Angles(0, 0, math.pi / 2); fountain.Size = Vector3.new(1.5, 23, 23)
    local water = scene:Part(plaza, "FountainWater", Vector3.new(0.1, 21, 21), CFrame.new(-25, 1.55, 115) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(86, 182, 189), Enum.Material.Glass, false)
    water.Shape = Enum.PartType.Cylinder
    scene:Part(plaza, "Sculpture", Vector3.new(2, 10, 2), CFrame.new(-25, 6, 115) * CFrame.Angles(0, 0, 0.15), Color3.fromRGB(77, 232, 184), Enum.Material.Metal, false)
    scene:Sign(plaza, "RIVERSIDE\nGARAŻ ← • MOST / ARENA →", CFrame.new(-25, 11, 35), Vector3.new(35, 7, 0.5), Color3.fromRGB(127, 234, 201))
    for _, x in {-95, 45} do
        for _, z in {55, 145} do
            scene:Tree(Vector3.new(x, 0, z), 1)
            local bench = scene:Model("Bench")
            scene:Part(bench, "Seat", Vector3.new(10, 0.5, 3), CFrame.new(x + 13, 2, z), Color3.fromRGB(139, 101, 66), Enum.Material.WoodPlanks, false)
            scene:Part(bench, "Back", Vector3.new(10, 2.5, 0.4), CFrame.new(x + 13, 3, z - 1.5), dark, Enum.Material.Metal, false)
        end
    end
    for index, position in {Vector3.new(-200, 0, -205), Vector3.new(-80, 0, -230), Vector3.new(45, 0, -220), Vector3.new(180, 0, -220), Vector3.new(180, 0, 160), Vector3.new(300, 0, -220), Vector3.new(-460, 0, -125), Vector3.new(-450, 0, 100), Vector3.new(325, 0, 210)} do
        local model = scene:Model("Residence_" .. index)
        local height = 24 + index % 4 * 8
        local color = if index % 2 == 0 then Color3.fromRGB(157, 146, 124) else Color3.fromRGB(123, 142, 153)
        scene:Part(model, "Building", Vector3.new(65, height, 55), CFrame.new(position + Vector3.new(0, height / 2, 0)), color, Enum.Material.Brick, true)
        scene:Part(model, "Roof", Vector3.new(69, 2, 59), CFrame.new(position + Vector3.new(0, height + 1, 0)), dark, Enum.Material.Concrete, true)
        for floor = 1, math.floor(height / 8) do
            for _, side in {-1, 1} do
                scene:Part(model, "WindowStrip", Vector3.new(53, 4, 0.2), CFrame.new(position + Vector3.new(0, floor * 8 - 3, side * 27.7)), glass, Enum.Material.Glass, false)
            end
        end
        scene:Part(model, "Door", Vector3.new(8, 10, 0.3), CFrame.new(position + Vector3.new(0, 5, 27.8)), dark, Enum.Material.Metal, false)
    end
    for x = -600, 380, 70 do scene:Lamp(Vector3.new(x, 0, 28)) end
    for index = 1, 16 do
        local x = -500 + index * 52
        scene:Tree(Vector3.new(x, 0, if index % 2 == 0 then 250 else -300), index)
    end
    -- Shore promenades stop at the river, so the actual bridge is the traversable crossing.
    for _, x in {425, 615} do
        local model = scene:Model("RiverPromenade")
        scene:Part(model, "Walkway", Vector3.new(16, 0.2, 850), CFrame.new(x, 0.1, 0), concrete, Enum.Material.Concrete, false)
        for _, z in {-235, 235} do scene:Lamp(Vector3.new(x, 0, z)) end
    end
end
return City
