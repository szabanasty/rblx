--!strict

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local InputController = {}

local context: any
local riding = false
local focused = true
local started = false
local elapsed = 0
local pendingJump = false
local menuOpen = false
local keys: { [Enum.KeyCode]: boolean } = {}
local touch: { [string]: boolean } = {}
local gamepadSteer = 0
local gamepadThrottle = 0
local gamepadBrake = false
local triggerThrottle = 0
local triggerBrake = false
local defaultControls: any = nil
local controlsWereEnabled = true
local controlledHumanoid: Humanoid? = nil
local jumpWasEnabled = true

local function applyRidingControls()
	if controlledHumanoid then
		if controlledHumanoid.Parent then
			controlledHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpWasEnabled)
		end
		controlledHumanoid = nil
	end
	if riding then
		local character = Players.LocalPlayer.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then
			controlledHumanoid = humanoid
			jumpWasEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			humanoid.Jump = false
		end
	end
	if defaultControls then
		if riding then
			defaultControls:Disable()
		elseif controlsWereEnabled then
			defaultControls:Enable()
		end
	end
end

local function sendNeutral()
	context.Remotes.Input:FireServer({ Throttle = 0, Steer = 0, Brake = true, Jump = false })
end

local function resetInput()
	table.clear(keys)
	table.clear(touch)
	gamepadSteer = 0
	gamepadThrottle = 0
	gamepadBrake = false
	triggerThrottle = 0
	triggerBrake = false
	pendingJump = false
end

local function down(key: Enum.KeyCode): boolean
	return keys[key] == true
end

local function gamepadAction(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Cancel or state == Enum.UserInputState.End then
		if action == "ScooterKeyboard" then
			keys[input.KeyCode] = nil
		elseif action == "ScooterSteer" then
			gamepadSteer = 0
			gamepadThrottle = 0
			gamepadBrake = false
		elseif action == "ScooterThrottle" then
			triggerThrottle = 0
		elseif action == "ScooterBrake" then
			triggerBrake = false
		end
	elseif focused and riding and not menuOpen and UserInputService:GetFocusedTextBox() == nil then
		if action == "ScooterKeyboard" then
			if state == Enum.UserInputState.Begin then
				keys[input.KeyCode] = true
				if input.KeyCode == Enum.KeyCode.Space then
					pendingJump = true
				elseif input.KeyCode == Enum.KeyCode.E then
					context.Send("DismountScooter", {})
				end
			end
		elseif action == "ScooterDismount" and state == Enum.UserInputState.Begin then
			context.Send("DismountScooter", {})
		elseif action == "ScooterSteer" then
			local position = input.Position
			gamepadSteer = if math.abs(position.X) > 0.12 then position.X else 0
			gamepadThrottle = if -position.Y > 0.12 then -position.Y else 0
			gamepadBrake = position.Y > 0.25
		elseif action == "ScooterThrottle" then
			triggerThrottle = math.clamp(input.Position.Z, 0, 1)
		elseif action == "ScooterBrake" then
			triggerBrake = input.Position.Z > 0.15
		elseif action == "ScooterJump" and state == Enum.UserInputState.Begin then
			pendingJump = true
		end
	end
	return if riding and not menuOpen and UserInputService:GetFocusedTextBox() == nil then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end

function InputController:Init(ctx: any)
	context = ctx
end

function InputController:SetMenuOpen(open: boolean)
	menuOpen = open
	if open then
		resetInput()
		if riding then sendNeutral() end
	end
end

function InputController:SetTouchInput(key: string, value: boolean)
	if not focused or not riding or menuOpen then
		return
	end
	if key == "Jump" then
		if value then
			pendingJump = true
		end
	elseif key == "Throttle" or key == "Brake" or key == "Left" or key == "Right" then
		touch[key] = value
	end
end

function InputController:Update(snapshot: any)
	local nextRiding = snapshot.Ready == true and typeof(snapshot.Telemetry) == "table" and snapshot.Telemetry.Riding == true
	if riding and not nextRiding then
		sendNeutral()
	end
	if nextRiding ~= riding then
		resetInput()
		elapsed = 0
		riding = nextRiding
		applyRidingControls()
	end
	riding = nextRiding
end

function InputController:Start()
	if started then
		return
	end
	started = true
	context.Controllers.UIController:SetInputHandlers({
		Set = function(key: string, value: boolean)
			InputController:SetTouchInput(key, value)
		end,
	})

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not focused or not riding or menuOpen or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keys[input.KeyCode] = true
			if input.KeyCode == Enum.KeyCode.Space then
				pendingJump = true
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keys[input.KeyCode] = nil
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		focused = false
		resetInput()
		if riding then
			sendNeutral()
		end
	end)
	UserInputService.WindowFocused:Connect(function()
		focused = true
	end)

	local priority = Enum.ContextActionPriority.High.Value + 1
	ContextActionService:BindActionAtPriority("ScooterSteer", gamepadAction, false, priority, Enum.KeyCode.Thumbstick1)
	ContextActionService:BindActionAtPriority("ScooterThrottle", gamepadAction, false, priority, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority("ScooterBrake", gamepadAction, false, priority, Enum.KeyCode.ButtonL2)
	ContextActionService:BindActionAtPriority("ScooterJump", gamepadAction, false, priority, Enum.KeyCode.ButtonA)
	ContextActionService:BindActionAtPriority("ScooterDismount", gamepadAction, false, priority, Enum.KeyCode.ButtonB)
	ContextActionService:BindActionAtPriority("ScooterKeyboard", gamepadAction, false, priority,
		Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D,
		Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
		Enum.KeyCode.Space, Enum.KeyCode.E)
	Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
		task.spawn(function()
			character:WaitForChild("Humanoid", 5)
			if Players.LocalPlayer.Character == character then
				applyRidingControls()
			end
		end)
	end)
	-- Roblox supplies PlayerModule; custom experiences may omit it. Jump safety
	-- and high-priority bindings also work without this optional native UI hook.
	task.spawn(function()
		local module = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
		if module and module:IsA("ModuleScript") then
			local success, result = pcall(require, module)
			if success then
				defaultControls = result:GetControls()
				controlsWereEnabled = defaultControls.controlsEnabled ~= false
				applyRidingControls()
			end
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		if not riding then
			return
		end
		elapsed += deltaTime
		if elapsed < 0.1 then
			return
		end
		elapsed %= 0.1
		local throttle = math.max(gamepadThrottle, triggerThrottle)
		local steer = gamepadSteer
		local brake = gamepadBrake or triggerBrake or touch.Brake == true or down(Enum.KeyCode.S) or down(Enum.KeyCode.Down)
		if touch.Throttle or down(Enum.KeyCode.W) or down(Enum.KeyCode.Up) then
			throttle = 1
		end
		local left = touch.Left == true or down(Enum.KeyCode.A) or down(Enum.KeyCode.Left)
		local right = touch.Right == true or down(Enum.KeyCode.D) or down(Enum.KeyCode.Right)
		if left or right then
			steer = (if right then 1 else 0) - (if left then 1 else 0)
		end
		if not focused or menuOpen or UserInputService:GetFocusedTextBox() ~= nil then
			throttle, steer, brake = 0, 0, true
			pendingJump = false
		end
		context.Remotes.Input:FireServer({
			Throttle = if brake then 0 else math.clamp(throttle, -1, 1),
			Steer = math.clamp(steer, -1, 1),
			Brake = brake,
			Jump = pendingJump,
		})
		pendingJump = false
	end)
end

return InputController
