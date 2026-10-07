--!strict
local Gui = {}
function Gui.Create(class: string, parent: Instance, properties: {[string]: any}): any
    local instance = Instance.new(class)
    for name, value in properties do (instance :: any)[name] = value end
    instance.Parent = parent
    return instance
end
function Gui.Label(parent: Instance, text: string, height: number): TextLabel
    return Gui.Create("TextLabel", parent, {
        Size = UDim2.new(1, -12, 0, height), BackgroundTransparency = 1, LayoutOrder = #parent:GetChildren(),
        Text = text, TextColor3 = Color3.fromRGB(236, 241, 246),
        Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end
function Gui.Button(parent: Instance, text: string, callback: () -> ()): TextButton
    local button = Gui.Create("TextButton", parent, {
        Size = UDim2.new(1, -12, 0, 68), BackgroundColor3 = Color3.fromRGB(41, 65, 80), LayoutOrder = #parent:GetChildren(),
        Text = text, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
        TextSize = 14, TextWrapped = true, AutoButtonColor = true, BorderSizePixel = 0,
    })
    Gui.Create("UICorner", button, {CornerRadius = UDim.new(0, 10)})
    button.Activated:Connect(callback)
    return button
end
return Gui
