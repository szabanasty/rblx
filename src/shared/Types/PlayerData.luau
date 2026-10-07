--!strict
export type Settings = {
    UIScale: number, GraphicsQuality: number, MusicVolume: number,
    SFXVolume: number, ReducedEffects: boolean,
}
export type PlayerData = {
    SchemaVersion: number, UserId: number, Money: number, Level: number, XP: number,
    Reputation: number, DriverScore: number, SelectedScooter: string,
    OwnedScooters: {[string]: boolean}, ScooterUpgrades: {[string]: any}, QuestCooldowns: {[string]: number},
    Pets: {[string]: any}, EquippedPet: string?, Clothing: {[string]: any},
    Inventory: {[string]: any}, Achievements: {[string]: any}, CrewId: string?,
    PoliceLevel: number, PoliceXP: number, PoliceReputation: number,
    PoliceCredits: number, PoliceRank: string, Statistics: {[string]: number},
    Settings: Settings, RewardBudget: {Day: number, Money: number, XP: number, Reputation: number},
    IdempotencyLedger: {[string]: number},
    ScooterCustomization: {[string]: any}, OwnedEquipment: {[string]: boolean},
    EquippedLoadout: {PRIMARY: string?, SECONDARY: string?, UTILITY: string?},
    FishingInventory: {{FishId: string, Weight: number, Rarity: string}}, Cosmetics: {[string]: boolean},
    Kills: number, Deaths: number, Assists: number, Revives: number, BestStreak: number, ZoneTime: number,
}
export type StoredRecord = {
    SchemaVersion: number, Data: PlayerData,
    Session: {Token: string, ExpiresAt: number}?,
}
return {}
