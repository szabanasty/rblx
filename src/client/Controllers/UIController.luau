--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UIController = {}
local context: any
local screen: ScreenGui
local snapshot: any = nil
local inputHandlers: any = nil
local scales: { UIScale } = {}
local refs: { [string]: any } = {}
local ownedKey = ""
local toastVersion = 0
local garageOpen = false
local started = false
local cameraConnection: RBXScriptConnection? = nil
local touchInputs: { [InputObject]: string } = {}
local colors = {
	Panel = Color3.fromRGB(19, 27, 39),
	Card = Color3.fromRGB(30, 41, 57),
	Text = Color3.fromRGB(239, 245, 250),
	Muted = Color3.fromRGB(167, 184, 202),
	Accent = Color3.fromRGB(67, 217, 170),
	Danger = Color3.fromRGB(255, 123, 122),
}

local function create(className: string, properties: { [string]: any }, parent: Instance): any
	local object: any = Instance.new(className)
	for key, value in properties do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function round(parent: GuiObject, radius: number)
	create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function addScale(parent: GuiObject)
	local scale = create("UIScale", { Scale = 1 }, parent)
	table.insert(scales, scale)
end

local function panel(name: string, size: UDim2, position: UDim2, anchor: Vector2): Frame
	local frame = create("Frame", {
		Name = name,
		Size = size,
		Position = position,
		AnchorPoint = anchor,
		BackgroundColor3 = colors.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, screen)
	round(frame, 12)
	addScale(frame)
	return frame
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2, fontSize: number): TextLabel
	return create("TextLabel", {
		Text = text,
		Size = size,
		Position = position,
		BackgroundTransparency = 1,
		TextColor3 = colors.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = fontSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local object = create("TextButton", {
		Text = text,
		Size = size,
		Position = position,
		BackgroundColor3 = colors.Card,
		BorderSizePixel = 0,
		TextColor3 = colors.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = true,
		Selectable = true,
	}, parent)
	round(object, 10)
	return object
end

local function setEnabled(object: TextButton, enabled: boolean)
	object.Active = enabled
	object.Selectable = enabled
	object.AutoButtonColor = enabled
	object.BackgroundTransparency = if enabled then 0 else 0.5
	object.TextTransparency = if enabled then 0 else 0.5
end

local function scooterName(id: string): string
	local data = context.Config.Scooters.ById[id]
	return if data then data.DisplayName else id
end

local function resize()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local narrow = viewport.X < 700
	local uiPreference = if snapshot and snapshot.Settings then snapshot.Settings.UIScale else 1
	if typeof(uiPreference) ~= "number" then
		uiPreference = 1
	end
	local scale = math.clamp(math.min(viewport.X / 1000, viewport.Y / 650), 0.85, 1.15)
	scale = math.clamp(scale * uiPreference, 0.85, 1.3)
	if narrow then
		-- Keep both pedal pairs and the two HUD cards apart in portrait mode.
		scale = math.min(scale, math.max(0.85, (viewport.X - 36) / 328))
	end
	for _, item in scales do
		item.Scale = scale
	end
	refs.Stats.Size = UDim2.fromOffset(if narrow then 216 else 300, 128)
	refs.Garage.Size = UDim2.fromOffset(if narrow then 340 else 430, math.min(450, math.max(280, (viewport.Y - 90) / scale)))
	refs.GarageScale.Scale = math.min(scale, math.max(0.7, (viewport.X - 28) / refs.Garage.Size.X.Offset))
	refs.Speed.Position = if UserInputService.TouchEnabled
		then UDim2.new(1, -14, 0, 72)
		else UDim2.new(1, -14, 1, -14)
	refs.Speed.AnchorPoint = if UserInputService.TouchEnabled then Vector2.new(1, 0) else Vector2.new(1, 1)
	refs.Hint.Visible = not UserInputService.TouchEnabled
end

local function releaseTouch()
	if inputHandlers then
		for _, key in touchInputs do
			inputHandlers.Set(key, false)
		end
	end
	table.clear(touchInputs)
end

local function toggleGarage(open: boolean)
	if open and context.Controllers.MenuController then context.Controllers.MenuController:Hide() end
	garageOpen = open
	context.Controllers.InputController:SetMenuOpen(open)
	refs.Garage.Visible = open
	refs.Touch.Visible = UserInputService.TouchEnabled and snapshot ~= nil and snapshot.Telemetry.Riding == true and not open
	if open then
		releaseTouch()
	end
end

local function touchButton(parent: Instance, name: string, text: string, position: UDim2): TextButton
	local object = button(parent, text, UDim2.fromOffset(78, 72), position)
	object.TextSize = 17
	object.InputBegan:Connect(function(input: InputObject)
		if not inputHandlers or not refs.Touch.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touchInputs[input] = name
			inputHandlers.Set(name, true)
			object.BackgroundColor3 = colors.Accent
		end
	end)
	object.InputEnded:Connect(function(input: InputObject)
		if touchInputs[input] then
			if inputHandlers then
				inputHandlers.Set(name, false)
			end
			touchInputs[input] = nil
		end
		object.BackgroundColor3 = colors.Card
	end)
	return object
end

local function refreshOwned()
	if not snapshot then
		return
	end
	local ids = snapshot.OwnedScooters
	local key = table.concat(ids, ":") .. "/" .. snapshot.SelectedScooter .. "/" .. tostring(snapshot.Ready)
	if ownedKey == key then
		return
	end
	ownedKey = key
	for _, child in refs.Owned:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for order, id in ids do
		local selected = id == snapshot.SelectedScooter
		local item = button(refs.Owned, (if selected then "✓ " else "") .. scooterName(id), UDim2.new(1, -8, 0, 58), UDim2.new())
		item.LayoutOrder = order
		item.TextXAlignment = Enum.TextXAlignment.Left
		create("UIPadding", { PaddingLeft = UDim.new(0, 12) }, item)
		item.BackgroundColor3 = if selected then Color3.fromRGB(27, 91, 80) else colors.Card
		setEnabled(item, snapshot.Ready == true)
		item.Activated:Connect(function()
			if snapshot and snapshot.Ready then
				context.Send("SelectScooter", { ScooterId = id })
			end
		end)
	end
end

function UIController:Init(ctx: any)
	context = ctx
end

function UIController:SetInputHandlers(handlers: any)
	inputHandlers = handlers
end

function UIController:OpenGarage(open: boolean)
	if started then toggleGarage(open) end
end

function UIController:Start()
	if started then
		return
	end
	started = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	screen = create("ScreenGui", {
		Name = "KukirinHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	refs.Stats = panel("PlayerStats", UDim2.fromOffset(300, 128), UDim2.fromOffset(14, 14), Vector2.zero)
	refs.RoadInfo = label(screen, "", UDim2.fromOffset(250, 28), UDim2.fromOffset(14, 150), 13)
	refs.Money = label(refs.Stats, "Money: —", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 7), 23)
	refs.Money.TextTruncate = Enum.TextTruncate.AtEnd
	refs.Level = label(refs.Stats, "Level: —", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 37), 17)
	local progress = create("Frame", {
		Size = UDim2.new(1, -24, 0, 8), Position = UDim2.fromOffset(12, 67),
		BackgroundColor3 = colors.Card, BorderSizePixel = 0,
	}, refs.Stats)
	round(progress, 4)
	refs.XPFill = create("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = colors.Accent, BorderSizePixel = 0,
	}, progress)
	round(refs.XPFill, 4)
	refs.XP = label(refs.Stats, "XP: —", UDim2.new(1, -24, 0, 21), UDim2.fromOffset(12, 77), 13)
	refs.Status = label(refs.Stats, "Ładowanie danych…", UDim2.new(1, -24, 0, 21), UDim2.fromOffset(12, 101), 11)
	refs.Status.TextColor3 = colors.Muted
	refs.Status.TextTruncate = Enum.TextTruncate.AtEnd

	local openGarage = button(screen, "GARAŻ", UDim2.fromOffset(98, 48), UDim2.new(1, -14, 0, 14))
	openGarage.AnchorPoint = Vector2.new(1, 0)
	addScale(openGarage)
	openGarage.Activated:Connect(function()
		toggleGarage(not garageOpen)
	end)

	refs.Speed = panel("Speedometer", UDim2.fromOffset(105, 62), UDim2.new(1, -14, 1, -14), Vector2.new(1, 1))
	refs.SpeedValue = label(refs.Speed, "0", UDim2.fromScale(1, 0.65), UDim2.new(), 28)
	refs.SpeedValue.TextXAlignment = Enum.TextXAlignment.Center
	local speedUnit = label(refs.Speed, "km/h", UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.65), 13)
	speedUnit.TextXAlignment = Enum.TextXAlignment.Center
	speedUnit.TextColor3 = colors.Muted
	refs.Hint = label(screen, "W / S: gaz / hamulec   A / D: skręt   Spacja: skok   E: zejdź   Pad: R2 / L2 / A / B", UDim2.new(1, -150, 0, 26), UDim2.new(0, 14, 1, -40), 12)
	refs.Hint.TextColor3 = colors.Muted
	refs.Hint.TextWrapped = true

	refs.Garage = panel("Garage", UDim2.fromOffset(430, 450), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	refs.Garage.ZIndex = 5
	refs.Garage.Visible = false
	refs.GarageScale = refs.Garage:FindFirstChildOfClass("UIScale")
	label(refs.Garage, "Twój garaż", UDim2.new(1, -85, 0, 40), UDim2.fromOffset(16, 10), 23)
	local close = button(refs.Garage, "×", UDim2.fromOffset(48, 44), UDim2.new(1, -62, 0, 10))
	close.Activated:Connect(function()
		toggleGarage(false)
	end)
	local detail = label(refs.Garage, "Wybierz posiadaną hulajnogę.", UDim2.new(1, -32, 0, 24), UDim2.fromOffset(16, 58), 13)
	detail.TextColor3 = colors.Muted
	refs.Owned = create("ScrollingFrame", {
		Name = "OwnedScooters", Size = UDim2.new(1, -32, 1, -240), Position = UDim2.fromOffset(16, 94),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, refs.Garage)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, refs.Owned)
	refs.Selected = label(refs.Garage, "Wybrano: —", UDim2.new(1, -32, 0, 25), UDim2.new(0, 16, 1, -125), 13)
	refs.Selected.TextTruncate = Enum.TextTruncate.AtEnd
	refs.Spawn = button(refs.Garage, "PRZYWOŁAJ", UDim2.new(0.5, -24, 0, 72), UDim2.new(0, 16, 1, -88))
	refs.Despawn = button(refs.Garage, "SCHOWAJ", UDim2.new(0.5, -24, 0, 72), UDim2.new(0.5, 8, 1, -88))
	setEnabled(refs.Spawn, false)
	setEnabled(refs.Despawn, false)
	refs.Spawn.Activated:Connect(function()
		if snapshot and snapshot.Ready and not snapshot.Telemetry.Riding then
			context.Send("SpawnScooter", {})
			toggleGarage(false)
		end
	end)
	refs.Despawn.Activated:Connect(function()
		if snapshot and snapshot.Ready then
			context.Send("DespawnScooter", {})
		end
	end)

	refs.Touch = create("Frame", {
		Name = "TouchControls", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
	}, screen)
	local steer = create("Frame", {
		Size = UDim2.fromOffset(164, 72), Position = UDim2.new(0, 14, 1, -18), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1,
	}, refs.Touch)
	addScale(steer)
	touchButton(steer, "Left", "◀", UDim2.new())
	touchButton(steer, "Right", "▶", UDim2.fromOffset(86, 0))
	local pedals = create("Frame", {
		Size = UDim2.fromOffset(164, 72), Position = UDim2.new(1, -14, 1, -18), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1,
	}, refs.Touch)
	addScale(pedals)
	touchButton(pedals, "Brake", "HAMULEC", UDim2.new())
	touchButton(pedals, "Throttle", "GAZ", UDim2.fromOffset(86, 0))
	local jump = touchButton(refs.Touch, "Jump", "SKOK", UDim2.new(1, -14, 1, -102))
	jump.AnchorPoint = Vector2.new(1, 1)
	addScale(jump)
	local dismount = button(refs.Touch, "ZEJDŹ", UDim2.fromOffset(78, 72), UDim2.new(0, 14, 1, -102))
	dismount.AnchorPoint = Vector2.new(0, 1)
	addScale(dismount)
	dismount.Activated:Connect(function()
		if snapshot and snapshot.Ready and snapshot.Telemetry.Riding then
			context.Send("DismountScooter", {})
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		local key = touchInputs[input]
		if key and inputHandlers then
			inputHandlers.Set(key, false)
			touchInputs[input] = nil
		end
	end)
	UserInputService.WindowFocusReleased:Connect(releaseTouch)

	refs.Toast = panel("Notification", UDim2.fromOffset(300, 60), UDim2.new(0.5, 0, 0, 155), Vector2.new(0.5, 0))
	refs.Toast.Visible = false
	refs.Toast.ZIndex = 10
	refs.ToastLabel = label(refs.Toast, "", UDim2.new(1, -24, 1, -12), UDim2.fromOffset(12, 6), 14)
	refs.ToastLabel.TextWrapped = true
	refs.ToastLabel.TextXAlignment = Enum.TextXAlignment.Center

	local function watchCamera()
		if cameraConnection then
			cameraConnection:Disconnect()
		end
		local camera = Workspace.CurrentCamera
		if camera then
			cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
		end
		resize()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()
end

function UIController:Update(nextSnapshot: any)
	if not started then
		return
	end
	local oldScale = if snapshot and snapshot.Settings then snapshot.Settings.UIScale else 1
	snapshot = nextSnapshot
	-- Loading and save-error snapshots may contain only status information.
	if typeof(snapshot.Telemetry) ~= "table" then
		snapshot.Telemetry = { Riding = false, Speed = 0 }
	end
	snapshot.OwnedScooters = snapshot.OwnedScooters or {}
	snapshot.SelectedScooter = snapshot.SelectedScooter or ""
	refs.Money.Text = if typeof(snapshot.Money) == "number" then string.format("Money: %d", snapshot.Money) else "Money: —"
	refs.Level.Text = if typeof(snapshot.Level) == "number" then string.format("Level: %d", snapshot.Level) else "Level: —"
	local xp = if typeof(snapshot.XP) == "number" then snapshot.XP else 0
	local required = if typeof(snapshot.XPToNextLevel) == "number" then snapshot.XPToNextLevel else 1
	refs.XP.Text = if snapshot.Ready then string.format("XP: %d / %d", xp, required) else "XP: —"
	refs.XPFill.Size = UDim2.fromScale(math.clamp(xp / math.max(1, required), 0, 1), 1)
	local mode = if snapshot.SaveMode == "StudioMemory" then "Studio: bez zapisu" else "DataStore"
	refs.Status.Text = mode .. " • " .. tostring(snapshot.Status or "Ładowanie…")
	refs.SpeedValue.Text = tostring(math.floor(math.max(0, snapshot.Telemetry.Speed or 0) + 0.5))
	refs.RoadInfo.Text = (snapshot.District or "") .. (if (snapshot.SpeedLimit or 0) > 0 then " • limit " .. tostring(snapshot.SpeedLimit) .. " km/h" else "")
	refs.Selected.Text = "Wybrano: " .. scooterName(snapshot.SelectedScooter)
	local ready = snapshot.Ready == true
	setEnabled(refs.Spawn, ready and not snapshot.Telemetry.Riding)
	setEnabled(refs.Despawn, ready and typeof(snapshot.Telemetry.ScooterId) == "string" and snapshot.Telemetry.ScooterId ~= "")
	refs.Touch.Visible = ready and UserInputService.TouchEnabled and snapshot.Telemetry.Riding == true and not garageOpen
	refreshOwned()
	if snapshot.Settings and snapshot.Settings.UIScale ~= oldScale then
		resize()
	end
end

function UIController:Notify(success: boolean, message: string)
	if not started then
		return
	end
	toastVersion += 1
	local version = toastVersion
	refs.Toast.Visible = true
	refs.ToastLabel.Text = message
	refs.ToastLabel.TextColor3 = if success then colors.Accent else colors.Danger
	task.delay(4, function()
		if version == toastVersion then
			refs.Toast.Visible = false
		end
	end)
end

return UIController
