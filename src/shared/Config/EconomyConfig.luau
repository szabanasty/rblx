--!strict
-- Profile initialization remains in GameConfig; income is disabled in PHASE 0.
return table.freeze({
    Currency = "Money", MaximumBalance = 2000000000,
    MaximumTransaction = 1000000,
    FishingSaleDailyCap = 2000,
    PvPRewardDailyCap = 10000,
})
