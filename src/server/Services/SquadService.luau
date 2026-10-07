--!strict
local Players = game:GetService("Players")
local Store = require(game:GetService("ReplicatedStorage").Shared.Modules.SquadStore)
local Service = {}
local context: any
local store: any
local function notifyAll()
    for _, player in Players:GetPlayers() do context.Notify(player) end
end
function Service:Init(ctx: any) context = ctx; store = Store.new(ctx.Config.Combat.SquadSize) end
function Service:Same(a: Player, b: Player): boolean return store:Same(a.UserId, b.UserId) end
function Service:GetId(player: Player): string? return store.Membership[player.UserId] end
function Service:Action(player: Player, action: string, targetId: number?): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Squad") then return false, "StateBlocked" end
    local success, message = false, "InvalidRequest"
    if action == "CreateSquad" then success, message = store:Create(player.UserId)
    elseif action == "AcceptSquad" then success, message = store:Accept(player.UserId, os.clock())
    elseif action == "DeclineSquad" then store.Invites[player.UserId] = nil; success, message = true, "InviteDeclined"
    elseif action == "LeaveSquad" then success, message = store:Leave(player.UserId)
    elseif targetId then
        local target = Players:GetPlayerByUserId(targetId)
        if not target or not context.Services.State:IsAllowed(target, "Squad") then return false, "PlayerUnavailable" end
        if action == "InviteSquad" then success, message = store:Invite(player.UserId, targetId, os.clock())
        elseif action == "KickSquad" then success, message = store:Kick(player.UserId, targetId) end
    end
    if success then notifyAll() end
    return success, message
end
function Service:GetSnapshot(player: Player): any
    local id = store.Membership[player.UserId]
    local source = if id then store.Squads[id] else nil
    local output: any = {Members = {}}
    if source then
        output.SquadId, output.Leader = id, source.Leader
        for _, member in source.Members do
            local target = Players:GetPlayerByUserId(member)
            if target then
                local position = context.Services.Movement:GetPosition(target)
                table.insert(output.Members, {UserId = member, Name = target.Name, State = context.Services.State:GetPublic(target),
                    Position = if position then {X = position.X, Y = position.Y, Z = position.Z} else nil})
            end
        end
    end
    local invite = store.Invites[player.UserId]
    if invite then
        if invite.ExpiresAt <= os.clock() then store.Invites[player.UserId] = nil
        else
            local leader = Players:GetPlayerByUserId(invite.Leader)
            if leader then output.Invite = {From = leader.Name, ExpiresIn = math.ceil(invite.ExpiresAt - os.clock())} end
        end
    end
    return output
end
function Service:Start()
    Players.PlayerRemoving:Connect(function(player: Player) store:Leave(player.UserId); notifyAll() end)
end
return Service
