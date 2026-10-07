# Wszystkie źródła i ich miejsca w Studio

50 plików Luau. Każdy zwykły `.luau` to ModuleScript; `init.server.luau` nadaje Server typ Script, `init.client.luau` nadaje Client typ LocalScript. PHASE 0 uruchamia wyłącznie pięć usług fundamentu i FoundationController. Obecność pozostałych modułów w Explorer nie oznacza ich uruchomienia.

| Plik | Explorer | Status |
| --- | --- | --- |
| [`src/client/Controllers/FoundationController.luau`](../src/client/Controllers/FoundationController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.FoundationController` | Aktywny fundament |
| [`src/client/Controllers/InputController.luau`](../src/client/Controllers/InputController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.InputController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Controllers/MenuController.luau`](../src/client/Controllers/MenuController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.MenuController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Controllers/MinimapController.luau`](../src/client/Controllers/MinimapController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.MinimapController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Controllers/ScooterController.luau`](../src/client/Controllers/ScooterController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.ScooterController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Controllers/SettingsController.luau`](../src/client/Controllers/SettingsController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.SettingsController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Controllers/UIController.luau`](../src/client/Controllers/UIController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.UIController` | Zachowany prototyp; nieuruchamiany |
| [`src/client/Modules/GuiFactory.luau`](../src/client/Modules/GuiFactory.luau) | `StarterPlayer.StarterPlayerScripts.Client.Modules.GuiFactory` | Aktywny fundament |
| [`src/client/init.client.luau`](../src/client/init.client.luau) | `StarterPlayer.StarterPlayerScripts.Client` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/server/Modules/ScooterFactory.luau`](../src/server/Modules/ScooterFactory.luau) | `ServerScriptService.Server.Modules.ScooterFactory` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Modules/WorldBuilder.luau`](../src/server/Modules/WorldBuilder.luau) | `ServerScriptService.Server.Modules.WorldBuilder` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/DayCycleService.luau`](../src/server/Services/DayCycleService.luau) | `ServerScriptService.Server.Services.DayCycleService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/EconomyService.luau`](../src/server/Services/EconomyService.luau) | `ServerScriptService.Server.Services.EconomyService` | Aktywny fundament |
| [`src/server/Services/NetworkService.luau`](../src/server/Services/NetworkService.luau) | `ServerScriptService.Server.Services.NetworkService` | Aktywny fundament |
| [`src/server/Services/PlayerDataService.luau`](../src/server/Services/PlayerDataService.luau) | `ServerScriptService.Server.Services.PlayerDataService` | Aktywny fundament |
| [`src/server/Services/PlayerStateService.luau`](../src/server/Services/PlayerStateService.luau) | `ServerScriptService.Server.Services.PlayerStateService` | Aktywny fundament |
| [`src/server/Services/QuestService.luau`](../src/server/Services/QuestService.luau) | `ServerScriptService.Server.Services.QuestService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/RoadService.luau`](../src/server/Services/RoadService.luau) | `ServerScriptService.Server.Services.RoadService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/ScooterService.luau`](../src/server/Services/ScooterService.luau) | `ServerScriptService.Server.Services.ScooterService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/ShopService.luau`](../src/server/Services/ShopService.luau) | `ServerScriptService.Server.Services.ShopService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/SnapshotService.luau`](../src/server/Services/SnapshotService.luau) | `ServerScriptService.Server.Services.SnapshotService` | Aktywny fundament |
| [`src/server/Services/TrafficService.luau`](../src/server/Services/TrafficService.luau) | `ServerScriptService.Server.Services.TrafficService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/Services/WorldService.luau`](../src/server/Services/WorldService.luau) | `ServerScriptService.Server.Services.WorldService` | Zachowany prototyp; nieuruchamiany |
| [`src/server/init.server.luau`](../src/server/init.server.luau) | `ServerScriptService.Server` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/CombatConfig.luau`](../src/shared/Config/CombatConfig.luau) | `ReplicatedStorage.Shared.Config.CombatConfig` | Parametry fundamentu / przyszłych faz |
| [`src/shared/Config/EconomyConfig.luau`](../src/shared/Config/EconomyConfig.luau) | `ReplicatedStorage.Shared.Config.EconomyConfig` | Parametry fundamentu / przyszłych faz |
| [`src/shared/Config/EquipmentConfig.luau`](../src/shared/Config/EquipmentConfig.luau) | `ReplicatedStorage.Shared.Config.EquipmentConfig` | Kontrakt przyszłej fazy |
| [`src/shared/Config/FishingConfig.luau`](../src/shared/Config/FishingConfig.luau) | `ReplicatedStorage.Shared.Config.FishingConfig` | Kontrakt przyszłej fazy |
| [`src/shared/Config/GameConfig.luau`](../src/shared/Config/GameConfig.luau) | `ReplicatedStorage.Shared.Config.GameConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/LevelConfig.luau`](../src/shared/Config/LevelConfig.luau) | `ReplicatedStorage.Shared.Config.LevelConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/MessageConfig.luau`](../src/shared/Config/MessageConfig.luau) | `ReplicatedStorage.Shared.Config.MessageConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/PvPRewardConfig.luau`](../src/shared/Config/PvPRewardConfig.luau) | `ReplicatedStorage.Shared.Config.PvPRewardConfig` | Kontrakt przyszłej fazy |
| [`src/shared/Config/QuestConfig.luau`](../src/shared/Config/QuestConfig.luau) | `ReplicatedStorage.Shared.Config.QuestConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/RewardConfig.luau`](../src/shared/Config/RewardConfig.luau) | `ReplicatedStorage.Shared.Config.RewardConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/RoadConfig.luau`](../src/shared/Config/RoadConfig.luau) | `ReplicatedStorage.Shared.Config.RoadConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/ScooterConfig.luau`](../src/shared/Config/ScooterConfig.luau) | `ReplicatedStorage.Shared.Config.ScooterConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/UpgradeConfig.luau`](../src/shared/Config/UpgradeConfig.luau) | `ReplicatedStorage.Shared.Config.UpgradeConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/WorldConfig.luau`](../src/shared/Config/WorldConfig.luau) | `ReplicatedStorage.Shared.Config.WorldConfig` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Config/ZoneConfig.luau`](../src/shared/Config/ZoneConfig.luau) | `ReplicatedStorage.Shared.Config.ZoneConfig` | Kontrakt przyszłej fazy |
| [`src/shared/Modules/ProfileSchema.luau`](../src/shared/Modules/ProfileSchema.luau) | `ReplicatedStorage.Shared.Modules.ProfileSchema` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Modules/Progression.luau`](../src/shared/Modules/Progression.luau) | `ReplicatedStorage.Shared.Modules.Progression` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Modules/RateLimiter.luau`](../src/shared/Modules/RateLimiter.luau) | `ReplicatedStorage.Shared.Modules.RateLimiter` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Modules/ScooterStats.luau`](../src/shared/Modules/ScooterStats.luau) | `ReplicatedStorage.Shared.Modules.ScooterStats` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Modules/Validation.luau`](../src/shared/Modules/Validation.luau) | `ReplicatedStorage.Shared.Modules.Validation` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Modules/WorldLayout.luau`](../src/shared/Modules/WorldLayout.luau) | `ReplicatedStorage.Shared.Modules.WorldLayout` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/ProjectInfo.luau`](../src/shared/ProjectInfo.luau) | `ReplicatedStorage.Shared.ProjectInfo` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Types/GameTypes.luau`](../src/shared/Types/GameTypes.luau) | `ReplicatedStorage.Shared.Types.GameTypes` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Types/Network.luau`](../src/shared/Types/Network.luau) | `ReplicatedStorage.Shared.Types.Network` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Types/PlayerData.luau`](../src/shared/Types/PlayerData.luau) | `ReplicatedStorage.Shared.Types.PlayerData` | Bootstrap / współdzielony moduł lub zgodność zapisu |
| [`src/shared/Types/ZoneTypes.luau`](../src/shared/Types/ZoneTypes.luau) | `ReplicatedStorage.Shared.Types.ZoneTypes` | Kontrakt przyszłej fazy |

Konfiguracja obiektów: [default.project.json](../default.project.json). Pełne drzewo: [EXPLORER.md](EXPLORER.md). Pliki dodane/zmienione w tej fazie: [PHASE_0_FILES.md](PHASE_0_FILES.md). Testy/scripts/docs nie trafiają do Roblox Studio.
