--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local MenuController = {}
local context: any
local state: any = nil
local card: Frame
local content: ScrollingFrame
local questLabel: TextLabel
local currentTab = "Shop"
local signature = ""
local function clear()
    for _, child in content:GetChildren() do if not child:IsA("UIListLayout") then child:Destroy() end end
end
local function chooseSetting(name: string, value: any)
    context.Send("SetSetting", {Name = name, Value = value})
end
function MenuController:Init(ctx: any) context = ctx end
function MenuController:Hide() card.Visible = false end
function MenuController:Render()
    clear()
    if not state or not state.Ready then Gui.Label(content, "Czekamy na bezpieczne wczytanie danych.", 44); return end
    if currentTab == "Shop" then
        Gui.Label(content, "Zakupy: stanowisko HULAJNOGI. Upgrade: stanowisko UPGRADE. Zsiądź przed zakupem.", 60)
        local ids: {string} = {}
        for id in context.Config.Scooters.ById do table.insert(ids, id) end
        table.sort(ids)
        local owned: {[string]: boolean} = {}
        for _, id in state.OwnedScooters do owned[id] = true end
        for _, id in ids do
            local item = context.Config.Scooters.ById[id]
            Gui.Button(content, item.DisplayName .. "\n" .. tostring(item.Price) .. " Money • Level " .. tostring(item.UnlockLevel)
                .. (if owned[id] then " • POSIADASZ" else ""), function()
                context.Send("BuyScooter", {ScooterId = id})
            end)
        end
        Gui.Label(content, "Ulepszenia wybranej hulajnogi: " .. tostring(state.SelectedScooter), 48)
        local upgrades = (state.ScooterUpgrades or {})[state.SelectedScooter] or {}
        local categories: {string} = {}
        for category in context.Config.Upgrades.Categories do table.insert(categories, category) end
        table.sort(categories)
        for _, category in categories do
            local data = context.Config.Upgrades.Categories[category]
            local level = upgrades[category] or 0
            local price, required = context.Stats.NextUpgrade(category, level, context.Config.Upgrades)
            if data.Enabled == false then Gui.Label(content, data.Name .. " • WKRÓTCE: system ładowania", 48)
            elseif price then
                Gui.Button(content, data.Name .. " " .. level .. " → " .. (level + 1) .. "\n" .. price .. " Money • Level " .. tostring(required), function()
                    context.Send("UpgradeScooter", {ScooterId = state.SelectedScooter, Category = category})
                end)
            else Gui.Label(content, data.Name .. " • MAX", 42) end
        end
    elseif currentTab == "Quests" then
        Gui.Label(content, "Podejdź do punktu DOSTAWY przy spawnie, odbierz paczkę i jedź do znacznika.", 60)
        for id, quest in context.Config.Quests do
            Gui.Button(content, quest.Name .. "\n+" .. quest.Money .. " Money • +" .. quest.XP .. " XP", function()
                context.Send("StartQuest", {QuestId = id})
            end)
        end
        if state.Quest then Gui.Button(content, "ANULUJ DOSTAWĘ", function() context.Send("CancelQuest", {}) end) end
    else
        Gui.Label(content, "Skala HUD", 32)
        for _, scale in {0.75, 1, 1.25, 1.5} do Gui.Button(content, tostring(scale * 100) .. "%", function() chooseSetting("UIScale", scale) end) end
        Gui.Label(content, "Dekoracje świata", 32)
        for _, quality in {1, 2, 3} do Gui.Button(content, "Jakość " .. quality, function() chooseSetting("GraphicsQuality", quality) end) end
        Gui.Button(content, "Ograniczone efekty: " .. (if state.Settings.ReducedEffects then "TAK" else "NIE"), function()
            chooseSetting("ReducedEffects", not state.Settings.ReducedEffects)
        end)
        Gui.Label(content, "Audio jest przygotowane na przyszłe legalne assety. Ta wersja nie odtwarza muzyki.", 60)
    end
end
function MenuController:Open(tab: string?)
    if tab == "Garage" then
        card.Visible = false
        context.Controllers.UIController:OpenGarage(true)
        return
    end
    context.Controllers.UIController:OpenGarage(false)
    currentTab = tab or "Shop"
    card.Visible = true
    context.Controllers.InputController:SetMenuOpen(true)
    self:Render()
end
function MenuController:Update(snapshot: any)
    state = snapshot
    if snapshot.Quest then
        local quest = snapshot.Quest
        questLabel.Text = quest.Name .. " • " .. quest.RemainingSeconds .. " s\nPrzejechano " .. quest.DistanceMeters .. "/" .. quest.RequiredDistance .. " m"
    else questLabel.Text = "Dostawy: punkt DOSTAWY przy spawnie" end
    local parts = {tostring(snapshot.Money), tostring(snapshot.Level), tostring(snapshot.SelectedScooter), tostring(snapshot.Ready), if snapshot.Quest then snapshot.Quest.Id else "",
        tostring(if snapshot.Settings then snapshot.Settings.UIScale else 1), tostring(if snapshot.Settings then snapshot.Settings.ReducedEffects else false)}
    for _, id in snapshot.OwnedScooters or {} do table.insert(parts, id) end
    local levels = if snapshot.ScooterUpgrades then snapshot.ScooterUpgrades[snapshot.SelectedScooter] else nil
    for category in context.Config.Upgrades.Categories do table.insert(parts, category .. tostring(if levels then levels[category] else 0)) end
    local nextSignature = table.concat(parts, "|")
    if nextSignature ~= signature then
        signature = nextSignature
        if card.Visible then self:Render() end
    end
end
function MenuController:Start()
    local screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "KukirinMenus", ResetOnSpawn = false, DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    local open = Gui.Button(screen, "MENU", function()
        if card.Visible then card.Visible = false; context.Controllers.InputController:SetMenuOpen(false)
        else MenuController:Open(nil) end
    end)
    open.AnchorPoint = Vector2.new(1, 0)
    open.Size, open.Position = UDim2.fromOffset(98, 52), UDim2.new(1, -14, 0, 148)
    questLabel = Gui.Label(screen, "Dostawy: punkt DOSTAWY przy spawnie", 68)
    questLabel.Size, questLabel.Position = UDim2.fromOffset(216, 68), UDim2.fromOffset(14, 190)
    card = Gui.Create("Frame", screen, {Name = "ActivityMenu", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(430, 520), BackgroundColor3 = Color3.fromRGB(21, 30, 43), BorderSizePixel = 0, Visible = false})
    Gui.Create("UICorner", card, {CornerRadius = UDim.new(0, 16)})
    local close = Gui.Button(card, "ZAMKNIJ", function() card.Visible = false; context.Controllers.InputController:SetMenuOpen(false) end)
    close.Size, close.Position = UDim2.new(1, -24, 0, 60), UDim2.fromOffset(12, 10)
    local titles = {"Shop", "Quests", "Settings"}
    local labels = {"SKLEP", "ZADANIA", "OPCJE"}
    for index, tab in titles do
        local button = Gui.Button(card, labels[index], function() currentTab = tab; self:Render() end)
        button.Size = UDim2.new(1/3, -16, 0, 60)
        button.Position = UDim2.new((index - 1)/3, 12, 0, 80)
    end
    content = Gui.Create("ScrollingFrame", card, {Position = UDim2.fromOffset(12, 154), Size = UDim2.new(1, -24, 1, -168),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6})
    Gui.Create("UIListLayout", content, {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    local function resize()
        local camera = Workspace.CurrentCamera
        if camera then
            card.Size = UDim2.fromOffset(math.min(460, math.max(280, camera.ViewportSize.X - 24)), math.min(560, math.max(260, camera.ViewportSize.Y - 80)))
            questLabel.Size = UDim2.fromOffset(math.min(216, math.max(160, camera.ViewportSize.X - 152)), 68)
        end
    end
    local cameraConnection: RBXScriptConnection? = nil
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera = Workspace.CurrentCamera
        if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    watchCamera()
    context.Remotes.Feedback.OnClientEvent:Connect(function(result: any)
        if type(result) == "table" and type(result.OpenMenu) == "string" then MenuController:Open(result.OpenMenu) end
    end)
end
return MenuController
