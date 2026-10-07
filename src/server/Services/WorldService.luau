--!strict
local Workspace = game:GetService("Workspace")
local Builder = require(script.Parent.Parent.Modules.WorldBuilder)
local WorldService = {}
local context: any
local roads: {any} = {}
local lights: {PointLight} = {}
local markers: {[string]: Part} = {}
local signals: {Part} = {}
local generated: Folder
function WorldService:Init(ctx: any) context = ctx end
function WorldService:GetRoads(): {any} return roads end
function WorldService:GetLights(): {PointLight} return lights end
function WorldService:GetLocation(id: string): Vector3?
    local location = context.Config.World.Locations[id]
    return if location then Vector3.new(location.X, 1, location.Z) else nil
end
function WorldService:IsNear(player: Player, id: string): boolean
    local location = context.Config.World.Locations[id]
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not location or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
    local target = Vector3.new(location.X, root.Position.Y, location.Z)
    return math.abs(root.Position.Y) < 15 and (root.Position - target).Magnitude <= location.Radius
end
function WorldService:GetSignalPhase(): number
    return math.floor(os.clock() / context.Config.World.SignalSeconds) % 2
end
function WorldService:Start()
    local map = Workspace:FindFirstChild("Map")
    assert(map and map:IsA("Folder"), "Rojo must create Workspace.Map")
    local existing = map:FindFirstChild("Generated")
    assert(not existing or existing:GetAttribute("GeneratedBy") == "KukirinCity", "Reserved Map.Generated contains user content")
    if existing then existing:Destroy() end
    generated = Instance.new("Folder")
    generated.Name = "Generated"
    generated:SetAttribute("GeneratedBy", "KukirinCity")
    generated.Parent = map
    roads = context.Layout.CreateRoads(context.Config.World, context.Config.Roads)
    local roadFolder = Instance.new("Folder")
    roadFolder.Name = "Roads"
    roadFolder.Parent = generated
    for _, road in roads do Builder.Road(roadFolder, road) end
    local districts = Instance.new("Folder")
    districts.Name = "Districts"
    districts.Parent = generated
    for _, district in context.Config.World.Districts do Builder.District(districts, district, context.Layout, context.Config.World.Locations) end
    local titles: {[string]: string} = {Garage = "GARAŻ", ScooterShop = "HULAJNOGI", UpgradeShop = "UPGRADE", DeliveryHub = "DOSTAWY", DeliveryTarget = "PUNKT DOSTAWY"}
    for id, location in context.Config.World.Locations do
        local marker = Builder.Part(generated, id, Vector3.new(9, 1, 9), CFrame.new(location.X, 0.7, location.Z), Color3.fromRGB(58, 179, 151), false)
        markers[id] = marker
        Builder.Label(marker, titles[id] or id, 180)
        if id ~= "DeliveryTarget" then
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Otwórz"
            prompt.ObjectText = titles[id] or id
            prompt.MaxActivationDistance = 18
            prompt.KeyboardKeyCode = Enum.KeyCode.F
            prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
            prompt.RequiresLineOfSight = false
            prompt.Parent = marker
            prompt.Triggered:Connect(function(player: Player)
                if self:IsNear(player, id) and context.Services.PlayerData:IsReady(player) then
                    context.OpenMenu(player, if id == "DeliveryHub" then "Quests" elseif id == "Garage" then "Garage" else "Shop")
                end
            end)
        end
    end
    for index = 1, 8 do
        local x = if index <= 4 then -24 else 24
        local z = -450 + ((index - 1) % 4) * 300
        local pole = Builder.Part(generated, "StreetLight", Vector3.new(0.5, 12, 0.5), CFrame.new(x, 6, z), Color3.fromRGB(73, 80, 91), false)
        local light = Instance.new("PointLight")
        light.Range, light.Brightness, light.Shadows = 20, 1, false
        light.Parent = pole
        table.insert(lights, light)
    end
    for _, offset in {Vector3.new(-22, 3, -22), Vector3.new(22, 3, 22)} do
        table.insert(signals, Builder.Part(generated, "TrafficLight", Vector3.new(1, 3, 1), CFrame.new(offset), Color3.fromRGB(60, 170, 95), false))
    end
end
function WorldService:UpdateSignals()
    local phase = self:GetSignalPhase()
    for index, signal in signals do
        signal.Color = if index - 1 == phase then Color3.fromRGB(60, 190, 90) else Color3.fromRGB(215, 65, 65)
    end
end
return WorldService
