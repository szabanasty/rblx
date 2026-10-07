--!strict
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Builder = require(script.Parent.Parent.Modules.WorldBuilder)
local TrafficService = {}
local context: any
type Car = {Model: Model, Position: Vector3, Nodes: {Vector3}, Index: number}
local cars: {Car} = {}
function TrafficService:Init(ctx: any) context = ctx end
function TrafficService:Start()
    local map = Workspace:WaitForChild("Map")
    local generated = map:WaitForChild("Generated")
    local folder = Instance.new("Folder")
    folder.Name = "Traffic"
    folder.Parent = generated
    local count = math.clamp(context.Config.World.TrafficCount, 0, 8)
    for index = 1, count do
        local sx, sz = if index % 2 == 0 then 1 else -1, if index % 3 == 0 then 1 else -1
        local span = context.Config.World.GridSpacing * (if index > 4 then 2 else 1)
        local nodes = {Vector3.new(sx * 8, 2, sz * 8), Vector3.new(sx * (span - 8), 2, sz * 8),
            Vector3.new(sx * (span - 8), 2, sz * (span - 8)), Vector3.new(sx * 8, 2, sz * (span - 8))}
        local start = nodes[1]:Lerp(nodes[2], (index % 3) * 0.25)
        local model = Builder.Vehicle(folder, "NPC_" .. index, CFrame.lookAt(start, nodes[2]), Color3.fromRGB(90 + index * 12, 108, 136))
        table.insert(cars, {Model = model, Position = start, Nodes = nodes, Index = 2})
    end
    local accumulator = 0
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        accumulator += dt
        if accumulator < 1 / context.Config.World.TrafficUpdateHz then return end
        local elapsed = math.min(accumulator, 0.5)
        accumulator = 0
        context.Services.World:UpdateSignals()
        for _, car in cars do
            local target = car.Nodes[car.Index]
            local delta = target - car.Position
            local remaining = delta.Magnitude
            if remaining < 0.5 then
                car.Index = car.Index % #car.Nodes + 1
                continue
            end
            local phase = if math.abs(delta.X) > math.abs(delta.Z) then 1 else 0
            local travel = math.min(remaining, context.Config.World.TrafficSpeedStuds * elapsed)
            if phase ~= context.Services.World:GetSignalPhase() then travel = math.min(travel, math.max(0, remaining - 15)) end
            if travel > 0 then
                car.Position += delta.Unit * travel
                car.Model:PivotTo(CFrame.lookAt(car.Position, car.Position + delta.Unit))
            end
        end
    end)
end
return TrafficService
