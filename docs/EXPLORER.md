# Pełne drzewo Rojo w Roblox Studio

Poniżej kompletne drzewo obiektów z rzeczywistego `rojo build` dla PHASE 0. Standardowe dodatkowe usługi Studio mogą również być widoczne; nie są częścią konfiguracji projektu. Nie twórz tych obiektów ręcznie — Rojo robi to automatycznie.

```text
DataModel (rblx)
├── ReplicatedStorage [ReplicatedStorage]
│   ├── Remotes [Folder]
│   │   ├── Action [RemoteEvent]
│   │   ├── Feedback [RemoteEvent]
│   │   ├── Input [RemoteEvent]
│   │   └── Snapshot [RemoteEvent]
│   └── Shared [Folder]
│       ├── Config [Folder]
│       │   ├── CombatConfig [ModuleScript]
│       │   ├── EconomyConfig [ModuleScript]
│       │   ├── EquipmentConfig [ModuleScript]
│       │   ├── FishingConfig [ModuleScript]
│       │   ├── GameConfig [ModuleScript]
│       │   ├── LevelConfig [ModuleScript]
│       │   ├── MessageConfig [ModuleScript]
│       │   ├── PvPRewardConfig [ModuleScript]
│       │   ├── QuestConfig [ModuleScript]
│       │   ├── RewardConfig [ModuleScript]
│       │   ├── RoadConfig [ModuleScript]
│       │   ├── ScooterConfig [ModuleScript]
│       │   ├── UpgradeConfig [ModuleScript]
│       │   ├── WorldConfig [ModuleScript]
│       │   └── ZoneConfig [ModuleScript]
│       ├── Modules [Folder]
│       │   ├── ProfileSchema [ModuleScript]
│       │   ├── Progression [ModuleScript]
│       │   ├── RateLimiter [ModuleScript]
│       │   ├── ScooterStats [ModuleScript]
│       │   ├── Validation [ModuleScript]
│       │   └── WorldLayout [ModuleScript]
│       ├── ProjectInfo [ModuleScript]
│       └── Types [Folder]
│           ├── GameTypes [ModuleScript]
│           ├── Network [ModuleScript]
│           ├── PlayerData [ModuleScript]
│           └── ZoneTypes [ModuleScript]
├── ServerScriptService [ServerScriptService]
│   └── Server [Script]
│       ├── Modules [Folder]
│       │   ├── ScooterFactory [ModuleScript]
│       │   └── WorldBuilder [ModuleScript]
│       └── Services [Folder]
│           ├── DayCycleService [ModuleScript]
│           ├── EconomyService [ModuleScript] — aktywny PHASE 0
│           ├── NetworkService [ModuleScript] — aktywny PHASE 0
│           ├── PlayerDataService [ModuleScript] — aktywny PHASE 0
│           ├── PlayerStateService [ModuleScript] — aktywny PHASE 0
│           ├── QuestService [ModuleScript]
│           ├── RoadService [ModuleScript]
│           ├── ScooterService [ModuleScript]
│           ├── ShopService [ModuleScript]
│           ├── SnapshotService [ModuleScript] — aktywny PHASE 0
│           ├── TrafficService [ModuleScript]
│           └── WorldService [ModuleScript]
├── ServerStorage [ServerStorage]
│   ├── EquipmentTemplates [Folder]
│   └── ScooterModels [Folder]
├── StarterPlayer [StarterPlayer]
│   └── StarterPlayerScripts [StarterPlayerScripts]
│       └── Client [LocalScript]
│           ├── Controllers [Folder]
│           │   ├── FoundationController [ModuleScript] — aktywny PHASE 0
│           │   ├── InputController [ModuleScript]
│           │   ├── MenuController [ModuleScript]
│           │   ├── MinimapController [ModuleScript]
│           │   ├── ScooterController [ModuleScript]
│           │   ├── SettingsController [ModuleScript]
│           │   └── UIController [ModuleScript]
│           └── Modules [Folder]
│               └── GuiFactory [ModuleScript] — aktywny PHASE 0
└── Workspace [Workspace]
    ├── Baseplate [Part]
    ├── Map [Folder]
    │   ├── Buildings [Folder]
    │   ├── CombatZone [Folder]
    │   ├── Cover [Folder]
    │   ├── FishingArea [Folder]
    │   ├── Garage [Folder]
    │   ├── Roads [Folder]
    │   ├── SafeZone [Folder]
    │   └── Shops [Folder]
    ├── SpawnLocation [SpawnLocation]
    └── Vehicles [Folder]
```

Podczas Play dochodzą `Players.<gracz>.PlayerGui.ZoneFoundation` (ScreenGui z panelem i ustawieniami) oraz `Players.<gracz>.leaderstats` (Money i Level). UI nie wymaga StarterGui. Współdzielone Config/Types/Modules to ModuleScripts; przyszłe katalogi nie uruchamiają mechanik. Wszystkie foldery mapy i modeli są puste w czystym miejscu tej fazy.

Aktywne usługi: PlayerData, Economy, PlayerState, Network, Snapshot. Aktywny klient: FoundationController. Pozostałe usługi i kontrolery należą do zachowanego, nieaktywnego prototypu. Docelowe nowe usługi są opisane w [ARCHITECTURE.md](ARCHITECTURE.md), ich kod powstanie we właściwych fazach. [Dokładne mapowanie plików](FILES.md).
