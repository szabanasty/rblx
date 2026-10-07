# Pliki i ich mapowanie — wersja 0.3.0

Wszystkie zwykłe pliki `.luau` poniżej są ModuleScripts. Wyjątki to dwa bootstrapy, opisane w tabeli. Rojo automatycznie tworzy foldery; nie trzeba ręcznie wklejać kodu w Studio.

| Plik źródłowy | Obiekt w Roblox Studio |
| --- | --- |
| [src/client/Controllers/InputController.luau](../src/client/Controllers/InputController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.InputController` |
| [src/client/Controllers/MenuController.luau](../src/client/Controllers/MenuController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.MenuController` |
| [src/client/Controllers/MinimapController.luau](../src/client/Controllers/MinimapController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.MinimapController` |
| [src/client/Controllers/ScooterController.luau](../src/client/Controllers/ScooterController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.ScooterController` |
| [src/client/Controllers/SettingsController.luau](../src/client/Controllers/SettingsController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.SettingsController` |
| [src/client/Controllers/UIController.luau](../src/client/Controllers/UIController.luau) | `StarterPlayer.StarterPlayerScripts.Client.Controllers.UIController` |
| [src/client/Modules/GuiFactory.luau](../src/client/Modules/GuiFactory.luau) | `StarterPlayer.StarterPlayerScripts.Client.Modules.GuiFactory` |
| [src/client/init.client.luau](../src/client/init.client.luau) | `StarterPlayer.StarterPlayerScripts.Client` (LocalScript) |
| [src/server/Modules/ScooterFactory.luau](../src/server/Modules/ScooterFactory.luau) | `ServerScriptService.Server.Modules.ScooterFactory` |
| [src/server/Modules/WorldBuilder.luau](../src/server/Modules/WorldBuilder.luau) | `ServerScriptService.Server.Modules.WorldBuilder` |
| [src/server/Services/DayCycleService.luau](../src/server/Services/DayCycleService.luau) | `ServerScriptService.Server.Services.DayCycleService` |
| [src/server/Services/EconomyService.luau](../src/server/Services/EconomyService.luau) | `ServerScriptService.Server.Services.EconomyService` |
| [src/server/Services/NetworkService.luau](../src/server/Services/NetworkService.luau) | `ServerScriptService.Server.Services.NetworkService` |
| [src/server/Services/PlayerDataService.luau](../src/server/Services/PlayerDataService.luau) | `ServerScriptService.Server.Services.PlayerDataService` |
| [src/server/Services/QuestService.luau](../src/server/Services/QuestService.luau) | `ServerScriptService.Server.Services.QuestService` |
| [src/server/Services/RoadService.luau](../src/server/Services/RoadService.luau) | `ServerScriptService.Server.Services.RoadService` |
| [src/server/Services/ScooterService.luau](../src/server/Services/ScooterService.luau) | `ServerScriptService.Server.Services.ScooterService` |
| [src/server/Services/ShopService.luau](../src/server/Services/ShopService.luau) | `ServerScriptService.Server.Services.ShopService` |
| [src/server/Services/SnapshotService.luau](../src/server/Services/SnapshotService.luau) | `ServerScriptService.Server.Services.SnapshotService` |
| [src/server/Services/TrafficService.luau](../src/server/Services/TrafficService.luau) | `ServerScriptService.Server.Services.TrafficService` |
| [src/server/Services/WorldService.luau](../src/server/Services/WorldService.luau) | `ServerScriptService.Server.Services.WorldService` |
| [src/server/init.server.luau](../src/server/init.server.luau) | `ServerScriptService.Server` (Script) |
| [src/shared/Config/GameConfig.luau](../src/shared/Config/GameConfig.luau) | `ReplicatedStorage.Shared.Config.GameConfig` |
| [src/shared/Config/LevelConfig.luau](../src/shared/Config/LevelConfig.luau) | `ReplicatedStorage.Shared.Config.LevelConfig` |
| [src/shared/Config/MessageConfig.luau](../src/shared/Config/MessageConfig.luau) | `ReplicatedStorage.Shared.Config.MessageConfig` |
| [src/shared/Config/QuestConfig.luau](../src/shared/Config/QuestConfig.luau) | `ReplicatedStorage.Shared.Config.QuestConfig` |
| [src/shared/Config/RewardConfig.luau](../src/shared/Config/RewardConfig.luau) | `ReplicatedStorage.Shared.Config.RewardConfig` |
| [src/shared/Config/RoadConfig.luau](../src/shared/Config/RoadConfig.luau) | `ReplicatedStorage.Shared.Config.RoadConfig` |
| [src/shared/Config/ScooterConfig.luau](../src/shared/Config/ScooterConfig.luau) | `ReplicatedStorage.Shared.Config.ScooterConfig` |
| [src/shared/Config/UpgradeConfig.luau](../src/shared/Config/UpgradeConfig.luau) | `ReplicatedStorage.Shared.Config.UpgradeConfig` |
| [src/shared/Config/WorldConfig.luau](../src/shared/Config/WorldConfig.luau) | `ReplicatedStorage.Shared.Config.WorldConfig` |
| [src/shared/Modules/ProfileSchema.luau](../src/shared/Modules/ProfileSchema.luau) | `ReplicatedStorage.Shared.Modules.ProfileSchema` |
| [src/shared/Modules/Progression.luau](../src/shared/Modules/Progression.luau) | `ReplicatedStorage.Shared.Modules.Progression` |
| [src/shared/Modules/RateLimiter.luau](../src/shared/Modules/RateLimiter.luau) | `ReplicatedStorage.Shared.Modules.RateLimiter` |
| [src/shared/Modules/ScooterStats.luau](../src/shared/Modules/ScooterStats.luau) | `ReplicatedStorage.Shared.Modules.ScooterStats` |
| [src/shared/Modules/Validation.luau](../src/shared/Modules/Validation.luau) | `ReplicatedStorage.Shared.Modules.Validation` |
| [src/shared/Modules/WorldLayout.luau](../src/shared/Modules/WorldLayout.luau) | `ReplicatedStorage.Shared.Modules.WorldLayout` |
| [src/shared/ProjectInfo.luau](../src/shared/ProjectInfo.luau) | `ReplicatedStorage.Shared.ProjectInfo` |
| [src/shared/Types/GameTypes.luau](../src/shared/Types/GameTypes.luau) | `ReplicatedStorage.Shared.Types.GameTypes` |
| [src/shared/Types/Network.luau](../src/shared/Types/Network.luau) | `ReplicatedStorage.Shared.Types.Network` |
| [src/shared/Types/PlayerData.luau](../src/shared/Types/PlayerData.luau) | `ReplicatedStorage.Shared.Types.PlayerData` |

## Pozostałe pliki

| Plik | Zastosowanie |
| --- | --- |
| `default.project.json` | Rojo: mapowanie, remotes, streaming, scena bazowa i foldery mapy |
| `.gitignore` | Pomija buildy, narzędzia i wygenerowane harnessy testowe |
| `scripts/install-tools.sh` | Weryfikowana instalacja przypiętych narzędzi w chmurze/Linux |
| `scripts/check-project.py` | Kompilacja, analiza typów, struktura i dziewięć zestawów testów |
| `scripts/check-rojo-server.py` | Żywe API Rojo i test file watchera |
| `.github/workflows/validate.yml` | Automatyczna walidacja na push i pull request |
| `tests/*.spec.luau` | Shared, player-data, economy, network, snapshot, input, shop, quest, world-stats |
| `README.md` | Uruchomienie, sterowanie, zapis i typowe problemy |
| `docs/ARCHITECTURE.md` | Obecne zależności i podział przyszłych systemów |
| `docs/ROADMAP.md` | Zakres etapów 0–7 i najbliższe zadania |
| `docs/TESTING.md`, `docs/PHASE_1_TESTING.md` | Testy dostępne i wymagany odbiór w Studio |
| `docs/ASSETS.md` | Placeholdery i instrukcja legalnych assetów |

`requirements-dev.txt` przypina bibliotekę MessagePack do opcjonalnego testu API Rojo. Do grania wystarczy rojo.exe i wtyczka. Nie ma wymaganych ręcznych modeli ani dźwięków; folder na własne eksporty assetów można dodać przy zastępowaniu placeholderów.
