--!strict
-- Explicit server-owned relocation avoids racing the character movement guard against SeatWeld creation.
local Workspace = game:GetService("Workspace")
local Mount = {}
function Mount.Try(player: Player, assembly: any, context: any): boolean
    if assembly.Model:GetAttribute("OwnerUserId") ~= player.UserId or not context.Services.PlayerData:IsReady(player) then return false end
    if context.Services.State and not context.Services.State:IsAllowed(player, "Drive") then return false end
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    local seat = assembly.Seat
    if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") or seat.Disabled then return false end
    if seat.Occupant == humanoid then return true end
    if humanoid.SeatPart or seat.Occupant or (root.Position - assembly.Root.Position).Magnitude > 14 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, assembly.Model}
    if Workspace:Raycast(root.Position, seat.Position - root.Position, params) then return false end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    character:PivotTo(seat.CFrame * CFrame.new(0, 2.2, 0))
    if context.Services.Movement then context.Services.Movement:AllowTeleport(player, root.Position) end
    seat:Sit(humanoid)
    return true
end
return Mount
