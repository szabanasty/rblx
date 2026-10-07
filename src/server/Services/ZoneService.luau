--!strict
local Service = {}
local context: any
function Service:Init(ctx: any) context = ctx end
function Service:Start() end
function Service:GetArea(player: Player): string
    local position = context.Services.Movement:GetPosition(player)
    return if position then context.ZoneRules.At(position, context.Config.Zones) else "Unknown"
end
function Service:AllowsDamage(player: Player): boolean
    return context.Services.State:IsAllowed(player, "Target")
end
return Service
