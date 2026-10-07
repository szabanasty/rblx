--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Minimap = {}
local context: any
local map: Frame
local playerDot: Frame
local questDot: Frame
local target: any = nil
function Minimap:Init(ctx: any) context = ctx end
function Minimap:Update(snapshot: any) target = if snapshot.Quest then snapshot.Quest.Target else nil end
local function point(x: number, z: number): UDim2
    return UDim2.fromScale(math.clamp(0.5 + x / context.Config.World.Width, 0, 1), math.clamp(0.5 + z / context.Config.World.Width, 0, 1))
end
function Minimap:Start()
    local screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "KukirinMinimap", ResetOnSpawn = false, DisplayOrder = 9})
    map = Gui.Create("Frame", screen, {Size = UDim2.fromOffset(140, 140), Position = UDim2.new(1, -14, 0, 220),
        AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(29, 39, 45), BorderSizePixel = 0, ClipsDescendants = true})
    for index = -2, 2 do
        local coordinate = index * context.Config.World.GridSpacing
        local at = 0.5 + coordinate / context.Config.World.Width
        Gui.Create("Frame", map, {Size = UDim2.new(0.018, 0, 1, 0), Position = UDim2.fromScale(at, 0), BackgroundColor3 = Color3.fromRGB(95, 105, 113), BorderSizePixel = 0})
        Gui.Create("Frame", map, {Size = UDim2.new(1, 0, 0.018, 0), Position = UDim2.fromScale(0, at), BackgroundColor3 = Color3.fromRGB(95, 105, 113), BorderSizePixel = 0})
    end
    local dotProperties = {Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(72, 222, 174), BorderSizePixel = 0}
    questDot = Gui.Create("Frame", map, dotProperties)
    questDot.Visible = false
    playerDot = Gui.Create("Frame", map, dotProperties)
    playerDot.BackgroundColor3 = Color3.new(1, 1, 1)
    local function resize()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local size = if viewport.X < 700 or viewport.Y < 500 then 110 else 140
        map.Size = UDim2.fromOffset(size, size)
        if viewport.Y < 500 and viewport.X >= 700 then
            map.AnchorPoint, map.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 14)
        else map.AnchorPoint, map.Position = Vector2.new(1, 0), UDim2.new(1, -14, 0, 220) end
    end
    local cameraConnection: RBXScriptConnection? = nil
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera = Workspace.CurrentCamera
        if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    watchCamera()
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt: number)
        elapsed += dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local character = Players.LocalPlayer.Character
        local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
        if root and root:IsA("BasePart") then playerDot.Position = point(root.Position.X, root.Position.Z) end
        questDot.Visible = target ~= nil
        if target then questDot.Position = point(target.X, target.Z) end
    end)
end
return Minimap
