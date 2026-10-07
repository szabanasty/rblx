--!strict
-- Server-only profile ownership. A failed production load never becomes a new profile.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type SessionState = {
	Player: Player,
	Token: string,
	Profile: any?,
	Status: string,
	Revision: number,
	SavedRevision: number,
	LeaseExpiresAt: number,
	Saving: boolean,
	Cancelled: boolean,
	Releasing: boolean,
	Memory: boolean,
}

local PlayerDataService = {}
local context: any = nil
local store: any = nil
local states: { [Player]: SessionState } = {}
local instanceId = HttpService:GenerateGUID(false)
local started = false
local shuttingDown = false
local shutdownDeadline: number? = nil
local memoryMode = false
local leaseSeconds = 180
local autoSaveSeconds = 60
local loadAttempts = 5
local saveAttempts = 3
local activeLoads = 0
local schemaVersion = 1

local function stillPresent(player: Player): boolean
	return player.Parent == Players
end

local function notify(player: Player)
	if context and stillPresent(player) then
		local ok = pcall(context.Notify, player)
		if not ok then
			warn(string.format("[Data] Snapshot notification failed for %d", player.UserId))
		end
	end
end

local function markSessionLost(state: SessionState, reason: string)
	if tostring(state.Status) == "SessionLost" then
		return
	end
	state.Status = "SessionLost"
	state.Cancelled = true
	warn(string.format("[Data] Session stopped for %d: %s", state.Player.UserId, reason))
	notify(state.Player)
	if stillPresent(state.Player) then
		state.Player:Kick("Your data session could not be renewed. Please rejoin to protect your progress.")
	end
end

local function usable(state: SessionState?): boolean
	if not state or not state.Profile or state.Cancelled or state.Releasing then
		return false
	end
	if not state.Memory and os.time() >= state.LeaseExpiresAt then
		markSessionLost(state, "session lease expired")
		return false
	end
	return state.Status == "Ready" or state.Status == "StudioMemory" or state.Status == "SaveFailed"
end

local function withinDeadline(): boolean
	return shutdownDeadline == nil or os.clock() < shutdownDeadline
end

local function retryDelay(attempt: number)
	local delaySeconds = math.min(2 ^ (attempt - 1), 4)
	if shutdownDeadline then
		delaySeconds = math.min(delaySeconds, math.max(0, shutdownDeadline - os.clock()))
	end
	task.wait(delaySeconds)
end

local function validSession(session: any): boolean
	return type(session) == "table"
		and type(session.Token) == "string"
		and #session.Token > 0
		and type(session.ExpiresAt) == "number"
		and session.ExpiresAt == session.ExpiresAt
		and session.ExpiresAt > 0
		and session.ExpiresAt < math.huge
end

local function releaseUnconfirmedAcquisition(state: SessionState)
	-- A timed-out acquisition may have committed. Release only this exact token;
	-- never write a default profile or touch another server's ownership.
	for attempt = 1, saveAttempts do
		if not withinDeadline() then
			return
		end
		local ok = pcall(function()
			store:UpdateAsync("Player_" .. state.Player.UserId, function(record: any): any
				if type(record) ~= "table" or not validSession(record.Session)
					or record.Session.Token ~= state.Token then
					return nil
				end
				local copy = context.Schema.deepCopy(record)
				copy.Session = nil
				return copy
			end)
		end)
		if ok then
			return
		end
		if attempt < saveAttempts then
			retryDelay(attempt)
		end
	end
	warn(string.format("[Data] Could not release an unconfirmed acquisition for %d; its lease will expire.", state.Player.UserId))
end

local function load(state: SessionState)
	if state.Memory then
		state.Profile = context.Schema.new(state.Player.UserId, context.Config.Game)
		state.Status = "StudioMemory"
		if not state.Cancelled and stillPresent(state.Player) then
			notify(state.Player)
		else
			states[state.Player] = nil
		end
		return
	end

	local failure: string = "LoadFailed"
	for attempt = 1, loadAttempts do
		if state.Cancelled or shuttingDown then
			releaseUnconfirmedAcquisition(state)
			states[state.Player] = nil
			return
		end
		local callbackFailure: string? = nil
		local ok, result = pcall(function()
			return store:UpdateAsync("Player_" .. state.Player.UserId, function(record: any): any
				callbackFailure = nil
				if state.Cancelled or shuttingDown then
					callbackFailure = "Cancelled"
					return nil
				end
				local data: any
				if record == nil then
					data = context.Schema.new(state.Player.UserId, context.Config.Game)
				else
					if type(record) ~= "table" or type(record.SchemaVersion) ~= "number" then
						callbackFailure = "InvalidRecord"
						return nil
					end
					if record.SchemaVersion ~= schemaVersion then
						callbackFailure = if record.SchemaVersion > schemaVersion then "FutureSchema" else "UnsupportedSchema"
						return nil
					end
					if type(record.Data) ~= "table" then
						callbackFailure = "InvalidRecord"
						return nil
					end
					if record.Session ~= nil then
						if not validSession(record.Session) then
							callbackFailure = "InvalidSession"
							return nil
						end
						if record.Session.Token ~= state.Token and record.Session.ExpiresAt > os.time() then
							callbackFailure = "SessionLocked"
							return nil
						end
					end
					data = context.Schema.sanitize(record.Data, context.Config.Game)
					if type(data) ~= "table" or data.UserId ~= state.Player.UserId then
						callbackFailure = "InvalidProfile"
						return nil
					end
				end
				return {
					SchemaVersion = schemaVersion,
					Data = data,
					Session = { Token = state.Token, ExpiresAt = os.time() + leaseSeconds },
				}
			end)
		end)

		if ok and type(result) == "table" and validSession(result.Session) and result.Session.Token == state.Token then
			state.Profile = context.Schema.sanitize(result.Data, context.Config.Game)
			if type(state.Profile) ~= "table" or state.Profile.UserId ~= state.Player.UserId then
				failure = "InvalidProfile"
				releaseUnconfirmedAcquisition(state)
				break
			end
			state.LeaseExpiresAt = result.Session.ExpiresAt
			state.Status = "Ready"
			if state.Cancelled or not stillPresent(state.Player) or shuttingDown then
				PlayerDataService:Save(state.Player, true)
				states[state.Player] = nil
			else
				notify(state.Player)
			end
			return
		end

		failure = if ok then callbackFailure or "EmptyResult" else "DataStoreUnavailable"
		warn(string.format("[Data] Load attempt %d failed for %d (%s)", attempt, state.Player.UserId, failure))
		if failure ~= "SessionLocked" and failure ~= "DataStoreUnavailable" then
			break
		end
		if attempt < loadAttempts then
			retryDelay(attempt)
		end
	end
	if state.Cancelled or shuttingDown then
		releaseUnconfirmedAcquisition(state)
		states[state.Player] = nil
		return
	end
	if failure == "DataStoreUnavailable" then
		releaseUnconfirmedAcquisition(state)
	end
	state.Status = "LoadFailed"
	if stillPresent(state.Player) then
		local message = if failure == "SessionLocked"
			then "Your profile is still active on another server. Wait a moment and rejoin."
			else "Your data could not be loaded safely. Please try again later."
		state.Player:Kick(message)
	else
		states[state.Player] = nil
	end
end

function PlayerDataService:Init(ctx: any)
	context = ctx
	local config = ctx.Config.Game
	leaseSeconds = config.SessionLeaseSeconds or 180
	autoSaveSeconds = config.AutoSaveSeconds or 60
	loadAttempts = config.LoadRetries or 5
	saveAttempts = config.SaveRetries or 3
	schemaVersion = config.DataSchemaVersion or 1
	assert(leaseSeconds >= 90 and autoSaveSeconds >= 15 and autoSaveSeconds < leaseSeconds / 2,
		"Invalid DataStore lease / autosave configuration")
	memoryMode = RunService:IsStudio() and config.UseStudioDataStore ~= true
	if memoryMode then
		warn("[Data] STUDIO MEMORY MODE: progress resets when this test stops. UseStudioDataStore=false protects live player data.")
	else
		store = DataStoreService:GetDataStore(config.DataStoreName or "KukirinCity_PlayerData_v1")
	end
end

function PlayerDataService:GetProfile(player: Player): any?
	local state = states[player]
	return if usable(state) then (state :: SessionState).Profile else nil
end

function PlayerDataService:IsReady(player: Player): boolean
	return usable(states[player])
end

function PlayerDataService:GetStatus(player: Player): string
	local state = states[player]
	return if state then state.Status else "Loading"
end

function PlayerDataService:MarkDirty(player: Player)
	local state = states[player]
	if usable(state) then
		(state :: SessionState).Revision += 1
	end
end

function PlayerDataService:Save(player: Player, release: boolean?): (boolean, string?)
	local state = states[player]
	if not state or not state.Profile then
		return false, "NotLoaded"
	end
	if tostring(state.Status) == "SessionLost" then
		return false, "SessionLost"
	end
	if tostring(state.Status) == "Closed" then
		return true, nil
	end
	if release then
		state.Releasing = true
	end
	-- Release waits for any autosave; ordinary autosaves do not queue duplicate writes.
	while state.Saving do
		if not release then
			return false, "SaveInProgress"
		end
		if not withinDeadline() then
			return false, "ShutdownDeadline"
		end
		task.wait(0.1)
	end
	if tostring(state.Status) == "Closed" then
		return true, nil
	end
	if tostring(state.Status) == "SessionLost" then
		return false, "SessionLost"
	end
	if not withinDeadline() then
		return false, "ShutdownDeadline"
	end
	if state.Memory then
		state.SavedRevision = state.Revision
		state.Status = if release then "Closed" else "StudioMemory"
		return true, nil
	end
	if os.time() >= state.LeaseExpiresAt then
		markSessionLost(state, "lease expired before save")
		return false, "SessionLost"
	end
	state.Saving = true
	local revision = state.Revision
	local copyOk, snapshot = pcall(context.Schema.deepCopy, state.Profile)
	if not copyOk then
		state.Saving = false
		state.Status = "SaveFailed"
		warn(string.format("[Data] Invalid profile snapshot for %d", player.UserId))
		return false, "InvalidSnapshot"
	end
	local saved = false
	local failure: string = "DataStoreUnavailable"
	local writeId = HttpService:GenerateGUID(false)
	for attempt = 1, saveAttempts do
		if not withinDeadline() then
			failure = "ShutdownDeadline"
			break
		end
		local lostOwnership = false
		local ok, result = pcall(function()
			return store:UpdateAsync("Player_" .. player.UserId, function(record: any): any
				lostOwnership = false
				-- Retrying a release whose response was lost must not overwrite a
				-- new session. Its exact committed write can safely be acknowledged.
				if release and type(record) == "table" and record.LastWriteId == writeId and record.Session == nil then
					return record
				end
				if type(record) ~= "table" or record.SchemaVersion ~= schemaVersion
					or not validSession(record.Session) or record.Session.Token ~= state.Token
					or record.Session.ExpiresAt <= os.time() then
					lostOwnership = true
					return nil
				end
				local nextRecord: any = { SchemaVersion = schemaVersion, Data = snapshot, LastWriteId = writeId }
				if not release then
					nextRecord.Session = { Token = state.Token, ExpiresAt = os.time() + leaseSeconds }
				end
				return nextRecord
			end)
		end)
		if ok and type(result) == "table" then
			if release and result.Session == nil then
				saved = true
			elseif not release and validSession(result.Session) and result.Session.Token == state.Token then
				state.LeaseExpiresAt = result.Session.ExpiresAt
				saved = true
			end
		end
		if saved then
			break
		end
		if lostOwnership then
			failure = "SessionLost"
			markSessionLost(state, "save no longer owns the stored session")
			break
		end
		warn(string.format("[Data] Save attempt %d failed for %d", attempt, player.UserId))
		if attempt < saveAttempts then
			retryDelay(attempt)
		end
	end
	state.Saving = false
	if saved then
		state.SavedRevision = revision
		if tostring(state.Status) ~= "SessionLost" then
			state.Status = if release then "Closed" else "Ready"
		end
		return true, nil
	end
	if tostring(state.Status) ~= "SessionLost" then
		state.Status = "SaveFailed"
	end
	notify(player)
	return false, failure
end

function PlayerDataService:Shutdown()
	if shuttingDown then
		return
	end
	shuttingDown = true
	context.IsClosing = true
	shutdownDeadline = os.clock() + 25
	local pending = 0
	for player, state in states do
		state.Cancelled = true
		if state.Profile then
			pending += 1
			task.spawn(function()
				local ok, err = PlayerDataService:Save(player, true)
				if not ok then
					warn(string.format("[Data] Shutdown save failed for %d (%s)", player.UserId, err or "unknown"))
				end
				pending -= 1
			end)
		end
	end
	while (pending > 0 or activeLoads > 0) and withinDeadline() do
		task.wait(0.1)
	end
	if pending > 0 or activeLoads > 0 then
		warn(string.format("[Data] Shutdown deadline reached; %d save(s), %d load(s) still pending.", pending, activeLoads))
	end
end

function PlayerDataService:Start()
	assert(context ~= nil, "PlayerDataService.Init must run before Start")
	if started then
		return
	end
	started = true
	local function onAdded(player: Player)
		if states[player] or shuttingDown then
			return
		end
		local state: SessionState = {
			Player = player,
			Token = instanceId .. ":" .. HttpService:GenerateGUID(false),
			Profile = nil,
			Status = "Loading",
			Revision = 0,
			SavedRevision = 0,
			LeaseExpiresAt = 0,
			Saving = false,
			Cancelled = false,
			Releasing = false,
			Memory = memoryMode,
		}
		states[player] = state
		activeLoads += 1
		task.spawn(function()
				local ok, err = pcall(function(): any
					load(state)
					return nil
				end)
			if not ok then
				state.Status = "LoadFailed"
				warn(string.format("[Data] Unexpected load error for %d: %s", player.UserId, tostring(err)))
				if not state.Memory then
					releaseUnconfirmedAcquisition(state)
				end
				if stillPresent(player) then
					player:Kick("Your data could not be loaded safely. Please try again later.")
				else
					states[player] = nil
				end
			end
			activeLoads -= 1
		end)
	end
	Players.PlayerAdded:Connect(onAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		local state = states[player]
		if not state then
			return
		end
		state.Cancelled = true
		if state.Profile then
			local ok, err = PlayerDataService:Save(player, true)
			if not ok then
				warn(string.format("[Data] Leave save failed for %d (%s)", player.UserId, err or "unknown"))
			end
			states[player] = nil
		end
		-- A load in flight owns cleanup and releases any lock acquired before cancellation.
	end)
	for _, player in Players:GetPlayers() do
		onAdded(player)
	end
	game:BindToClose(function()
		PlayerDataService:Shutdown()
	end)
	task.spawn(function()
		while not shuttingDown do
			task.wait(autoSaveSeconds)
			if shuttingDown then
				break
			end
			for player, state in states do
				if usable(state) then
					task.spawn(function()
						PlayerDataService:Save(player, false)
					end)
				end
			end
		end
	end)
end

return PlayerDataService
