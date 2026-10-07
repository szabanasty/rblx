--!strict
local RoadService = {}
local context: any
function RoadService:Init(ctx: any) context = ctx end
function RoadService:Start() end
function RoadService:GetRoadAt(position: Vector3): any
    return context.Layout.GetRoadAt(context.Services.World:GetRoads(), position.X, position.Z)
end
function RoadService:GetDistrictAt(position: Vector3): string
    return context.Layout.GetDistrictAt(context.Config.World.Districts, position.X, position.Z)
end
return RoadService
