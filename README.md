# KUKIRIN ZONE — Roblox / Luau / Rojo

**Wersja 0.4.0, PHASE 0 — FOUNDATION.** Kukiriny zostają. Nowy kierunek to własna gra arcade PvP: drużyny, Safe Zone, Combat Zone, łowienie i progresja garażu. Inspiracja atmosferą serwerów FiveM; własne zasady, kod, mapa i assety. Dokładne wytyczne: [SPEC_ZONE.md](docs/SPEC_ZONE.md).

W tej fazie działają: ładowanie profilu, serwerowa ekonomia jako API dla przyszłych usług, blokady sesji i zapis, walidowana komunikacja, snapshot danych, obserwacja zdrowia Roblox, prosty HUD oraz zmiana skali HUD. **Nowa mapa, jazda, walka, squady i łowienie nie są jeszcze uruchomione.** Dawny kod miasta pozostaje w repozytorium jako materiał do dalszych etapów, ale bootstrap go nie uruchamia. Stare dane nie są celowo kasowane.

## Uruchomienie na Windows — krok po kroku

1. W Roblox Studio kliknij czerwony **Stop**, jeżeli trwa test. W starym oknie PowerShell zatrzymaj Rojo przez **Ctrl+C**.
2. [Pobierz aktualny ZIP projektu](https://github.com/szabanasty/rblx/archive/refs/heads/main.zip). Wypakuj do nowego folderu. Skopiuj folder `.tools` zawierający `rojo.exe` ze starego projektu do nowego. Właściwy folder ma obok siebie `default.project.json`, `src`, `README.md` i `.tools`.
3. Otwórz ten folder w Eksploratorze Windows. Kliknij pasek adresu u góry, wpisz `powershell` i naciśnij Enter. Konsola ma być w folderze projektu, **nie wewnątrz `.tools`**.
4. Wklej polecenie i naciśnij Enter:

   ```powershell
   .\.tools\rojo.exe serve default.project.json --address 127.0.0.1 --port 34872
   ```

   Zostaw konsolę otwartą. Powinno być `Rojo server listening`, adres `127.0.0.1`, port `34872`.
5. W Studio otwórz nowy **Baseplate**. Dzięki temu wcześniejsze ręczne skrypty i modele nie pomieszają się z nową wersją. Nie musisz ręcznie tworzyć folderów ani wklejać kodu.
6. U góry kliknij **Dodatki plug-in / Plugins → Rojo**. Jeśli wtyczka pamięta stary serwer, rozłącz ją. Wpisz adres `localhost` i port `34872`. Kliknij **Connect**, następnie zaakceptuj proponowaną synchronizację drzewa. Nie wpisuj `local`.
7. Kliknij **Play / F5**. Otwórz **Wyświetl / View → Wyjście / Output**. W nowym interfejsie Studio możesz też wyszukać panel Output.
8. Oczekiwany rezultat: płaska plansza, spawn, postać i panel **KUKIRIN ZONE • PHASE 0**. Nowy profil pokazuje **Money 100**, po załadowaniu postaci **Health 100/100**, **ALIVE**, zerowe statystyki oraz `Studio: pamięć testowa`. Tekst `Strefy w PHASE 1` jest poprawny: detekcja stref będzie dopiero w następnej fazie. Serwer i klient logują `PHASE 0 ready (version 0.4.0)`.
9. Kliknij **OPCJE → 125%**, sprawdź zmianę wielkości panelu, a potem **100%**. Kliknij **ODŚWIEŻ DANE**, zamknij opcje. Zresetuj postać z menu Roblox i sprawdź, czy panel ponownie pokazuje Health 100/100.

Jeżeli nie masz `rojo.exe`, pobierz [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), archiwum `rojo-7.7.1-windows-x86_64.zip`, i wypakuj plik do `.tools`. Wtyczkę instalujesz raz, poleceniem `.\.tools\rojo.exe plugin install`, następnie restartujesz Studio. Studio jest na [oficjalnej stronie Roblox](https://create.roblox.com/). Python i Git nie są potrzebne do tego testu na Twoim PC.

Jeśli połączenie nadal nie działa, w PowerShell sprawdź `Test-Path .\default.project.json` oraz `Test-Path .\.tools\rojo.exe` — obie odpowiedzi mają być `True`. Sprawdź, czy drugie okno Rojo nie zajmuje portu. Zbudowanie miejsca bez połączenia jest alternatywą:

```powershell
.\.tools\rojo.exe build default.project.json --output rblx.rbxlx
```

Otwórz wynik `rblx.rbxlx` w Studio i kliknij Play. Synchronizacja zmian nadal wymaga `rojo serve`.

## Gdzie jest kod

| Pliki repozytorium | Miejsce w Roblox Studio |
| --- | --- |
| `src/server/init.server.luau` | `ServerScriptService.Server` — Script |
| `src/server/Services/*.luau` | `ServerScriptService.Server.Services` — ModuleScripts |
| `src/server/Modules/*.luau` | `ServerScriptService.Server.Modules` — ModuleScripts |
| `src/client/init.client.luau` | `StarterPlayer.StarterPlayerScripts.Client` — LocalScript |
| `src/client/Controllers/*.luau` | `…Client.Controllers` — ModuleScripts |
| `src/client/Modules/*.luau` | `…Client.Modules` — ModuleScripts |
| `src/shared/*` | `ReplicatedStorage.Shared` — Config, Types, Modules, ProjectInfo |
| `default.project.json` | Tworzy Remotes, bazową planszę i puste foldery mapy/modeli |
| HUD podczas Play | `Players.<TwojaNazwa>.PlayerGui.ZoneFoundation` |

Pełne [drzewo Explorer](docs/EXPLORER.md), [lista wszystkich źródeł](docs/FILES.md) i [lista zmian tej fazy](docs/PHASE_0_FILES.md). Nie przenoś Services poza Server ani Controllers poza Client. UI powstaje kodem, więc StarterGui nie wymaga ręcznej konfiguracji. Rojo wysyła pliki do Studio; edycje zrobione tylko w Studio nie zapisują się automatycznie w repozytorium.

## Zapis danych

Domyślnie Studio działa w trybie **StudioMemory**. Stop usuwa pamięć testu, kolejny Play zaczyna od domyślnych danych. Komunikat o zatwierdzeniu ustawienia oznacza jego przyjęcie do profilu; dopiero udany save zapisuje je trwale. W opublikowanej grze działa DataStore: autosave co 60 s, zapis przy wyjściu/zamknięciu, retry i blokada sesji odnawiana przed wygaśnięciem 180 s. Nie udało się sprawdzić prawdziwego backendu Roblox w chmurze.

Zachowaliśmy `DataStoreName = "KukirinCity_PlayerData_v1"`, wersję schematu 1 i stare ID hulajnóg. Nowe pola są uzupełniane podczas ładowania istniejącego profilu. Money, XP i kolekcje pozostają kompatybilne. Dawna ekonomia jazdy i questy nie przyznają nagród w PHASE 0.

Test trwałego zapisu wykonaj na **osobnym opublikowanym doświadczeniu testowym**:

1. **Plik / File → Publish to Roblox** — opublikuj osobny test.
2. **Game Settings → Security → Enable Studio Access to API Services** — włącz.
3. W `src/shared/Config/GameConfig.luau` ustaw `UseStudioDataStore = true` i `DataStoreName = "KukirinZone_DEV_v1"`. Zatrzymaj Play, zsynchronizuj pliki.
4. Play → OPCJE → 125%, odczekaj autosave lub zakończ test. Uruchom ponownie i sprawdź 125%, Money 100 i poprawny status DataStore. Po zatrzymaniu zaczekaj na zakończenie zapisu poprzedniej sesji.
5. Po teście przywróć `UseStudioDataStore = false` i pierwotną nazwę magazynu. Nie podłączaj prób Studio do profili graczy produkcyjnych.

Nie udostępniamy klientowi mutacji Money ani Health. Błąd ładowania produkcyjnego nie zakłada pustego profilu; utrata blokady odbiera dostęp do danych. Blokady i retry wymagają odbioru w prawdziwym doświadczeniu i nie gwarantują zapisu podczas awarii infrastruktury.

## Testy i dalszy rozwój

```bash
cd /workspace/rblx
bash scripts/install-tools.sh
python3 scripts/check-project.py
```

Przypięte narzędzia: Rojo 7.7.1, Luau 0.741 i luau-lsp 1.70.1 z API Roblox, pobierane z kontrolą TLS i SHA-256. Runner kompiluje i analizuje typy **50 źródeł**, buduje miejsce, sprawdza kompletne mapowanie, streaming, remotes i puste foldery oraz uruchamia **11 zestawów testów Luau**. Są to testy logiki i mocki API, nie test Play w silniku. CI korzysta z tego samego runnera.

- [ARCHITECTURE.md](docs/ARCHITECTURE.md): moduły, zależności, schemat i bezpieczeństwo.
- [TESTING.md](docs/TESTING.md): dokładna checklista PHASE 0, multiplayer, mobile i zapis.
- [ROADMAP.md](docs/ROADMAP.md): fazy 0–10 zgodnie z nową specyfikacją.
- [ASSETS.md](docs/ASSETS.md): obecne placeholdery i późniejsze czynności w Studio.

**Zatrzymujemy rozwój po PHASE 0 do potwierdzenia testu w Studio.** Następny etap to własna kompaktowa mapa i działająca detekcja Safe/Combat/Fishing Area. Nie ma jeszcze ochrony Safe Zone ani combat tagu: w tej fazie system walki nie istnieje.

## Najczęstsze problemy

| Objaw | Rozwiązanie |
| --- | --- |
| `rojo.exe is not recognized` | Konsola jest w złym folderze lub plik nie znajduje się w `.tools`. Sprawdź obie ścieżki z `Test-Path`. |
| `Couldn't connect to the Rojo server` | Uruchom lokalnie polecenie z kroku 4, zostaw PowerShell otwarty, ustaw `localhost` i `34872` w Studio. |
| Log `Sync ready` / `Core ready 0.3.0`, stare miasto | Masz stary ZIP, stary serwer Rojo albo stare skrypty miejsca. Użyj nowego Baseplate i nowego folderu projektu. |
| Brak HUD | Użyj Play, sprawdź Client.Controllers.FoundationController oraz błędy w Output. |
| Puste foldery CombatZone/FishingArea | To zaplanowane kontenery; geometria i detekcja dopiero w PHASE 1. |
| Ustawienia znikają po Stop | StudioMemory celowo resetuje profil; test DataStore opisano powyżej. |
| `SessionLocked` / `SessionLost` | Sprawdź Output i drugą sesję; po awarii może być potrzebne wygaśnięcie 180 s blokady. Nie kasuj profilu. |

Zatrzymuj Play przed zmianą skryptów i ponowną synchronizacją bootstrapów.
