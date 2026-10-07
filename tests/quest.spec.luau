--!nonstrict
return function(loadService, Schema, GameConfig, QuestConfig, WorldConfig)
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local clock, timestamp, guid = 100, 10000, 0
    local profile = Schema.new(123, GameConfig)
    local player = {}
    local ready, near, riding = true, true, true
    local distance = 20
    local target = WorldConfig.Locations.DeliveryTarget
    local position = {X = target.X, Y = 1, Z = target.Z}
    local grants, receipts, messages = {}, {}, {}
    local heartbeat, removing
    local players = {PlayerRemoving = {Connect = function(_, callback) removing = callback end}}
    local mockServices = {
        Players = players,
        RunService = {Heartbeat = {Connect = function(_, callback) heartbeat = callback end}},
        HttpService = {GenerateGUID = function() guid += 1; return "test-" .. guid end},
    }
    local ctx = {
        Config = {Quests = QuestConfig, World = WorldConfig}, Notify = function() end,
        Remotes = {Feedback = {FireClient = function(_, _, result) table.insert(messages, result) end}},
        Services = {
            PlayerData = {GetProfile = function() return if ready then profile else nil end, MarkDirty = function() end},
            World = {IsNear = function() return near end, GetLocation = function() return {X = target.X, Y = 1, Z = target.Z} end},
            Scooter = {GetTelemetry = function() return {Distance = distance, Riding = riding} end, GetPosition = function() return position end},
            Economy = {Reward = function(_, _, reason, money, xp, reputation, receipt)
                check(not receipts[receipt], "quest receipt unique")
                receipts[receipt] = true
                table.insert(grants, {Reason = reason, Money = money, XP = xp, Reputation = reputation})
                return true, "Granted"
            end},
        },
    }
    local quest = loadService({GetService = function(_, name) return mockServices[name] end}, {clock = function() return clock end, time = function() return timestamp end})
    quest:Init(ctx); quest:Start()
    ready = false
    check(not quest:StartQuest(player, "first_delivery"), "data readiness checked")
    ready = true
    check(not quest:StartQuest(player, "fake"), "unknown quest rejected")
    near = false
    check(not quest:StartQuest(player, "first_delivery"), "delivery hub proximity required")
    near = true
    check(quest:StartQuest(player, "first_delivery"), "valid start succeeds")
    check(not quest:StartQuest(player, "first_delivery"), "only one quest per player")
    local snapshot = quest:GetSnapshot(player)
    check(snapshot.DistanceMeters == 0 and snapshot.Target.X == target.X and snapshot.Token == nil, "snapshot has own target and hides receipt")
    quest:Check(player)
    check(#grants == 0, "being at target immediately cannot grant")
    distance = 100
    quest:Check(player)
    check(#grants == 0, "minimum elapsed time enforced")
    clock += 15
    riding = false
    quest:Check(player)
    check(#grants == 0, "on foot cannot complete delivery")
    riding = true
    position = {X = target.X + target.Radius + 1, Y = 1, Z = target.Z}
    quest:Check(player)
    check(#grants == 0, "server target radius enforced")
    position = {X = target.X, Y = 50, Z = target.Z}
    quest:Check(player)
    check(#grants == 0, "vertical teleport cannot complete delivery")
    position.Y = 1
    heartbeat(0.5)
    check(#grants == 1 and grants[1].Money == QuestConfig.first_delivery.Money and grants[1].XP == QuestConfig.first_delivery.XP, "server catalog reward granted")
    check(profile.Statistics.DeliveriesCompleted == 1 and profile.QuestCooldowns.first_delivery == timestamp + 120, "completion and persistent cooldown saved")
    quest:Check(player)
    check(#grants == 1 and quest:GetSnapshot(player) == nil, "duplicate completion cannot grant")
    check(select(2, quest:StartQuest(player, "first_delivery")) == "QuestCooldown", "successful quest cooldown survives state reset")
    timestamp += 121; clock += 121
    check(quest:StartQuest(player, "first_delivery"), "cooldown expires")
    check(quest:Cancel(player), "cancel succeeds")
    check(not quest:StartQuest(player, "first_delivery"), "cancel/start spam cooldown enforced")
    clock += 3
    check(quest:StartQuest(player, "first_delivery"), "start after anti-spam window")
    clock += 181
    quest:Check(player)
    check(quest:GetSnapshot(player) == nil and #grants == 1, "expired quest gives no reward")
    check(quest:StartQuest(player, "first_delivery"), "new active quest after expiry")
    removing(player)
    check(quest:GetSnapshot(player) == nil, "leave clears transient quest state")
    print("Quest checks passed: " .. checks)
end
