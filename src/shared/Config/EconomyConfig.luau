--!strict
-- Profile initialization remains in GameConfig; income is disabled in PHASE 0.
return table.freeze({
    SourceCaps = {PvP = 10000, Fishing = 2000, Objective = 3000, Revive = 400, Season = 1000},
    Currency = "Money", MaximumBalance = 2000000000,
    MaximumTransaction = 1000000,
    FishingSaleDailyCap = 2000,
    PvPRewardDailyCap = 10000,
})
