--!nonstrict
return function(loadGui, loadWorkshop, loadCommerce, Schema, GameConfig, ScooterConfig, Upgrades, Stats, SeasonConfig)
    local Mock = require("../GuiMocks")
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local function fixture(data, page)
        local world = Mock.World(390, 844, true)
        local gui = loadGui(world.Instance, world.UDim2, world.Color3, world.Enum, world.UDim)
        local require = function() return gui end
        local script = {Parent = {GuiFactory = {}}}
        local menu = loadWorkshop(require, script)
        local commerce = loadCommerce(require, script)
        local parent = world.Instance.new("Frame")
        local sent = {}
        local ctx = {Config = {Scooters = ScooterConfig, Upgrades = Upgrades, Season = SeasonConfig}, Stats = Stats,
            Send = function(action, payload) table.insert(sent, {Action = action, Payload = payload}) end,
            Controllers = {UIController = {Open = function() end}}}
        if page == "Store" then commerce.Store(ctx, parent, data)
        elseif page == "Season" then commerce.Season(ctx, parent, data)
        elseif page == "Garage" then commerce.Garage(ctx, parent, data)
        else menu.Build(ctx, parent, data) end
        local function buttons(prefix)
            local out = {}; for _, item in parent:GetChildren() do
                if item.ClassName == "TextButton" and string.sub(item.Text, 1, #prefix) == prefix then table.insert(out, item) end
            end; return out
        end
        return {World = world, Parent = parent, Sent = sent, Buttons = buttons}
    end
    local profile = Schema.new(123, GameConfig)
    local data = {SelectedScooter = profile.SelectedScooter, OwnedScooters = {profile.SelectedScooter}, ScooterUpgrades = {},
        Money = 100, Level = 1, Telemetry = {Riding = false}, Commerce = {UpgradeCredits = 0}}
    local f = fixture(data)
    local buys = f.Buttons("KUP • ")
    check(#buys == #Upgrades.ShopOrder and #buys == 6, "Workshop actually renders six upgrade categories")
    check(buys[1].Active ~= false and buys[1].Text == "KUP • 75 Money • wymagany Level 1", "starter can use first motor upgrade immediately")
    buys[1].Activated:Fire()
    check(f.Sent[1].Action == "UpgradeScooter" and f.Sent[1].Payload.Category == "Motor" and f.Sent[1].Payload.ScooterId == profile.SelectedScooter, "Workshop click sends only upgrade intent")
    local effects = false
    for _, item in f.Parent:GetChildren() do if item.Text and string.find(item.Text, "TopSpeed 35.00 → 37.00", 1, true) then effects = true end end
    check(effects, "Workshop shows real before/after stats")
    data.ScooterUpgrades[profile.SelectedScooter] = {Motor = 1}
    f = fixture(data); check(f.Buttons("KUP • ")[1].Active == false and f.Buttons("KUP • ")[1].Interactable == false, "required level disables native button interaction")
    data.Telemetry.Riding = true; data.Commerce.UpgradeCredits = 2
    f = fixture(data)
    check(f.World.Button("ZEJDŹ Z HULAJNOGI") ~= nil, "mounted user has an actionable dismount button")
    f.World.Button("ZEJDŹ Z HULAJNOGI").Activated:Fire()
    check(f.Sent[1].Action == "DismountScooter", "dismount action is wired")
    for _, button in f.Buttons("KUP • ") do check(button.Active == false, "mounted upgrades disabled") end
    for _, button in f.Buttons("UŻYJ 1 KREDYTU") do check(button.Active == false, "mounted credits disabled") end
    data.Telemetry.Riding = false; data.Level = 4
    f = fixture(data); local credits = f.Buttons("UŻYJ 1 KREDYTU")
    check(#credits == 6 and credits[1].Active ~= false, "owned credits usable at required level")
    credits[1].Activated:Fire()
    check(f.Sent[1].Action == "RedeemUpgrade" and f.Sent[1].Payload.Category == "Motor", "credit button uses dedicated validated server action")
    data.ScooterUpgrades[profile.SelectedScooter].Motor = 5
    f = fixture(data); check(#f.Buttons("KUP • ") == 5, "maxed upgrade no longer offers a buy button")
    data.Commerce.Offers = {{Key = "VIP", Name = "VIP", Description = "fixture", Available = false, Owned = false}}
    f = fixture(data, "Store"); check(f.Buttons("NIEAKTYWNE")[1].Active == false, "unconfigured shop cannot pretend to sell")
    data.Commerce.Offers[1].Available = true
    f = fixture(data, "Store"); f.Buttons("KUP ZA ROBUX")[1].Activated:Fire()
    check(f.Sent[1].Action == "PurchaseOffer" and f.Sent[1].Payload.OfferKey == "VIP" and f.Sent[1].Payload.Id == nil, "store sends catalog key, never client-controlled Marketplace ID")
    data.Commerce.Offers[1].Owned = true
    f = fixture(data, "Store"); check(f.Buttons("POSIADANE")[1].Active == false, "owned pass shown without buy action")
    data.Season = {Name = SeasonConfig.Name, Level = 1, Tiers = SeasonConfig.Tiers, XP = 200, XPPerTier = 200, Active = true,
        Premium = false, FreeClaims = {}, PremiumClaims = {}}
    f = fixture(data, "Season")
    check(#f.Buttons("Free • ") == 12 and #f.Buttons("Premium • ") == 12, "both season tracks rendered")
    check(f.Buttons("Free • ")[1].Active ~= false and f.Buttons("Free • ")[2].Active == false
        and f.Buttons("Premium • ")[1].Active == false, "tier and premium locks visible")
    f.Buttons("Free • ")[1].Activated:Fire()
    check(f.Sent[1].Action == "ClaimSeasonReward" and f.Sent[1].Payload.Tier == 1 and f.Sent[1].Payload.Track == "Free", "season sends only tier/track intent")
    data.Garage = {Slots = 1, Presets = {}}
    f = fixture(data, "Garage")
    check(f.Buttons("WCZYTAJ")[1].Active == false, "empty garage preset cannot load")
    f.Buttons("ZAPISZ")[1].Activated:Fire()
    check(f.Sent[1].Action == "SaveGaragePreset" and f.Sent[1].Payload.Slot == 1, "garage save sends slot only")
    print("Actual Workshop/commerce GUI checks passed: " .. checks)
end
