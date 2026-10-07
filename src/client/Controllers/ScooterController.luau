--!strict

local ScooterController = {}
local context: any
local started = false

function ScooterController:Init(ctx: any)
	context = ctx
end

function ScooterController:Start()
	if started then
		return
	end
	started = true
	context.Remotes.Snapshot.OnClientEvent:Connect(function(snapshot: any)
		if typeof(snapshot) ~= "table" or typeof(snapshot.Ready) ~= "boolean" then
			return
		end
		context.Controllers.InputController:Update(snapshot)
		context.Controllers.UIController:Update(snapshot)
		context.Controllers.MenuController:Update(snapshot)
		context.Controllers.MinimapController:Update(snapshot)
		context.Controllers.SettingsController:Update(snapshot)
	end)
	context.Remotes.Feedback.OnClientEvent:Connect(function(feedback: any)
		if typeof(feedback) == "table" and typeof(feedback.Message) == "string" and feedback.Message ~= "" then
			context.Controllers.UIController:Notify(feedback.Success == true, context.Config.Messages[feedback.Message] or feedback.Message)
		end
	end)
end

return ScooterController
