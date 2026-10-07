--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Menus = require(script.Parent.Parent.Modules.ZoneMenus)
local Service = {}
local context: any
local screen: ScreenGui
local refs: any = {}
local data: any
local handlers: any
local page = "Main"
local menuOpen = false
local showMap = false
local signature = ""
local toastVersion = 0
local scales: {UIScale} = {}
local touchInputs: {[InputObject]: string} = {}
function Service:Init(ctx: any) context = ctx end
function Service:SetInputHandlers(value: any) handlers = value end
function Service:IsMenuOpen(): boolean return menuOpen end
local function resize()
    local camera = Workspace.CurrentCamera
    if not camera or camera.ViewportSize.X <= 28 or camera.ViewportSize.Y <= 90 then return end
    local view = camera.ViewportSize
    local preference = if data and data.Settings then data.Settings.UIScale else 1
    refs.HudScale.Scale = math.min(preference, (view.X - 28) / 370, (view.Y - 150) / 270)
    refs.Menu.Size = UDim2.fromOffset(math.min(460, view.X - 24), math.min(600, view.Y - 24))
    for _, scale in scales do scale.Scale = math.min(1, (view.X - 24) / 370) end
    refs.Map.Visible = (view.X >= 700 or showMap) and data ~= nil and data.Ready
    refs.MapToggle.Visible = view.X < 700
end
function Service:Open(pageName: string?)
    page = pageName or "Main"
    menuOpen = true
    refs.Menu.Visible = true
    context.Controllers.InputController:SetMenuOpen(true)
    signature = ""
    if data then Service:Update(data) end
end
function Service:Close()
    menuOpen = false
    refs.Menu.Visible = false
    context.Controllers.InputController:SetMenuOpen(false)
end
local function releaseTouch()
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
    refs.Hud = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(370, 270), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.fromRGB(21, 29, 43), BorderSizePixel = 0})
    Gui.Create("UICorner", refs.Hud, {CornerRadius = UDim.new(0, 12)})
    refs.HudScale = Gui.Create("UIScale", refs.Hud, {})
    for index, name in {"Title", "Money", "Health", "Area", "Squad", "Stats", "Scooter", "Equipment", "Activity", "Save"} do
        local label = Gui.Label(refs.Hud, "", 25)
        label.Position, label.Size = UDim2.fromOffset(12, (index - 1) * 25), UDim2.new(1, -24, 0, 25)
        label.TextWrapped, label.TextTruncate = false, Enum.TextTruncate.AtEnd
        refs[name] = label
    end
    refs.Title.Text = "KUKIRIN ZONE"
    local open = Gui.Button(screen, "MENU", function() Service:Open() end)
    open.Size, open.Position, open.AnchorPoint = UDim2.fromOffset(92, 60), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0)
    refs.MapToggle = Gui.Button(screen, "MAPA", function() showMap = not showMap; resize() end)
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
    table.insert(scales, Gui.Create("UIScale", pedals, {}))
    touchButton(pedals, "Throttle", "GAZ", 88, 80); touchButton(pedals, "Brake", "HAMULEC", 0, 80)
    touchButton(pedals, "Left", "◀", 0, 0); touchButton(pedals, "Right", "▶", 88, 0)
    local jump = Gui.Button(refs.Touch, "SKOK", function() if handlers then handlers.Set("Jump", true); task.delay(0.15, function() if handlers then handlers.Set("Jump", false) end end) end end)
    jump.Position, jump.Size, jump.AnchorPoint = UDim2.new(1, -12, 1, -180), UDim2.fromOffset(80, 60), Vector2.new(1, 1)
    local dismount = Gui.Button(refs.Touch, "ZEJDŹ", function() context.Send("DismountScooter", {}) end)
    dismount.Position, dismount.Size, dismount.AnchorPoint = UDim2.new(1, -100, 1, -180), UDim2.fromOffset(80, 60), Vector2.new(1, 1)
    refs.Map = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(130, 130), Position = UDim2.new(1, -12, 0, 84), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(22, 29, 39)})
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
    cameraChanged()
end
local function ctxScooterName(id: string): string
    local item = context.Config.Scooters.ById[id]
    return if item then item.DisplayName else id
end
function Service:Update(snapshot: any)
    data = snapshot
    refs.Save.Text = tostring(data.SaveMode) .. " • " .. tostring(data.Status)
    if not data.Ready then
        refs.Money.Text = "Wczytywanie profilu..."
        for _, name in {"Health", "Area", "Squad", "Stats", "Scooter", "Equipment", "Activity", "Downed"} do refs[name].Text = "" end
        refs.Touch.Visible, refs.StopFishing.Visible = false, false
        releaseTouch()
        Service:Close()
        resize()
        return
    end
    local state, gear = data.PlayerState, data.Equipment
    refs.Money.Text = string.format("Money %d • Level %d • XP %d/%d", data.Money, data.Level, data.XP, data.XPToNextLevel)
    refs.Health.Text = if state then string.format("HEALTH %d/%d • %s", state.CurrentHealth, state.MaxHealth, state.State) else "Postać się ładuje..."
    refs.Area.Text = if state then state.AreaName .. (if state.CombatSeconds > 0 then " • TAG " .. state.CombatSeconds .. "s" else "") else ""
    refs.Squad.Text = "SQUAD " .. (if data.Squad.SquadId then #data.Squad.Members .. "/4" else "— utwórz w MENU")
    refs.Stats.Text = string.format("K %d / D %d / A %d / R %d • STREAK %d", data.Kills, data.Deaths, data.Assists, data.Revives, if state then state.CurrentStreak else 0)
    local telemetry = data.Telemetry
    refs.Scooter.Text = string.format("%d km/h • BATTERY %s%% • %s", telemetry.Speed, tostring(telemetry.Battery or "—"), if telemetry.ScooterId then ctxScooterName(telemetry.ScooterId) else "GARAŻ → PRZYWOŁAJ")
    refs.Equipment.Text = gear.Slot .. " • " .. tostring(gear.EquipmentId or "EMPTY") .. " • " .. gear.Ammo .. "/" .. gear.Capacity .. (if gear.ReloadSeconds > 0 then " RELOAD" else "")
    local objective = data.Objective
    refs.StopFishing.Visible = data.Fishing.Active and not menuOpen
    refs.Activity.Text = if data.Fishing.Active then "ŁOWIENIE: " .. data.Fishing.WaitSeconds .. "s • " .. #data.Fishing.Inventory .. "/" .. data.Fishing.Limit .. (if data.Fishing.LastCatch then " • " .. data.Fishing.LastCatch.FishId else "") else "CONTROL POINT " .. math.floor(objective.Progress * 100) .. "%" .. (if objective.Contested then " • CONTESTED" else "") .. (if objective.Cooldown > 0 then " • " .. objective.Cooldown .. "s" else "")
    refs.Downed.Text = if state and state.State == "DOWNED" then "ZGINIĘTY\nOCZEKUJ NA POMOC DRUŻYNY\nODRODZENIE ZA " .. state.DownedSeconds .. "s" elseif data.Revive then "OCUCANIE... " .. math.floor(data.Revive.Progress * 100) .. "%" else ""
    local canRide = state and state.State ~= "DOWNED" and state.State ~= "RESPAWNING"
    refs.Touch.Visible = UserInputService.TouchEnabled and telemetry.Riding and not menuOpen and canRide
    if not refs.Touch.Visible then releaseTouch() end
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
