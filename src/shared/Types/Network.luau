--!strict
export type Input = {Throttle: number, Steer: number, Brake: boolean, Jump: boolean}
export type Action = {Action: string, Payload: {[string]: any}, RequestId: number}
export type Telemetry = {Speed: number, Distance: number, ScooterId: string?, Riding: boolean}
export type Snapshot = {
    Mode: string, Phase: number,
    Ready: boolean, Status: string, SaveMode: string, Money: number?,
    Level: number?, XP: number?, XPToNextLevel: number?, Reputation: number?,
    OwnedScooters: {string}?, SelectedScooter: string?, Telemetry: Telemetry?,
    Settings: {[string]: any}?,
    ScooterUpgrades: {[string]: {[string]: number}}?,
    Quest: {Id: string, Name: string, Description: string, RemainingSeconds: number, DistanceMeters: number, RequiredDistance: number, Target: {X: number, Y: number, Z: number}}?,
    District: string?, SpeedLimit: number?,
    PlayerState: {State: string, CurrentHealth: number, MaxHealth: number, HealthReady: boolean, AreaId: string, AreaName: string, CurrentStreak: number}?,
    Kills: number?, Deaths: number?, Assists: number?, Revives: number?, BestStreak: number?,
    FishingInventoryCount: number?, OwnedEquipment: {[string]: boolean}?, EquippedLoadout: {[string]: string}?,
}
export type Feedback = {RequestId: number, Success: boolean, Message: string, OpenMenu: string?}
return {}
