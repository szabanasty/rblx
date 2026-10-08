--!strict
type Reward = {Money: number?, Credits: number?, Cosmetic: string?}
local rewards: {[number]: {Free: Reward, Premium: Reward}} = {}
for tier = 1, 12 do
    rewards[tier] = {Free = {Money = 100}, Premium = {Credits = 1}}
end
rewards[4].Free = {Cosmetic = "Color:Violet"}
rewards[6].Free = {Cosmetic = "Tag:city"}
rewards[9].Free = {Cosmetic = "Clothing:Tech"}
rewards[12].Free = {Credits = 1}
rewards[4].Premium = {Cosmetic = "Lights:Gold"}
rewards[8].Premium = {Cosmetic = "Clothing:Neon"}
rewards[12].Premium = {Cosmetic = "Tag:neon"}
return table.freeze({
    Enabled = true, Id = "RIVERSIDE_01", Name = "Riverside • Sezon 01", PremiumOfferKey = "SeasonRiverside",
    StartsAt = 0, EndsAt = 0, -- Unix UTC. 0 = open-ended development season; change ID for every new season.
    Tiers = 12, XPPerTier = 200, DailyXPCap = 1000, Rewards = rewards,
})
