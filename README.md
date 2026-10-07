# Kukirin City — Roblox/Luau + Rojo

Wersja 0.3.0: modularny prototyp multiplayer. Zawiera serwerowe dane i ekonomię, hulajnogi, HUD i sterowanie dotykowe, oryginalne miasto z prostych części, ruch NPC, dzień/noc, sklepy, sześć aktywnych kategorii ulepszeń oraz dostawę sprawdzaną przez serwer.

Kod przeszedł kompilację, analizę typów Roblox i testy logiki w chmurze. **Fizyka, wygląd UI, prawdziwy multiplayer i produkcyjny DataStore wymagają testu w Roblox Studio.** Nie są jeszcze potwierdzone testem w silniku. Projekt nie wymaga modeli, animacji, muzyki ani assetów z Toolboxa.

## Uruchomienie na Twoim komputerze — Windows

Jeśli masz już Rojo i działającą wtyczkę, wykonaj kroki 1, 3, 4 i 5.

1. Zatrzymaj Play w Studio. W starym PowerShell zatrzymaj Rojo przez **Ctrl+C**. Pobierz [aktualny ZIP projektu](https://github.com/szabanasty/rblx/archive/refs/heads/main.zip) i wypakuj do nowego folderu. Skopiuj do niego folder `.tools` ze starego projektu, aby zachować `rojo.exe`; jeśli go nie masz, wykonaj krok 2. Nie nadpisuj własnych zmian bez kopii. Właściwy folder zawiera `default.project.json`, `src` i `README.md`.
2. Pobierz [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), plik `rojo-7.7.1-windows-x86_64.zip`. Wypakuj `rojo.exe` do `.tools` w folderze projektu. Roblox Studio pobierzesz z [oficjalnej strony](https://create.roblox.com/). Git, Node.js i Python nie są potrzebne do grania w prototyp.
3. Otwórz PowerShell w folderze z `default.project.json` i wykonaj:

   ```powershell
   .\.tools\rojo.exe --version
   .\.tools\rojo.exe plugin install
   .\.tools\rojo.exe serve default.project.json
   ```

   Powinien pojawić się `Rojo server listening`, `localhost`, port `34872`. Zostaw to okno otwarte. Jeśli masz wtyczkę, polecenie `plugin install` nie jest potrzebne ponownie. Po pierwszej instalacji uruchom ponownie Studio.
4. Otwórz czysty Baseplate w Studio. Zatrzymaj ewentualny test. W zakładce **Dodatki plug-in / Plugins** otwórz **Rojo**, wybierz **Connect**, adres `localhost`, port `34872`, a następnie połącz i zaakceptuj synchronizację drzewa tego projektu. Po aktualizacji ZIP rozłącz poprzednie połączenie i połącz nowe. Kod ma pojawić się w miejscach opisanych poniżej.
5. Włącz **Play / F5**. Użyj Play, aby uruchomić gracza i klienta; samo Run nie jest pełnym testem. Miasto powstaje dopiero podczas Play. W Output / Wyjście powinny pojawić się `Core ready (version 0.3.0)` dla serwera i klienta oraz informacja o trybie zapisu.

Alternatywnie zbuduj samodzielny plik miejsca:

```powershell
.\.tools\rojo.exe build default.project.json --output rblx.rbxlx
```

Otwórz `rblx.rbxlx` w Studio. Do późniejszej synchronizacji nadal służy `rojo serve`. Na macOS użyj archiwum Rojo dla swojej architektury, `./rojo plugin install` i `./rojo serve default.project.json`.

## Pierwszy przejazd

- Masz bezpłatną KuKirin G2, 100 Money i Level 1. Otwórz **GARAŻ → PRZYWOŁAJ**. Serwer szuka wolnego miejsca obok gracza i próbuje automatycznie posadzić go na hulajnodze. Jeśli nie wsiądziesz, podejdź i użyj **E** / przycisku promptu.
- PC: **W / ↑** gaz, **S / ↓** hamulec, **A/D / ←/→** skręt, **Space** skok, **E** zejdź. Przy punktach sklepu i garażu **F** otwiera menu.
- Telefon/tablet: przyciski **GAZ, HAMULEC, ←, →, SKOK, ZEJDŹ**. Interakcje mają standardowy przycisk ProximityPrompt Roblox. Rozmiary UI reagują na viewport. Nie ma jeszcze driftu ani tricków poza fizycznym skokiem.
- Gamepad: lewy drążek skręt/gaz, R2 gaz, L2 hamulec, A skok, B zejdź, X interakcja. Nawigacja całego menu gamepadem wymaga osobnego odbioru.
- Za każde 250 zweryfikowanych metrów jazdy serwer nalicza 25 Money i 15 XP. Awans daje do 100 Money, mieszcząc się w limicie dziennym. W prototypie wszystkie źródła wspólnie mają limity: 1000 Money, 2000 XP i 200 Reputation na dobę UTC.
- Przy spawnie są **GARAŻ** `(65,65)`, **HULAJNOGI** `(95,65)`, **UPGRADE** `(65,95)` i **DOSTAWY** `(95,95)`; podane współrzędne to X/Z. Zsiądź przed zakupem.
- Zarób 25 Money, podejdź do UPGRADE i kup pierwszy silnik za 125. Kupno odbywa się tylko blisko właściwego punktu; globalne MENU pozwala przeglądać oferty. Poziomy upgrade wynoszą 0–3, wymagania Level 1/4/7.
- Odbierz **Pierwszą dostawę**, przywołaj hulajnogę i jedź do zielonego punktu `(220,-140)`, widocznego na minimapie. Potrzeba minimum 45 m sprawdzonej jazdy, 12 sekund i dotarcia hulajnogą w promień 20 studów w ciągu 180 sekund. Ukończenie jest automatyczne: 80 Money, 30 XP i 2 Reputation, do pozostałego dziennego limitu. Następna dostawa po 120 sekundach.
- MENU → OPCJE pozwala zmienić skalę HUD i lokalną widoczność dekoracji. Ustawienia dźwięku i Reduced Effects są zapisane w schemacie na przyszłe assety; w tej wersji nie ma muzyki ani VFX do ograniczenia.

G2 ma maksymalnie 35 km/h, G3 45 km/h (12000 Money, Level 8), G4 55 km/h (45000 Money, Level 20). To świadomie dłuższy progres; obecny balans jest prototypowy. Statystyki prędkości, przyspieszenia, hamowania, skrętu, skoku i stabilności wpływają na kontroler serwera. Bateria jest skonfigurowana, lecz **jej upgrade jest zablokowany do czasu dodania zużycia i ładowania**.

## Gdzie znajdują się pliki w Roblox Studio

| Repozytorium | Roblox Studio | Rodzaj |
| --- | --- | --- |
| `src/server/init.server.luau` | `ServerScriptService.Server` | Script startowy |
| `src/server/Services/*.luau` | `ServerScriptService.Server.Services` | ModuleScripts usług |
| `src/server/Modules/*.luau` | `ServerScriptService.Server.Modules` | ModuleScripts builderów |
| `src/client/init.client.luau` | `StarterPlayer.StarterPlayerScripts.Client` | LocalScript startowy |
| `src/client/Controllers/*.luau` | `…Client.Controllers` | ModuleScripts klienta |
| `src/client/Modules/*.luau` | `…Client.Modules` | Wspólne funkcje GUI klienta |
| `src/shared/*` | `ReplicatedStorage.Shared` | Config, Modules, Types, ProjectInfo |
| RemoteEvents z `default.project.json` | `ReplicatedStorage.Remotes` | Action, Input, Snapshot, Feedback |
| Modele generowane przy Play | `Workspace.Map.Generated`, `Workspace.Vehicles` | Miasto, NPC, aktywne hulajnogi |
| Interfejs generowany przy Play | `Players.<gracz>.PlayerGui` | KukirinHUD, KukirinMenus, KukirinMinimap |

Nie przenoś Services obok Server ani Controllers obok Client. Zwykły plik `.luau` tworzy ModuleScript; `init.server.luau` i `init.client.luau` nadają typ obiektowi nadrzędnemu. UI nie wymaga ręcznego wklejania do StarterGui. Foldery mapy w Rojo zachowują nieznane obiekty, jednak nazwa `Map.Generated` jest zarezerwowana dla generatora. Własne modele dodawaj poza tym folderem. Pełna lista źródeł: [docs/FILES.md](docs/FILES.md).

## Dane gracza i test zapisu

Domyślnie **StudioMemory**: każdy Play zaczyna nowy profil. Jest to zamierzone, bezpieczne dla prototypu. Opublikowana gra używa `DataStoreService`, autosave 60 s, zapisu przy wyjściu i zamknięciu serwera, retry oraz blokady sesji 180 s. Błąd ładowania produkcyjnego nie tworzy nowego pustego profilu; utrata blokady zatrzymuje dostęp do danych.

Aby sprawdzić zapis:

1. Opublikuj **osobne testowe doświadczenie** przez File / Plik → Publish to Roblox.
2. W Game Settings / ustawieniach doświadczenia → Security włącz **Enable Studio Access to API Services**.
3. W `src/shared/Config/GameConfig.luau` zmień `UseStudioDataStore = true` oraz `DataStoreName = "KukirinCity_DEV_v1"`. Po edycji zatrzymaj Play i zsynchronizuj Rojo.
4. Uruchom Play, zarób Money, kup upgrade, zatrzymaj Play i uruchom ponownie. Sprawdź saldo, XP, Level, kolekcję, upgrade i cooldown dostawy.
5. Po próbach przywróć `UseStudioDataStore = false`; nie podłączaj testów Studio do magazynu graczy produkcyjnych. Poświadczenia DataStore zapewnia Roblox; nie wpisuj tokenów do repozytorium.

Retry i blokady zmniejszają ryzyko utraty danych, lecz nie zastępują testów w prawdziwym backendzie ani nie gwarantują zapisu podczas awarii serwera. Procedura testów: [docs/TESTING.md](docs/TESTING.md).

## Architektura i rozwój

- [ARCHITECTURE.md](docs/ARCHITECTURE.md): pełny podział systemów, typy, zależności, dane i reguły bezpieczeństwa.
- [ROADMAP.md](docs/ROADMAP.md): fazy 0–7, ukończone wycinki i następne mechaniki.
- [ASSETS.md](docs/ASSETS.md): istniejące placeholdery i wymagane później ręczne assety.
- [TESTING.md](docs/TESTING.md): faktycznie dostępne testy i instrukcja odbioru w Studio.

Wszystkie ważne mutacje są serwerowe. Klient przesyła zamiar sterowania lub ID oferty, nigdy cenę, nagrodę, prędkość czy wynik dostawy. Dwa niezależne limitery, schematy payloadów, cooldowny i monotoniczne RequestId blokują część nadużyć. Serwer kontroluje fizykę hulajnogi i odrzuca anomalie ruchu bez automatycznego bana za jeden sygnał. Chodzenie zwykłym awatarem nie jest objęte pełnym anti-cheatem; płatna nagroda za dostawę wymaga zweryfikowanej jazdy.

Mapa ma StreamingEnabled, 13 dzielnic jako proste blockouty, 10 dróg z limitami 30/50/70/90, kilka ramp, punkty interakcji, sześć bezkolizyjnych NPC samochodów oraz 20-minutowy cykl dnia. To własny układ prototypowy, wymagający późniejszego level designu i pomiarów na telefonie. Nie ma jeszcze odblokowywania dzielnic, minimapy innych graczy, wyścigów, policji, pets, crew, battle passa ani Robux.

## Testy w Linux/chmurze

```bash
cd /workspace/rblx
bash scripts/install-tools.sh
python3 scripts/check-project.py
```

Instalator obsługuje Linux x86_64, weryfikuje TLS i SHA-256 archiwów, przypina Rojo 7.7.1, Luau 0.741 oraz luau-lsp 1.70.1 z definicjami API Roblox. Runner kompiluje wszystkie źródła, buduje miejsce i sourcemap, sprawdza typy i odwzorowanie drzewa, uruchamia testy rzeczywistych modułów z kontrolowanymi mockami Roblox. `build/` i `tests/.generated/` są ignorowane. CI uruchamia ten sam skrypt przez GitHub Actions; wynik zdalnego CI sprawdzaj w zakładce Actions, niezależnie od wyniku lokalnego.

## Typowe problemy

| Objaw | Co sprawdzić |
| --- | --- |
| Widać stary komunikat Sync ready | Uruchamiasz stary ZIP albo niewłaściwy folder; nowe źródła logują Core ready 0.3.0. |
| Brak zakładki Rojo | `plugin install`, restart Studio; Dodatki plug-in / Plugins. |
| Connection refused | Rojo działa lokalnie, konsola jest otwarta, port 34872; chmurowy localhost nie jest Twoim komputerem. |
| Miasto nie pojawia się w edytorze | Generator uruchamia się na serwerze przy Play. W trybie klienta odległe obiekty mogą być wyładowane przez streaming. |
| NoSafeSpawnLocation | Zsiądź, przejdź na otwarty plac i spróbuj ponownie po 3 s. |
| Hulajnoga nie rusza / gracz zsiada przy skoku | Sprawdź Output, poprawne Client.Controllers, ustawienia sił i ownership; przeprowadź test z TESTING.md. Fizyka wymaga testu w Studio. |
| VisitShop / DismountFirst | Zsiądź i podejdź do właściwego stanowiska; MENU nie omija odległości. |
| Money nie zapisuje się po Play | StudioMemory celowo resetuje profil. Włącz testowy DataStore zgodnie z instrukcją. |
| SessionLocked / SessionLost | Sprawdź Output i drugą aktywną sesję; po awarii może być potrzebne wygaśnięcie 180 s lease. Nie kasuj profilu. |
| Brak kolejnych nagród | Sprawdź wymagany dystans, cooldown i dzienne limity UTC. |

Kod edytuj w plikach. Zmiany zrobione tylko w Studio nie zapisują się automatycznie do repozytorium przez Rojo. Zatrzymuj Play przed aktualizacją skryptów: ponowne uruchamianie bootstrapów w trwającym teście może pozostawić stare połączenia i modele.
