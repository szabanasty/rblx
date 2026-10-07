--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Service = {}
local context: any
local records: {[Player]: any} = {}
local function root(player: Player): BasePart?
    local character = player.Character
    local part = if character then character:FindFirstChild("HumanoidRootPart") else nil
    return if part and part:IsA("BasePart") then part else nil
end
function Service:Init(ctx: any) context = ctx end
function Service:AllowTeleport(player: Player, position: Vector3)
    local part = root(player)
    records[player] = {Root = part, Position = position, GroundedPosition = position, At = os.clock(), BlockedUntil = os.clock() + 1, Flags = 0, LastLog = 0, WindowAt = os.clock(), WindowPosition = position, AirborneAt = nil}
end
function Service:GetPosition(player: Player): Vector3?
    local part = root(player)
    if not part then return nil end
    local now = os.clock()
    local record = records[player]
    if not record or record.Root ~= part then
        self:AllowTeleport(player, part.Position)
        return nil
    end
    local position = part.Position
    local cfg = context.Config.Game
    if not context.Validation.IsFinite(position.X) or not context.Validation.IsFinite(position.Y) or not context.Validation.IsFinite(position.Z) then return nil end
    local telemetry = context.Services.Scooter:GetTelemetry(player)
    if record.Riding ~= telemetry.Riding then
        if telemetry.Riding then
            -- Only the validated server-owned seat can establish this transition.
            record.Position, record.At, record.WindowPosition, record.WindowAt = position, now, position, now
            record.AirborneAt = nil
        else record.WindowPosition, record.WindowAt = record.Position, record.At end
        record.Riding = telemetry.Riding
    end
    local speed = if telemetry.Riding then 110 else 24
    local elapsed = math.min(0.5, now - record.At)
    local delta = position - record.Position
    local planar = Vector3.new(delta.X, 0, delta.Z)
    local invalid = planar.Magnitude > speed * elapsed + 6 or math.abs(delta.Y) > 60 * elapsed + 15
        or position.Y < (cfg.MinimumWorldY or -100) or math.abs(position.X) > cfg.WorldHalfWidth or math.abs(position.Z) > cfg.WorldHalfWidth
    local window = position - record.WindowPosition
    invalid = invalid or Vector3.new(window.X, 0, window.Z).Magnitude > speed * (now - record.WindowAt) + 4
    if not invalid and not telemetry.Riding then
        local groundParams = RaycastParams.new()
        groundParams.FilterType = Enum.RaycastFilterType.Exclude
        groundParams.FilterDescendantsInstances = {player.Character :: Model, Workspace:WaitForChild("Vehicles")}
        if Workspace:Raycast(position, Vector3.new(0, -7, 0), groundParams) then record.AirborneAt = nil; record.GroundedPosition = position
        else
            record.AirborneAt = record.AirborneAt or now
            if now - record.AirborneAt > 3 then invalid = true end
        end
    end
    if not invalid and not telemetry.Riding and planar.Magnitude > 1 then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {player.Character :: Model, Workspace:WaitForChild("Vehicles")}
        local hit = Workspace:Raycast(record.Position, delta, params)
        invalid = hit ~= nil and hit.Instance.CanCollide
    end
    if invalid then
        record.Flags += 1
        record.BlockedUntil = now + 3
        record.WindowAt, record.WindowPosition, record.AirborneAt = now, record.Position, nil
        local restorePosition = if position.Y < (cfg.MinimumWorldY or -100) then record.GroundedPosition else record.Position
        record.Position = restorePosition
        part.CFrame = CFrame.new(restorePosition) * part.CFrame.Rotation
        part.AssemblyLinearVelocity = Vector3.zero
        if record.Flags >= 3 and now - record.LastLog >= 5 then
            record.LastLog = now
            warn(string.format("[MovementGuard] user=%d flags=%d", player.UserId, record.Flags))
        end
        return nil
    end
    if now - record.WindowAt >= 1 then record.WindowAt, record.WindowPosition = now, position end
    if now < record.BlockedUntil then
        record.Position, record.At = position, now
        return nil
    end
    return position
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) records[player] = nil end)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 0.2 then return end
        elapsed = 0
        for _, player in Players:GetPlayers() do
            local position = self:GetPosition(player)
            local record = records[player]
            if position and record then record.Position, record.At = position, os.clock() end
        end
    end)
end
return Service
