--!strict
export type PlayerState = "SAFE" | "ALIVE" | "COMBAT" | "DOWNED" | "REVIVING" | "RESPAWNING" | "FISHING"
export type Loadout = {PRIMARY: string?, SECONDARY: string?, UTILITY: string?}
export type FishEntry = {FishId: string, Weight: number, Rarity: string}
export type Squad = {SquadId: string, Leader: number, Members: {number}}
export type Encounter = {
    Id: string, Victim: number, Attacker: number, VictimStreak: number, At: number,
    Paid: boolean?, Settled: boolean?, Contributions: {[number]: {Damage: number, At: number}},
}
export type PublicPlayerState = {
    State: PlayerState, CurrentHealth: number, MaxHealth: number, HealthReady: boolean,
    AreaId: string, AreaName: string, CurrentStreak: number,
    CombatSeconds: number, DownedSeconds: number, ProtectionSeconds: number,
}
return {}
