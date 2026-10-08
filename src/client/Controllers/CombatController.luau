--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Layout = require(script.Parent.Parent.Modules.HudLayout)
local Service = {}
local context: any
local snapshot: any
local held = false
local firePointer: InputObject? = nil
local aiming = false
local lastFire = -math.huge
local aimCamera: Camera? = nil
local oldFov = 70
local screen: ScreenGui
local panel: Frame
local crosshair: TextLabel
function Service:Init(ctx: any) context = ctx end
local function available(): boolean
    local state = if snapshot then snapshot.PlayerState else nil
    return snapshot ~= nil and snapshot.Ready and state ~= nil and (state.State == "SAFE" or state.State == "ALIVE" or state.State == "COMBAT")
        and not snapshot.Telemetry.Riding and not context.Controllers.UIController:IsMenuOpen()
end
function Service:SetAim(value: boolean)
    aiming = value
    local camera = Workspace.CurrentCamera
    if aiming and camera then
        if not aimCamera then aimCamera = camera; oldFov = camera.FieldOfView end
        camera.FieldOfView = 55
    elseif aimCamera then
        if aimCamera.Parent then aimCamera.FieldOfView = oldFov end
        aimCamera = nil
    end
end
function Service:Fire()
    if not available() then return end
    if snapshot.PlayerState.AreaId ~= "CombatZone" and snapshot.PlayerState.CombatSeconds <= 0 then return end
    local gear = snapshot.Equipment
    local item = context.Config.Equipment.ById[gear.EquipmentId or ""]
    if not item or gear.Ammo <= 0 or gear.ReloadSeconds > 0 or os.clock() - lastFire < item.Cooldown then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local point = camera.ViewportSize / 2
    if not UserInputService.TouchEnabled then point = UserInputService:GetMouseLocation() - GuiService:GetGuiInset() end
    local ray = camera:ViewportPointToRay(point.X, point.Y)
    local character = Players.LocalPlayer.Character
    local head = if character then character:FindFirstChild("Head") else nil
    if not head or not head:IsA("BasePart") then return end
    -- Camera chooses aim intent; server independently chooses origin and performs raycast.
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character :: Model}
    local hit = Workspace:Raycast(ray.Origin, ray.Direction * item.EffectiveRange, params)
    local aimPoint = if hit then hit.Position else ray.Origin + ray.Direction * item.EffectiveRange
    local offset = aimPoint - head.Position
    if offset.Magnitude < 0.1 then return end
    local direction = offset.Unit
    lastFire = os.clock()
    context.Send("Shoot", {X = direction.X, Y = direction.Y, Z = direction.Z, Aim = aiming})
end
function Service:Update(data: any)
    snapshot = data
    if not available() then held = false; self:SetAim(false) end
    panel.Visible = UserInputService.TouchEnabled and available()
    crosshair.Visible = available()
end
function Service:Start()
    screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "ZoneCombatControls", ResetOnSpawn = false, DisplayOrder = 5})
    crosshair = Gui.Label(screen, "+", 36)
    crosshair.Size, crosshair.AnchorPoint, crosshair.TextXAlignment = UDim2.fromOffset(40, 40), Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center
    crosshair.TextColor3 = Color3.fromRGB(106, 240, 204)
    panel = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(174, 155), Position = UDim2.new(1, -12, 1, -105), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Visible = false})
    local scale = Gui.Create("UIScale", panel, {})
    local function button(text: string, x: number, y: number, callback: () -> ()): TextButton
        local value = Gui.Button(panel, text, callback)
        value.Size, value.Position = UDim2.fromOffset(80, 70), UDim2.fromOffset(x, y)
        return value
    end
    local fire = button("FIRE", 88, 80, function() end)
    fire.InputBegan:Connect(function(input: InputObject) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then firePointer = input; held = true; self:Fire() end end)
    fire.InputEnded:Connect(function(input: InputObject) if firePointer == input then firePointer = nil; held = false end end)
    button("AIM", 0, 80, function() self:SetAim(not aiming) end)
    button("RELOAD", 0, 0, function() context.Send("Reload", {}) end)
    button("SWITCH", 88, 0, function()
        if not snapshot or not snapshot.Ready then return end
        local slots = {"PRIMARY", "SECONDARY", "UTILITY"}
        local index = table.find(slots, snapshot.Equipment.Slot) or 1
        context.Send("SwitchEquipment", {Slot = slots[index % 3 + 1]})
    end)
    UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
        if processed or not available() or UserInputService:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then held = true; self:Fire()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then self:SetAim(true)
        elseif input.KeyCode == Enum.KeyCode.R then context.Send("Reload", {})
        elseif input.KeyCode == Enum.KeyCode.One then context.Send("SwitchEquipment", {Slot = "PRIMARY"})
        elseif input.KeyCode == Enum.KeyCode.Two then context.Send("SwitchEquipment", {Slot = "SECONDARY"})
        elseif input.KeyCode == Enum.KeyCode.Three then context.Send("SwitchEquipment", {Slot = "UTILITY"}) end
    end)
    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or firePointer == input then held = false; firePointer = nil end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then self:SetAim(false) end
    end)
    UserInputService.WindowFocusReleased:Connect(function() held = false; self:SetAim(false) end)
    local elapsed = 0
    local layoutWidth, layoutHeight, layoutPreference = 0, 0, 0
    RunService.RenderStepped:Connect(function(dt: number)
        if not available() then held = false; self:SetAim(false); panel.Visible = false; crosshair.Visible = false end
        if held then self:Fire() end
        elapsed += dt
        if elapsed < 1/30 then return end
        elapsed = 0
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local view = if screen.AbsoluteSize.X > 0 then screen.AbsoluteSize else camera.ViewportSize
        local preference = if snapshot and snapshot.Settings then snapshot.Settings.UIScale else 1
        if layoutWidth ~= view.X or layoutHeight ~= view.Y or layoutPreference ~= preference then
            layoutWidth, layoutHeight, layoutPreference = view.X, view.Y, preference
            local rect = Layout.Calculate(view.X, view.Y, preference, UserInputService.TouchEnabled).Panels.CombatControls
            scale.Scale = rect.W / 174
            panel.Position, panel.AnchorPoint = UDim2.fromOffset(rect.X, rect.Y), Vector2.zero
        end
        if aimCamera and aimCamera ~= camera then self:SetAim(false) end
        local point = if UserInputService.TouchEnabled then camera.ViewportSize / 2 else UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
        crosshair.Position = UDim2.fromOffset(point.X, point.Y)
        local root = if Players.LocalPlayer.Character then Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
        local motion = if root and root:IsA("BasePart") then math.min(root.AssemblyLinearVelocity.Magnitude / 3, 12) else 0
        crosshair.TextSize = 22 + motion + (if os.clock() - lastFire < 0.15 then 8 else 0) - (if aiming then 4 else 0)
    end)
end
return Service
