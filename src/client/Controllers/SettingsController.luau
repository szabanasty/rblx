--!strict
local CollectionService = game:GetService("CollectionService")
local Settings = {}
local current: any = {GraphicsQuality = 2, ReducedEffects = false}
function Settings:Init(_ctx: any) end
local function apply(instance: Instance)
    if instance:IsA("BasePart") then instance.LocalTransparencyModifier = if current.GraphicsQuality == 1 then 1 else 0 end
end
function Settings:Update(snapshot: any)
    if not snapshot.Settings then return end
    local changed = current.GraphicsQuality ~= snapshot.Settings.GraphicsQuality or current.ReducedEffects ~= snapshot.Settings.ReducedEffects
    current = snapshot.Settings
    if changed then for _, instance in CollectionService:GetTagged("WorldDecoration") do apply(instance) end end
end
function Settings:Start()
    CollectionService:GetInstanceAddedSignal("WorldDecoration"):Connect(apply)
    for _, instance in CollectionService:GetTagged("WorldDecoration") do apply(instance) end
end
return Settings
