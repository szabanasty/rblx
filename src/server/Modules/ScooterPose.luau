--!strict
-- R15 inverse kinematics, no external animation asset. R6 retains native seating.
local Pose = {}
function Pose.Clear(player: Player)
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if humanoid then
        for _, item in humanoid:GetChildren() do
            if item:IsA("IKControl") and item:GetAttribute("ZoneScooterPose") then item:Destroy() end
        end
    end
end
function Pose.Apply(player: Player, root: BasePart)
    Pose.Clear(player)
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not character or not humanoid then return end
    for _, limb in {"Left", "Right"} do
        for _, kind in {"Leg", "Arm"} do
            local chain = character:FindFirstChild(limb .. "Upper" .. kind)
            local tip = character:FindFirstChild(limb .. (if kind == "Leg" then "Foot" else "Hand"))
            local target = root:FindFirstChild(limb .. (if kind == "Leg" then "Foot" else "Hand") .. "Target")
            if chain and chain:IsA("BasePart") and tip and tip:IsA("BasePart") and target and target:IsA("Attachment") then
                local control = Instance.new("IKControl")
                control.Name, control.Type = "ScooterPose_" .. limb .. kind, Enum.IKControlType.Position
                control.ChainRoot, control.EndEffector, control.Target = chain, tip, target
                control.Weight, control.SmoothTime = 1, 0.12
                control:SetAttribute("ZoneScooterPose", true)
                control.Parent = humanoid
            end
        end
    end
end
return Pose
