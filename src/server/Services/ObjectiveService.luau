--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Service = {}
local context: any
local owner: string? = nil
local progress = 0
local cooldownUntil = 0
local contested = false
function Service:Init(ctx: any) context = ctx end
function Service:GetSnapshot(): any
    return {SquadId = owner, Progress = progress / context.Config.World.Objective.HoldSeconds,
        Cooldown = math.max(0, math.ceil(cooldownUntil - os.clock())), Contested = contested}
end
function Service:Start()
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.5 then return end
        local tick = math.min(elapsed, 0.75)
        elapsed = 0
        if os.clock() < cooldownUntil then return end
        local cfg = context.Config.World.Objective
        local groups: {[string]: {Player}} = {}
        local opponentsPresent = false
        for _, player in Players:GetPlayers() do
            local position = context.Services.Movement:GetPosition(player)
            if not position or (position - Vector3.new(cfg.X, position.Y, cfg.Z)).Magnitude > cfg.Radius or math.abs(position.Y) > 12
                or not context.Services.State:IsAllowed(player, "Shoot") or context.Services.Scooter:GetTelemetry(player).Riding then continue end
            local id = context.Services.Squad:GetId(player)
            if not id then opponentsPresent = true; continue end
            if not groups[id] then groups[id] = {} end
            table.insert(groups[id], player)
        end
        local candidate: string? = nil
        local count = 0
        for id, members in groups do count += 1; if #members >= cfg.MinimumMembers then candidate = id end end
        contested = count > 1 or opponentsPresent
        if contested or not candidate then owner, progress = nil, 0; return end
        if owner ~= candidate then owner, progress = candidate, 0 end
        progress += tick
        if progress < cfg.HoldSeconds then return end
        local receipt = HttpService:GenerateGUID(false)
        for _, player in groups[candidate] do
            context.Services.Economy:Credit(player, cfg.Reward, "Objective", "objective:" .. receipt .. ":" .. player.UserId)
            context.Services.Economy:Reward(player, "ObjectiveXP", 0, 60, 0, "objxp:" .. receipt .. ":" .. player.UserId)
            context.Feedback(player, true, "ObjectiveCaptured")
        end
        owner, progress, cooldownUntil = nil, 0, os.clock() + cfg.CooldownSeconds
    end)
end
return Service
