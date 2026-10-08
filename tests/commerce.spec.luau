--!nonstrict
return function(loadService, Rules, Schema, Validation, GameConfig, Config, ScooterConfig, EquipmentConfig)
    local M = require("../RuntimeMocks")
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local function fixture(saved, configure)
        local now = 100
        local players = {PlayerRemoving = M.Signal()}
        local player = {UserId = 123, Parent = players}
        function players:GetPlayerByUserId(id) return if id == player.UserId and player.Parent == players then player else nil end
        local marketplace = {PromptGamePassPurchaseFinished = M.Signal(), Ownership = {}, Prompts = {}, Checks = 0}
        function marketplace:UserOwnsGamePassAsync(_, id)
            self.Checks += 1
            if self.FailOwnership then error("API unavailable") end
            if self.YieldOwnership then coroutine.yield() end
            return self.Ownership[id] == true
        end
        function marketplace:PromptGamePassPurchase(_, id) table.insert(self.Prompts, {Kind = "Pass", Id = id}) end
        function marketplace:PromptProductPurchase(_, id) table.insert(self.Prompts, {Kind = "Product", Id = id}) end
        local cfg = table.clone(Config); cfg.Enabled = true; cfg.Offers = {}
        for i, key in cfg.Order do cfg.Offers[key] = table.clone(Config.Offers[key]); cfg.Offers[key].Id = 1000 + i end
        if configure then configure(cfg) end
        local profile = if saved then assert(Schema.sanitize(saved, GameConfig)) else Schema.new(player.UserId, GameConfig)
        local ready, persistent, safe = true, true, true
        local store = {Saves = 0, Dirty = 0, FailSave = false, YieldSave = false}
        function store:IsReady() return ready end
        function store:IsPersistent() return ready and persistent end
        function store:GetProfile() return if ready then profile else nil end
        function store:MarkDirty() self.Dirty += 1 end
        function store:Save()
            self.Saves += 1
            if self.YieldSave then coroutine.yield() end
            if self.FailSave then return false end
            self.Saved = Schema.deepCopy(profile); return true
        end
        local ctx = {Config = {Monetization = cfg, Scooters = ScooterConfig, Equipment = EquipmentConfig}, CommerceRules = Rules, Validation = Validation,
            Services = {PlayerData = store, State = {IsAllowed = function() return safe end}}, Notify = function() end}
        local spawned = {}
        local service = loadService({GetService = function(_, name) return if name == "Players" then players else marketplace end},
            {spawn = function(fn) local co = coroutine.create(fn); table.insert(spawned, co); assert(coroutine.resume(co)); return co end}, {ProductPurchaseDecision = {NotProcessedYet = "retry", PurchaseGranted = "granted"}},
            {clock = function() return now end}, function() end)
        service:Init(ctx); service:Start()
        local function receipt(id, key) return {PurchaseId = id, PlayerId = player.UserId, ProductId = cfg.Offers[key or "UpgradeCredit"].Id} end
        return {Service = service, Profile = profile, Context = ctx, Marketplace = marketplace, Player = player, Store = store, Config = cfg, Receipt = receipt, Spawned = spawned,
            Advance = function() now += 4 end, Ready = function(value) ready = value end, Persistent = function(value) persistent = value end,
            Safe = function(value) safe = value end}
    end
    local f = fixture()
    check(f.Service:Prompt(f.Player, "UpgradeCredit") and #f.Marketplace.Prompts == 1, "native product prompt uses configured ID")
    check(f.Profile.UpgradeCredits == 0, "opening prompt never grants product")
    check(select(2, f.Service:Prompt(f.Player, "VIP")) == "PurchaseCooldown", "server prompt cooldown")
    f.Advance(); f.Safe(false)
    check(select(2, f.Service:Prompt(f.Player, "VIP")) == "VisitSafeZone", "purchase needs valid trade state")
    f.Safe(true); f.Persistent(false)
    check(select(2, f.Service:Prompt(f.Player, "UpgradeCredit")) == "PurchaseNeedsDataStore", "consumables cannot charge in memory-only sessions")
    check(f.Service:GetSnapshot(f.Player).Offers[7].Available == false, "memory-only session shows product unavailable")
    f.Persistent(true); f.Ready(false)
    check(select(2, f.Service:Prompt(f.Player, "VIP")) == "DataNotReady", "prompt handles missing data safely")
    f.Ready(true); f.Config.Enabled = false
    check(select(2, f.Service:Prompt(f.Player, "VIP")) == "RobuxNotConfigured", "master switch disables prompts")
    f.Config.Enabled = true; f.Config.Offers.VIP.Id = 0
    check(not f.Service:Prompt(f.Player, "VIP") and not f.Service:Prompt(f.Player, "fake"), "missing and unknown IDs cannot prompt")
    f = fixture()
    f.Marketplace.PromptGamePassPurchaseFinished:Fire(f.Player, f.Config.Offers.EliteScooter.Id, true)
    check(not f.Profile.OwnedScooters.volt_elite, "purchase-finished signal is not ownership proof")
    f.Marketplace.Ownership[f.Config.Offers.EliteScooter.Id] = true
    f.Marketplace.Ownership[f.Config.Offers.EliteWeapon.Id] = true
    f.Marketplace.Ownership[f.Config.Offers.VIP.Id] = true
    f.Service:OnDataReady(f.Player)
    check(f.Profile.OwnedScooters.volt_elite and f.Profile.OwnedEquipment.flux_elite and f.Profile.Entitlements.VIP, "Marketplace ownership grants paid catalog entries")
    check(f.Profile.Cosmetics["Tag:vip"] and f.Profile.Cosmetics["Clothing:VIP"], "VIP cosmetics granted")
    local queried = f.Marketplace.Checks
    f.Service:OnDataReady(f.Player)
    check(f.Marketplace.Checks == queried, "snapshots do not repeatedly query ownership")
    check(select(2, f.Service:Prompt(f.Player, "VIP")) == "AlreadyOwned", "owned passes cannot prompt again")
    f.Marketplace.FailOwnership = true; f.Service:Reconcile(f.Player)
    check(f.Profile.Entitlements.VIP, "temporary Marketplace failure does not revoke paid access")
    f = fixture()
    local pending = f.Receipt("retry-once")
    f.Store.FailSave = true
    check(f.Service:ProcessReceipt(pending) == "retry" and f.Profile.UpgradeCredits == 1, "failed durable save defers receipt acknowledgement")
    check(f.Service:ProcessReceipt(pending) == "retry" and f.Profile.UpgradeCredits == 1, "retry while unsaved cannot grant twice")
    f.Store.FailSave = false
    check(f.Service:ProcessReceipt(pending) == "granted" and f.Store.Saved.PurchaseReceipts["retry-once"] and f.Store.Saved.UpgradeCredits == 1, "receipt and reward committed in one profile snapshot")
    check(f.Service:ProcessReceipt(pending) == "granted" and f.Profile.UpgradeCredits == 1, "native duplicate receipt idempotent")
    local restart = fixture(f.Store.Saved)
    check(restart.Service:ProcessReceipt(pending) == "granted" and restart.Profile.UpgradeCredits == 1, "replay after reload remains idempotent")
    check(restart.Marketplace.ProcessReceipt(restart.Receipt("pack", "UpgradePack")) == "granted" and restart.Profile.UpgradeCredits == 6, "registered native callback grants exact pack count")
    restart.Context.Config.Monetization.Enabled = false
    check(restart.Service:ProcessReceipt(restart.Receipt("switch-off")) == "granted", "disabling new sales still fulfills pending legitimate receipts")
    restart.Persistent(false)
    check(restart.Service:ProcessReceipt(restart.Receipt("memory")) == "retry", "receipt cannot be acknowledged without persistent session")
    restart.Persistent(true); restart.Context.IsClosing = true
    check(restart.Service:ProcessReceipt(restart.Receipt("closing")) == "retry", "shutdown defers new receipts")
    restart.Context.IsClosing = false
    for _, receipt in {{}, {PlayerId = 123, ProductId = 0/0, PurchaseId = "nan"}, {PlayerId = 123, ProductId = 999999, PurchaseId = "unknown"},
        {PlayerId = 999, ProductId = 1007, PurchaseId = "offline"}, {PlayerId = 123, ProductId = 1007, PurchaseId = string.rep("x", 129)}} do
        check(restart.Service:ProcessReceipt(receipt) == "retry", "malformed/offline/unconfigured receipt stays pending")
    end
    f = fixture(); f.Store.YieldSave = true
    local co = coroutine.create(function() return f.Service:ProcessReceipt(f.Receipt("concurrent")) end)
    check(coroutine.resume(co) and f.Profile.UpgradeCredits == 1, "receipt can wait for storage")
    check(f.Service:ProcessReceipt(f.Receipt("concurrent-other")) == "retry" and f.Profile.UpgradeCredits == 1, "parallel same-player receipt is serialized")
    f.Store.YieldSave = false
    local ok, result = coroutine.resume(co)
    check(ok and result == "granted", "in-flight receipt completes after save")
    f = fixture(); f.Profile.UpgradeCredits = f.Config.MaxUpgradeCredits
    check(select(2, f.Service:Prompt(f.Player, "UpgradeCredit")) == "CreditLimit" and #f.Marketplace.Prompts == 0, "full wallet prevents opening a new paid consumable prompt")
    check(f.Service:ProcessReceipt(f.Receipt("full")) == "retry" and not f.Profile.PurchaseReceipts.full, "full credit balance cannot discard purchased product")
    f = fixture()
    for i = 1, 300 do check(f.Service:ProcessReceipt(f.Receipt("history-" .. i)) == "granted", "permanent ledger extends beyond generic copy limit") end
    local fullHistory = fixture(f.Store.Saved)
    check(fullHistory.Profile.UpgradeCredits == 300, "balance survives complete profile reload")
    local count = 0; for _ in fullHistory.Profile.PurchaseReceipts do count += 1 end
    check(count == 300, "sanitize preserves all receipts beyond 256 entries")
    check(fullHistory.Service:ProcessReceipt(fullHistory.Receipt("history-1")) == "granted" and fullHistory.Profile.UpgradeCredits == 300, "oldest receipt never becomes spendable again")
    fullHistory.Config.MaxReceipts = 300
    check(select(2, fullHistory.Service:Prompt(fullHistory.Player, "UpgradeCredit")) == "ReceiptLedgerFull" and #fullHistory.Marketplace.Prompts == 0, "full ledger prevents charging for a new unfulfillable product")
    check(fullHistory.Service:ProcessReceipt(fullHistory.Receipt("ledger-full")) == "retry" and fullHistory.Profile.UpgradeCredits == 300, "full permanent ledger blocks grant without evicting receipts")
    f = fixture(); f.Marketplace.YieldOwnership = true
    for _, offer in f.Config.Offers do if offer.Kind == "Pass" then f.Marketplace.Ownership[offer.Id] = true end end
    f.Service:OnDataReady(f.Player)
    check(coroutine.status(f.Spawned[1]) == "suspended", "ownership query may yield")
    f.Player.Parent = nil; f.Marketplace.YieldOwnership = false
    check(coroutine.resume(f.Spawned[1]) and next(f.Profile.Entitlements) == nil, "departed player cannot receive stale ownership result")
    check(not pcall(function() fixture(nil, function(cfg) cfg.Offers.VIP.Id = cfg.Offers.EliteScooter.Id end) end), "duplicate pass IDs fail startup instead of granting the wrong offer")
    check(not pcall(function() fixture(nil, function(cfg) cfg.Offers.UpgradePack.Credits = 0/0 end) end), "invalid product grant fails startup")
    -- Direct receipt validation never depends on client-provided currency or purchase completion signals.
    check(EquipmentConfig.ById.flux_elite.Damage > EquipmentConfig.ById.pulse.Damage
        and EquipmentConfig.ById.flux_elite.Cooldown < EquipmentConfig.ById.pulse.Cooldown, "paid combat stats are concretely stronger and faster")
    print("Commerce checks passed: " .. checks)
end
