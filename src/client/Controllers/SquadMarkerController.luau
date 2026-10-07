--!strict
local Players = game:GetService("Players")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Service = {}
local context: any
local markers: {[number]: BillboardGui} = {}
function Service:Init(ctx: any) context = ctx end
function Service:Start() end
function Service:Update(snapshot: any)
    local keep: {[number]: boolean} = {}
    if snapshot.Ready and snapshot.Squad then
        for _, member in snapshot.Squad.Members do
            if member.UserId == Players.LocalPlayer.UserId then continue end
            keep[member.UserId] = true
            local player = Players:GetPlayerByUserId(member.UserId)
            local character = if player then player.Character else nil
            local head = if character then character:FindFirstChild("Head") else nil
            local gui = markers[member.UserId]
            if head and head:IsA("BasePart") then
                if not gui or gui.Adornee ~= head then
                    if gui then gui:Destroy() end
                    gui = Gui.Create("BillboardGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "SquadMarker", Adornee = head, AlwaysOnTop = true, Size = UDim2.fromOffset(160, 58), StudsOffsetWorldSpace = Vector3.new(0, 3, 0), MaxDistance = 800})
                    Gui.Label(gui :: BillboardGui, "", 58)
                    markers[member.UserId] = gui :: BillboardGui
                end
                local label = (gui :: BillboardGui):FindFirstChildOfClass("TextLabel")
                local root = if Players.LocalPlayer.Character then Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
                local distance = if root and root:IsA("BasePart") then math.floor((root.Position - head.Position).Magnitude / context.Config.Game.StudsPerMeter) else 0
                if label then
                    label.Text = member.Name .. "\n" .. (if member.State and member.State.State == "DOWNED" then "ZGINIĘTY • " else "") .. distance .. "m"
                    label.TextXAlignment = Enum.TextXAlignment.Center
                    label.TextColor3 = if member.State and member.State.State == "DOWNED" then Color3.fromRGB(255, 167, 104) else Color3.fromRGB(106, 236, 181)
                end
            elseif gui then gui:Destroy(); markers[member.UserId] = nil end
        end
    end
    for id, marker in markers do if not keep[id] then marker:Destroy(); markers[id] = nil end end
end
return Service
