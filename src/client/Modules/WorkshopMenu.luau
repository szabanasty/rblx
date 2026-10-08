--!strict
local Gui = require(script.Parent.GuiFactory)
local Menu = {}
local units: {[string]: string} = {TopSpeed = "km/h", Acceleration = "m/s²", Handling = "°/s", Braking = "m/s²", Jump = "m/s", Battery = "capacity", Stability = "stability"}
local function enabled(button: TextButton, value: boolean)
    button.Active, button.Selectable, button.AutoButtonColor = value, value, value
    button.Interactable = value
    button.BackgroundTransparency, button.TextTransparency = if value then 0 else 0.5, if value then 0 else 0.35
end
function Menu.Build(ctx: any, parent: Instance, data: any)
    local selected = ctx.Config.Scooters.ById[data.SelectedScooter]
    Gui.Label(parent, "WORKSHOP • ULEPSZENIA TWOJEJ HULAJNOGI", 42)
    Gui.Label(parent, "Money " .. data.Money .. " • Level " .. data.Level .. " • Kredyty " .. (if data.Commerce then data.Commerce.UpgradeCredits else 0) .. "\nKredyt zastępuje cenę Money. Level i limit 5 nadal obowiązują.", 60)
    if data.Telemetry.Riding then
        Gui.Label(parent, "Najpierw zejdź z hulajnogi, aby kupować ulepszenia.", 42)
        Gui.Button(parent, "ZEJDŹ Z HULAJNOGI", function() ctx.Send("DismountScooter", {}) end)
    end
    Gui.Label(parent, "WYBIERZ MODEL:", 30)
    for _, id in data.OwnedScooters do
        local item = ctx.Config.Scooters.ById[id]
        if item then Gui.Button(parent, (if id == data.SelectedScooter then "✓ " else "") .. item.DisplayName, function() ctx.Send("SelectScooter", {ScooterId = id}) end) end
    end
    if not selected then Gui.Label(parent, "Wybierz dostępny model w garażu.", 42); return end
    local levels = data.ScooterUpgrades[data.SelectedScooter] or {}
    local currentStats = ctx.Stats.Get(selected, levels, ctx.Config.Upgrades)
    Gui.Label(parent, string.format("%s\n%.0f km/h • accel %.2f • battery %.0f", selected.DisplayName, currentStats.TopSpeed, currentStats.Acceleration, currentStats.Battery), 54)
    for _, category in ctx.Config.Upgrades.ShopOrder do
        local cfg = ctx.Config.Upgrades.Categories[category]
        local level = levels[category] or 0
        local price, required = ctx.Stats.NextUpgrade(category, level, ctx.Config.Upgrades)
        Gui.Label(parent, cfg.Name .. " • " .. level .. "/" .. ctx.Config.Upgrades.MaxLevel, 32)
        if price and required and cfg.Enabled ~= false then
            local nextLevels = table.clone(levels); nextLevels[category] = level + 1
            local nextStats = ctx.Stats.Get(selected, nextLevels, ctx.Config.Upgrades)
            local effects: {string} = {}
            for stat in cfg.Effects do table.insert(effects, string.format("%s %.2f → %.2f %s", stat, currentStats[stat], nextStats[stat], units[stat] or "")) end
            table.sort(effects)
            Gui.Label(parent, table.concat(effects, "\n"), math.max(42, #effects * 24))
            local eligible = data.Level >= required and not data.Telemetry.Riding
            local paid = Gui.Button(parent, "KUP • " .. price .. " Money • wymagany Level " .. required, function() ctx.Send("UpgradeScooter", {ScooterId = data.SelectedScooter, Category = category}) end)
            enabled(paid, eligible and data.Money >= price)
            if data.Commerce and data.Commerce.UpgradeCredits > 0 then
                local credit = Gui.Button(parent, "UŻYJ 1 KREDYTU • wymagany Level " .. required, function() ctx.Send("RedeemUpgrade", {ScooterId = data.SelectedScooter, Category = category}) end)
                enabled(credit, eligible)
            end
            if data.Level < required then Gui.Label(parent, "ZABLOKOWANE: potrzebujesz Level " .. required, 30)
            elseif data.Money < price then Gui.Label(parent, "Brakuje " .. price - data.Money .. " Money; zarabiaj je w grze albo użyj kredytu.", 40) end
        else Gui.Label(parent, "OSIĄGNIĘTO MAKSIMUM / NIEDOSTĘPNE", 36) end
    end
end
return Menu
