--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Builder = require(script.Parent.Parent.Modules.WorldBuilder)
local Factory = require(script.Parent.Parent.Modules.ScooterFactory)
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
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) promptLimiter:Remove(player.UserId) end)
    local map = Workspace:WaitForChild("Map")
    local previous = map:FindFirstChild("ZoneGenerated")
    assert(not previous or previous:GetAttribute("GeneratedBy") == "KukirinZone", "Map.ZoneGenerated is reserved")
    if previous then previous:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "ZoneGenerated", map
    folder:SetAttribute("GeneratedBy", "KukirinZone")
    local function block(name: string, size: Vector3, position: Vector3, color: Color3, collision: boolean): Part
        local part = Builder.Part(folder, name, size, CFrame.new(position), color, collision)
        part.CanQuery = collision
        return part
    end
    for _, id in {"SafeZone", "CombatZone", "FishingArea"} do
        local area = context.Config.Zones.Areas[id]
        local color = if id == "CombatZone" then Color3.fromRGB(91, 56, 66) elseif id == "FishingArea" then Color3.fromRGB(49, 96, 107) else Color3.fromRGB(48, 100, 84)
        local surface = block(id, Vector3.new(area.Size[1], 0.1, area.Size[3]), Vector3.new(area.Center[1], 0.06, area.Center[3]), color, false)
        Builder.Label(surface, area.DisplayName, 250)
        for _, sign in {-1, 1} do
            block(id .. "Boundary", Vector3.new(area.Size[1], 0.2, 1), Vector3.new(area.Center[1], 0.15, area.Center[3] + sign * area.Size[3] / 2), color, false)
            block(id .. "Boundary", Vector3.new(1, 0.2, area.Size[3]), Vector3.new(area.Center[1] + sign * area.Size[1] / 2, 0.15, area.Center[3]), color, false)
        end
    end
    block("MainRoad", Vector3.new(720, 0.1, 24), Vector3.new(0, 0.2, 0), Color3.fromRGB(39, 43, 52), false)
    block("LakeRoad", Vector3.new(22, 0.1, 160), Vector3.new(-220, 0.2, 75), Color3.fromRGB(39, 43, 52), false)
    for x = -330, 330, 30 do block("RoadMarking", Vector3.new(10, 0.1, 0.6), Vector3.new(x, 0.28, 0), Color3.fromRGB(225, 210, 147), false) end
    for _, x in {135, 180, 240, 290, 325} do
        for _, z in {-85, -45, 45, 85} do
            block("Cover", Vector3.new(10, 10, 12), Vector3.new(x, 5, z), Color3.fromRGB(90 + x % 30, 98, 118), true)
        end
    end
    for _, x in {160, 275} do
        local ramp = block("Ramp", Vector3.new(12, 1, 20), Vector3.new(x, 2.6, 110), Color3.fromRGB(91, 99, 111), true)
        ramp.CFrame *= CFrame.Angles(math.rad(-15), 0, 0)
    end
    local pond = block("Lake", Vector3.new(55, 0.3, 75), Vector3.new(-255, 0.25, 175), Color3.fromRGB(48, 142, 184), false)
    pond.Material, pond.Transparency = Enum.Material.Glass, 0.2
    block("Dock", Vector3.new(15, 0.5, 28), Vector3.new(-220, 0.35, 166), Color3.fromRGB(132, 104, 77), true)
    local titles = {Garage = "GARAŻ", ScooterShop = "DEALERSHIP", UpgradeShop = "WORKSHOP", EquipmentShop = "WYPOSAŻENIE", CosmeticsShop = "KOSMETYKI", FishingDock = "AUTO FISHING", FishBuyer = "FISH BUYER"}
    for id, location in context.Config.World.Locations do
        local marker = block(id, Vector3.new(8, 0.5, 8), Vector3.new(location.X, 0.55, location.Z), Color3.fromRGB(76, 213, 174), false)
        Builder.Label(marker, titles[id], 150)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText, prompt.ObjectText = if id == "FishingDock" then "Łów" else "Otwórz", titles[id]
        prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
        prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 12, false
        prompt.Parent = marker
        prompt.Triggered:Connect(function(player: Player)
            if context.IsClosing or not promptLimiter:Allow(player.UserId, os.clock()) then return end
            if not self:IsNear(player, id) or not context.Services.PlayerData:IsReady(player) then return end
            if id == "FishingDock" then
                local ok, message = context.Services.Fishing:Toggle(player)
                context.Feedback(player, ok, message)
            else context.OpenMenu(player, id) end
        end)
        if id ~= "FishingDock" then
            block(id .. "Kiosk", Vector3.new(10, 8, 4), Vector3.new(location.X, 4, location.Z + 10), Color3.fromRGB(64, 73, 90), true)
        end
    end
    local objective = context.Config.World.Objective
    local point = block("ControlPoint", Vector3.new(16, 0.15, 16), Vector3.new(objective.X, 0.3, objective.Z), Color3.fromRGB(196, 165, 86), false)
    Builder.Label(point, "CONTROL POINT — 2+ SQUAD", 180)
    for index, id in {"kukirin_g2", "volt_city", "kukirin_g3", "volt_dual", "kukirin_g4"} do
        local item = context.Config.Scooters.ById[id]
        local model = Factory.Create(id, item.DisplayName, -index, CFrame.new(25 + index * 9, 1.1, -60))
        model.Model.Name = "Showroom_" .. id
        model.Model.Parent = folder
        model.Seat.Disabled, model.Prompt.Enabled = true, false
        Builder.Label(model.Root, item.DisplayName .. " • " .. item.Price, 60)
    end
    for x = -300, 300, 100 do
        local pole = block("LightPole", Vector3.new(0.8, 12, 0.8), Vector3.new(x, 6, 17), Color3.fromRGB(73, 79, 92), false)
        local light = Instance.new("PointLight")
        light.Range, light.Brightness, light.Shadows, light.Parent = 24, 1, false, pole
        table.insert(lights, light)
    end
end
return Service
