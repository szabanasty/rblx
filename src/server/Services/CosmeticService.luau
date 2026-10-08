--!strict
local Service = {}
local context: any
function Service:Init(ctx: any) context = ctx end
function Service:Start() end
function Service:Buy(player: Player, category: string, option: string): (boolean, string)
    if not context.Services.State:IsAllowed(player, "Trade") or not context.Services.World:IsNear(player, "CosmeticsShop") then return false, "VisitShop" end
    local config = context.Config.Cosmetics
    local profile = context.Services.PlayerData:GetProfile(player)
    if not profile then return false, "DataNotReady" end
    if category ~= "Tag" and category ~= "Clothing" and (not profile.OwnedScooters[profile.SelectedScooter] or not context.Config.Scooters.ById[profile.SelectedScooter]) then return false, "ScooterNotOwned" end
    local price: number? = nil
    if category == "Clothing" then local style = config.Styles[option]; price = if style then style.Price else nil
    elseif category == "Tag" then local tag = config.Tags[option]; price = if tag then tag.Price else nil
    elseif config.Categories[category] and config.Colors[option] then price = config.Categories[category] end
    if price == nil then return false, "InvalidCosmetic" end
    local id = category .. ":" .. option
    local premium = (category == "Clothing" and config.Styles[option].RobuxOnly)
        or (category == "Tag" and config.Tags[option].RobuxOnly)
        or (config.Categories[category] and config.RobuxColors[option])
    if premium and not profile.Cosmetics[id] then return false, "RobuxPurchaseRequired" end
    if not profile.Cosmetics[id] then
        if price > 0 then local ok, message = context.Services.Economy:Spend(player, price); if not ok then return false, message end end
        profile.Cosmetics[id] = true
    end
    if category == "Clothing" then profile.EquippedClothing = option
    elseif category == "Tag" then profile.EquippedTag = option
    else
        local scooter = profile.SelectedScooter
        if not profile.OwnedScooters[scooter] then return false, "ScooterNotOwned" end
        profile.ScooterCustomization[scooter] = profile.ScooterCustomization[scooter] or {}
        profile.ScooterCustomization[scooter][category] = option
        context.Services.Scooter:RefreshAppearance(player)
    end
    context.Services.PlayerData:MarkDirty(player); context.Notify(player)
    return true, "CosmeticEquipped"
end
function Service:Apply(player: Player, model: Model, id: string)
    local profile = context.Services.PlayerData:GetProfile(player)
    local appearance = if profile then profile.ScooterCustomization[id] else nil
    if type(appearance) ~= "table" then return end
    local parts: {[string]: string} = {Color = "Stem", Grips = "Handlebar", Deck = "Chassis", Lights = "FrontLightPlaceholder", Wheels = "FrontWheel", Decals = "Grip", Effects = "RearWheel"}
    for category, partName in parts do
        local option = appearance[category]
        local rgb = if type(option) == "string" and profile.Cosmetics[category .. ":" .. option] then context.Config.Cosmetics.Colors[option] else nil
        local part = model:FindFirstChild(partName)
        if rgb and part and part:IsA("BasePart") then
            part.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            if category == "Lights" or category == "Effects" then part.Material = Enum.Material.Neon end
            if category == "Wheels" then
                local rear = model:FindFirstChild("RearWheel")
                if rear and rear:IsA("BasePart") then rear.Color = part.Color end
            end
        end
    end
end
return Service
