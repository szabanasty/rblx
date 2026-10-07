--!strict
local ZoneTypes = require(script.Parent.ZoneTypes)
export type Input = {Throttle: number, Steer: number, Brake: boolean, Jump: boolean}
export type Action = {Action: string, Payload: {[string]: any}, RequestId: number}
export type Telemetry = {Battery: number?, Speed: number, Distance: number, ScooterId: string?, Riding: boolean}
export type Snapshot = {
    Mode: string, Phase: number,
    Ready: boolean, Status: string, SaveMode: string, Money: number?,
    Level: number?, XP: number?, XPToNextLevel: number?, Reputation: number?,
    OwnedScooters: {string}?, SelectedScooter: string?, Telemetry: Telemetry?,
    Settings: {[string]: any}?,
    ScooterUpgrades: {[string]: {[string]: number}}?,
    Quest: {Id: string, Name: string, Description: string, RemainingSeconds: number, DistanceMeters: number, RequiredDistance: number, Target: {X: number, Y: number, Z: number}}?,
    District: string?, SpeedLimit: number?,
    PlayerState: ZoneTypes.PublicPlayerState?,
    Kills: number?, Deaths: number?, Assists: number?, Revives: number?, BestStreak: number?,
    FishingInventoryCount: number?, OwnedEquipment: {[string]: boolean}?, EquippedLoadout: {[string]: string}?,
    Equipment: {Slot: string, EquipmentId: string?, Ammo: number, Capacity: number, ReloadSeconds: number}?,
    Fishing: {Active: boolean, WaitSeconds: number, Limit: number, Revision: number, LastCatch: ZoneTypes.FishEntry?, Inventory: {{Index: number, FishId: string, Weight: number, Rarity: string, Value: number}}}?,
    Revive: {Progress: number, Target: number}?,
    Objective: {SquadId: string?, Progress: number, Contested: boolean, Cooldown: number}?,
    Cosmetics: {[string]: boolean}?, ScooterCustomization: {[string]: {[string]: string}}?, EquippedTag: string?,
    Position: {X: number, Y: number, Z: number}?, Players: {{UserId: number, Name: string}}?,
    Squad: {SquadId: string?, Leader: number?, Invite: {From: string, ExpiresIn: number}?, Members: {{UserId: number, Name: string, Position: {X: number, Y: number, Z: number}?, State: ZoneTypes.PublicPlayerState?}}}?,
    Leaderboard: {{UserId: number, Name: string, Kills: number, Deaths: number, Assists: number, Revives: number, CurrentStreak: number, BestStreak: number, Level: number}}?,
}
export type Feedback = {RequestId: number, Success: boolean, Message: string, OpenMenu: string?}
return {}
