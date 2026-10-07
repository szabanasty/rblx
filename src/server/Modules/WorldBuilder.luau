--!strict
-- Procedural blockout uses Roblox primitives only; no licensed art is assumed.
local CollectionService = game:GetService("CollectionService")
local Builder = {}
function Builder.Part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, collidable: boolean?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = frame
    part.Anchored = true
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.CanCollide = collidable ~= false
    part.CanTouch = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end
function Builder.Label(part: BasePart, text: string, maximumDistance: number?)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Size = UDim2.fromOffset(220, 50)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.MaxDistance = maximumDistance or 140
    gui.AlwaysOnTop = false
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(20, 27, 40)
    label.BackgroundTransparency = 0.2
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextWrapped = true
    label.Parent = gui
end
function Builder.Road(parent: Instance, road: any)
    local size = if road.Axis == "X" then Vector3.new(road.Width, 0.2, road.Length) else Vector3.new(road.Length, 0.2, road.Width)
    local surface = Builder.Part(parent, road.RoadId, size, CFrame.new(road.X, 0.1, road.Z), Color3.fromRGB(42, 45, 52))
    surface.Material = Enum.Material.Asphalt
    for _, key in {"RoadId", "SpeedLimit", "RoadType", "District", "PoliceEnabled"} do surface:SetAttribute(key, road[key]) end
    for _, side in {-1, 1} do
        local offset = side * (road.Width / 2 + 5)
        local sidewalkSize = if road.Axis == "X" then Vector3.new(10, 0.4, road.Length) else Vector3.new(road.Length, 0.4, 10)
        local frame = if road.Axis == "X" then CFrame.new(road.X + offset, 0.2, road.Z) else CFrame.new(road.X, 0.2, road.Z + offset)
        Builder.Part(parent, road.RoadId .. "_Sidewalk", sidewalkSize, frame, Color3.fromRGB(122, 126, 132))
    end
    for marker = -6, 6 do
        local position = marker * 95
        local markerSize = if road.Axis == "X" then Vector3.new(0.4, 0.05, 25) else Vector3.new(25, 0.05, 0.4)
        local frame = if road.Axis == "X" then CFrame.new(road.X, 0.23, position) else CFrame.new(position, 0.23, road.Z)
        Builder.Part(parent, "LaneMark", markerSize, frame, Color3.fromRGB(235, 218, 159), false)
    end
    local sign = Builder.Part(parent, "SpeedSign", Vector3.new(3, 5, 0.4), CFrame.new(road.X + 24, 3, road.Z + 24), Color3.fromRGB(245, 245, 245), false)
    Builder.Label(sign, tostring(road.SpeedLimit) .. " km/h", 120)
end
function Builder.District(parent: Instance, district: any, layout: any, locations: any)
    local folder = Instance.new("Folder")
    folder.Name = district.Id
    folder.Parent = parent
    local colors = district.Color
    local color = Color3.fromRGB(colors[1], colors[2], colors[3])
    local sign = Builder.Part(folder, "DistrictSign", Vector3.new(5, 7, 0.5), CFrame.new(district.X, 3.5, district.Z), color, false)
    Builder.Label(sign, district.Name .. " • placeholder", 220)
    if district.Id == "Park" or district.Id == "Hills" then
        Builder.Part(folder, "GreenArea", Vector3.new(210, 0.3, 210), CFrame.new(district.X, 0.15, district.Z), Color3.fromRGB(85, 127, 81))
        for index = 1, 5 do
            local x, z = district.X - 85 + index * 25, district.Z - 60 + (index % 2) * 110
            Builder.Part(folder, "TreeTrunk", Vector3.new(2, 10, 2), CFrame.new(x, 5, z), Color3.fromRGB(101, 76, 52))
            local leaves = Builder.Part(folder, "TreeCanopy", Vector3.new(12, 12, 12), CFrame.new(x, 13, z), Color3.fromRGB(67, 106, 70), false)
            leaves.Shape = Enum.PartType.Ball
            leaves:SetAttribute("Decorative", true)
            CollectionService:AddTag(leaves, "WorldDecoration")
        end
        if district.Id == "Hills" then
            Builder.Part(folder, "JumpRamp", Vector3.new(16, 1, 35), CFrame.new(district.X, 4, district.Z + 50) * CFrame.Angles(math.rad(-12), 0, 0), color)
        end
    elseif district.Id == "Beach" then
        Builder.Part(folder, "SandPlaceholder", Vector3.new(210, 0.3, 210), CFrame.new(district.X, 0.15, district.Z), Color3.fromRGB(218, 198, 143))
        Builder.Part(folder, "WaterPlaceholder", Vector3.new(210, 0.2, 55), CFrame.new(district.X, 0.1, district.Z + 90), Color3.fromRGB(61, 144, 185), false)
    else
        for index, offset in {Vector3.new(-70, 0, -65), Vector3.new(70, 0, -65), Vector3.new(-70, 0, 65), Vector3.new(70, 0, 65)} do
            local position = Vector3.new(district.X, 0, district.Z) + offset
            if not layout.IsBuildingClear(position.X, position.Z, 57, 47, locations) then continue end
            local model = Instance.new("Model")
            model.Name = "Building_" .. index
            model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
            model.Parent = folder
            local height = if district.Id == "Downtown" then 35 + index * 12 else 14 + index * 3
            Builder.Part(model, "Shell", Vector3.new(55, height, 45), CFrame.new(position + Vector3.new(0, height / 2, 0)), color)
            Builder.Part(model, "Roof", Vector3.new(57, 1, 47), CFrame.new(position + Vector3.new(0, height + 0.5, 0)), Color3.fromRGB(53, 60, 68), false)
        end
    end
end
function Builder.Vehicle(parent: Instance, name: string, frame: CFrame, color: Color3): Model
    local model = Instance.new("Model")
    model.Name = name
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = parent
    local body = Builder.Part(model, "Body", Vector3.new(5, 2, 9), frame, color, false)
    model.PrimaryPart = body
    Builder.Part(model, "Cabin", Vector3.new(4.3, 1.5, 4.5), frame * CFrame.new(0, 1.5, 0), Color3.fromRGB(63, 78, 93), false)
    for _, offset in {Vector3.new(-2.5, -0.6, -2.8), Vector3.new(2.5, -0.6, -2.8), Vector3.new(-2.5, -0.6, 2.8), Vector3.new(2.5, -0.6, 2.8)} do
        local wheel = Builder.Part(model, "Wheel", Vector3.new(0.8, 1.6, 1.6), frame * CFrame.new(offset), Color3.fromRGB(24, 27, 31), false)
        wheel.Shape = Enum.PartType.Cylinder
    end
    return model
end
return Builder
