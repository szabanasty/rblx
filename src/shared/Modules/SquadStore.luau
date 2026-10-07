--!strict
-- Session-only membership; no client-supplied squad IDs, names or ranks.
local Store = {}
Store.__index = Store
function Store.new(maximum: number): any
    return setmetatable({Maximum = maximum, Sequence = 0, Squads = {}, Membership = {}, Invites = {}}, Store)
end
function Store:Create(userId: number): (boolean, string)
    if self.Membership[userId] then return false, "AlreadyInSquad" end
    self.Sequence += 1
    local id = tostring(self.Sequence)
    self.Squads[id] = {SquadId = id, Leader = userId, Members = {userId}}
    self.Membership[userId] = id
    return true, "SquadCreated"
end
function Store:Same(a: number, b: number): boolean
    return self.Membership[a] ~= nil and self.Membership[a] == self.Membership[b]
end
function Store:Invite(leader: number, target: number, now: number): (boolean, string)
    local id = self.Membership[leader]
    local squad = if id then self.Squads[id] else nil
    if not squad or squad.Leader ~= leader then return false, "LeaderOnly" end
    if leader == target or self.Membership[target] then return false, "AlreadyInSquad" end
    if #squad.Members >= self.Maximum then return false, "SquadFull" end
    local invitation = self.Invites[target]
    if invitation and invitation.ExpiresAt > now then return false, "InvitePending" end
    self.Invites[target] = {SquadId = id, Leader = leader, ExpiresAt = now + 30}
    return true, "InviteSent"
end
function Store:Accept(userId: number, now: number): (boolean, string)
    local invite = self.Invites[userId]
    self.Invites[userId] = nil
    if self.Membership[userId] then return false, "AlreadyInSquad" end
    if not invite or invite.ExpiresAt <= now then return false, "InviteExpired" end
    local squad = self.Squads[invite.SquadId]
    if not squad or squad.Leader ~= invite.Leader then return false, "InviteExpired" end
    if #squad.Members >= self.Maximum then return false, "SquadFull" end
    table.insert(squad.Members, userId)
    self.Membership[userId] = invite.SquadId
    return true, "SquadJoined"
end
function Store:Leave(userId: number): (boolean, string)
    local id = self.Membership[userId]
    self.Invites[userId] = nil
    if not id then return false, "NoSquad" end
    local squad = self.Squads[id]
    self.Membership[userId] = nil
    for index, member in squad.Members do if member == userId then table.remove(squad.Members, index); break end end
    if #squad.Members == 0 then self.Squads[id] = nil
    elseif squad.Leader == userId then squad.Leader = squad.Members[1] end
    for target, invite in self.Invites do if invite.SquadId == id then self.Invites[target] = nil end end
    return true, "SquadLeft"
end
function Store:Kick(leader: number, target: number): (boolean, string)
    local id = self.Membership[leader]
    local squad = if id then self.Squads[id] else nil
    if not squad or squad.Leader ~= leader or leader == target then return false, "LeaderOnly" end
    if not self:Same(leader, target) then return false, "NoSquad" end
    return self:Leave(target)
end
return Store
