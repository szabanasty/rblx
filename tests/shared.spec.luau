--!strict
return function(Progression: any, Schema: any, Validation: any, RateLimiter: any, Levels: any, GameConfig: any)
    local checks = 0
    local function check(condition: boolean, description: string)
        assert(condition, description)
        checks += 1
    end
    local profile = Schema.new(123, GameConfig)
    check(profile.Money == 100 and profile.OwnedScooters.kukirin_g2 == true, "starter profile")
    check(Progression.AddXP(profile, 99, Levels) == 0 and profile.XP == 99, "below level boundary")
    check(Progression.AddXP(profile, 1, Levels) == 1 and profile.Level == 2 and profile.XP == 0, "level boundary")
    check(Progression.AddXP(profile, 360, Levels) == 2 and profile.Level == 4 and profile.XP == 10, "XP overflow")
    profile.Level, profile.XP = 99, 0
    check(Progression.AddXP(profile, 1000000, Levels) == 1 and profile.Level == 100 and profile.XP == 0, "max level")
    check(Progression.XPToNextLevel(100, Levels) == 0, "max level denominator")
    for _, value in {-1, math.huge, 0/0, 0.5} do
        check(not pcall(Progression.AddXP, profile, value, Levels), "invalid XP rejected")
    end
    profile = Schema.new(123, GameConfig)
    local receipt = string.rep("k", 100)
    profile.IdempotencyLedger[receipt] = 55
    local clone = Schema.deepCopy(profile)
    clone.Settings.UIScale = 1.5
    check(profile.Settings.UIScale == 1 and clone.IdempotencyLedger[receipt] == 55, "deep copy and long receipt preserve")
    profile.Settings.UIScale = math.huge
    local sanitized = Schema.sanitize(profile, GameConfig)
    check(sanitized and sanitized.Settings.UIScale == 1, "settings sanitize non-finite")
    profile.Money = 0/0
    check(Schema.sanitize(profile, GameConfig) == nil, "corrupt money fails closed")
    profile = Schema.new(123, GameConfig)
    profile.SchemaVersion = 99
    check(Schema.sanitize(profile, GameConfig) == nil, "future schema fails closed")
    local request = {Action = "SpawnScooter", Payload = {}, RequestId = 1}
    check(Validation.ParseAction(request) ~= nil, "spawn request")
    for _, raw in {
        {Action = "Reward", Payload = {Money = 999999}, RequestId = 2},
        {Action = "SpawnScooter", Payload = {TopSpeed = 999}, RequestId = 2},
        {Action = "SpawnScooter", Payload = {}, RequestId = 0/0},
        {Action = "SelectScooter", Payload = {ScooterId = string.rep("a", 65)}, RequestId = 2},
        {Action = "SetSetting", Payload = {Name = "Money", Value = 999}, RequestId = 2},
        {Action = "SetSetting", Payload = {Name = "UIScale", Value = math.huge}, RequestId = 2},
        {Action = "BuyScooter", Payload = {ScooterId = "kukirin_g4", Price = 0}, RequestId = 2},
        {Action = "UpgradeScooter", Payload = {ScooterId = "kukirin_g2", Category = "Motor", TopSpeed = 1000}, RequestId = 2},
        {Action = "FinishQuest", Payload = {QuestId = "first_delivery"}, RequestId = 2},
        {Action = "StartQuest", Payload = {QuestId = "first_delivery", Money = 999999}, RequestId = 2},
    } do check(Validation.ParseAction(raw) == nil, "remote payload rejection") end
    check(Validation.ParseAction({Action="DismountScooter",Payload={},RequestId=2}) ~= nil, "dismount request")
    check(Validation.ParseAction({Action="SetSetting",Payload={Name="ReducedEffects",Value=true},RequestId=3}) ~= nil, "boolean setting")
    check(Validation.ParseInput({Throttle=1,Steer=-1,Brake=false,Jump=true}) ~= nil, "input intent")
    for _, raw in {
        {Throttle=0/0,Steer=0,Brake=false,Jump=false},
        {Throttle=1,Steer=math.huge,Brake=false,Jump=false},
        {Throttle=2,Steer=0,Brake=false,Jump=false},
        {Throttle=1,Steer=0,Brake=false,Jump=false,Speed=500},
    } do check(Validation.ParseInput(raw) == nil, "invalid motion input") end
    local limiter = RateLimiter.new(2, 1)
    check(limiter:Allow(123, 0) and limiter:Allow(123, 0) and not limiter:Allow(123, 0), "burst cap")
    check(limiter:Allow(123, 1) and not limiter:Allow(123, 0), "refill monotonic")
    check(not limiter:Allow(123, 2, 0/0) and not limiter:Allow(123, -math.huge), "nonfinite limiter")
    limiter:Remove(123)
    check(limiter:Allow(123, 2), "cleanup permits clean session")
    print("Shared contracts passed: " .. checks .. " checks")
end
