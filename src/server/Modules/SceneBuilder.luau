--!strict
-- Original architecture built from primitives; repeated façades use strips rather than hundreds of windows.
local Builder = require(script.Parent.WorldBuilder)
local Scene = {}
export type Scene = {
    Root: Folder, Lights: {PointLight},
    Model: (self: Scene, name: string) -> Model,
    Part: (self: Scene, parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?) -> Part,
    Beam: (self: Scene, parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3) -> Part,
    Sign: (self: Scene, parent: Instance, text: string, cf: CFrame, size: Vector3, accent: Color3) -> Part,
    Tree: (self: Scene, position: Vector3, variant: number) -> (),
    Lamp: (self: Scene, position: Vector3) -> (),
}
local Methods = {}
Methods.__index = Methods
function Scene.new(root: Folder, lights: {PointLight}): Scene
    return setmetatable({Root = root, Lights = lights}, Methods) :: any
end
function Methods:Model(name: string): Model
    local model = Instance.new("Model")
    model.Name, model.ModelStreamingMode, model.Parent = name, Enum.ModelStreamingMode.Atomic, self.Root
    return model
end
function Methods:Part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?): Part
    local part = Builder.Part(parent, name, size, cf, color, solid == true)
    part.CanQuery = solid == true
    part.Material = material or Enum.Material.SmoothPlastic
    part.CastShadow = solid == true
    return part
end
function Methods:Beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3): Part
    local distance = (b - a).Magnitude
    return self:Part(parent, name, Vector3.new(thickness, thickness, distance), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Metal, false)
end
function Methods:Sign(parent: Instance, text: string, cf: CFrame, size: Vector3, accent: Color3): Part
    local panel: Part = self:Part(parent, "Sign", size, cf, Color3.fromRGB(22, 30, 38), Enum.Material.Metal, false)
    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.Parent = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 24, panel
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency, label.TextColor3, label.Text, label.Font = UDim2.fromScale(1, 1), 1, accent, text, Enum.Font.GothamBold
    label.TextScaled, label.TextWrapped, label.Parent = true, true, gui
    return panel
end
function Methods:Tree(position: Vector3, variant: number)
    local model = self:Model("Willow_" .. variant)
    self:Part(model, "Trunk", Vector3.new(1.7, 11, 1.7), CFrame.new(position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(106, 78, 56), Enum.Material.Wood, false)
    local crown = self:Part(model, "Crown", Vector3.new(13, 15 + variant % 3, 13), CFrame.new(position + Vector3.new(0, 14, 0)), Color3.fromRGB(64, 105 + variant % 3 * 9, 77), Enum.Material.Grass, false)
    crown.Shape = Enum.PartType.Ball
    self:Part(model, "Planter", Vector3.new(8, 0.45, 8), CFrame.new(position + Vector3.new(0, 0.23, 0)), Color3.fromRGB(65, 73, 65), Enum.Material.Slate, false)
end
function Methods:Lamp(position: Vector3)
    local model = self:Model("StreetLamp")
    self:Part(model, "Post", Vector3.new(0.5, 17, 0.5), CFrame.new(position + Vector3.new(0, 8.5, 0)), Color3.fromRGB(40, 51, 61), Enum.Material.Metal, false)
    local bulb = self:Part(model, "Lamp", Vector3.new(3.5, 0.25, 1.3), CFrame.new(position + Vector3.new(0, 17, 0)), Color3.fromRGB(255, 225, 163), Enum.Material.Neon, false)
    local light = Instance.new("PointLight")
    light.Range, light.Brightness, light.Shadows, light.Color, light.Parent = 30, 1.4, false, Color3.fromRGB(255, 225, 187), bulb
    table.insert(self.Lights, light)
end
return Scene
