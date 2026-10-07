--!strict
local Players = game:GetService("Players")
local NetworkService = {}
local context: any
local actionLimiter: any
local inputLimiter: any
local history: {[Player]: {LastId: number, Cooldowns: {[string]: number}, Violations: number, LastLog: number}} = {}
local cooldowns: {[string]: number} = {Sync = 0.5, SelectScooter = 0.3, SetSetting = 0.2, DismountScooter = 0.5, BuyScooter = 0.5, UpgradeScooter = 0.5, StartQuest = 0.75, CancelQuest = 0.3, Shoot = 0.09, HoldRevive = 0.2, CancelRevive = 0.1, ToggleFishing = 1, StopFishing = 0.5, SellFish = 0.5, InviteSquad = 2, AcceptSquad = 0.5, BuyCosmetic = 0.5, BuyEquipment = 0.5, EquipEquipment = 0.3, SwitchEquipment = 0.2, Reload = 0.3, ChargeScooter = 1}
local function record(player: Player)
    local state = history[player]
    if not state then
        state = {LastId = 0, Cooldowns = {}, Violations = 0, LastLog = 0}
        history[player] = state
    end
    return state
end
local function suspicious(player: Player, reason: string)
    local state = record(player)
    state.Violations += 1
    local now = os.clock()
    if state.Violations >= 5 and now - state.LastLog >= 10 then
        state.LastLog = now
        warn(string.format("[Security] user=%d reason=%s count=%d", player.UserId, reason, state.Violations))
    end
end
local function allowedInFoundation(action: string): boolean
    return action == "Sync" or action == "SetSetting"
end
function NetworkService:Init(ctx: any)
    context = ctx
    actionLimiter = ctx.RateLimiter.new(ctx.Config.Game.ActionBurst, ctx.Config.Game.ActionRate)
    inputLimiter = ctx.RateLimiter.new(ctx.Config.Game.InputBurst, ctx.Config.Game.InputRate)
end
function NetworkService:Start()
    context.Remotes.Action.OnServerEvent:Connect(function(player: Player, raw: any)
        if context.IsClosing then return end
        if not actionLimiter:Allow(player.UserId, os.clock()) then
            suspicious(player, "ActionRate")
            return
        end
        local request, errorCode = context.Validation.ParseAction(raw)
        if not request then suspicious(player, errorCode or "InvalidAction"); return end
        local state = record(player)
        if request.RequestId <= state.LastId then
            suspicious(player, "Replay")
            return
        end
        state.LastId = request.RequestId
        local now = os.clock()
        local cooldown = cooldowns[request.Action] or 0
        if now - (state.Cooldowns[request.Action] or -math.huge) < cooldown then return end
        state.Cooldowns[request.Action] = now
        if context.Config.Game.FoundationOnly and not allowedInFoundation(request.Action) then
            context.Remotes.Feedback:FireClient(player, {RequestId = request.RequestId, Success = false, Message = "PhaseLocked"})
            return
        end
        local success, message = false, "DataNotReady"
        if request.Action == "Sync" then
            context.Services.Snapshot:Send(player)
            return
        elseif context.Services.PlayerData:IsReady(player) then
            if context.Services.State and (request.Action == "SelectScooter" or request.Action == "SpawnScooter") and not context.Services.State:IsAllowed(player, "Drive") then
                success, message = false, "StateBlocked"
            elseif context.Config.Game.ZoneGame and request.Action == "Shoot" then
                success, message = context.Services.Combat:Shoot(player, request.Payload)
            elseif context.Config.Game.ZoneGame and request.Action == "Reload" then
                success, message = context.Services.Equipment:Reload(player)
            elseif context.Config.Game.ZoneGame and request.Action == "SwitchEquipment" then
                success, message = context.Services.Equipment:Switch(player, request.Payload.Slot)
            elseif context.Config.Game.ZoneGame and request.Action == "EquipEquipment" then
                success, message = context.Services.Equipment:Equip(player, request.Payload.Slot, request.Payload.EquipmentId)
            elseif context.Config.Game.ZoneGame and request.Action == "BuyEquipment" then
                success, message = context.Services.Equipment:Buy(player, request.Payload.EquipmentId)
            elseif context.Config.Game.ZoneGame and request.Action == "HoldRevive" then
                success, message = context.Services.Revive:Hold(player, request.Payload.TargetId)
            elseif context.Config.Game.ZoneGame and request.Action == "CancelRevive" then
                context.Services.Revive:Cancel(player); success, message = true, ""
            elseif context.Config.Game.ZoneGame and request.Action == "ToggleFishing" then
                success, message = context.Services.Fishing:Toggle(player)
            elseif context.Config.Game.ZoneGame and request.Action == "StopFishing" then
                success, message = context.Services.Fishing:Stop(player)
            elseif context.Config.Game.ZoneGame and request.Action == "SellFish" then
                success, message = context.Services.Fishing:Sell(player, request.Payload.Index, request.Payload.Revision)
            elseif context.Config.Game.ZoneGame and request.Action == "BuyCosmetic" then
                success, message = context.Services.Cosmetics:Buy(player, request.Payload.Category, request.Payload.Option)
            elseif context.Config.Game.ZoneGame and request.Action == "ChargeScooter" then
                success, message = context.Services.Scooter:Charge(player)
            elseif context.Config.Game.ZoneGame and string.find(request.Action, "Squad", 1, true) then
                success, message = context.Services.Squad:Action(player, request.Action, request.Payload.TargetId)
            elseif request.Action == "SelectScooter" then
                success, message = context.Services.Scooter:Select(player, request.Payload.ScooterId)
            elseif request.Action == "SpawnScooter" then
                success, message = context.Services.Scooter:Spawn(player)
            elseif request.Action == "DespawnScooter" then
                success, message = context.Services.Scooter:Despawn(player)
            elseif request.Action == "DismountScooter" then
                success, message = context.Services.Scooter:Dismount(player)
            elseif request.Action == "BuyScooter" then
                success, message = context.Services.Shop:BuyScooter(player, request.Payload.ScooterId)
            elseif request.Action == "UpgradeScooter" then
                success, message = context.Services.Shop:Upgrade(player, request.Payload.ScooterId, request.Payload.Category)
            elseif request.Action == "StartQuest" and context.Services.Quests then
                success, message = context.Services.Quests:StartQuest(player, request.Payload.QuestId)
            elseif request.Action == "CancelQuest" and context.Services.Quests then
                success, message = context.Services.Quests:Cancel(player)
            elseif request.Action == "SetSetting" then
                local profile = context.Services.PlayerData:GetProfile(player)
                if profile then
                    profile.Settings[request.Payload.Name] = request.Payload.Value
                    context.Services.PlayerData:MarkDirty(player)
                    success, message = true, "SettingSaved"
                end
            end
        end
        if request.Action ~= "Shoot" and request.Action ~= "HoldRevive" or not success then
            context.Remotes.Feedback:FireClient(player, {RequestId = request.RequestId, Success = success, Message = message})
        end
        if success and request.Action ~= "Shoot" and request.Action ~= "HoldRevive" then context.Notify(player) end
    end)
    context.Remotes.Input.OnServerEvent:Connect(function(player: Player, raw: any)
        if context.IsClosing then return end
        if not inputLimiter:Allow(player.UserId, os.clock()) then suspicious(player, "InputRate"); return end
        local input, errorCode = context.Validation.ParseInput(raw)
        if not input then suspicious(player, errorCode or "InvalidInput"); return end
        if context.Config.Game.FoundationOnly then return end
        if context.Services.PlayerData:IsReady(player) then context.Services.Scooter:SetInput(player, input) end
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        actionLimiter:Remove(player.UserId)
        inputLimiter:Remove(player.UserId)
        history[player] = nil
    end)
end
return NetworkService
