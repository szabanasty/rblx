--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Layout = require(script.Parent.Parent.Modules.HudLayout)
local Service = {}
local context: any
local data: any
local held = false
local holdPointer: InputObject? = nil
local target: number? = nil
local lastSent = -math.huge
local button: TextButton
function Service:Init(ctx: any) context = ctx end
local function stop()
    if held then context.Send("CancelRevive", {}) end
    held = false; holdPointer = nil
end
function Service:Update(snapshot: any)
    data = snapshot
    target = nil
    local state = if data.PlayerState then data.PlayerState.State else "RESPAWNING"
    if not data.Ready or (state ~= "SAFE" and state ~= "ALIVE" and state ~= "COMBAT" and state ~= "REVIVING") or data.Telemetry.Riding or context.Controllers.UIController:IsMenuOpen() then
        stop(); button.Visible = false; context.Controllers.UIController:SetReviveAvailable(false); return
    end
    local root = if Players.LocalPlayer.Character then Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
    local closest = math.huge
    if root and root:IsA("BasePart") then
        for _, member in data.Squad.Members do
            if member.UserId == Players.LocalPlayer.UserId or not member.Position or not member.State or member.State.State ~= "DOWNED" then continue end
            local position = member.Position
            local distance = (root.Position - Vector3.new(position.X, position.Y, position.Z)).Magnitude
            if distance <= context.Config.Combat.ReviveRangeStuds and distance < closest then target, closest = member.UserId, distance end
        end
    end
    button.Visible = target ~= nil
    context.Controllers.UIController:SetReviveAvailable(target ~= nil)
    if not target then stop() end
    button.Text = if data.Revive then "OCUCANIE " .. math.floor(data.Revive.Progress * 100) .. "%" else "PRZYTRZYMAJ E\nOCUĆ"
end
function Service:Start()
    local screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "ZoneRevive", ResetOnSpawn = false, DisplayOrder = 10})
    button = Gui.Button(screen, "OCUĆ", function() end)
    button.Position, button.Size, button.AnchorPoint, button.Visible = UDim2.new(0, 12, 1, -220), UDim2.fromOffset(150, 75), Vector2.new(0, 1), false
    local scale = Gui.Create("UIScale", button, {})
    local layoutWidth, layoutHeight, layoutPreference = 0, 0, 0
    local function resize()
        local camera = game:GetService("Workspace").CurrentCamera
        if not camera then return end
        local view = if screen.AbsoluteSize.X > 0 then screen.AbsoluteSize else camera.ViewportSize
        local preference = if data and data.Settings then data.Settings.UIScale else 1
        if layoutWidth == view.X and layoutHeight == view.Y and layoutPreference == preference then return end
        layoutWidth, layoutHeight, layoutPreference = view.X, view.Y, preference
        local layout = Layout.Calculate(view.X, view.Y, preference, UserInputService.TouchEnabled)
        local rect = layout.Panels.Revive
        button.Position, button.AnchorPoint = UDim2.fromOffset(rect.X, rect.Y), Vector2.zero
        button.Size, scale.Scale = UDim2.fromOffset(rect.W / layout.Scale, rect.H / layout.Scale), layout.Scale
    end
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    button.InputBegan:Connect(function(input: InputObject)
        if target and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then holdPointer = input; held = true end
    end)
    button.InputEnded:Connect(function(input: InputObject) if holdPointer == input then stop() end end)
    UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean) if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.E and target then held = true end end)
    UserInputService.InputEnded:Connect(function(input: InputObject) if input.KeyCode == Enum.KeyCode.E or holdPointer == input then stop() end end)
    UserInputService.WindowFocusReleased:Connect(stop)
    RunService.Heartbeat:Connect(function()
        resize()
        if context.Controllers.UIController:IsMenuOpen() then stop(); button.Visible = false; return end
        if held and target and os.clock() - lastSent >= 0.35 then
            lastSent = os.clock()
            context.Send("HoldRevive", {TargetId = target})
        end
    end)
end
return Service
