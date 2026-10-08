--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Menus = require(script.Parent.Parent.Modules.ZoneMenus)
local Hud = require(script.Parent.Parent.Modules.ZoneHud)
local Layout = require(script.Parent.Parent.Modules.HudLayout)
local Service = {}
local context: any
local screen: ScreenGui
local refs: any = {}
local data: any
local handlers: any
local page = "Main"
local menuOpen = false
local showMap = false
local mapChosen = false
local mapDefault = false
local signature = ""
local toastVersion = 0
local scales: {UIScale} = {}
local touchInputs: {[InputObject]: string} = {}
local hud: any
local reviveAvailable = false
local releaseTouch: () -> ()
function Service:Init(ctx: any) context = ctx end
function Service:SetInputHandlers(value: any) handlers = value end
function Service:IsMenuOpen(): boolean return menuOpen end
local function resize()
    local camera = Workspace.CurrentCamera
    if not camera or camera.ViewportSize.X <= 28 or camera.ViewportSize.Y <= 90 then return end
    local view = if screen.AbsoluteSize.X > 0 then screen.AbsoluteSize else camera.ViewportSize
    local preference = if data and data.Settings then data.Settings.UIScale else 1
    local layout = Layout.Calculate(view.X, view.Y, preference, UserInputService.TouchEnabled)
    mapDefault = layout.MapDefault
    local ready = data ~= nil and data.Ready
    local riding = ready and data.Telemetry.Riding
    local activity = ready and (data.Fishing.Active or (data.PlayerState and data.PlayerState.AreaId == "CombatZone"))
    Hud.Resize(hud, layout, ready, riding, activity, menuOpen)
    local function place(object: GuiObject, name: string, baseScale: boolean?)
        local rect = layout.Panels[name]
        object.Position, object.AnchorPoint = UDim2.fromOffset(rect.X, rect.Y), Vector2.zero
        object.Size = UDim2.fromOffset(rect.W, rect.H)
        if baseScale then
            object.Size = UDim2.fromOffset(rect.W / layout.Scale, rect.H / layout.Scale)
            local objectScale = object:FindFirstChildOfClass("UIScale") :: UIScale
            objectScale.Scale = layout.Scale
        end
    end
    place(refs.OpenMenu, "Menu"); place(refs.MapToggle, "MapToggle"); place(refs.Map, "Map")
    place(refs.StopFishing, "StopFishing")
    local controlScale = layout.Panels.RideControls.W / 174
    for _, entry in {{refs.Pedals, "RideControls"}, {refs.RideActions, "RideActions"}} do
        local rect = layout.Panels[entry[2]]
        entry[1].Position, entry[1].Size = UDim2.fromOffset(rect.X, rect.Y), UDim2.fromOffset(rect.W / controlScale, rect.H / controlScale)
        entry[1]:FindFirstChildOfClass("UIScale").Scale = controlScale
    end
    refs.Menu.Size = UDim2.fromOffset(math.min(460, view.X - 24), math.min(600, view.Y - 24))
    for _, scale in scales do scale.Scale = math.min(1, (view.X - 24) / 370) end
    refs.Map.Visible = (if mapChosen then showMap else layout.MapDefault) and ready and not menuOpen
    refs.MapToggle.Visible = not layout.MapDefault and not menuOpen and (not layout.Small or showMap)
    if (showMap and layout.Compact) or reviveAvailable then
        for _, name in {"Equipment", "Scooter", "Activity"} do hud.Cards[name].Visible = false end
        if showMap then hud.Cards.Health.Visible = false; hud.Cards.Squad.Visible = false end
    end
    refs.StopFishing.Visible = ready and data.Fishing.Active and not menuOpen and not (showMap and layout.Compact)
    refs.Touch.Visible = ready and UserInputService.TouchEnabled and riding and not menuOpen and data.PlayerState ~= nil
        and data.PlayerState.State ~= "DOWNED" and data.PlayerState.State ~= "RESPAWNING"
    if not refs.Touch.Visible then releaseTouch() end
end
function Service:SetReviveAvailable(value: boolean)
    if reviveAvailable == value then return end
    reviveAvailable = value
    resize()
end
function Service:ToggleMap()
    showMap, mapChosen = not (if mapChosen then showMap else mapDefault), true
    Service:Close()
end
function Service:Open(pageName: string?)
    page = pageName or "Main"
    menuOpen = true
    refs.Menu.Visible = true
    context.Controllers.InputController:SetMenuOpen(true)
    signature = ""
    if data then Service:Update(data) end
    resize()
end
function Service:Close()
    menuOpen = false
    refs.Menu.Visible = false
    context.Controllers.InputController:SetMenuOpen(false)
    resize()
end
releaseTouch = function()
    if handlers then for _, key in touchInputs do handlers.Set(key, false) end end
    table.clear(touchInputs)
end
local function touchButton(parent: Instance, key: string, text: string, x: number, y: number)
    local button = Gui.Button(parent, text, function() end)
    button.Size, button.Position = UDim2.fromOffset(80, 70), UDim2.fromOffset(x, y)
    button.InputBegan:Connect(function(input: InputObject)
        if handlers and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            touchInputs[input] = key; handlers.Set(key, true)
        end
    end)
    button.InputEnded:Connect(function(input: InputObject)
        if handlers and touchInputs[input] then handlers.Set(touchInputs[input], false); touchInputs[input] = nil end
    end)
end
function Service:Start()
    screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "KukirinZone", ResetOnSpawn = false, DisplayOrder = 10})
    hud = Hud.Create(screen)
    local open = Gui.Button(screen, "MENU", function() Service:Open() end)
    refs.OpenMenu = open
    refs.MapToggle = Gui.Button(screen, "MAPA", function() Service:ToggleMap() end)
    refs.MapToggle.Size, refs.MapToggle.Position, refs.MapToggle.AnchorPoint = UDim2.fromOffset(92, 60), UDim2.new(1, -12, 0, 150), Vector2.new(1, 0)
    refs.StopFishing = Gui.Button(screen, "STOP ŁOWIENIA", function() context.Send("StopFishing", {}) end)
    refs.StopFishing.Size, refs.StopFishing.Position, refs.StopFishing.AnchorPoint = UDim2.fromOffset(170, 65), UDim2.new(1, -12, 0, 230), Vector2.new(1, 0)
    refs.StopFishing.Visible = false
    refs.Menu = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(460, 600), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(23, 31, 47), Visible = false, ZIndex = 20})
    Gui.Create("UICorner", refs.Menu, {CornerRadius = UDim.new(0, 14)})
    local back = Gui.Button(refs.Menu, "MENU GŁÓWNE", function() Service:Open("Main") end)
    back.Position, back.Size = UDim2.fromOffset(12, 8), UDim2.new(0.65, -18, 0, 55)
    local close = Gui.Button(refs.Menu, "ZAMKNIJ", function() Service:Close() end)
    close.Position, close.Size = UDim2.new(0.65, 0, 0, 8), UDim2.new(0.35, -12, 0, 55)
    refs.Content = Gui.Create("ScrollingFrame", refs.Menu, {Size = UDim2.new(1, -24, 1, -85), Position = UDim2.fromOffset(12, 73), BackgroundTransparency = 1,
        BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6})
    Gui.Create("UIListLayout", refs.Content, {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    refs.Downed = Gui.Label(screen, "", 100)
    refs.Downed.Size, refs.Downed.Position, refs.Downed.AnchorPoint = UDim2.fromOffset(350, 110), UDim2.fromScale(0.5, 0.35), Vector2.new(0.5, 0.5)
    refs.Downed.TextSize, refs.Downed.TextColor3, refs.Downed.TextXAlignment = 22, Color3.fromRGB(245, 160, 119), Enum.TextXAlignment.Center
    local downedScale = Gui.Create("UIScale", refs.Downed, {}); table.insert(scales, downedScale)
    refs.Toast = Gui.Label(screen, "", 55)
    refs.Toast.Size, refs.Toast.Position, refs.Toast.AnchorPoint = UDim2.fromOffset(350, 55), UDim2.fromScale(0.5, 0.22), Vector2.new(0.5, 0.5)
    refs.Toast.TextXAlignment = Enum.TextXAlignment.Center
    table.insert(scales, Gui.Create("UIScale", refs.Toast, {}))
    refs.Touch = Gui.Create("Frame", screen, {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
    local pedals = Gui.Create("Frame", refs.Touch, {BackgroundTransparency = 1, Size = UDim2.fromOffset(174, 155), Position = UDim2.new(1, -12, 1, -12), AnchorPoint = Vector2.new(1, 1)})
    refs.Pedals = pedals
    pedals.AnchorPoint = Vector2.zero
    Gui.Create("UIScale", pedals, {})
    touchButton(pedals, "Throttle", "GAZ", 88, 80); touchButton(pedals, "Brake", "HAMULEC", 0, 80)
    touchButton(pedals, "Left", "◀", 0, 0); touchButton(pedals, "Right", "▶", 88, 0)
    refs.RideActions = Gui.Create("Frame", refs.Touch, {BackgroundTransparency = 1})
    Gui.Create("UIScale", refs.RideActions, {})
    local jump = Gui.Button(refs.RideActions, "SKOK", function() if handlers then handlers.Set("Jump", true); task.delay(0.15, function() if handlers then handlers.Set("Jump", false) end end) end end)
    jump.Position, jump.Size = UDim2.fromOffset(88, 0), UDim2.fromOffset(80, 60)
    local dismount = Gui.Button(refs.RideActions, "ZEJDŹ", function() context.Send("DismountScooter", {}) end)
    dismount.Position, dismount.Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(80, 60)
    refs.Map = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(130, 130), Position = UDim2.new(1, -12, 0, 84), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(22, 29, 39)})
    refs.Map.Name, refs.Map.ClipsDescendants, refs.Map.BorderSizePixel = "Minimap", true, 0
    Gui.Create("UICorner", refs.Map, {CornerRadius = UDim.new(0, 10)})
    Gui.Create("UIStroke", refs.Map, {Color = Color3.fromRGB(80, 109, 125), Transparency = 0.5})
    local width = context.Config.Zones.WorldWidth
    local worldConfig = context.Config.World
    Gui.Create("Frame", refs.Map, {Position = UDim2.fromScale(0.5 + (worldConfig.River.X - worldConfig.River.Width / 2) / width, 0), Size = UDim2.fromScale(worldConfig.River.Width / width, 1), BackgroundColor3 = Color3.fromRGB(67, 146, 179), BorderSizePixel = 0})
    Gui.Create("Frame", refs.Map, {Position = UDim2.fromScale(0.5 + (worldConfig.Bridge.X - worldConfig.Bridge.Length / 2) / width, 0.5 - 0.007), Size = UDim2.fromScale(worldConfig.Bridge.Length / width, 0.014), BackgroundColor3 = Color3.fromRGB(237, 204, 130), BorderSizePixel = 0})
    for _, id in {"SafeZone", "CombatZone", "FishingArea"} do
        local area = context.Config.Zones.Areas[id]
        Gui.Create("Frame", refs.Map, {Position = UDim2.fromScale(0.5 + area.Center[1] / context.Config.Zones.WorldWidth - area.Size[1] / (2 * context.Config.Zones.WorldWidth), 0.5 + area.Center[3] / context.Config.Zones.WorldWidth - area.Size[3] / (2 * context.Config.Zones.WorldWidth)),
            Size = UDim2.fromScale(area.Size[1] / context.Config.Zones.WorldWidth, area.Size[3] / context.Config.Zones.WorldWidth), BorderSizePixel = 0,
            BackgroundColor3 = if id == "CombatZone" then Color3.fromRGB(155, 71, 88) else Color3.fromRGB(57, 149, 127)})
    end
    for _, name in {"Garage", "ScooterShop", "FishingDock"} do
        local p = worldConfig.Locations[name]
        local marker = Gui.Label(refs.Map, if name == "Garage" then "G" elseif name == "FishingDock" then "F" else "$", 12)
        marker.Size, marker.TextSize, marker.Position = UDim2.fromOffset(12, 12), 10, UDim2.fromScale(0.5 + p.X / width, 0.5 + p.Z / width)
    end
    refs.MapPlayer = Gui.Create("Frame", refs.Map, {Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0})
    UserInputService.InputEnded:Connect(function(input: InputObject)
        if handlers and touchInputs[input] then handlers.Set(touchInputs[input], false); touchInputs[input] = nil end
    end)
    UserInputService.WindowFocusReleased:Connect(releaseTouch)
    local cameraConnection: RBXScriptConnection? = nil
    local function cameraChanged()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera = Workspace.CurrentCamera
        if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged)
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    cameraChanged()
end
function Service:Update(snapshot: any)
    data = snapshot
    Hud.Update(hud, data, context.Config)
    if not data.Ready then
        refs.Downed.Text = ""
        refs.Touch.Visible, refs.StopFishing.Visible = false, false
        releaseTouch()
        Service:Close()
        resize()
        return
    end
    local state = data.PlayerState
    refs.Downed.Text = if state and state.State == "DOWNED" then "POWALONY\nOCZEKUJ NA POMOC DRUŻYNY\nODRODZENIE ZA " .. state.DownedSeconds .. "s" elseif data.Revive then "OCUCANIE... " .. math.floor(data.Revive.Progress * 100) .. "%" else ""
    if data.Position then refs.MapPlayer.Position = UDim2.fromScale(0.5 + data.Position.X / context.Config.Zones.WorldWidth, 0.5 + data.Position.Z / context.Config.Zones.WorldWidth) end
    if menuOpen then
        local memberIds: {number} = {}
        for _, member in data.Squad.Members do table.insert(memberIds, member.UserId) end
        local key = page .. HttpService:JSONEncode({data.Money, data.Level, data.OwnedScooters, data.SelectedScooter, data.ScooterUpgrades, data.OwnedEquipment, data.EquippedLoadout, data.Cosmetics, data.Fishing.Revision, data.Settings, data.Players, data.Squad.SquadId, data.Squad.Leader, data.Squad.Invite ~= nil, memberIds, data.Leaderboard})
        if key ~= signature then signature = key; Menus.Build(context, refs.Content, page, data, function(name: string) Service:Open(name) end) end
    end
    resize()
end
function Service:Notify(success: boolean, message: string)
    toastVersion += 1
    local version = toastVersion
    refs.Toast.Text, refs.Toast.TextColor3 = message, if success then Color3.fromRGB(100, 238, 181) else Color3.fromRGB(245, 162, 122)
    task.delay(3, function() if toastVersion == version then refs.Toast.Text = "" end end)
end
return Service
