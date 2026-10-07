--!strict
-- PHASE 0 observes the native avatar. Custom combat/downed logic is not active.
local Players = game:GetService("Players")
type Record = {
    State: string, CurrentHealth: number, MaxHealth: number, HealthReady: boolean,
    Generation: number, Connections: {RBXScriptConnection}, CharacterConnections: {RBXScriptConnection},
}
local Service = {}
local context: any
local records: {[Player]: Record} = {}
local function disconnect(connections: {RBXScriptConnection})
    for _, connection in connections do connection:Disconnect() end
    table.clear(connections)
end
local function changed(player: Player)
    if not context.IsClosing and player.Parent == Players then context.Notify(player) end
end
local function observe(player: Player, character: Model, record: Record)
    record.Generation += 1
    local generation = record.Generation
    disconnect(record.CharacterConnections)
    record.HealthReady = false
    task.spawn(function()
        local found = character:WaitForChild("Humanoid", 5)
        if records[player] ~= record or record.Generation ~= generation or player.Character ~= character then return end
        if not found or not found:IsA("Humanoid") then return end
        local humanoid = found :: Humanoid
        humanoid.MaxHealth = record.MaxHealth
        local function healthChanged()
            if records[player] ~= record or record.Generation ~= generation then return end
            record.CurrentHealth = math.clamp(humanoid.Health, 0, record.MaxHealth)
            record.HealthReady = true
            record.State = if record.CurrentHealth > 0 then "ALIVE" else "RESPAWNING"
            changed(player)
        end
        table.insert(record.CharacterConnections, humanoid.HealthChanged:Connect(healthChanged))
        table.insert(record.CharacterConnections, humanoid.Died:Connect(healthChanged))
        healthChanged()
    end)
end
local function add(player: Player)
    if records[player] or context.IsClosing then return end
    local record: Record = {
        State = "ALIVE", CurrentHealth = context.Config.Combat.MaxHealth,
        MaxHealth = context.Config.Combat.MaxHealth, HealthReady = false, Generation = 0,
        Connections = {}, CharacterConnections = {},
    }
    records[player] = record
    table.insert(record.Connections, player.CharacterAdded:Connect(function(character: Model) observe(player, character, record) end))
    table.insert(record.Connections, player.CharacterRemoving:Connect(function()
        record.Generation += 1
        disconnect(record.CharacterConnections)
        record.HealthReady = false
        record.State = "RESPAWNING"
        record.CurrentHealth = 0
        changed(player)
    end))
    if player.Character then observe(player, player.Character, record) end
end
function Service:Init(ctx: any)
    context = ctx
    assert(ctx.Config.Combat.MaxHealth > 0 and ctx.Config.Combat.MaxHealth <= 1000, "Invalid MaxHealth")
end
function Service:GetPublic(player: Player): any
    local record = records[player]
    if not record then return nil end
    return {
        State = record.State, CurrentHealth = record.CurrentHealth, MaxHealth = record.MaxHealth,
        HealthReady = record.HealthReady, AreaId = "UNASSIGNED", AreaName = "Strefy w PHASE 1", CurrentStreak = 0,
    }
end
function Service:Start()
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player: Player)
        local record = records[player]
        records[player] = nil
        if record then disconnect(record.Connections); disconnect(record.CharacterConnections) end
    end)
    for _, player in Players:GetPlayers() do add(player) end
end
return Service
