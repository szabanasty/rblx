--!strict
-- Presentation only: every value comes from the server snapshot.
local Gui = require(script.Parent.GuiFactory)
local Hud = {}
local accent = Color3.fromRGB(103, 231, 185)
local muted = Color3.fromRGB(173, 190, 208)
local danger = Color3.fromRGB(255, 123, 120)
local function card(parent: Instance, name: string): Frame
    local panel = Gui.Create("Frame", parent, {Name = name, BackgroundColor3 = Color3.fromRGB(17, 25, 36), BackgroundTransparency = 0.15, BorderSizePixel = 0})
    Gui.Create("UICorner", panel, {CornerRadius = UDim.new(0, 10)})
    Gui.Create("UIStroke", panel, {Color = Color3.fromRGB(80, 109, 125), Transparency = 0.65, Thickness = 1})
    Gui.Create("UIScale", panel, {Name = "HudScale"})
    return panel
end
local function text(parent: Frame, name: string, y: number, h: number, size: number, color: Color3?): TextLabel
    local label = Gui.Label(parent, "", h)
    label.Name, label.Position, label.Size = name, UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, h)
    label.TextSize, label.TextWrapped, label.TextTruncate = size, false, Enum.TextTruncate.AtEnd
    label.TextColor3, label.Font = color or Color3.fromRGB(239, 245, 250), Enum.Font.GothamMedium
    return label
end
local function bar(parent: Frame, y: number, color: Color3): Frame
    local track = Gui.Create("Frame", parent, {Size = UDim2.new(1, -24, 0, 5), Position = UDim2.fromOffset(12, y), BackgroundColor3 = Color3.fromRGB(50, 65, 78), BorderSizePixel = 0, ClipsDescendants = true})
    Gui.Create("UICorner", track, {CornerRadius = UDim.new(0, 3)})
    local fill = Gui.Create("Frame", track, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0})
    Gui.Create("UICorner", fill, {CornerRadius = UDim.new(0, 3)})
    return fill
end
function Hud.Create(screen: ScreenGui): any
    local refs: any = {Cards = {}}
    for _, name in {"Area", "Squad", "Economy", "Health", "Equipment", "Scooter", "Activity"} do refs.Cards[name] = card(screen, name .. "HUD") end
    refs.Area = text(refs.Cards.Area, "Area", 5, 28, 16, accent)
    refs.Money = text(refs.Cards.Economy, "Money", 4, 30, 24, accent)
    refs.Level = text(refs.Cards.Economy, "Level", 35, 24, 13, muted)
    refs.XP = bar(refs.Cards.Economy, 65, accent)
    refs.Health = text(refs.Cards.Health, "Health", 4, 26, 17)
    refs.HealthBar = bar(refs.Cards.Health, 36, accent)
    refs.Stats = text(refs.Cards.Health, "Stats", 48, 25, 12, muted)
    refs.Squad = text(refs.Cards.Squad, "Squad", 4, 22, 14, accent)
    refs.Members = text(refs.Cards.Squad, "Members", 28, 20, 12, muted)
    refs.SquadHint = text(refs.Cards.Squad, "Hint", 51, 22, 12, muted)
    refs.Equipment = text(refs.Cards.Equipment, "Equipment", 4, 24, 14, muted)
    refs.Ammo = text(refs.Cards.Equipment, "Ammo", 26, 34, 29)
    refs.Reload = text(refs.Cards.Equipment, "Reload", 63, 20, 12, accent)
    refs.Scooter = text(refs.Cards.Scooter, "Scooter", 4, 22, 13, muted)
    refs.Speed = text(refs.Cards.Scooter, "Speed", 25, 34, 30)
    refs.Battery = text(refs.Cards.Scooter, "Battery", 62, 20, 12, accent)
    refs.BatteryBar = bar(refs.Cards.Scooter, 85, accent)
    refs.Activity = text(refs.Cards.Activity, "Activity", 3, 24, 13, accent)
    refs.ActivityDetail = text(refs.Cards.Activity, "Detail", 27, 23, 12, muted)
    refs.ActivityBar = bar(refs.Cards.Activity, 55, accent)
    return refs
end
function Hud.Resize(refs: any, layout: any, ready: boolean, riding: boolean, activity: boolean, menuOpen: boolean)
    for name, panel in refs.Cards do
        local rect = layout.Panels[name]
        panel.Position, panel.Size = UDim2.fromOffset(rect.X, rect.Y), UDim2.fromOffset(rect.W / layout.Scale, rect.H / layout.Scale)
        local panelScale = panel:FindFirstChild("HudScale") :: UIScale
        panelScale.Scale = layout.Scale
        panel.Visible = not menuOpen and (ready or name == "Economy" or name == "Area")
    end
    refs.Cards.Equipment.Visible = ready and not riding and not menuOpen
    refs.Cards.Scooter.Visible = ready and riding and not menuOpen
    refs.Cards.Activity.Visible = ready and activity and not menuOpen
    refs.SquadHint.Visible = not layout.Compact
    refs.Stats.Visible = not (layout.Short and layout.Compact)
end
function Hud.Update(refs: any, data: any, config: any)
    if not data.Ready then
        refs.Money.Text, refs.Level.Text, refs.Area.Text = "WCZYTYWANIE…", tostring(data.Status or "Łączenie"), "KUKIRIN ZONE"
        refs.XP.Size = UDim2.fromScale(0, 1)
        return
    end
    local state, gear, telemetry = data.PlayerState, data.Equipment, data.Telemetry
    refs.Money.Text = "$ " .. tostring(data.Money)
    refs.Level.Text = string.format("LVL %d   •   XP %d / %d", data.Level, data.XP, data.XPToNextLevel)
    local saveProblem = data.Status == "SaveFailed" or data.Status == "SessionLost"
    if saveProblem then refs.Level.Text = "PROBLEM Z ZAPISEM • " .. data.Status end
    refs.Level.TextColor3 = if saveProblem then danger else muted
    refs.XP.Size = UDim2.fromScale(math.clamp(data.XP / math.max(1, data.XPToNextLevel), 0, 1), 1)
    refs.Area.Text = if state then state.AreaName .. (if state.CombatSeconds > 0 then " • " .. state.CombatSeconds .. "s TAG" else "") else "ŁADOWANIE POSTACI"
    refs.Area.TextColor3 = if state and (state.AreaId == "CombatZone" or state.CombatSeconds > 0) then danger else accent
    refs.Health.Text = if state and state.HealthReady ~= false then string.format("HP %d / %d", state.CurrentHealth, state.MaxHealth) else "ODRADZANIE…"
    local health = if state and state.HealthReady ~= false then math.clamp(state.CurrentHealth / math.max(1, state.MaxHealth), 0, 1) else 0
    refs.HealthBar.Size, refs.HealthBar.BackgroundColor3 = UDim2.fromScale(health, 1), if health < 0.3 then danger else accent
    refs.Stats.Text = string.format("K %d / D %d  •  S %d", data.Kills, data.Deaths, if state then state.CurrentStreak else 0)
    local squad = data.Squad
    refs.Squad.Text = if squad.SquadId then "SQUAD  " .. #squad.Members .. "/4" else "SOLO • SQUAD W MENU"
    local names: {string} = {}
    for _, member in squad.Members do table.insert(names, member.Name) end
    refs.Members.Text = if squad.Invite then "ZAPROSZENIE: " .. squad.Invite.From else table.concat(names, " • ")
    refs.SquadHint.Text = "MENU → SQUAD / ZNAJOMI"
    local item = config.Equipment.ById[gear.EquipmentId or ""]
    refs.Equipment.Text = if item then item.DisplayName .. " • " .. gear.Slot else "BRAK WYPOSAŻENIA"
    refs.Ammo.Text = string.format("%02d / %02d", gear.Ammo, gear.Capacity)
    refs.Reload.Text = if gear.ReloadSeconds > 0 then string.format("PRZEŁADOWANIE %.1fs", gear.ReloadSeconds) else "R • RELOAD    1 / 2 / 3 • SLOT"
    local scooter = config.Scooters.ById[telemetry.ScooterId or ""]
    refs.Scooter.Text = if scooter then scooter.DisplayName else "HULAJNOGA"
    refs.Speed.Text = telemetry.Speed .. " km/h"
    refs.Battery.Text = "BATERIA " .. tostring(telemetry.Battery or 0) .. "%"
    refs.BatteryBar.Size = UDim2.fromScale(math.clamp((telemetry.Battery or 0) / 100, 0, 1), 1)
    local fish, objective = data.Fishing, data.Objective
    refs.Activity.Text = if fish.Active then "WILLOW LAKE • ŁOWIENIE" else "IRON ISLAND • CONTROL POINT"
    refs.ActivityDetail.Text = if fish.Active then fish.WaitSeconds .. "s • PLECAK " .. #fish.Inventory .. "/" .. fish.Limit else math.floor(objective.Progress * 100) .. "%" .. (if objective.Contested then " • CONTESTED" elseif objective.Cooldown > 0 then " • " .. objective.Cooldown .. "s" else " • ZAJMIJ Z DRUŻYNĄ")
    refs.ActivityBar.Size = UDim2.fromScale(if fish.Active then math.clamp(#fish.Inventory / math.max(1, fish.Limit), 0, 1) else math.clamp(objective.Progress, 0, 1), 1)
end
return Hud
