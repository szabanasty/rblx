--!strict
-- Session leaderboard from actual server profiles. No client score submission.
local Players = game:GetService("Players")
local Service = {}
local context: any
local cached: {any} = {}
local nextRefresh = 0
function Service:Init(ctx: any) context = ctx end
function Service:Start() end
function Service:GetSnapshot(): {any}
    if os.clock() < nextRefresh then return cached end
    nextRefresh = os.clock() + 5
    cached = {}
    for _, player in Players:GetPlayers() do
        local profile = context.Services.PlayerData:GetProfile(player)
        if profile then
            table.insert(cached, {UserId = player.UserId, Name = player.Name, Kills = profile.Kills,
                Assists = profile.Assists, CurrentStreak = profile.CurrentStreak, Deaths = profile.Deaths, Revives = profile.Revives, BestStreak = profile.BestStreak, Level = profile.Level})
        end
    end
    table.sort(cached, function(a, b) return if a.Kills == b.Kills then a.UserId < b.UserId else a.Kills > b.Kills end)
    while #cached > 100 do table.remove(cached) end
    return cached
end
return Service
