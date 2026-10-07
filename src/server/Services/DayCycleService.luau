--!strict
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local DayCycleService = {}
local context: any
function DayCycleService:Init(ctx: any) context = ctx end
function DayCycleService:Start()
    local start = os.clock()
    local elapsed = 2
    RunService.Heartbeat:Connect(function(dt: number)
        if context.IsClosing then return end
        elapsed += dt
        if elapsed < 2 then return end
        elapsed = 0
        Lighting.ClockTime = (9 + (os.clock() - start) / context.Config.World.DayLengthSeconds * 24) % 24
        local night = Lighting.ClockTime < 6 or Lighting.ClockTime >= 18
        for _, light in context.Services.World:GetLights() do light.Enabled = night end
    end)
end
return DayCycleService
