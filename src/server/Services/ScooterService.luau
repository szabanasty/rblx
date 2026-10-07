--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Factory = require(script.Parent.Parent.Modules.ScooterFactory)

type Input = { Throttle: number, Steer: number, Brake: boolean, Jump: boolean }
type Stats = {
	Id: string, DisplayName: string, TopSpeed: number, Acceleration: number,
	Handling: number, Braking: number, Jump: number, UnlockLevel: number,
	Stability: number,
}
type State = {
	Assembly: Factory.Assembly,
	Stats: Stats,
	Input: Input,
	LastInputAt: number,
	JumpUntil: number,
	LastJumpAt: number,
	Yaw: number,
	LastPosition: Vector3,
	LastSafeCFrame: CFrame,
	LastVerticalSpeed: number,
	Suspicion: number,
	LastLogAt: number,
	NextOwnershipCheck: number,
	Connections: { RBXScriptConnection },
}

local ScooterService = {}
local context: any = nil
local states: { [Player]: State } = {}
local distances: { [Player]: number } = {}
local spawnTimes: { [Player]: number } = {}
local despawnTimes: { [Player]: number } = {}
local playerConnections: { [Player]: { RBXScriptConnection } } = {}
local connections: { RBXScriptConnection } = {}
local vehicles: Folder? = nil
local accumulator = 0

local function idle(): Input
	return { Throttle = 0, Steer = 0, Brake = false, Jump = false }
end

local function finite(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function alive(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return humanoid, root
end

local function notify(player: Player)
	if context.Notify then
		context.Notify(player)
	end
end

local function riding(player: Player, state: State): boolean
	local humanoid = alive(player)
	return humanoid ~= nil and state.Assembly.Seat.Occupant == humanoid
end

local function serverOwnership(state: State)
	local root = state.Assembly.Root
	if root.Parent and not root.Anchored then
		local canSet = root:CanSetNetworkOwnership()
		if canSet then
			root:SetNetworkOwner(nil)
		end
	end
end

local function releaseCharacterOwnership(player: Player, scooterRoot: Part)
	-- Removing the SeatWeld splits the rider from the vehicle. Return only the
	-- player's own separated character to Roblox's standard character ownership.
	local function restoreCharacter()
		local humanoid, characterRoot = alive(player)
		if humanoid and not humanoid.SeatPart and characterRoot
			and characterRoot.AssemblyRootPart ~= scooterRoot.AssemblyRootPart then
			local canSet = characterRoot:CanSetNetworkOwnership()
			if canSet then
				characterRoot:SetNetworkOwnershipAuto()
			end
		end
	end
	task.defer(restoreCharacter)
	task.delay(0.1, restoreCharacter)
end

local function remove(player: Player, announce: boolean)
	local state = states[player]
	if not state then
		return
	end
	states[player] = nil
	for _, connection in state.Connections do
		connection:Disconnect()
	end
	local occupant = state.Assembly.Seat.Occupant
	if occupant then
		occupant.Sit = false
	end
	releaseCharacterOwnership(player, state.Assembly.Root)
	state.Assembly.Model:Destroy()
	if announce then
		notify(player)
	end
end

local function mount(player: Player, state: State): boolean
	if states[player] ~= state or not context.Services.PlayerData:IsReady(player) then
		return false
	end
	local humanoid, characterRoot = alive(player)
	if not humanoid or not characterRoot or humanoid.SeatPart then
		return false
	end
	if (characterRoot.Position - state.Assembly.Root.Position).Magnitude > 14 then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model, state.Assembly.Model }
	local direction = state.Assembly.Seat.Position - characterRoot.Position
	if Workspace:Raycast(characterRoot.Position, direction, params) then
		return false
	end
	state.Assembly.Seat:Sit(humanoid)
	serverOwnership(state)
	return true
end

local function spawnPosition(player: Player, characterRoot: BasePart): CFrame?
	local forward = Vector3.new(characterRoot.CFrame.LookVector.X, 0, characterRoot.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	end
	forward = forward.Unit
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Model, vehicles :: Folder }
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { player.Character :: Model }
	local offset = context.Config.Game.SpawnOffsetStuds
	for _, direction in { forward, right, -right, -forward } do
		local target = characterRoot.Position + direction * offset
		local ground = Workspace:Raycast(target + Vector3.new(0, 12, 0), Vector3.new(0, -48, 0), params)
		if ground and ground.Normal.Y > 0.65 then
			local position = ground.Position + Vector3.new(0, 1.1, 0)
			local pivot = CFrame.lookAt(position, position + forward)
			local box = CFrame.new(ground.Position + Vector3.new(0, 3.1, 0))
			local clear = true
			for _, obstacle in Workspace:GetPartBoundsInBox(box, Vector3.new(4, 5.8, 6), overlap) do
				if obstacle.CanCollide then
					clear = false
					break
				end
			end
			if clear then
				return pivot
			end
		end
	end
	return nil
end

local function restore(player: Player, state: State, reason: string)
	state.Suspicion += 1
	state.Assembly.Model:PivotTo(state.LastSafeCFrame)
	state.Assembly.Root.AssemblyLinearVelocity = Vector3.zero
	state.Assembly.Root.AssemblyAngularVelocity = Vector3.zero
	state.Input = idle()
	state.LastVerticalSpeed = 0
	state.LastPosition = state.Assembly.Root.Position
	serverOwnership(state)
	local now = os.clock()
	if now - state.LastLogAt > 5 then
		state.LastLogAt = now
		warn(string.format("[ScooterGuard] user=%d reason=%s flags=%d", player.UserId, reason, state.Suspicion))
	end
	-- A single anomalous collision never bans a player. Invalid motion earns no distance.
end

local function grounded(player: Player, state: State): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded: { Instance } = { state.Assembly.Model }
	if player.Character then
		table.insert(excluded, player.Character)
	end
	params.FilterDescendantsInstances = excluded
	local hit = Workspace:Raycast(state.Assembly.Root.Position, Vector3.new(0, -1.65, 0), params)
	return hit ~= nil and hit.Normal.Y > 0.55
end

local function step(player: Player, state: State, dt: number, now: number)
	local root = state.Assembly.Root
	if not root.Parent then
		remove(player, true)
		return
	end
	local gameConfig = context.Config.Game
	if now >= state.NextOwnershipCheck then
		state.NextOwnershipCheck = now + 1
		serverOwnership(state)
	end
	local studsPerMeter = gameConfig.StudsPerMeter
	local maxSpeed = state.Stats.TopSpeed / 3.6 * studsPerMeter
	local position = root.Position
	local delta = position - state.LastPosition
	local planarDelta = Vector3.new(delta.X, 0, delta.Z)
	local velocity = root.AssemblyLinearVelocity
	local planarVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local permittedSpeed = maxSpeed * 1.35 + 10
	local verticalAllowance = (math.max(math.abs(state.LastVerticalSpeed), state.Stats.Jump * studsPerMeter, 45)
		+ Workspace.Gravity * dt + 20) * dt + gameConfig.MaxPositionErrorStuds
	if not finite(position.X) or not finite(position.Y) or not finite(position.Z)
		or not finite(velocity.X) or not finite(velocity.Y) or not finite(velocity.Z)
		or planarDelta.Magnitude > permittedSpeed * dt + gameConfig.MaxPositionErrorStuds
		or math.abs(delta.Y) > verticalAllowance
		or planarVelocity.Magnitude > maxSpeed * 1.8 + 25 then
		restore(player, state, "invalid-motion")
		return
	end
	if position.Y < -100 then
		remove(player, true)
		return
	end
	local isRiding = riding(player, state)
	if isRiding and planarDelta.Magnitude <= permittedSpeed * dt + 0.5 then
		distances[player] = (distances[player] or 0) + planarDelta.Magnitude / studsPerMeter
	end
	state.LastPosition = position
	state.LastSafeCFrame = root.CFrame
	state.LastVerticalSpeed = velocity.Y
	local input = state.Input
	if not isRiding or now - state.LastInputAt > gameConfig.InputTimeout then
		input = idle()
		input.Brake = true
	end
	local onGround = grounded(player, state)
	local forward = CFrame.Angles(0, state.Yaw, 0).LookVector
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local forwardSpeed = planarVelocity:Dot(forward)
	local steerFactor = math.clamp(math.abs(forwardSpeed) / (maxSpeed * 0.5), 0.15, 1)
	if isRiding then
		local reverse = if forwardSpeed < -1 then -1 else 1
		state.Yaw -= input.Steer * math.rad(state.Stats.Handling) * steerFactor * reverse * dt
	end
	state.Assembly.Orientation.CFrame = CFrame.Angles(0, state.Yaw, 0)
	local acceleration = 0
	local accelStuds = state.Stats.Acceleration * studsPerMeter
	local brakeStuds = state.Stats.Braking * studsPerMeter
	if input.Brake or input.Throttle == 0 then
		local deceleration = if input.Brake then brakeStuds else accelStuds * 0.3
		acceleration = math.clamp(-forwardSpeed / math.max(dt, 0.01), -deceleration, deceleration)
	else
		local target = if input.Throttle >= 0 then maxSpeed * input.Throttle else maxSpeed * 0.3 * input.Throttle
		acceleration = math.clamp((target - forwardSpeed) * 2.5, -brakeStuds, accelStuds)
	end
	local stability = math.clamp(state.Stats.Stability, 0.5, 3)
	local sideAcceleration = math.clamp(-planarVelocity:Dot(right) * 7 * stability, -Workspace.Gravity * 0.8, Workspace.Gravity * 0.8)
	local drive = (forward * acceleration + right * sideAcceleration) * root.AssemblyMass
	state.Assembly.DriveForce.Force = if onGround then drive else drive * 0.08
	if isRiding and onGround and state.JumpUntil >= now and now - state.LastJumpAt >= gameConfig.ScooterJumpCooldown then
		state.JumpUntil = 0
		state.LastJumpAt = now
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, state.Stats.Jump * studsPerMeter, velocity.Z)
	end
	-- Force control normally respects the catalog speed. This handles steep downhill spikes.
	if planarVelocity.Magnitude > maxSpeed then
		local capped = planarVelocity.Unit * maxSpeed
		root.AssemblyLinearVelocity = Vector3.new(capped.X, root.AssemblyLinearVelocity.Y, capped.Z)
	end
end

function ScooterService:Init(ctx: any)
	context = ctx
	local existing = Workspace:FindFirstChild("Vehicles")
	assert(not existing or existing:IsA("Folder"), "Workspace.Vehicles must be a Folder")
	if existing and existing:IsA("Folder") then
		vehicles = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "Vehicles"
		folder.Parent = Workspace
		vehicles = folder
	end
end

function ScooterService:Select(player: Player, id: string): (boolean, string)
	if not context.Services.PlayerData:IsReady(player) then
		return false, "DataNotReady"
	end
	local profile = context.Services.PlayerData:GetProfile(player)
	local stats = context.Config.Scooters.ById[id]
	if not profile or not stats or profile.OwnedScooters[id] ~= true then
		return false, "ScooterNotOwned"
	end
	if profile.Level < stats.UnlockLevel then
		return false, "LevelTooLow"
	end
	profile.SelectedScooter = id
	context.Services.PlayerData:MarkDirty(player)
	notify(player)
	return true, "ScooterSelected"
end

function ScooterService:Spawn(player: Player, id: string?): (boolean, string)
	if not context.Services.PlayerData:IsReady(player) then
		return false, "DataNotReady"
	end
	local now = os.clock()
	if spawnTimes[player] and now - spawnTimes[player] < context.Config.Game.SpawnCooldown then
		return false, "SpawnCooldown"
	end
	local profile = context.Services.PlayerData:GetProfile(player)
	if not profile then
		return false, "DataNotReady"
	end
	local selected = id or profile.SelectedScooter
	local base = context.Config.Scooters.ById[selected]
	if not base or profile.OwnedScooters[selected] ~= true then
		return false, "ScooterNotOwned"
	end
	local stats: Stats = context.Stats.Get(base, profile.ScooterUpgrades[selected], context.Config.Upgrades)
	if profile.Level < stats.UnlockLevel then
		return false, "LevelTooLow"
	end
	local humanoid, characterRoot = alive(player)
	if not humanoid or not characterRoot then
		return false, "CharacterNotReady"
	end
	local count = 0
	for other in states do
		if other ~= player then
			count += 1
		end
	end
	if count >= context.Config.Game.MaxScootersPerServer then
		return false, "ServerScooterLimit"
	end
	local pivot = spawnPosition(player, characterRoot)
	if not pivot then
		return false, "NoSafeSpawnLocation"
	end
	remove(player, false)
	local assembly = Factory.Create(selected, stats.DisplayName, player.UserId, pivot)
	assembly.Orientation.Responsiveness = math.clamp(25 * stats.Stability, 15, 60)
	assembly.Model.Parent = vehicles
	assembly.Root.Anchored = false
	local _, yaw = pivot:ToOrientation()
	local state: State = {
		Assembly = assembly, Stats = stats, Input = idle(), LastInputAt = now,
		JumpUntil = 0, LastJumpAt = -context.Config.Game.ScooterJumpCooldown,
		Yaw = yaw, LastPosition = pivot.Position, LastSafeCFrame = pivot,
		LastVerticalSpeed = 0, Suspicion = 0, LastLogAt = -math.huge,
		NextOwnershipCheck = now + 1, Connections = {},
	}
	states[player] = state
	spawnTimes[player] = now
	profile.SelectedScooter = selected
	context.Services.PlayerData:MarkDirty(player)
	serverOwnership(state)
	table.insert(state.Connections, assembly.Prompt.Triggered:Connect(function(triggeringPlayer: Player)
		if triggeringPlayer == player then
			mount(player, state)
		end
	end))
	table.insert(state.Connections, assembly.Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = assembly.Seat.Occupant
		local ownerHumanoid = alive(player)
		if occupant and occupant ~= ownerHumanoid then
			occupant.Sit = false
			local riderCharacter = occupant.Parent
			if riderCharacter and riderCharacter:IsA("Model") then
				local unauthorizedPlayer = Players:GetPlayerFromCharacter(riderCharacter)
				if unauthorizedPlayer then
					releaseCharacterOwnership(unauthorizedPlayer, assembly.Root)
				end
			end
			serverOwnership(state)
			return
		end
		state.Input = idle()
		state.LastInputAt = os.clock()
		assembly.Prompt.Enabled = occupant == nil
		serverOwnership(state)
		if not occupant then
			releaseCharacterOwnership(player, assembly.Root)
		end
		notify(player)
	end))
	table.insert(state.Connections, humanoid.Died:Connect(function()
		remove(player, true)
	end))
	-- Mounting on the next scheduler turn allows Studio to assemble the welds first.
	task.defer(function()
		mount(player, state)
	end)
	notify(player)
	return true, "ScooterSpawned"
end

function ScooterService:Despawn(player: Player): (boolean, string)
	local now = os.clock()
	if despawnTimes[player] and now - despawnTimes[player] < context.Config.Game.DespawnCooldown then
		return false, "DespawnCooldown"
	end
	despawnTimes[player] = now
	remove(player, true)
	return true, "ScooterDespawned"
end

function ScooterService:Dismount(player: Player): (boolean, string)
	local state = states[player]
	if not state or not riding(player, state) then
		return false, "NotRiding"
	end
	local humanoid = state.Assembly.Seat.Occupant
	if not humanoid then
		return false, "NotRiding"
	end
	state.Input = idle()
	state.JumpUntil = 0
	humanoid.Sit = false
	releaseCharacterOwnership(player, state.Assembly.Root)
	serverOwnership(state)
	notify(player)
	return true, "ScooterDismounted"
end

function ScooterService:SetInput(player: Player, input: Input): (boolean, string)
	local state = states[player]
	if not state or not riding(player, state) then
		return false, "NotRiding"
	end
	if typeof(input) ~= "table" or not finite(input.Throttle) or not finite(input.Steer)
		or math.abs(input.Throttle) > 1 or math.abs(input.Steer) > 1
		or typeof(input.Brake) ~= "boolean" or typeof(input.Jump) ~= "boolean" then
		return false, "InvalidInput"
	end
	local now = os.clock()
	if input.Jump and not state.Input.Jump then
		state.JumpUntil = now + 0.25
	end
	state.Input = { Throttle = input.Throttle, Steer = input.Steer, Brake = input.Brake, Jump = input.Jump }
	state.LastInputAt = now
	return true, "InputAccepted"
end

function ScooterService:RefreshStats(player: Player)
	local state = states[player]
	local profile = context.Services.PlayerData:GetProfile(player)
	if state and profile then
		local id = state.Stats.Id
		state.Stats = context.Stats.Get(context.Config.Scooters.ById[id], profile.ScooterUpgrades[id], context.Config.Upgrades)
		state.Assembly.Orientation.Responsiveness = math.clamp(25 * state.Stats.Stability, 15, 60)
	end
end

function ScooterService:GetPosition(player: Player): Vector3?
	local state = states[player]
	if state and riding(player, state) then return state.LastSafeCFrame.Position end
	local _, root = alive(player)
	return if root then root.Position else nil
end

function ScooterService:GetTelemetry(player: Player): { [string]: any }
	local state = states[player]
	if not state then
		return { Speed = 0, Distance = distances[player] or 0, Riding = false, Suspicion = 0 }
	end
	local velocity = state.Assembly.Root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude / context.Config.Game.StudsPerMeter * 3.6
	return {
		Speed = speed, Distance = distances[player] or 0, ScooterId = state.Stats.Id,
		Riding = riding(player, state), Suspicion = state.Suspicion,
	}
end

local function observePlayer(player: Player)
	if playerConnections[player] then
		return
	end
	playerConnections[player] = { player.CharacterRemoving:Connect(function()
		remove(player, true)
	end) }
end

function ScooterService:Start()
	for _, player in Players:GetPlayers() do
		observePlayer(player)
	end
	table.insert(connections, Players.PlayerAdded:Connect(observePlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		remove(player, false)
		local playerSignals: {RBXScriptConnection} = playerConnections[player] or {}
		for _, connection in playerSignals do
			connection:Disconnect()
		end
		playerConnections[player] = nil
		distances[player] = nil
		spawnTimes[player] = nil
		despawnTimes[player] = nil
	end))
	table.insert(connections, RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < 1 / context.Config.Game.SimulationHz then
			return
		end
		local elapsed = accumulator
		accumulator = 0
		local now = os.clock()
		for player, state in states do
			step(player, state, elapsed, now)
		end
	end))
end

function ScooterService:Shutdown()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for player in states do
		remove(player, false)
	end
	for _, scoped in playerConnections do
		for _, connection in scoped do
			connection:Disconnect()
		end
	end
	table.clear(playerConnections)
	table.clear(distances)
	table.clear(spawnTimes)
	table.clear(despawnTimes)
	accumulator = 0
end

return ScooterService
