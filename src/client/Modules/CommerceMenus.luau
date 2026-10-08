--!strict
local Gui = require(script.Parent.GuiFactory)
local Menus = {}
local function button(parent: Instance, text: string, action: () -> (), active: boolean?)
    local item = Gui.Button(parent, text, action)
    if active == false then
        item.Active, item.Selectable, item.AutoButtonColor = false, false, false
        item.Interactable = false
        item.BackgroundTransparency, item.TextTransparency = 0.5, 0.35
    end
end
function Menus.Store(ctx: any, parent: Instance, data: any)
    Gui.Label(parent, "ROBUX SHOP • cenę i potwierdzenie pokazuje Roblox. Zamknięcie okna nie przyznaje nagrody.", 65)
    if not data.Commerce then Gui.Label(parent, "Sklep wymaga aktualnego serwera.", 40); return end
    for _, item in data.Commerce.Offers do
        Gui.Label(parent, item.Name .. "\n" .. item.Description, 95)
        button(parent, if item.Owned then "POSIADANE" elseif item.Available then "KUP ZA ROBUX • POTWIERDZENIE ROBLOX" else "NIEAKTYWNE • oferta chwilowo niedostępna",
            function() ctx.Send("PurchaseOffer", {OfferKey = item.Key}) end, item.Available and not item.Owned)
    end
    button(parent, "ODŚWIEŻ POSIADANE GAME PASSES", function() ctx.Send("RefreshPurchases", {}) end)
end
local function describe(reward: any): string
    if reward.Money then return reward.Money .. " Money" end
    if reward.Credits then return reward.Credits .. " kredyt Workshop" end
    return tostring(reward.Cosmetic)
end
function Menus.Season(ctx: any, parent: Instance, data: any)
    local state = data.Season
    if not state then Gui.Label(parent, "Karnet wymaga aktualnego serwera.", 42); return end
    Gui.Label(parent, string.format("%s\nPOZIOM %d / %d • XP %d\n%d XP na poziom • zdobywaj XP grając", state.Name, state.Level, state.Tiers, state.XP, state.XPPerTier), 85)
    if not state.Active then Gui.Label(parent, "SEZON NIEAKTYWNY", 40) end
    button(parent, if state.Premium then "PREMIUM POSIADANE" else "ODBLOKUJ PREMIUM • ROBUX SHOP", function() ctx.Controllers.UIController:Open("RobuxShop") end, not state.Premium)
    for tier = 1, state.Tiers do
        Gui.Label(parent, "POZIOM " .. tier .. " • " .. tier * state.XPPerTier .. " XP", 34)
        for _, track in {"Free", "Premium"} do
            local claimed = (if track == "Free" then state.FreeClaims else state.PremiumClaims)[tostring(tier)]
            local canClaim = state.Active and tier <= state.Level and not claimed and (track == "Free" or state.Premium)
            button(parent, track .. " • " .. describe(ctx.Config.Season.Rewards[tier][track]) .. " • " .. (if claimed then "ODEBRANO" elseif canClaim then "ODBIERZ W SAFE" else "ZABLOKOWANE"),
                function() ctx.Send("ClaimSeasonReward", {Tier = tier, Track = track}) end, canClaim)
        end
    end
end
function Menus.Garage(ctx: any, parent: Instance, data: any)
    if not data.Garage then return end
    Gui.Label(parent, "PRESETY • " .. data.Garage.Slots .. " slotów\nZapisz wybrany model i kosmetyki przy garażu. Nie kopiuje ulepszeń ani nie tworzy nowych pojazdów.", 75)
    for slot = 1, data.Garage.Slots do
        local preset = data.Garage.Presets[tostring(slot)]
        local item = if preset then ctx.Config.Scooters.ById[preset.ScooterId] else nil
        Gui.Label(parent, "SLOT " .. slot .. " • " .. (if item then item.DisplayName else "PUSTY"), 35)
        button(parent, "ZAPISZ AKTUALNĄ KONFIGURACJĘ • " .. slot, function() ctx.Send("SaveGaragePreset", {Slot = slot}) end)
        button(parent, "WCZYTAJ KONFIGURACJĘ • " .. slot, function() ctx.Send("LoadGaragePreset", {Slot = slot}) end, item ~= nil)
    end
end
return Menus
