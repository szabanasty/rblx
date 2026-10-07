--!strict
export type ScooterData = {
    Id: string, DisplayName: string, Price: number, TopSpeed: number,
    Acceleration: number, Handling: number, Braking: number, Jump: number,
    Battery: number, Stability: number, Rarity: string, UnlockLevel: number,
}
export type RoadData = {
    RoadId: string, SpeedLimit: number, RoadType: string,
    District: string, PoliceEnabled: boolean,
}
export type QuestData = {Id: string, Name: string, Description: string, Money: number, XP: number, Reputation: number?}
export type PoliceRank = "Cadet" | "Officer" | "Senior Officer" | "Sergeant" | "Lieutenant" | "Captain"
return {}
