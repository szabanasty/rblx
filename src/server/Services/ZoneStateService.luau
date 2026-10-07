--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Service = {}
local context: any
local records: {[Player]: any} = {}
local signals: {[Player]: {RBXScriptConnection}} = {}
local characterSignals: {[Player]: {RBXScriptConnection}} = {}
local function clear(list: {RBXScriptConnection}?)
    if list then for _, connection in list do connection:Disconnect() end end
end
local function syncCharacter(player: Player, record: any)
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if humanoid and root and root:IsA("BasePart") then
        local frozen = record.DownedUntil > 0 or record.Reviving
        root.Anchored = record.DownedUntil > 0
        humanoid.WalkSpeed = if frozen then 0 else context.Services.Equipment:GetMobility(player) * 16
        humanoid.JumpHeight = if frozen or record.Fishing then 0 else 7.2
        humanoid.JumpPower = if frozen or record.Fishing then 0 else 50
        humanoid.AutoRotate = not frozen
        if humanoid.Health > 0 then humanoid.Health = math.max(1, record.Health) end
    end
end
function Service:Init(ctx: any) context = ctx end
function Service:GetRecord(player: Player): any return records[player] end
function Service:IsAllowed(player: Player, kind: string): boolean
    if not context.Services.PlayerData:IsReady(player) or not context.Services.Movement:GetPosition(player) then return false end
    local record = records[player]
    if record then
        local area = context.Services.Zones:GetArea(player)
        if area ~= "Unknown" then record.Area = area end
    end
    return context.StateRules.CanAct(record, kind, os.clock())
end
function Service:Changed(player: Player)
    local record = records[player]
    if record then syncCharacter(player, record) end
    context.Notify(player)
end
function Service:Tag(player: Player)
    local record = records[player]
    if record then record.TaggedUntil = os.clock() + context.Config.Combat.CombatTagSeconds end
end
function Service:GetPublic(player: Player): any
    local record = records[player]
    if not record then return nil end
    local now = os.clock()
    return {State = context.StateRules.State(record, now), CurrentHealth = record.Health, MaxHealth = record.MaxHealth,
        HealthReady = record.Ready, AreaId = record.Area, AreaName = if context.Config.Zones.Areas[record.Area] then context.Config.Zones.Areas[record.Area].DisplayName else "CITY",
        CurrentStreak = record.Streak, CombatSeconds = math.max(0, math.ceil(record.TaggedUntil - now)),
        DownedSeconds = if record.DownedUntil > 0 then math.max(0, math.ceil(record.DownedUntil - now)) else 0,
        ProtectionSeconds = math.max(0, math.ceil(record.ProtectedUntil - now))}
end
function Service:Respawn(player: Player)
    local record = records[player]
    if not record or not record.Ready then return end
    context.Services.Combat:Finalize(player)
    record.Ready, record.Fishing, record.Reviving = false, false, false
    context.Services.Scooter:Despawn(player)
    self:Changed(player)
    task.spawn(function()
        if player.Parent ~= Players or context.IsClosing then return end
        for attempt = 1, 3 do
            if player.Parent ~= Players or context.IsClosing or records[player] ~= record then return end
            local ok, message = pcall(function() player:LoadCharacterAsync() end)
            if ok then return end
            warn("[Respawn] attempt=" .. attempt .. " " .. tostring(message))
            task.wait(attempt)
        end
        if records[player] == record then
            record.Ready, record.DownedUntil = true, os.clock() + 5
            context.Notify(player)
        end
    end)
end
local function observe(player: Player, character: Model)
    clear(characterSignals[player])
    local record = context.StateRules.New(context.Config.Combat.MaxHealth)
    records[player] = record
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if records[player] ~= record or player.Character ~= character or not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then return end
        humanoid.MaxHealth, humanoid.Health, humanoid.BreakJointsOnDeath = record.MaxHealth, record.MaxHealth, false
        record.Ready, record.Area, record.ProtectedUntil = true, "SafeZone", os.clock() + 3
        context.Services.Movement:AllowTeleport(player, root.Position)
        characterSignals[player] = {humanoid.Died:Connect(function()
            if records[player] ~= record then return end
            context.Services.Combat:OnExit(player)
            record.Ready = false
            context.Notify(player)
        end)}
        Service:Changed(player)
    end)
end
local function add(player: Player)
    if signals[player] then return end
    records[player] = context.StateRules.New(context.Config.Combat.MaxHealth)
    signals[player] = {
        player.CharacterAdded:Connect(function(character: Model) observe(player, character) end),
        player.CharacterRemoving:Connect(function()
            context.Services.Combat:OnExit(player)
            clear(characterSignals[player]); characterSignals[player] = nil
            local record = records[player]
            if record then record.Ready = false end
        end),
    }
    if player.Character then observe(player, player.Character) end
end
function Service:Start()
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player: Player)
        context.Services.Combat:OnExit(player)
        clear(signals[player]); clear(characterSignals[player])
        signals[player], characterSignals[player], records[player] = nil, nil, nil
    end)
    for _, player in Players:GetPlayers() do add(player) end
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.2 then return end
        local tick = elapsed
        elapsed = 0
        for player, record in records do
            local area = context.Services.Zones:GetArea(player)
            if area ~= "Unknown" then record.Area = area end
            if record.Ready and record.DownedUntil > 0 and record.DownedUntil <= os.clock() then self:Respawn(player)
            elseif record.Ready then
                if record.Area == "SafeZone" and record.TaggedUntil <= os.clock() and record.DownedUntil == 0 then record.Health = math.min(record.MaxHealth, record.Health + tick * 5) end
                if record.Area == "CombatZone" and record.DownedUntil == 0 then
                    record.ZoneSeconds = (record.ZoneSeconds or 0) + math.min(tick, 0.5)
                    if record.ZoneSeconds >= 10 then
                        local profile = context.Services.PlayerData:GetProfile(player)
                        if profile then profile.ZoneTime = math.min(2000000000, profile.ZoneTime + math.floor(record.ZoneSeconds)); context.Services.PlayerData:MarkDirty(player) end
                        record.ZoneSeconds %= 1
                    end
                end
                syncCharacter(player, record)
            end
        end
    end)
end
return Service
