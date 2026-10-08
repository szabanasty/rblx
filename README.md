# KUKIRIN ZONE — Roblox / Luau / Rojo

**Wersja 0.7.0: squad PvP, Kukiriny, łowienie, karnet i kod zakupów Robux.** Miasto Riverside, most nad rzeką i odległa arena Iron Island, fikcyjne wyposażenie arcade i oryginalne modele z części Roblox. Projekt nie wymaga zewnętrznych modeli, animacji ani audio. Inspiracja atmosferą FiveM nie oznacza kopiowania clowns.cool, GTA, map ani znaków firmowych.

Działają: strefy SAFE/COMBAT/FISHING, garaż z presetami, pięć klas hulajnóg i premium Volt Elite, bateria i ładowanie, ulepszenia 0–5, sklepy, kosmetyki, squad do czterech osób, pięć rodzajów wyposażenia i premium Flux Elite, walka serwerowa, combat tag, DOWNED, revive, respawn, nagrody/streak/bounty, punkt kontrolny drużyny, łowienie bez minigry, sprzedaż ryb, XP/poziomy, ranking aktualnego serwera, HUD, minimapa, przyciski dotykowe i ustawienia. Zapis obejmuje profil, kolekcje, statystyki, uprawnienia premium, rachunki produktów i limity ekonomii.

**Nowe: Workshop z działającym stanowiskiem wewnątrz, karnet 12 poziomów, VIP/kosmetyki/sloty oraz kredyty ulepszeń. Robux jest wyłączony do wpisania własnych ID ofert. [Dokładna instrukcja aktywacji i używania](docs/MONETIZATION.md).**

Kod został skompilowany, sprawdzony analizą typów i testami logiki. **Roblox Studio nie jest dostępne w środowisku Linux: rzeczywista fizyka, multiplayer, układ UI na urządzeniach i produkcyjny DataStore wymagają odbioru w Studio.** To prototyp do testowania, z placeholderami grafiki i pustą konfiguracją dźwięków/animacji; nie deklarujemy zakończonego wydania produkcyjnego.

## Uruchomienie na Windows

1. Zatrzymaj Play w Studio. W starym PowerShell zatrzymaj Rojo przez **Ctrl+C**.
2. [Pobierz aktualny ZIP](https://github.com/szabanasty/rblx/archive/refs/heads/main.zip), wypakuj do nowego folderu. Skopiuj folder `.tools` z `rojo.exe` ze starego projektu. Właściwy katalog zawiera obok siebie `default.project.json`, `src`, `README.md` i `.tools`.
3. Otwórz katalog w Eksploratorze Windows, kliknij pasek adresu, wpisz `powershell`, Enter. Konsola ma być w katalogu projektu, **nie w `.tools`**.
4. Uruchom:

   ```powershell
   .\.tools\rojo.exe serve default.project.json --address 127.0.0.1 --port 34872
   ```

   Zostaw okno otwarte. Oczekuj `Rojo server listening`, port `34872`.
5. Otwórz **nowy Baseplate** w Studio, aby stare skrypty miejsca nie działały równolegle. W ustawieniach doświadczenia ustaw Avatar na **R15**; model ma także podstawowy fallback dla R6.
6. **Dodatki plug-in / Plugins → Rojo → Connect**: adres `localhost`, port `34872`. Zaakceptuj synchronizację. Nie wpisuj `local`.
7. **Play / F5**. Mapa jest widoczna już po synchronizacji w edytorze. Play zastępuje podgląd interaktywnym światem i uruchamia HUD. W Output oczekuj `PHASE 10 ready (version 0.7.0)` na serwerze i kliencie. Nowy profil: Money 100, Level 1, Starter i wyposażony Spark.
8. Podejdź do żółtego stanowiska **ODBIERZ SWOJĄ HULAJNOGĘ** przed garażem i naciśnij E. Alternatywnie **MENU → Garage → PRZYWOŁAJ**; menu zamknie się automatycznie. Wsiadanie ponownie: E przy swoim pojeździe albo **Garage → WSIĄDŹ**. Steruj W/A/D, hamuj S, skacz Spacją; zejdź E albo przyciskiem ZEJDŹ. Dokładne klawisze wynikają z InputController; patrz tabela niżej.

Jeśli brakuje Rojo, [pobierz Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), plik `rojo-7.7.1-windows-x86_64.zip`, wypakuj `rojo.exe` do `.tools`. Wtyczkę instalujesz raz: `.\.tools\rojo.exe plugin install`, potem restart Studio. [Roblox Studio](https://create.roblox.com/). Git i Python nie są potrzebne do grania z ZIP-a.

Alternatywa bez aktywnej synchronizacji:

```powershell
.\.tools\rojo.exe build default.project.json --output rblx.rbxlx
```

Otwórz wynik w Studio, Play. Przed zmianą bootstrapów zatrzymuj Play; edycja wyłącznie w Studio nie zapisuje się do plików repozytorium.

Nowy HUD rozdziela informacje na osobne panele po ekranie. [Instrukcja multiplayera i układu HUD-u](docs/MULTIPLAYER.md).

Zobacz [zmiany i podglądy grafiki 0.6.0](docs/WORLD_060.md). Podglądy są renderami rzeczywistej wygenerowanej geometrii w Blenderze, nie zrzutami Roblox Studio.

## Pierwsze aktywności

| Miejsce / działanie | Jak użyć |
| --- | --- |
| Garaż, SAFE (-180, -58) | Wybór, spawn/despawn i ładowanie hulajnogi po zejściu. Spawn jest dostępny z menu; zakupy/ładowanie wymagają pobliskiej stacji. |
| Dealer (-80, -58) / Workshop (30, -58) | Zakupy według Money/Level, wewnętrzny stół E, sześć kategorii ulepszeń, statystyki przed/po; pierwszy silnik 75 Money lub jeden kredyt. |
| Equipment (145, -58) | Kup oryginalne wyposażenie, załóż do PRIMARY/SECONDARY/UTILITY w SAFE. |
| Cosmetics (-180, 145) | Kolory części, placeholdery efektów/naklejek, kamizelki i tagi. Nie zwiększają statystyk. |
| Pomost FISHING (-340, 355) | Zejdź z hulajnogi, użyj E/native prompt lub MENU → FishBuyer → ŁÓW. Po 18–28 s serwer losuje wynik. STOP ŁOWIENIA kończy sesję. |
| FISH BUYER (-340, 285) | Podejdź pieszo; sprzedaj pojedynczą rybę lub wszystkie. Serwer ustala cenę; przy limicie wypłaty inventory zostaje. |
| COMBAT, środek (1050, 0) | Walka z graczem z innego squad/solo. Friendly fire wyłączone. Combat tag trwa 20 s również po wejściu do SAFE. |
| CONTROL POINT (1050, 0) | Dwóch członków jednego squad przez 30 s, bez przeciwnika, pieszo: po 150 Money; cooldown 180 s. |
| Squad | MENU → Squad → UTWÓRZ, zaproś obecnego gracza; ma 30 s na AKCEPTUJ. Maksimum 4. |
| DOWNED | Health 0: 60 s oczekiwania. Teammate trzyma E/OCUĆ przez 5 s w zasięgu 10 studów bez ściany; wracasz z 35 HP. |

Eliminacja/nagroda zostaje rozliczona po definitywnym respawnie/reset/logout, a nie samym DOWNED. Udany revive anuluje tę eliminację. Ponowne pokonanie tego samego przeciwnika w 10 minut daje mnożniki Money/XP 100%, 50%, 25%, 0%. Cooldown nagrody revive tej samej pary: 180 s. Limity dzienne i historia par są w profilu, więc ponowne wejście nie resetuje ograniczeń. Streak bieżącej sesji resetuje się przy DOWNED/nowej sesji; BestStreak zostaje.

| PC | Telefon/tablet |
| --- | --- |
| W: gaz; S: hamulec; A/D: skręt; Space: skok; E: zejście/interakcja/revive | GAZ, HAMULEC, ◀, ▶, SKOK, ZEJDŹ; natywny prompt interakcji |
| LMB: fire; RMB: aim; R: reload; 1/2/3: slot | FIRE, AIM, RELOAD, SWITCH |
| MENU: ustawienia, sklepy i inventory | Duże przyciski, przewijane menu; MAPA na wąskim ekranie |

Przejdź przez [pełną checklistę Studio](docs/TESTING.md) po pobraniu. Hulajnogi mają szczegółowe własne modele z części: zawieszenie, tarcze, manetki, światła i dashboard. R15 korzysta z proceduralnej pozy IK rąk/stóp; jej zasięg i wygląd przy różnych avatarach trzeba odebrać w Studio. R6 zachowuje natywną pozycję siedzącą. W salonie modele są wystawowe — własny pojazd odbierz przed garażem.

## Kod i zapis

| Repozytorium | Roblox Studio |
| --- | --- |
| `src/server/init.server.luau` | `ServerScriptService.Server` — Script |
| `src/server/Services`, `src/server/Modules` | `ServerScriptService.Server.Services/Modules` — ModuleScripts |
| `src/client/init.client.luau` | `StarterPlayer.StarterPlayerScripts.Client` — LocalScript |
| `src/client/Controllers`, `src/client/Modules` | `…Client.Controllers/Modules` — ModuleScripts |
| `src/shared` | `ReplicatedStorage.Shared` — Config, Types, Modules |
| HUD przy Play | `Players.<Nazwa>.PlayerGui.KukirinZone` i pomocnicze GUI kontrolerów |
| Wygenerowany świat przy Play | `Workspace.Map.ZoneGenerated`, hulajnogi w `Workspace.Vehicles` |

W Studio domyślny **StudioMemory** resetuje profil po Stop. Produkcja używa natywnego DataStore, autosave 60 s, zapisu przy wyjściu/zamknięciu, retry i odnawianej blokady sesji 180 s. Klient nie zapisuje profilu. Nieudany load nie zakłada pustego profilu nad istniejącymi danymi; utrata sesji blokuje mutacje.

Test prawdziwego zapisu: opublikuj **osobne doświadczenie testowe**; w ustawieniach Security włącz **Enable Studio Access to API Services**. W GameConfig ustaw `UseStudioDataStore = true` i `DataStoreName = "KukirinZone_DEV_v1"`. Zsynchronizuj po Stop, kup rzecz/zmień skalę, odczekaj autosave, wyjdź i wróć. Potem przywróć domyślne wartości. Nie testuj na magazynie produkcyjnych graczy.

Zachowano dotychczasowe ID hulajnóg, nazwę `KukirinCity_PlayerData_v1` i schemat 1. Sanitizer dodaje pola do starszych profili; obecne Money/XP/kolekcje nie są celowo usuwane. Legacy city/quest/traffic i PHASE 0 pozostają opcjonalnymi, wyłączonymi trybami; domyślnie `FoundationOnly = false`, `ZoneGame = true`.

## Testy i dokumentacja

```bash
cd /workspace/rblx
bash scripts/install-tools.sh
python3 scripts/check-project.py
```

Rojo 7.7.1, Luau 0.741, luau-lsp 1.70.1 z API Roblox, instalacja TLS/SHA-256. Runner sprawdza **92 źródła**, typy, build/sourcemap, wszystkie mapowania klas, 4 remotes, StreamingEnabled i **25 zestawów testów** logiki z mockami API. CI korzysta z tego samego runnera. To nie jest test silnika.

- [Robux, karnet i Workshop — aktywacja ofert](docs/MONETIZATION.md)
- [Architektura i zależności](docs/ARCHITECTURE.md)
- [Wszystkie pliki i położenie w Studio](docs/FILES.md), [Explorer](docs/EXPLORER.md)
- [Stan implementacji, naprawy i ograniczenia](docs/IMPLEMENTATION.md)
- [Testy i możliwe błędy](docs/TESTING.md)
- [Placeholdery i ręczna konfiguracja](docs/ASSETS.md), [dalszy rozwój](docs/ROADMAP.md)
- [Oryginalna specyfikacja](docs/SPEC_ZONE.md)

## Rozwiązywanie problemów

| Objaw | Co zrobić |
| --- | --- |
| `rojo.exe is not recognized` | `Test-Path .\default.project.json` i `Test-Path .\.tools\rojo.exe` mają zwracać True. Jeśli jesteś w `.tools`, wykonaj `cd ..`. |
| `Couldn't connect to the Rojo server` | Uruchom serve w nowym katalogu, pozostaw PowerShell otwarty; wtyczka localhost:34872. Sprawdź, czy stare Rojo nie zajmuje portu. |
| PHASE 0 / stary HUD / stare miasto | Stary ZIP, proces Rojo albo pozostałe skrypty. Nowy katalog i nowy Baseplate, Connect/synchronizacja, Play. |
| W edytorze pusta plansza | Sprawdź ScenePreview po synchronizacji; interakcje i UI uruchamia Play. Sprawdź Output, Server.Services.ZoneWorldService i Client.Controllers.ZoneUIController. |
| Postać chwilowo cofana | MovementGuard odrzuca teleport/speed/flight; tolerancje wymagają próby przy rzeczywistym pingu, rampach i dismount. Pojedyncza flaga nie wyrzuca gracza. |
| Nie można kupić / sprzedać / łowić | Podejdź do odpowiedniego stanowiska, zejdź, poczekaj aż tag wygaśnie; sprawdź Money/Level/limit dzienny/inventory. |
| Brak nagrody po DOWNED | Czeka na definitywną eliminację; revive ją anuluje. Następne eliminacje tej samej pary mają malejące nagrody. |
| `SessionLocked` / `SessionLost` | Druga sesja albo utracony lease; sprawdź Output. Po awarii może być potrzebne wygaśnięcie 180 s. Nie kasuj profilu. |
| Cisza / brak animacji jazdy | ID assetów są puste; wymagane własne lub legalnie udostępnione pliki, opisane w ASSETS. |
