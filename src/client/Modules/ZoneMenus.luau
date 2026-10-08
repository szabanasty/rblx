--!strict
local Gui = require(script.Parent.GuiFactory)
local Menus = {}
local slot = "PRIMARY"
function Menus.Build(ctx: any, parent: Instance, page: string, data: any, open: (string) -> ())
    for _, child in parent:GetChildren() do if not child:IsA("UIListLayout") then child:Destroy() end end
    local function label(text: string) Gui.Label(parent, text, 48) end
    local function button(text: string, action: string, payload: any?)
        Gui.Button(parent, text, function() ctx.Send(action, payload or {}) end)
    end
    local ready = data and data.Ready
    if not ready then label("Wczytywanie danych..."); return end
    if page == "Main" then
        Gui.Button(parent, "POKAŻ / UKRYJ MINIMAPĘ", function() ctx.Controllers.UIController:ToggleMap() end)
        label("SAFE: garaż i sklepy. COMBAT: arcade PvP i CONTROL POINT. FISHING: łów automatycznie, sprzedawaj przy FISH BUYER.")
        for _, name in {"Garage", "ScooterShop", "UpgradeShop", "EquipmentShop", "Squad", "FishBuyer", "CosmeticsShop", "Leaderboard", "Settings"} do
            Gui.Button(parent, name, function() open(name) end)
        end
    elseif page == "Garage" then
        for _, id in data.OwnedScooters do
            local item = ctx.Config.Scooters.ById[id]
            button((if data.SelectedScooter == id then "✓ " else "") .. item.DisplayName .. " • " .. item.Class, "SelectScooter", {ScooterId = id})
        end
        button("PRZYWOŁAJ", "SpawnScooter")
        button("WSIĄDŹ — podejdź do swojej hulajnogi", "MountScooter")
        button("ZEJDŹ", "DismountScooter")
        button("SCHOWAJ", "DespawnScooter")
        button("NAŁADUJ — przy garażu, po zejściu", "ChargeScooter")
    elseif page == "ScooterShop" then
        local ids = {}
        for id in ctx.Config.Scooters.ById do table.insert(ids, id) end
        table.sort(ids, function(a, b) return ctx.Config.Scooters.ById[a].Price < ctx.Config.Scooters.ById[b].Price end)
        for _, id in ids do
            local item = ctx.Config.Scooters.ById[id]
            label(string.format("%s • %s • %s\n%d km/h / accel %.1f / handling %d / brake %.1f / battery %d", item.DisplayName, item.Class, item.Rarity, item.TopSpeed, item.Acceleration, item.Handling, item.Braking, item.Battery))
            button((if table.find(data.OwnedScooters, id) then "POSIADANA" else "KUP") .. " • " .. item.Price .. " Money • Level " .. item.UnlockLevel, "BuyScooter", {ScooterId = id})
        end
    elseif page == "UpgradeShop" then
        local selected = ctx.Config.Scooters.ById[data.SelectedScooter]
        if not selected then label("Ten model jest niedostępny. Wybierz inną hulajnogę w Garage."); return end
        label("Ulepszenia: " .. selected.DisplayName)
        local levels = data.ScooterUpgrades[data.SelectedScooter] or {}
        for _, category in ctx.Config.Upgrades.ShopOrder do
            local config = ctx.Config.Upgrades.Categories[category]
            local current = levels[category] or 0
            local price, level = ctx.Stats.NextUpgrade(category, current, ctx.Config.Upgrades)
            button(config.Name .. " " .. current .. "/5 • " .. (if price then tostring(price) .. " Money • Level " .. tostring(level) else "MAX"), "UpgradeScooter", {ScooterId = data.SelectedScooter, Category = category})
        end
    elseif page == "EquipmentShop" then
        label("LOADOUT — wyposażanie w SAFE ZONE")
        for _, name in {"PRIMARY", "SECONDARY", "UTILITY"} do
            Gui.Button(parent, (if slot == name then "✓ " else "") .. name .. " • " .. tostring(data.EquippedLoadout[name] or "EMPTY"), function() slot = name; open(page) end)
        end
        button("ODŁÓŻ ZE SLOTU " .. slot, "EquipEquipment", {Slot = slot, EquipmentId = ""})
        local ids = {}
        for id in ctx.Config.Equipment.ById do table.insert(ids, id) end
        table.sort(ids)
        for _, id in ids do
            local item = ctx.Config.Equipment.ById[id]
            label(string.format("%s • %s • %s\nDamage %d / Range %d / Cooldown %.2f / Capacity %d", item.DisplayName, item.Category, item.Rarity, item.Damage, item.EffectiveRange, item.Cooldown, item.Capacity))
            if data.OwnedEquipment[id] then button("WYPOSAŻ " .. slot, "EquipEquipment", {Slot = slot, EquipmentId = id})
            else button("KUP • " .. item.Price .. " Money", "BuyEquipment", {EquipmentId = id}) end
        end
    elseif page == "Squad" then
        local squad = data.Squad
        if squad.Invite then
            label("Zaproszenie od " .. squad.Invite.From)
            button("AKCEPTUJ", "AcceptSquad"); button("ODRZUĆ", "DeclineSquad")
        end
        if squad.SquadId then
            label("SQUAD " .. squad.SquadId .. " • " .. #squad.Members .. "/4")
            for _, member in squad.Members do
                label(member.Name .. (if member.UserId == squad.Leader then " • LEADER" else ""))
                if squad.Leader == ctx.Player.UserId and member.UserId ~= ctx.Player.UserId then button("USUŃ " .. member.Name, "KickSquad", {TargetId = member.UserId}) end
            end
            button("OPUŚĆ SQUAD", "LeaveSquad")
        else button("UTWÓRZ SQUAD", "CreateSquad") end
        label("Gracze na serwerze — zaprasza leader:")
        for _, player in data.Players do
            if player.UserId ~= ctx.Player.UserId then button("ZAPROŚ " .. player.Name, "InviteSquad", {TargetId = player.UserId}) end
        end
    elseif page == "FishBuyer" then
        local fishing = data.Fishing
        label("AUTO FISHING — jezioro za miastem. Pomost i FISH BUYER zaznaczone na mapie.\nInventory " .. #fishing.Inventory .. "/" .. fishing.Limit)
        button(if fishing.Active then "STOP ŁOWIENIA" else "ŁÓW — przy pomoście", "ToggleFishing")
        button("SPRZEDAJ WSZYSTKIE — przy FISH BUYER", "SellFish", {Index = 0, Revision = fishing.Revision})
        for _, fish in fishing.Inventory do
            button(fish.FishId .. " • " .. fish.Rarity .. " • " .. fish.Weight .. " kg • SPRZEDAJ " .. fish.Value .. " Money", "SellFish", {Index = fish.Index, Revision = fishing.Revision})
        end
    elseif page == "CosmeticsShop" then
        label("Kosmetyki nie zwiększają statystyk. Wybierz hulajnogę w garażu.")
        for _, category in {"Color", "Grips", "Deck", "Lights", "Wheels", "Decals", "Effects"} do
            for _, option in {"Orange", "Mint", "Violet", "Blue", "Red"} do
                local owned = data.Cosmetics[category .. ":" .. option]
                button(category .. " • " .. option .. " • " .. (if owned then "ZAŁÓŻ" else ctx.Config.Cosmetics.Categories[category] .. " Money"), "BuyCosmetic", {Category = category, Option = option})
            end
        end
        for id, style in ctx.Config.Cosmetics.Styles do button("UBRANIE " .. id .. " • placeholder • " .. style.Price .. " Money", "BuyCosmetic", {Category = "Clothing", Option = id}) end
        for id, tag in ctx.Config.Cosmetics.Tags do button("TAG " .. tag.DisplayName .. " • " .. tag.Price .. " Money", "BuyCosmetic", {Category = "Tag", Option = id}) end
    elseif page == "Leaderboard" then
        label("TOP KILLS — ten serwer")
        for _, entry in data.Leaderboard do label(entry.Name .. " • K " .. entry.Kills .. " / D " .. entry.Deaths .. " / A " .. entry.Assists .. " / R " .. entry.Revives .. " / STREAK " .. entry.CurrentStreak .. " / BEST " .. entry.BestStreak) end
        label("TOP STREAK")
        local ordered: {any} = table.clone(data.Leaderboard)
        table.sort(ordered, function(a: any, b: any) return a.BestStreak > b.BestStreak end)
        for index = 1, math.min(10, #ordered) do label(ordered[index].Name .. " • " .. ordered[index].BestStreak) end
    elseif page == "Settings" then
        label("ZAPIS: " .. tostring(data.SaveMode) .. " • " .. tostring(data.Status))
        for _, value in {0.75, 1, 1.25, 1.5} do button("HUD SCALE " .. value * 100 .. "%", "SetSetting", {Name = "UIScale", Value = value}) end
        for _, value in {1, 2, 3} do button("GRAPHICS " .. value, "SetSetting", {Name = "GraphicsQuality", Value = value}) end
        for _, category in {"MusicVolume", "SFXVolume"} do
            for _, value in {0, 0.5, 1} do button(category .. " " .. value * 100 .. "%", "SetSetting", {Name = category, Value = value}) end
        end
        button("REDUCED EFFECTS " .. (if data.Settings.ReducedEffects then "OFF" else "ON"), "SetSetting", {Name = "ReducedEffects", Value = not data.Settings.ReducedEffects})
        button("ODŚWIEŻ DANE", "Sync")
    end
end
return Menus
