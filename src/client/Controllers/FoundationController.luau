--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Controller = {}
local context: any
local screen: ScreenGui
local card: Frame
local scale: UIScale
local settings: Frame
local status: TextLabel
local wallet: TextLabel
local health: TextLabel
local stateLabel: TextLabel
local stats: TextLabel
local toast: TextLabel
local uiPreference = 1
local toastVersion = 0
local function line(parent: Instance, text: string, y: number): TextLabel
    local label = Gui.Label(parent, text, 28)
    label.Position, label.Size = UDim2.fromOffset(14, y), UDim2.new(1, -28, 0, 28)
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.TextWrapped = false
    return label
end
local function resize()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    scale.Scale = math.min(uiPreference, (viewport.X - 28) / 380, (viewport.Y - 90) / 250)
    settings.Size = UDim2.fromOffset(math.min(380, viewport.X - 24), math.min(400, viewport.Y - 48))
end
function Controller:Init(ctx: any) context = ctx end
function Controller:Update(snapshot: any)
    if type(snapshot) ~= "table" or type(snapshot.Ready) ~= "boolean" then return end
    local ready = snapshot.Ready
    wallet.Text = if ready then "Money: " .. tostring(snapshot.Money) else "Money: wczytywanie..."
    status.Text = (if snapshot.SaveMode == "StudioMemory" then "Studio: pamięć testowa" else "DataStore") .. " • " .. tostring(snapshot.Status)
    local state = snapshot.PlayerState
    health.Text = if ready and state and state.HealthReady then string.format("Health: %d / %d", state.CurrentHealth, state.MaxHealth) else "Health: oczekiwanie na postać"
    stateLabel.Text = if ready and state then state.State .. " • " .. state.AreaName else "Stan: wczytywanie..."
    stats.Text = if ready then string.format("Kills %d   Deaths %d   Assists %d   Revives %d", snapshot.Kills, snapshot.Deaths, snapshot.Assists, snapshot.Revives) else "Statystyki: wczytywanie..."
    if snapshot.Settings then uiPreference = snapshot.Settings.UIScale; resize() end
end
function Controller:Notify(success: boolean, message: string)
    toastVersion += 1
    local version = toastVersion
    toast.Text = message
    toast.TextColor3 = if success then Color3.fromRGB(84, 215, 173) else Color3.fromRGB(245, 170, 100)
    task.delay(4, function() if version == toastVersion then toast.Text = "" end end)
end
function Controller:Start()
    screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "ZoneFoundation", ResetOnSpawn = false, DisplayOrder = 10})
    card = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(380, 250), Position = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(22, 29, 43), BorderSizePixel = 0})
    Gui.Create("UICorner", card, {CornerRadius = UDim.new(0, 14)})
    scale = Gui.Create("UIScale", card, {Scale = 1})
    line(card, context.Config.Game.DisplayName .. " • PHASE 0", 8)
    wallet = line(card, "Money: wczytywanie...", 42)
    health = line(card, "Health: oczekiwanie na postać", 72)
    stateLabel = line(card, "Stan: wczytywanie...", 102)
    stats = line(card, "Statystyki: wczytywanie...", 132)
    line(card, "Squad: system w PHASE 4", 162)
    status = line(card, "Czekam na serwer...", 192)
    status.TextSize = 12
    toast = line(card, "", 220)
    toast.TextSize = 12
    local open = Gui.Button(screen, "OPCJE", function() settings.Visible = not settings.Visible end)
    open.Size, open.Position, open.AnchorPoint = UDim2.fromOffset(110, 60), UDim2.new(1, -14, 1, -14), Vector2.new(1, 1)
    settings = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(380, 400), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(22, 29, 43), BorderSizePixel = 0, Visible = false})
    Gui.Create("UICorner", settings, {CornerRadius = UDim.new(0, 14)})
    local content = Gui.Create("ScrollingFrame", settings, {Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6})
    Gui.Create("UIListLayout", content, {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    Gui.Label(content, "Skala HUD — ustawienie zapisuje serwer", 36)
    for _, value in {0.75, 1, 1.25, 1.5} do
        Gui.Button(content, tostring(value * 100) .. "%", function() context.Send("SetSetting", {Name = "UIScale", Value = value}) end)
    end
    Gui.Button(content, "ODŚWIEŻ DANE", function() context.Send("Sync", {}) end)
    Gui.Button(content, "ZAMKNIJ", function() settings.Visible = false end)
    local cameraConnection: RBXScriptConnection? = nil
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera = Workspace.CurrentCamera
        if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    watchCamera()
    context.Remotes.Snapshot.OnClientEvent:Connect(function(snapshot: any) Controller:Update(snapshot) end)
    context.Remotes.Feedback.OnClientEvent:Connect(function(feedback: any)
        if type(feedback) == "table" and type(feedback.Message) == "string" and feedback.Message ~= "" then
            Controller:Notify(feedback.Success == true, context.Config.Messages[feedback.Message] or feedback.Message)
        end
    end)
end
return Controller
