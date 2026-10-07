--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Modules = script.Parent.Parent.Modules
local SceneBuilder = require(Modules.SceneBuilder)
local City = require(Modules.CityScene)
local Island = require(Modules.IslandScene)
local Factory = require(Modules.ScooterFactory)
local Service = {}
local context: any
local lights: {PointLight} = {}
local promptLimiter: any
function Service:Init(ctx: any)
    context = ctx
    promptLimiter = ctx.RateLimiter.new(3, 2)
end
function Service:GetLights(): {PointLight} return lights end
function Service:IsNear(player: Player, id: string): boolean
    local location = context.Config.World.Locations[id]
    local position = context.Services.Movement:GetPosition(player)
    return location ~= nil and position ~= nil and math.abs(position.Y) <= 15
        and (position - Vector3.new(location.X, position.Y, location.Z)).Magnitude <= location.Radius
end
local function atmosphere()
    Lighting.Brightness, Lighting.GlobalShadows, Lighting.ShadowSoftness = 2.5, true, 0.35
    Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(98, 111, 128), Color3.fromRGB(138, 149, 163)
    Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.6, 0.7
    local previous = Lighting:FindFirstChild("ZoneAtmosphere")
    if previous then previous:Destroy() end
    local effect = Instance.new("Atmosphere")
    effect.Name, effect.Density, effect.Offset, effect.Color, effect.Decay = "ZoneAtmosphere", 0.22, 0.1, Color3.fromRGB(204, 226, 235), Color3.fromRGB(104, 137, 169)
    effect.Glare, effect.Haze, effect.Parent = 0.1, 0.8, Lighting
    local correction = Lighting:FindFirstChild("ZoneColor")
    if correction then correction:Destroy() end
    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name, grade.Saturation, grade.Contrast, grade.TintColor, grade.Parent = "ZoneColor", 0.08, 0.08, Color3.fromRGB(255, 249, 238), Lighting
end
local function interaction(part: BasePart, id: string, title: string, action: string, callback: (Player) -> ())
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = action, title
    prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 14, false
    prompt.Parent = part
    prompt.Triggered:Connect(function(player: Player)
        if context.IsClosing or not promptLimiter:Allow(player.UserId, os.clock()) then return end
        if not Service:IsNear(player, id) or not context.Services.PlayerData:IsReady(player) then return end
        callback(player)
    end)
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) promptLimiter:Remove(player.UserId) end)
    local map = Workspace:WaitForChild("Map")
    local preview = map:FindFirstChild("ScenePreview")
    if preview then preview:Destroy() end -- Rojo-owned editor model; runtime has modular models and validated interactions.
    local previous = map:FindFirstChild("ZoneGenerated")
    assert(not previous or previous:GetAttribute("GeneratedBy") == "KukirinZone", "Map.ZoneGenerated is reserved")
    if previous then previous:Destroy() end
    table.clear(lights)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "ZoneGenerated", map
    folder:SetAttribute("GeneratedBy", "KukirinZone")
    local scene = SceneBuilder.new(folder, lights)
    local cfg = context.Config.World
    local half, river = cfg.Width / 2, cfg.River
    local left, right = river.X - river.Width / 2, river.X + river.Width / 2
    scene:Part(folder, "WestLand", Vector3.new(half + left, 12, cfg.Width), CFrame.new((left - half) / 2, -6, 0), Color3.fromRGB(100, 135, 105), Enum.Material.Grass, true)
    scene:Part(folder, "EastLand", Vector3.new(half - right, 12, cfg.Width), CFrame.new((half + right) / 2, -6, 0), Color3.fromRGB(109, 128, 109), Enum.Material.Grass, true)
    local water = scene:Part(folder, "RiverWater", Vector3.new(river.Width, 0.2, cfg.Width), CFrame.new(river.X, river.WaterY, 0), Color3.fromRGB(49, 126, 157), Enum.Material.Glass, false)
    water.Transparency, water.Reflectance = 0.18, 0.1
    for _, shore in {left, right} do scene:Part(folder, "RiverBank", Vector3.new(5, 12, cfg.Width), CFrame.new(shore, -6, 0), Color3.fromRGB(129, 126, 112), Enum.Material.Rock, true) end
    City.Build(scene, cfg)
    Island.Build(scene, cfg, context.Config.Zones)
    local titles: {[string]: string} = {Garage = "VOLT GARAGE", ScooterShop = "VOLT MOTORS", UpgradeShop = "WORKSHOP", EquipmentShop = "ARCADE SUPPLY", CosmeticsShop = "STREET STUDIO", FishBuyer = "WILLOW FISH MARKET"}
    for _, id in {"Garage", "ScooterShop", "UpgradeShop", "EquipmentShop", "CosmeticsShop", "FishBuyer"} do
        local accent = if id == "ScooterShop" or id == "Garage" then Color3.fromRGB(246, 162, 69) elseif id == "EquipmentShop" then Color3.fromRGB(101, 213, 234) else Color3.fromRGB(134, 221, 177)
        local shop, marker = City.Shop(scene, id, cfg.Locations[id], titles[id], accent)
        interaction(marker, id, titles[id], "Otwórz sklep / garaż", function(player: Player) context.OpenMenu(player, id) end)
        if id == "Garage" then
            local location = cfg.Locations[id]
            local pad = scene:Part(shop, "ScooterPickup", Vector3.new(8, 0.12, 10), CFrame.new(location.X - 16, 0.5, location.Z + 6), Color3.fromRGB(235, 171, 86), Enum.Material.Neon, false)
            scene:Sign(shop, "ODBIERZ SWOJĄ HULAJNOGĘ\nE • PRZYWOŁAJ I JEDŹ", CFrame.new(location.X - 16, 8, location.Z + 5), Vector3.new(24, 5, 0.3), Color3.fromRGB(255, 216, 149))
            interaction(pad, id, "TWOJA HULAJNOGA", "Przywołaj i jedź", function(player: Player)
                local ok, message = context.Services.Scooter:Spawn(player)
                context.Feedback(player, ok, message)
            end)
        end
        if id == "ScooterShop" then
            local location = cfg.Locations[id]
            for index, scooterId in {"kukirin_g2", "volt_city", "kukirin_g3", "volt_dual", "kukirin_g4"} do
                local item = context.Config.Scooters.ById[scooterId]
                local x = location.X - 30 + (index - 1) * 13
                local platform = scene:Part(shop, "DisplayPlatform", Vector3.new(8, 0.5, 9), CFrame.new(x, 0.75, location.Z - 48), Color3.fromRGB(57, 65, 74), Enum.Material.Metal, true)
                local assembly = Factory.Create(scooterId, item.DisplayName, -index, CFrame.new(x, 2, location.Z - 48) * CFrame.Angles(0, 0.4, 0))
                assembly.Model.Name, assembly.Model.Parent = "Showroom_" .. scooterId, shop
                assembly.Seat.Disabled, assembly.Prompt.Enabled = true, false
                scene:Sign(shop, item.Class .. "\n" .. item.Price .. " MONEY • LEVEL " .. item.UnlockLevel, CFrame.new(x, 2.5, location.Z - 42), Vector3.new(10, 3, 0.25), accent)
                interaction(platform, id, item.Class .. " • MODEL WYSTAWOWY", "Zobacz ofertę", function(player: Player) context.OpenMenu(player, "ScooterShop") end)
            end
        end
        if id == "UpgradeShop" then
            local p = cfg.Locations[id]
            scene:Part(shop, "ServiceLift", Vector3.new(15, 1, 20), CFrame.new(p.X - 15, 1, p.Z - 32), Color3.fromRGB(57, 72, 85), Enum.Material.Metal, true)
            for _, side in {-1, 1} do scene:Part(shop, "LiftPost", Vector3.new(1, 10, 2), CFrame.new(p.X - 15 + side * 9, 5, p.Z - 32), accent, Enum.Material.Metal, false) end
        end
    end
    local fishing = scene:Model("WillowLake")
    local dock = cfg.Locations.FishingDock
    scene:Part(fishing, "Lake", Vector3.new(160, 0.2, 95), CFrame.new(dock.X - 15, 0.13, dock.Z + 45), Color3.fromRGB(67, 154, 173), Enum.Material.Glass, false)
    scene:Part(fishing, "Sand", Vector3.new(160, 0.08, 22), CFrame.new(dock.X - 15, 0.1, dock.Z - 10), Color3.fromRGB(195, 183, 141), Enum.Material.Sand, false)
    local pier = scene:Part(fishing, "Dock", Vector3.new(18, 0.65, 45), CFrame.new(dock.X, 0.45, dock.Z + 10), Color3.fromRGB(150, 116, 76), Enum.Material.WoodPlanks, true)
    for _, side in {-1, 1} do
        scene:Part(fishing, "DockRail", Vector3.new(0.5, 3, 40), CFrame.new(dock.X + side * 9, 2, dock.Z + 12), Color3.fromRGB(104, 84, 64), Enum.Material.Wood, true)
    end
    scene:Sign(fishing, "WILLOW LAKE\nE • AUTO FISHING", CFrame.new(dock.X, 9, dock.Z - 12), Vector3.new(26, 5, 0.4), Color3.fromRGB(192, 234, 221))
    interaction(pier, "FishingDock", "AUTO FISHING", "Łów / zatrzymaj", function(player: Player)
        local ok, message = context.Services.Fishing:Toggle(player)
        context.Feedback(player, ok, message)
    end)
    for index = 1, 10 do scene:Tree(Vector3.new(dock.X - 100 + index * 18, 0, dock.Z + 110), index) end
    atmosphere()
end
return Service
