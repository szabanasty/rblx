--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Gui = require(script.Parent.Parent.Modules.GuiFactory)
local Service = {}
local context: any
local settings: any = {SFXVolume = 0.7, MusicVolume = 0.5, ReducedEffects = false, GraphicsQuality = 2}
local hitmarker: TextLabel
local music: Sound? = nil
local hitVersion = 0
function Service:Init(ctx: any) context = ctx end
function Service:Update(snapshot: any)
    if snapshot.Settings then settings = snapshot.Settings end
    if music then music.Volume = settings.MusicVolume * 0.35 end
end
function Service:Sound(id: string)
    local asset = context.Config.Cosmetics.Audio[id]
    if type(asset) ~= "string" or asset == "" then return end
    local sound = Instance.new("Sound")
    sound.SoundId, sound.Volume, sound.Parent = asset, settings.SFXVolume * 0.4, SoundService
    sound:Play(); Debris:AddItem(sound, 5)
end
function Service:Feedback(value: any)
    if value.Effect == "Hit" then
        hitVersion += 1
        local version = hitVersion
        hitmarker.Visible = true; self:Sound("Hit")
        task.delay(0.2, function() if hitVersion == version then hitmarker.Visible = false end end)
    elseif value.Effect == "Shot" and value.From and value.To and not settings.ReducedEffects and settings.GraphicsQuality > 1 then
        local from, to = Vector3.new(value.From.X, value.From.Y, value.From.Z), Vector3.new(value.To.X, value.To.Y, value.To.Z)
        local camera = Workspace.CurrentCamera
        local length = (to - from).Magnitude
        if not camera or length <= 0.1 or (camera.CFrame.Position - from).Magnitude > 250 then return end
        local part = Instance.new("Part")
        part.Name, part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = "ArcadeTrace", true, false, false, false
        part.Material, part.Color = Enum.Material.Neon, Color3.fromRGB(116, 223, 235)
        part.Size, part.CFrame, part.Parent = Vector3.new(0.06, 0.06, length), CFrame.lookAt((from + to) / 2, to), Workspace
        Debris:AddItem(part, 0.08)
        if value.Owner == Players.LocalPlayer.UserId then self:Sound("Fire") end
    end
end
function Service:Start()
    local screen = Gui.Create("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {Name = "ZoneEffects", ResetOnSpawn = false, DisplayOrder = 30})
    hitmarker = Gui.Label(screen, "×", 35)
    hitmarker.Size, hitmarker.Position, hitmarker.AnchorPoint = UDim2.fromOffset(40, 40), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
    hitmarker.TextSize, hitmarker.TextXAlignment, hitmarker.Visible = 30, Enum.TextXAlignment.Center, false
    local asset = context.Config.Cosmetics.Audio.Music
    if asset ~= "" then
        local sound = Instance.new("Sound")
        music = sound
        sound.SoundId, sound.Looped, sound.Parent = asset, true, SoundService
        sound:Play()
    end
end
return Service
