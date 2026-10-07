--!strict
-- Validated encounter settlements; no client reward endpoint.
return table.freeze({
    Enabled = true, EliminationMoney = 100, AssistMoney = 35, ReviveMoney = 40,
    AssistWindowSeconds = 20, SameOpponentWindowSeconds = 600,
    SameOpponentMultipliers = {1, 0.5, 0.25, 0}, RevivePairCooldownSeconds = 180,
    StreakMilestones = {[3] = 100, [5] = 200, [10] = 500, [15] = 750, [20] = 1000},
    Bounty = {[10] = 150, [15] = 250, [20] = 400},
    Objectives = {Small = 150, Medium = 300, Large = 500},
})
