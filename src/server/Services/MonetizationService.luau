--!strict
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local Service = {}
local context: any
local products: {[number]: string} = {}
local passes: {[number]: string} = {}
local observed: {[Player]: boolean} = {}
local busy: {[number]: boolean} = {}
local promptAt: {[Player]: number} = {}
local checkBusy: {[Player]: boolean} = {}
local started = false
local function current(player: Player, profile: any): boolean
    return player.Parent == Players and context.Services.PlayerData:IsReady(player) and context.Services.PlayerData:GetProfile(player) == profile
end
function Service:Init(ctx: any)
    context = ctx
    local cfg = ctx.Config.Monetization
    assert(ctx.Validation.IsInteger(cfg.MaxUpgradeCredits, 1, 1000000), "Credit limit must fit the saved schema")
    assert(ctx.Validation.IsInteger(cfg.MaxGaragePresets, 1, 6), "Garage limit must fit the saved schema")
    assert(ctx.Validation.IsInteger(cfg.MaxReceipts, 1, 10000), "Receipt limit must fit the permanent profile ledger")
    for key, offer in cfg.Offers do
        assert(ctx.Validation.IsInteger(offer.Id, 0, 9007199254740991), "Invalid Marketplace ID: " .. key)
        assert(offer.Kind == "Pass" or offer.Kind == "Product", "Invalid offer kind")
        if offer.Kind == "Product" then
            assert(ctx.Validation.IsInteger(offer.Credits, 1, cfg.MaxUpgradeCredits), "Invalid upgrade credit product")
        end
        if offer.ScooterId then assert(ctx.Config.Scooters.ById[offer.ScooterId], "Unknown paid scooter") end
        if offer.EquipmentId then assert(ctx.Config.Equipment.ById[offer.EquipmentId], "Unknown paid equipment") end
        if offer.Id > 0 then
            local index = if offer.Kind == "Pass" then passes else products
            assert(index[offer.Id] == nil, "Duplicate Marketplace ID in the same catalog")
            index[offer.Id] = key
        end
    end
end
local function checkPass(player: Player, key: string): boolean
    local profile = context.Services.PlayerData:GetProfile(player)
    local offer = context.Config.Monetization.Offers[key]
    if not profile or not offer or offer.Kind ~= "Pass" or offer.Id == 0 then return false end
    local ok, owns = pcall(function() return Marketplace:UserOwnsGamePassAsync(player.UserId, offer.Id) end)
    if not ok or not owns or not current(player, profile) then return false end
    context.CommerceRules.Grant(profile, key, offer, context.Config.Monetization)
    context.Services.PlayerData:MarkDirty(player)
    context.Notify(player)
    return true
end
function Service:Reconcile(player: Player)
    if checkBusy[player] or not context.Services.PlayerData:IsReady(player) then return end
    checkBusy[player] = true
    task.spawn(function()
        local ok, message = pcall(function()
            for _, key in passes do if player.Parent == Players and not context.IsClosing then checkPass(player, key) end end
        end)
        checkBusy[player] = nil
        if not ok then warn("[Commerce] ownership reconciliation failed: " .. tostring(message)) end
    end)
end
function Service:OnDataReady(player: Player)
    if observed[player] or not context.Services.PlayerData:IsReady(player) then return end
    observed[player] = true
    self:Reconcile(player)
end
function Service:Prompt(player: Player, key: string): (boolean, string)
    local offer = context.Config.Monetization.Offers[key]
    if not context.Config.Monetization.Enabled or not offer or offer.Id == 0 then return false, "RobuxNotConfigured" end
    if not context.Services.State:IsAllowed(player, "Trade") then return false, "VisitSafeZone" end
    if os.clock() - (promptAt[player] or -math.huge) < 3 then return false, "PurchaseCooldown" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return false, "DataNotReady" end
    if offer.Kind == "Pass" and profile.Entitlements[key] then return false, "AlreadyOwned" end
    if offer.Kind == "Product" and not context.Services.PlayerData:IsPersistent(player) then return false, "PurchaseNeedsDataStore" end
    if offer.Kind == "Product" then
        if profile.UpgradeCredits + offer.Credits > context.Config.Monetization.MaxUpgradeCredits then return false, "CreditLimit" end
        local count = 0
        for _ in profile.PurchaseReceipts do count += 1 end
        if count >= context.Config.Monetization.MaxReceipts then return false, "ReceiptLedgerFull" end
    end
    promptAt[player] = os.clock()
    local ok = pcall(function()
        if offer.Kind == "Pass" then Marketplace:PromptGamePassPurchase(player, offer.Id)
        else Marketplace:PromptProductPurchase(player, offer.Id) end
    end)
    return ok, if ok then "PurchasePrompted" else "MarketplaceUnavailable"
end
function Service:ProcessReceipt(receipt: any): Enum.ProductPurchaseDecision
    local retry = Enum.ProductPurchaseDecision.NotProcessedYet
    if context.IsClosing or type(receipt) ~= "table" or type(receipt.PurchaseId) ~= "string" or #receipt.PurchaseId == 0 or #receipt.PurchaseId > 128
        or not context.Validation.IsInteger(receipt.PlayerId, 1, 9007199254740991) or not context.Validation.IsInteger(receipt.ProductId, 1, 9007199254740991) then return retry end
    local key = products[receipt.ProductId]
    local player = Players:GetPlayerByUserId(receipt.PlayerId)
    if not key or not player or busy[receipt.PlayerId] or not context.Services.PlayerData:IsPersistent(player) then return retry end
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return retry end
    busy[receipt.PlayerId] = true
    local ok, saved = pcall(function(): boolean
        if not profile.PurchaseReceipts[receipt.PurchaseId] then
            local count = 0
            for _ in profile.PurchaseReceipts do count += 1 end
            -- No eviction: an old receipt must never become spendable a second time.
            if count >= context.Config.Monetization.MaxReceipts then return false end
            local granted = context.CommerceRules.Grant(profile, key, context.Config.Monetization.Offers[key], context.Config.Monetization)
            if not granted then return false end
            profile.PurchaseReceipts[receipt.PurchaseId] = true
            context.Services.PlayerData:MarkDirty(player)
        end
        -- Reward and receipt live in ONE session-locked profile write. Ack only after durable save.
        local committed = context.Services.PlayerData:Save(player, false)
        if committed and current(player, profile) then context.Notify(player) end
        return committed
    end)
    busy[receipt.PlayerId] = nil
    if not ok then warn("[Commerce] receipt pending after processing error") end
    return if ok and saved then Enum.ProductPurchaseDecision.PurchaseGranted else retry
end
function Service:GetSnapshot(player: Player): any
    local profile = context.Services.PlayerData:GetProfile(player)
    local offers = {}
    for _, key in context.Config.Monetization.Order do
        local offer = context.Config.Monetization.Offers[key]
        local available = context.Config.Monetization.Enabled and offer.Id > 0
        if offer.Kind == "Product" then available = available and context.Services.PlayerData:IsPersistent(player) end
        table.insert(offers, {Key = key, Name = offer.Name, Description = offer.Description, Kind = offer.Kind,
            Available = available, Owned = profile and profile.Entitlements[key] == true})
    end
    return {Offers = offers, UpgradeCredits = if profile then profile.UpgradeCredits else 0}
end
function Service:Start()
    assert(not started, "MonetizationService already started")
    started = true -- Roblox callback members can be assigned but cannot be read.
    Marketplace.ProcessReceipt = function(receipt: any) return self:ProcessReceipt(receipt) end
    Marketplace.PromptGamePassPurchaseFinished:Connect(function(player: Player, id: number, bought: boolean)
        -- This signal is only a reason to re-query ownership. Never use bought as proof.
        local key = passes[id]
        if bought and key and player.Parent == Players then task.spawn(function() checkPass(player, key) end) end
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        observed[player], promptAt[player], checkBusy[player] = nil, nil, nil
    end)
end
return Service
