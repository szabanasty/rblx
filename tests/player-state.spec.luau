--!nonstrict
return function(loadService)
    local checks = 0
    local function check(ok, message) assert(ok, message); checks += 1 end
    local function signal()
        local event = {Connections = {}}
        function event:Connect(callback)
            local connection = {Enabled = true, Callback = callback}
            function connection:Disconnect() self.Enabled = false end
            table.insert(self.Connections, connection)
            return connection
        end
        function event:Fire(...)
            for _, connection in self.Connections do if connection.Enabled then connection.Callback(...) end end
        end
        return event
    end
    local function humanoid(health)
        return {Health = health, MaxHealth = 100, HealthChanged = signal(), Died = signal(), IsA = function(_, class) return class == "Humanoid" end}
    end
    local function character(human)
        return {WaitForChild = function() return human end}
    end
    local players = {PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return {} end}
    local queued = {}
    local taskMock = {spawn = function(callback)
        local thread = coroutine.create(callback)
        local ok, message = coroutine.resume(thread)
        assert(ok, message)
        if coroutine.status(thread) ~= "dead" then table.insert(queued, thread) end
    end}
    local notifications = 0
    local ctx = {Config = {Combat = {MaxHealth = 100}}, Notify = function() notifications += 1 end}
    local state = loadService({GetService = function() return players end}, taskMock)
    state:Init(ctx); state:Start()
    local h = humanoid(80)
    local p = {Parent = players, Character = character(h), CharacterAdded = signal(), CharacterRemoving = signal()}
    players.PlayerAdded:Fire(p)
    check(state:GetPublic(p).CurrentHealth == 80 and state:GetPublic(p).HealthReady, "native health observed on existing character")
    check(state:GetPublic(p).State == "ALIVE" and state:GetPublic(p).AreaId == "UNASSIGNED", "phase 0 does not pretend zones are active")
    local public = state:GetPublic(p)
    public.CurrentHealth = 999
    check(state:GetPublic(p).CurrentHealth == 80 and public.Generation == nil, "public state is detached from internal session")
    h.Health = 50; h.HealthChanged:Fire(50)
    check(state:GetPublic(p).CurrentHealth == 50, "server health changes synchronized")
    h.Health = 0; h.Died:Fire()
    check(state:GetPublic(p).State == "RESPAWNING", "native death is observed, downed feature remains unimplemented")
    local nextHuman = humanoid(100)
    p.CharacterRemoving:Fire(p.Character)
    p.Character = character(nextHuman)
    p.CharacterAdded:Fire(p.Character)
    check(state:GetPublic(p).CurrentHealth == 100 and state:GetPublic(p).State == "ALIVE", "respawn rebinds state")
    h.Health = 10; h.HealthChanged:Fire(10)
    check(state:GetPublic(p).CurrentHealth == 100, "old character events disconnected")
    local oldCharacter = p.Character
    p.Character = {WaitForChild = function() return coroutine.yield() end}
    p.CharacterAdded:Fire(p.Character)
    check(not state:GetPublic(p).HealthReady and #queued == 1, "pending avatar waits without inventing health")
    p.CharacterRemoving:Fire(p.Character)
    local ok, message = coroutine.resume(queued[1], humanoid(25)); assert(ok, message)
    check(state:GetPublic(p).State == "RESPAWNING" and not state:GetPublic(p).HealthReady, "stale awaited avatar cannot overwrite removal")
    p.Character = oldCharacter
    p.CharacterAdded:Fire(oldCharacter)
    local q = {Parent = players, Character = character(humanoid(70)), CharacterAdded = signal(), CharacterRemoving = signal()}
    players.PlayerAdded:Fire(q)
    check(state:GetPublic(q).CurrentHealth == 70 and state:GetPublic(p).CurrentHealth == 100, "player records isolated")
    p.Parent = nil
    players.PlayerRemoving:Fire(p)
    local before = notifications
    nextHuman.Health = 2; nextHuman.HealthChanged:Fire(2)
    check(state:GetPublic(p) == nil and notifications == before, "leave cleans state and all character listeners")
    print("Player state lifecycle checks passed: " .. checks)
end
