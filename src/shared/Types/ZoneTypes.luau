--!strict
export type PlayerState = "SAFE" | "ALIVE" | "COMBAT" | "DOWNED" | "REVIVING" | "RESPAWNING" | "FISHING"
export type Loadout = {PRIMARY: string?, SECONDARY: string?, UTILITY: string?}
export type FishEntry = {FishId: string, Weight: number, Rarity: string}
export type Squad = {SquadId: string, Leader: number, Members: {number}}
export type Encounter = {EncounterId: string, Victim: number, Attacker: number, RewardPaid: boolean}
export type PublicPlayerState = {
    State: PlayerState, CurrentHealth: number, MaxHealth: number, HealthReady: boolean,
    AreaId: string, AreaName: string, CurrentStreak: number,
}
return {}
