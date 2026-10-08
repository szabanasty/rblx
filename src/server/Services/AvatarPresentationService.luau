--!strict
-- Original primitive placeholders. No uploaded models, audio or animations assumed.
local Players = game:GetService("Players")
local Service = {}
local context: any
local connections: {[Player]: {RBXScriptConnection}} = {}
local function attached(parent: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3): Part
    local part = Instance.new("Part")
    part.Name, part.Size, part.CFrame, part.Color = name, size, root.CFrame * offset, color
    part.Massless, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = parent
    local weld = Instance.new("WeldConstraint")
    weld.Part0, weld.Part1, weld.Parent = root, part, part
    return part
end
function Service:Init(ctx: any) context = ctx end
function Service:Refresh(player: Player)
    local profile = context.Services.PlayerData:GetProfile(player)
    local character = player.Character
    if not profile or not character then return end
    local item = context.Services.Equipment:GetItem(player)
    local id = if item then item.EquipmentId else ""
    local previous = character:FindFirstChild("ArcadeEquipment")
    if previous and previous:GetAttribute("EquipmentId") ~= id then previous:Destroy(); previous = nil end
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not previous and item and hand and hand:IsA("BasePart") then
        local model = Instance.new("Model")
        model.Name, model.Parent = "ArcadeEquipment", character
        model:SetAttribute("EquipmentId", id)
        local core = attached(model, hand, "EnergyCore", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, -0.3, -0.35), Color3.fromRGB(101, 218, 223))
        core.Shape, core.Material = Enum.PartType.Ball, Enum.Material.Neon
        attached(model, hand, "Grip", Vector3.new(0.2, 0.45, 0.2), CFrame.new(0, 0, -0.2), Color3.fromRGB(44, 51, 70))
    end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local style = profile.EquippedClothing
    local clothing = character:FindFirstChild("PlaceholderClothing")
    if clothing and clothing:GetAttribute("Style") ~= style then clothing:Destroy(); clothing = nil end
    local config = if style and profile.Cosmetics["Clothing:" .. style] then context.Config.Cosmetics.Styles[style] else nil
    if config and not clothing and torso and torso:IsA("BasePart") then
        local model = Instance.new("Model")
        model.Name, model.Parent = "PlaceholderClothing", character
        model:SetAttribute("Style", style)
        attached(model, torso, "StreetVest", torso.Size + Vector3.new(0.08, 0.05, 0.08), CFrame.new(), Color3.fromRGB(config.Color[1], config.Color[2], config.Color[3]))
    end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local billboard = head:FindFirstChild("ZoneTitle")
        if not billboard then
            local gui = Instance.new("BillboardGui")
            gui.Name, gui.Size, gui.StudsOffset, gui.MaxDistance, gui.Parent = "ZoneTitle", UDim2.fromOffset(180, 45), Vector3.new(0, 2.5, 0), 80, head
            local label = Instance.new("TextLabel")
            label.Size, label.BackgroundTransparency, label.TextColor3, label.TextSize, label.Font, label.Parent = UDim2.fromScale(1, 1), 1, Color3.fromRGB(214, 238, 225), 12, Enum.Font.GothamBold, gui
            billboard = gui
        end
        local label = if billboard then billboard:FindFirstChildOfClass("TextLabel") else nil
        local tag = if profile.EquippedTag and profile.Cosmetics["Tag:" .. profile.EquippedTag] then context.Config.Cosmetics.Tags[profile.EquippedTag] else nil
        local state = context.Services.State:GetRecord(player)
        local highValue = state and state.Streak >= 10
        if label then label.Text = (if tag then tag.DisplayName else "") .. (if highValue then "\nHIGH VALUE TARGET" else "") end
    end
end
function Service:Start()
    local function add(player: Player)
        if connections[player] then return end
        connections[player] = {
            player.CharacterAdded:Connect(function(character: Model)
                task.spawn(function()
                    character:WaitForChild("HumanoidRootPart", 10)
                    if player.Character == character and player.Parent == Players and not context.IsClosing then self:Refresh(player) end
                end)
            end),
            player.CharacterAppearanceLoaded:Connect(function(character: Model)
                if player.Character == character and player.Parent == Players and not context.IsClosing then self:Refresh(player) end
            end),
        }
    end
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(function(player: Player)
        if connections[player] then for _, connection in connections[player] do connection:Disconnect() end end
        connections[player] = nil
    end)
    for _, player in Players:GetPlayers() do add(player); self:Refresh(player) end
end
return Service
