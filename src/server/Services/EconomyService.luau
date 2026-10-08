--!strict
-- Money, XP and level mutations belong here. No client reward endpoint exists.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

type RewardBudget = { Day: number, Money: number, XP: number, Reputation: number? }
type Profile = {
	Money: number,
	Level: number,
	XP: number,
	Reputation: number,
	RewardBudget: RewardBudget,
	IdempotencyLedger: { [string]: number },
}
type RideProgress = { LastDistance: number, PendingDistance: number, Sequence: number }

local EconomyService = {}
local context: any = nil
local rideProgress: { [Player]: RideProgress } = {}
local sessionNonce = HttpService:GenerateGUID(false)
local started = false
local MAX_BALANCE = 2_000_000_000
local MAX_GRANT = 1_000_000
local MAX_LEDGER_ENTRIES = 128
local ledgerLimit = MAX_LEDGER_ENTRIES

local function safeInteger(value: any, maximum: number): boolean
	return type(value) == "number"
		and value == value
		and value >= 0
		and value <= maximum
		and value % 1 == 0
end

local function finiteDistance(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function getProfile(player: Player): Profile?
	if not context or not context.Services.PlayerData:IsReady(player) then
		return nil
	end
	return context.Services.PlayerData:GetProfile(player)
end

local function updateLeaderstats(player: Player, profile: Profile)
	local existing = player:FindFirstChild("leaderstats")
	if existing and not existing:IsA("Folder") then
		warn("[Economy] Existing leaderstats is not a Folder for " .. player.UserId)
		return
	end
	local folder: Folder
	if existing then
		folder = existing :: Folder
	else
		local created = Instance.new("Folder")
		created.Name = "leaderstats"
		created.Parent = player
		folder = created
	end
	local values: {[string]: number} = {Money = profile.Money, Level = profile.Level}
	for name, value in values do
		local found = folder:FindFirstChild(name)
		if found and not found:IsA("IntValue") then
			warn("[Economy] Existing " .. name .. " stat is not an IntValue")
			continue
		end
		local stat: IntValue
		if found then
			stat = found :: IntValue
		else
			local created = Instance.new("IntValue")
			created.Name = name
			created.Parent = folder
			stat = created
		end
		stat.Value = value
	end
end

local function changed(player: Player, profile: Profile)
	context.Services.PlayerData:MarkDirty(player)
	updateLeaderstats(player, profile)
	context.Notify(player)
end

local function rememberGrant(profile: Profile, key: string, timestamp: number)
	local ledger = profile.IdempotencyLedger
	ledger[key] = timestamp
	local count = 0
	for _ in ledger do
		count += 1
	end
	-- A small persisted recent-grant window; permanent quest receipts belong in
	-- quest state, rather than relying on this intentionally bounded ledger.
	while count > ledgerLimit do
		local oldestKey: string? = nil
		local oldestTime = math.huge
		for candidate, grantedAt in ledger do
			if candidate ~= key and (grantedAt < oldestTime
				or (grantedAt == oldestTime and (oldestKey == nil or candidate < oldestKey))) then
				oldestKey = candidate
				oldestTime = grantedAt
			end
		end
		if not oldestKey then
			break
		end
		ledger[oldestKey] = nil
		count -= 1
	end
end

function EconomyService:Init(ctx: any)
	assert(context == nil, "EconomyService was already initialized")
	local rewards = ctx.Config.Rewards
	assert(safeInteger(rewards.RideDistanceMeters, MAX_GRANT) and rewards.RideDistanceMeters > 0,
		"RideDistanceMeters must be a positive integer")
	assert(safeInteger(rewards.RideMoney, MAX_GRANT), "Invalid RideMoney")
	assert(safeInteger(rewards.RideXP, MAX_GRANT), "Invalid RideXP")
	assert(safeInteger(rewards.DailyMoneyCap, MAX_BALANCE), "Invalid DailyMoneyCap")
	assert(safeInteger(rewards.DailyXPCap, MAX_BALANCE), "Invalid DailyXPCap")
	assert(safeInteger(rewards.DailyReputationCap, MAX_BALANCE), "Invalid DailyReputationCap")
	assert(type(rewards.RewardPollSeconds) == "number" and rewards.RewardPollSeconds >= 0.25
		and rewards.RewardPollSeconds < math.huge, "Invalid RewardPollSeconds")
	assert(safeInteger(ctx.Config.Levels.LevelRewardMoney, MAX_GRANT), "Invalid LevelRewardMoney")
	local configuredLedgerLimit = rewards.MaxLedgerEntries or MAX_LEDGER_ENTRIES
	assert(safeInteger(configuredLedgerLimit, MAX_LEDGER_ENTRIES) and configuredLedgerLimit > 0,
		"MaxLedgerEntries must be between 1 and 128")
	ledgerLimit = configuredLedgerLimit
	context = ctx
end

-- Trusted server API. Client input must never choose a reward, amount or key.
-- The daily money budget includes the money awarded for gaining a level.
function EconomyService:Reward(
	player: Player,
	reason: string,
	money: number,
	xp: number,
	reputation: number?,
	idempotencyKey: string?
): (boolean, string)
	local rep = reputation or 0
	if type(reason) ~= "string" or #reason == 0 or #reason > 64
		or not safeInteger(money, MAX_GRANT)
		or not safeInteger(xp, MAX_GRANT)
		or not safeInteger(rep, MAX_GRANT) then
		return false, "InvalidReward"
	end
	if idempotencyKey ~= nil and (type(idempotencyKey) ~= "string"
		or #idempotencyKey == 0 or #idempotencyKey > 128) then
		return false, "InvalidRewardKey"
	end
	local profile = getProfile(player)
	if not profile then
		return false, "DataNotReady"
	end
	if idempotencyKey and profile.IdempotencyLedger[idempotencyKey] ~= nil then
		return false, "AlreadyGranted"
	end
	local now = os.time()
	local day = math.floor(now / 86400)
	local budget = profile.RewardBudget
	local usedMoney = if budget.Day == day then budget.Money else 0
	local usedXP = if budget.Day == day then budget.XP else 0
	local usedRep = if budget.Day == day then (budget.Reputation or 0) else 0
	local rewards = context.Config.Rewards
	local availableMoney = math.min(math.max(0, rewards.DailyMoneyCap - usedMoney), MAX_BALANCE - profile.Money)
	local grantedMoney = math.min(money, availableMoney)
    local commerce = context.Config.Monetization
    if commerce and (profile :: any).Entitlements.VIP then xp = math.min(MAX_GRANT, math.floor(xp * (1 + commerce.VIPXPBonus))) end
    local earnedXP = math.min(xp, math.max(0, rewards.DailyXPCap - usedXP))
    local grantedXP = earnedXP
	if profile.Level >= context.Config.Levels.MaxLevel then
		grantedXP = 0
	end
	local grantedRep = math.min(rep, MAX_BALANCE - profile.Reputation, math.max(0, (rewards.DailyReputationCap or 200) - usedRep))
    if grantedMoney == 0 and grantedXP == 0 and grantedRep == 0 and (not context.Services.Season or earnedXP == 0) then
		return false, "DailyLimit"
	end
	-- This mutation is nonyielding: another server callback cannot interleave
	-- between checking the receipt and applying the grant.
	local levelsGained = context.Progression.AddXP(profile, grantedXP, context.Config.Levels)
	local levelMoney = math.min(levelsGained * context.Config.Levels.LevelRewardMoney,
		math.max(0, availableMoney - grantedMoney))
	grantedMoney += levelMoney
	profile.Money += grantedMoney
	profile.Reputation += grantedRep
    profile.RewardBudget = { Day = day, Money = usedMoney + grantedMoney, XP = usedXP + (if context.Services.Season then earnedXP else grantedXP), Reputation = usedRep + grantedRep }
	if idempotencyKey then
		rememberGrant(profile, idempotencyKey, now)
	end
    if context.Services.Season and earnedXP > 0 then context.Services.Season:AddXP(player, earnedXP) end
	changed(player, profile)
	return true, "Granted"
end

-- Trusted server API: callers still validate ownership, price and transaction
-- eligibility before charging. No yields are permitted between charge and grant.
function EconomyService:Credit(player: Player, amount: number, source: string, receipt: string): (boolean, string)
    if not safeInteger(amount, MAX_GRANT) or amount == 0 or type(receipt) ~= "string" or #receipt > 128 or #receipt == 0 then return false, "InvalidReward" end
    local cap = context.Config.Economy.SourceCaps[source]
    if not cap then return false, "InvalidRewardSource" end
    local found = getProfile(player)
    if not found then return false, "DataNotReady" end
    local profile: any = found
    if profile.IdempotencyLedger[receipt] then return false, "AlreadyGranted" end
    local day = math.floor(os.time() / 86400)
    local budget = profile.ActivityBudget
    local used = if budget.Day == day then budget[source] or 0 else 0
    if profile.Money + amount > MAX_BALANCE then return false, "BalanceLimit" end
    if used + amount > cap then return false, "DailyLimit" end
    if budget.Day ~= day then budget = {Day = day, PvP = 0, Fishing = 0, Objective = 0, Revive = 0}; profile.ActivityBudget = budget end
    budget[source] = used + amount
    profile.Money += amount
    rememberGrant(profile, receipt, os.time())
    changed(player, profile)
    return true, "Granted"
end

function EconomyService:Spend(player: Player, amount: number): (boolean, string)
	if not safeInteger(amount, MAX_BALANCE) or amount == 0 then
		return false, "InvalidAmount"
	end
	local profile = getProfile(player)
	if not profile then
		return false, "DataNotReady"
	end
	if profile.Money < amount then
		return false, "InsufficientMoney"
	end
	profile.Money -= amount
	changed(player, profile)
	return true, "Paid"
end

function EconomyService:OnDataChanged(player: Player)
	local profile = getProfile(player)
	if profile then
		updateLeaderstats(player, profile)
	end
end

function EconomyService:GetSnapshot(player: Player): any
	local profile = getProfile(player)
	if not profile then
		return nil
	end
	return {
		Money = profile.Money,
		Level = profile.Level,
		XP = profile.XP,
		XPToNextLevel = context.Progression.XPToNextLevel(profile.Level, context.Config.Levels),
		Reputation = profile.Reputation,
	}
end

local function pollRide(player: Player)
	local profile = getProfile(player)
	if not profile then
		return
	end
	updateLeaderstats(player, profile)
	local telemetry = context.Services.Scooter:GetTelemetry(player)
	if not telemetry or not finiteDistance(telemetry.Distance) then
		return
	end
	local distance: number = telemetry.Distance
	local progress = rideProgress[player]
	if not progress then
		rideProgress[player] = { LastDistance = distance, PendingDistance = 0, Sequence = 0 }
		return
	end
	local delta = math.max(0, distance - progress.LastDistance)
	progress.LastDistance = distance
	local fullProfile: any = profile
	if delta > 0 and type(fullProfile.Statistics) == "table" then
		fullProfile.Statistics.DistanceMeters = math.min(MAX_BALANCE, fullProfile.Statistics.DistanceMeters + delta)
		context.Services.PlayerData:MarkDirty(player)
	end
	-- ScooterService only accumulates validated distance. Even if its counter
	-- resets on respawn, this retained remainder never re-awards old distance.
	-- Current Riding may already be false when a player dismounts between
	-- polls; that does not invalidate distance ScooterService already checked.
	progress.PendingDistance += delta
	local rewards = context.Config.Rewards
	local maxUnitsPerGrant = math.floor(MAX_GRANT / math.max(1, rewards.RideMoney, rewards.RideXP))
	local units = math.min(4, maxUnitsPerGrant, math.floor(progress.PendingDistance / rewards.RideDistanceMeters))
	if units == 0 then
		return
	end
	progress.PendingDistance -= units * rewards.RideDistanceMeters
	progress.Sequence += 1
	EconomyService:Reward(player, "ValidatedRide", rewards.RideMoney * units, rewards.RideXP * units,
		0, string.format("ride:%s:%d:%d", sessionNonce, player.UserId, progress.Sequence))
	-- Consuming the cadence at the cap prevents banking a day's ride rewards.
end

function EconomyService:Start()
	assert(context ~= nil, "Init EconomyService before Start")
	if started then
		return
	end
	started = true
	-- Foundation has no distance income or running gameplay simulation.
	if context.Config.Game and context.Config.Game.FoundationOnly then return end
	Players.PlayerRemoving:Connect(function(player: Player)
		rideProgress[player] = nil
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if context.IsClosing then return end
		elapsed += dt
		if elapsed < context.Config.Rewards.RewardPollSeconds then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			pollRide(player)
		end
	end)
end

return EconomyService
