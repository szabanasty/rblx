--!strict
local Service = {}
local context: any
function Service:Init(ctx: any) context = ctx end
function Service:Start() end
local function eligible(player: Player, slot: number): (any?, string)
    if not context.Services.State:IsAllowed(player, "Trade") or not context.Services.World:IsNear(player, "Garage") then return nil, "VisitShop" end
    if context.Services.Scooter:GetTelemetry(player).Riding then return nil, "DismountFirst" end
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return nil, "DataNotReady" end
    local slots = context.CommerceRules.GarageSlots(profile, context.Config.Monetization)
    if not context.Validation.IsInteger(slot, 1, slots) then return nil, "GarageSlotLocked" end
    return profile, ""
end
function Service:SavePreset(player: Player, slot: number): (boolean, string)
    local profile, message = eligible(player, slot)
    if not profile then return false, message end
    local id = profile.SelectedScooter
    if not profile.OwnedScooters[id] or not context.Config.Scooters.ById[id] then return false, "ScooterNotOwned" end
    profile.GaragePresets[tostring(slot)] = {ScooterId = id, Customization = context.Schema.deepCopy(profile.ScooterCustomization[id] or {})}
    context.Services.PlayerData:MarkDirty(player); context.Notify(player)
    return true, "GaragePresetSaved"
end
function Service:LoadPreset(player: Player, slot: number): (boolean, string)
    local profile, message = eligible(player, slot)
    if not profile then return false, message end
    local preset = profile.GaragePresets[tostring(slot)]
    if not preset then return false, "GaragePresetEmpty" end
    local ok, reason = context.Services.Scooter:Select(player, preset.ScooterId)
    if not ok then return false, reason end
    local styles: {[string]: string} = {}
    for category, option in preset.Customization do
        if type(option) == "string" and context.Config.Cosmetics.Categories[category] and context.Config.Cosmetics.Colors[option]
            and profile.Cosmetics[category .. ":" .. option] then styles[category] = option end
    end
    profile.ScooterCustomization[preset.ScooterId] = styles
    context.Services.Scooter:RefreshAppearance(player)
    context.Services.PlayerData:MarkDirty(player); context.Notify(player)
    return true, "GaragePresetLoaded"
end
function Service:GetSnapshot(player: Player): any
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return nil end
    return {Slots = context.CommerceRules.GarageSlots(profile, context.Config.Monetization), Presets = context.Schema.deepCopy(profile.GaragePresets)}
end
return Service
