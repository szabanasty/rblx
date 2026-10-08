--!nonstrict
-- Actual UI, menus and commerce pages through API mocks. No Roblox renderer is emulated.
return function(loadGui, loadHud, loadUI, loadMenus, loadWorkshop, loadCommerce, Layout, Schema, GameConfig,
    ScooterConfig, EquipmentConfig, ZoneConfig, WorldConfig, CombatConfig, UpgradeConfig, CosmeticConfig, SeasonConfig, Stats)
    local Mock = require("../GuiMocks")
    local checks = 0
    local function check(ok, message) assert(ok, message); checks += 1 end
    for _, touch in {false, true} do
        local world = Mock.World(if touch then 390 else 1736, if touch then 844 else 611, touch)
        local gui = loadGui(world.Instance, world.UDim2, world.Color3, world.Enum, world.UDim)
        local modules = {GuiFactory = "Gui", ZoneMenus = "Menus", ZoneHud = "Hud", HudLayout = "Layout", WorkshopMenu = "Workshop", CommerceMenus = "Commerce"}
        local resolved = {Gui = gui, Layout = Layout}
        local requires = function(key) return assert(resolved[key], key) end
        local moduleScript = {Parent = modules}
        resolved.Hud = loadHud(requires, moduleScript, world.Color3, world.UDim2, world.UDim, world.Enum)
        resolved.Workshop = loadWorkshop(requires, moduleScript)
        resolved.Commerce = loadCommerce(requires, moduleScript)
        resolved.Menus = loadMenus(requires, moduleScript)
        local ui = loadUI(world.Game, requires, {Parent = {Parent = {Modules = modules}}},
            world.UDim2, world.UDim, world.Color3, world.Vector2, world.Enum, world.Task)
        local inputOpen = false
        local ctx = {Config = {Scooters = ScooterConfig, Equipment = EquipmentConfig, Zones = ZoneConfig, World = WorldConfig,
            Combat = CombatConfig, Upgrades = UpgradeConfig, Cosmetics = CosmeticConfig, Season = SeasonConfig}, Stats = Stats,
            Player = world.Player, Controllers = {UIController = ui, InputController = {SetMenuOpen = function(_, value) inputOpen = value end}},
            Send = function() end}
        ui:Init(ctx); ui:Start()
        check(world.Find("KukirinZone").ZIndexBehavior == world.Enum.ZIndexBehavior.Sibling,
            "explicit Sibling layer policy keeps menu background below its descendants")
        local menu, content = world.Find("MainMenu"), world.Find("MenuContent")
        check(menu.ZIndex == 20 and world.Find("MenuHome").Parent == menu and world.Find("MenuClose").Parent == menu,
            "home and close buttons are descendants of the elevated menu")
        local function hasText(needle)
            for _, child in content:GetChildren() do if child.Text and string.find(child.Text, needle, 1, true) then return true end end
            return false
        end
        world.Button("MENU").Activated:Fire()
        check(menu.Visible and inputOpen and hasText("Wczytywanie danych..."), "opening before first snapshot shows loading instead of empty frame")
        world.Find("MenuClose").Activated:Fire()
        check(not menu.Visible and not inputOpen, "menu can close before profile has arrived")
        world.Button("MENU").Activated:Fire()
        local profile = Schema.new(world.Player.UserId, GameConfig)
        local data = {Ready = true, Money = profile.Money, Level = 1, XP = 0, XPToNextLevel = 100, Settings = profile.Settings,
            SaveMode = "StudioMemory", Status = "Ready", SelectedScooter = profile.SelectedScooter, OwnedScooters = {profile.SelectedScooter},
            ScooterUpgrades = {}, OwnedEquipment = {spark = true}, EquippedLoadout = {PRIMARY = "spark"}, Cosmetics = {}, Players = {}, Leaderboard = {},
            PlayerState = {State = "SAFE", AreaId = "SafeZone", AreaName = "SAFE ZONE", HealthReady = true, CurrentHealth = 100,
                MaxHealth = 100, CurrentStreak = 0, CombatSeconds = 0, DownedSeconds = 0},
            Equipment = {Slot = "PRIMARY", EquipmentId = "spark", Ammo = 12, Capacity = 12, ReloadSeconds = 0}, Squad = {Members = {}},
            Telemetry = {Riding = false, Speed = 0, Battery = 100, ScooterId = profile.SelectedScooter},
            Fishing = {Active = false, Inventory = {}, Limit = 60, Revision = 1}, Revive = {Progress = 0},
            Objective = {Progress = 0, Cooldown = 0, Contested = false}, Kills = 0, Deaths = 0, Assists = 0, Revives = 0,
            Garage = {Slots = 1, Presets = {}}, Commerce = {UpgradeCredits = 0, Offers = {{Key = "VIP", Name = "VIP", Description = "Fixture", Available = false, Owned = false}}},
            Season = {Name = SeasonConfig.Name, Id = SeasonConfig.Id, Active = true, Level = 0, Tiers = 12, XP = 0, XPPerTier = 200,
                Premium = false, FreeClaims = {}, PremiumClaims = {}}}
        ui:Update(data)
        check(menu.Visible and world.Button("Garage") and world.Button("RobuxShop") and world.Button("BattlePass"),
            "first ready snapshot populates actual main menu without reopening")
        for _, page in {"Garage", "ScooterShop", "UpgradeShop", "EquipmentShop", "RobuxShop", "BattlePass", "Squad", "FishBuyer", "CosmeticsShop", "Leaderboard", "Settings"} do
            ui:Open("Main")
            world.Button(page).Activated:Fire()
            check(menu.Visible and #content:GetChildren() > 1 and content:FindFirstChildOfClass("UIListLayout"),
                "real page renders children and retains scrolling layout: " .. page)
        end
        ui:Open("UpgradeShop")
        check(hasText("WORKSHOP") and world.Button("KUP • 75 Money • wymagany Level 1"), "actual menu uses functional Workshop builder")
        ui:Update({Ready = false, Status = "Loading"})
        check(menu.Visible and hasText("Wczytywanie danych...") and not hasText("WORKSHOP"),
            "lost readiness removes stale shop and shows loading while close stays available")
        ui:Update(data)
        check(hasText("WORKSHOP"), "ready data restores selected page after a loading interval")
        world.Find("MenuHome").Activated:Fire()
        check(world.Button("Garage") ~= nil, "header returns from a shop to actual main menu")
        world.Find("MenuClose").Activated:Fire()
        check(not menu.Visible and not inputOpen, "header closes loaded menu and restores controls")
    end
    print("Actual menu lifecycle/layer contract checks passed: " .. checks .. " (no Roblox renderer)")
end
