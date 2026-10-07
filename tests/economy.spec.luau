--!strict
-- The test runner injects a fresh copy of the real service with local Roblox
-- mocks. No game, account, DataStore or network connection is needed.
return function(loadService: any, progression: any, rewardConfig: any, levelConfig: any)
	local day = math.floor(os.time() / 86400)
	local function newProfile(): any
		return {
			Money = 0, Level = 1, XP = 0, Reputation = 0,
			RewardBudget = { Day = day, Money = 0, XP = 0 }, IdempotencyLedger = {},
		}
	end
	local profile = newProfile()
	local ready = true
	local dirtyCount = 0
	local notifyCount = 0
	local distance = 0
	local riding = true
	local heartbeat: ((number) -> ())? = nil
	local removing: ((any) -> ())? = nil
	local stats: any = {
		Money = { Value = 0, IsA = function(_self: any, class: string) return class == "IntValue" end },
		Level = { Value = 0, IsA = function(_self: any, class: string) return class == "IntValue" end },
	}
	local folder: any = {
		IsA = function(_self: any, class: string) return class == "Folder" end,
		FindFirstChild = function(_self: any, name: string) return stats[name] end,
	}
	local player: any = {
		UserId = 123,
		FindFirstChild = function(_self: any, name: string) return if name == "leaderstats" then folder else nil end,
	}
	local players: any = {
		GetPlayers = function() return { player } end,
		PlayerRemoving = { Connect = function(_self: any, callback: any) removing = callback end },
	}
	player.Parent = players
	local services: any = {
		Players = players,
		RunService = { Heartbeat = { Connect = function(_self: any, callback: any) heartbeat = callback end } },
		HttpService = { GenerateGUID = function() return "deterministic-test-session" end },
	}
	local mockedGame = { GetService = function(_self: any, name: string) return services[name] end }
	local mockedInstance = { new = function() error("Unexpected Instance creation: preset leaderstats are missing") end }
	local economy = loadService(mockedGame, mockedInstance)
	economy:Init({
		Services = {
			PlayerData = {
				IsReady = function() return ready end,
				GetProfile = function() return profile end,
				MarkDirty = function() dirtyCount += 1 end,
			},
			Scooter = { GetTelemetry = function() return { Distance = distance, Riding = riding, Speed = 30 } end },
		},
		Config = { Rewards = rewardConfig, Levels = levelConfig },
		Progression = progression,
		Notify = function() notifyCount += 1 end,
	})
	local function reward(money: number, xp: number, key: string?, reputation: number?): (boolean, string)
		return economy:Reward(player, "Test", money, xp, reputation, key)
	end
	for _, amount in { -1, 0.5, math.huge, -math.huge, 0 / 0, 1_000_001 } do
		assert(not reward(amount, 0, "invalid-money"), "Invalid money was granted")
		assert(not reward(0, amount, "invalid-xp"), "Invalid XP was granted")
		assert(not reward(0, 0, "invalid-reputation", amount), "Invalid reputation was granted")
	end
	assert(profile.Money == 0 and profile.XP == 0 and dirtyCount == 0, "Validation changed the profile")
	assert(not reward(1, 0, ""), "An empty receipt key was accepted")
	assert(not reward(1, 0, string.rep("a", 129)), "Oversized receipt key was accepted")
	ready = false
	assert(select(2, reward(1, 1, "not-ready")) == "DataNotReady", "Reward mutated an unready profile")
	assert(select(2, economy:Spend(player, 1)) == "DataNotReady", "Spend mutated an unready profile")
	assert(economy:GetSnapshot(player) == nil, "Unready economy snapshot was exposed")
	ready = true
	assert(reward(10, 10, "once"), "A valid reward failed")
	assert(profile.Money == 10 and profile.XP == 10, "Valid reward was not applied")
	assert(select(2, reward(10, 10, "once")) == "AlreadyGranted", "Duplicate receipt was accepted")
	assert(profile.Money == 10 and profile.XP == 10, "Duplicate receipt changed progress")
	assert(stats.Money.Value == 10 and stats.Level.Value == 1, "Leaderstats were not updated")
	assert(not economy:Spend(player, 0), "A zero payment was accepted")
	assert(not economy:Spend(player, 0.5), "A fractional payment was accepted")
	assert(not economy:Spend(player, math.huge), "An infinite payment was accepted")
	assert(select(2, economy:Spend(player, 11)) == "InsufficientMoney", "Balance went negative")
	assert(economy:Spend(player, 10), "A funded payment failed")
	assert(profile.Money == 0 and stats.Money.Value == 0, "Payment did not update balance and leaderboard")
	profile = newProfile()
	assert(reward(950, 100, "level-cap"), "Level reward failed")
	assert(profile.Level == 2 and profile.XP == 0, "Level progression was not applied")
	assert(profile.Money == 1000 and profile.RewardBudget.Money == 1000,
		"Level-up money exceeded the daily money cap")
	assert(reward(25, 2000, "xp-cap"), "Remaining XP budget was not awarded")
	assert(profile.RewardBudget.XP == 2000 and profile.Money == 1000,
		"Daily XP cap or money cap was bypassed")
	assert(select(2, reward(25, 15, "fully-capped")) == "DailyLimit", "Exhausted daily limits were bypassed")
	profile.RewardBudget.Day = day - 1
	assert(reward(25, 15, "new-day"), "A new UTC day did not renew the budget")
	assert(profile.RewardBudget.Day == day and profile.RewardBudget.Money == 25 and profile.RewardBudget.XP == 15,
		"Daily budget reset was incorrect")
	profile = newProfile()
	profile.Level = levelConfig.MaxLevel
	assert(reward(25, 2000, "max-level"), "Max-level money reward failed")
	assert(profile.Level == levelConfig.MaxLevel and profile.XP == 0 and profile.RewardBudget.XP == 0,
		"Max-level XP consumed the daily XP budget")
	profile = newProfile()
	profile.Money = 2_000_000_000 - 5
	profile.Reputation = 2_000_000_000 - 1
	assert(reward(50, 0, "balance-cap", 50), "Balance-cap partial grant failed")
	assert(profile.Money == 2_000_000_000 and profile.Reputation == 2_000_000_000,
		"Persistent numeric storage bounds were exceeded")
	profile = newProfile()
	for index = 1, 160 do
		assert(reward(0, 0, "ledger-" .. index, 1), "Trusted reputation reward failed")
	end
	local entries = 0
	for _ in profile.IdempotencyLedger do entries += 1 end
	assert(entries == rewardConfig.MaxLedgerEntries, "Receipt ledger grew beyond its bound")
	assert(select(2, reward(0, 0, "ledger-160", 1)) == "AlreadyGranted", "Newest receipt was evicted")
	assert(reward(0, 0, "reputation-cap", 100), "Remaining reputation budget was not granted")
	assert(profile.Reputation == rewardConfig.DailyReputationCap and profile.RewardBudget.Reputation == rewardConfig.DailyReputationCap,
		"Reputation exceeded the daily cap")
	assert(select(2, reward(0, 0, "reputation-overflow", 1)) == "DailyLimit", "Reputation could be farmed after its daily cap")
	profile = newProfile()
	economy:Start()
	assert(heartbeat ~= nil and removing ~= nil, "Lifecycle hooks were not registered")
	local tick: any = heartbeat
	tick(1) -- Establish the current distance, without claiming historical meters.
	distance = 120
	tick(1)
	assert(profile.Money == 0, "Incomplete riding cadence was rewarded")
	distance = 250
	tick(1)
	assert(profile.Money == 25 and profile.XP == 15, "Validated riding cadence was not rewarded")
	tick(1)
	assert(profile.Money == 25, "The same cumulative distance was rewarded twice")
	distance = 260
	tick(1)
	distance = 0 -- Simulate a respawn/counter reset.
	tick(1)
	assert(profile.Money == 25, "Counter reset generated a reward")
	distance = 240
	tick(1)
	assert(profile.Money == 50, "Valid remainder was lost across a reset")
	riding = false -- The player dismounted just after accumulating valid meters.
	distance = 500
	tick(1)
	assert(profile.Money == 75, "Dismount discarded already-validated riding distance")
	profile.RewardBudget.Money = 1000
	profile.RewardBudget.XP = 2000
	distance = 750
	tick(1)
	assert(profile.Money == 75, "Ride polling bypassed daily reward limits")
	profile.RewardBudget.Day = day - 1
	tick(1)
	assert(profile.Money == 75, "Exhausted riding rewards were banked until tomorrow")
	assert(dirtyCount > 0 and notifyCount == dirtyCount, "Mutations failed to save or notify")
	print("Economy tests passed: amount validation, readiness, payments, receipts, daily caps, levels, bounded ledger and riding.")
end
