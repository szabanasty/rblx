--!strict
local Service = {}
local context: any
function Service:Init(ctx: any) context = ctx end
function Service:Start()
    context.Remotes.Snapshot.OnClientEvent:Connect(function(snapshot: any)
        if type(snapshot) ~= "table" or type(snapshot.Ready) ~= "boolean" then return end
        context.Controllers.InputController:Update(snapshot)
        context.Controllers.UIController:Update(snapshot)
        context.Controllers.CombatController:Update(snapshot)
        context.Controllers.ReviveController:Update(snapshot)
        context.Controllers.SquadMarkerController:Update(snapshot)
        context.Controllers.EffectsController:Update(snapshot)
    end)
    context.Remotes.Feedback.OnClientEvent:Connect(function(feedback: any)
        if type(feedback) ~= "table" then return end
        if feedback.OpenMenu then context.Controllers.UIController:Open(feedback.OpenMenu) end
        context.Controllers.EffectsController:Feedback(feedback)
        if type(feedback.Message) == "string" and feedback.Message ~= "" and feedback.Message ~= "Fired" and feedback.Message ~= "FireCooldown" then
            context.Controllers.UIController:Notify(feedback.Success == true, context.Config.Messages[feedback.Message] or feedback.Message)
        end
    end)
end
return Service
