# Testy wersji 0.3.0

## Automatyczne — dostępne bez Studio

`bash scripts/install-tools.sh` i `python3 scripts/check-project.py`.

Runner testuje **rzeczywiste źródła** usług i kontrolera wejścia, owinięte lokalnie w funkcję przyjmującą kontrolowane mocki. Wygenerowane harnessy nie trafiają do gry. Moduły czyste są bezpośrednio require'owane. Nie emuluje to fizyki, GUI ani backendu Roblox.

| Obszar | Co jest sprawdzane |
| --- | --- |
| Kompilacja i typy | Wszystkie src/*.luau, definicje API Roblox, require resolution z sourcemap |
| Rojo | Build, sourcemap, klasy Script/LocalScript/ModuleScript, źródła, cztery RemoteEvents, StreamingEnabled |
| Shared | Schemat i kopie profilu, NaN/inf, krzywa XP, maksymalny level, whitelist i token bucket |
| PlayerData | Failed load bez nadpisania, foreign lock, lease i jego utrata, autosave bez mutacji, retry, leave/shutdown, utracone potwierdzenie zapisu |
| Economy | Ujemne/niecałkowite/infinite kwoty, saldo, idempotencja, limity Money/XP/Reputation, nagroda awansu w limicie, maksymalny level, bounded ledger, zweryfikowany dystans |
| Network | Brak akcji Reward, replay RequestId, ustawienia tylko z whitelist, flood 500 żądań, niezależne limity Input/Action, shutdown i cleanup |
| Snapshot | Własny stan publiczny, kopie kolekcji i preferencji, brak tokenów/ledger/flag anti-cheatu |
| Input | Priorytet nad sterowaniem Roblox, wyłączenie natywnego skoku podczas jazdy, gaz/hamulec/skręt, jednorazowy skok, focus loss, touch, pisanie, menu, przywrócenie sterowania |
| Shop | Katalog i serwerowa cena, własność/poziom/środki, brak podwójnego zakupu, odległość, zsiadanie, max upgrade, odświeżenie statystyk, zablokowana bateria |
| Quest | Hub, jeden quest, minimalny czas/dystans, Riding, promień i wysokość celu, automatyczny reward raz, persistent cooldown, cancel/start spam, timeout/leave |
| World/statystyki | Dziesięć dróg, limity i skrzyżowania, granice, 13 dzielnic, wpływ upgrade, niezmienność katalogu, niepoprawne zapisane poziomy |

Wyjście kodu 0 oznacza zaliczenie dostępnych testów. Ostrzeżenie luau-lsp o `didChangeWatchedFiles` pochodzi z trybu CLI i nie jest błędem typów. GitHub Actions uruchamia ten sam runner; zdalny wynik CI nie jest automatycznie potwierdzony przez lokalny test.

Serwer Rojo można dodatkowo sprawdzić przez `python3 scripts/check-rojo-server.py --check-reload` (wymaga pakietu Python `msgpack`, dostępnego w chmurze; poza nią zainstaluj `python3 -m pip install -r requirements-dev.txt`). Sprawdza wszystkie 41 źródeł w żywym drzewie API, klasy i remotes oraz zmianę pliku i przywrócenie jego treści. Jest to test protokołu Rojo i file watchera; nie jest połączeniem z uruchomionym Studio.

## Ręczny odbiór w Roblox Studio — wymagany

Ta lista jest instrukcją **do wykonania**, a nie deklaracją przeprowadzonych testów.

1. **Start:** zsynchronizuj nowy ZIP, Play, sprawdź dwie linie Core ready i brak czerwonych błędów. W widoku serwera sprawdź Map.Generated oraz Vehicles. Zwykłe modele miejskie mają być statyczne; runtime scene nie musi istnieć przed Play.
2. **Pierwsza jazda:** GARAŻ → PRZYWOŁAJ, E jeśli auto-mount nie zadziała, W/A/D/S. Bez upgrade prędkość G2 powinna zatrzymać się około 35 km/h. Space ma skakać hulajnogą, E pozwalać zejść; powrót na piechotę przywraca normalny skok i sterowanie Roblox. Sprawdź rampę, kolizję z budynkiem i hamowanie.
3. **Ruch i naliczanie:** przejedź więcej niż 250 m. Sprawdź +25 Money/+15 XP, brak nagrody stojąc, brak ponownego naliczenia po otwarciu menu lub schowaniu pojazdu. Zweryfikuj XP rollover i nagrodę awansu.
4. **Lifecycle:** przywołaj kilka razy, sprawdź jeden model własny, cooldown 3 s, śmierć/respawn/despawn/wyjście sprzątają model. Zejdź przy spawnie, upewnij się, że hulajnoga hamuje bez inputu.
5. **Upgrades:** za pierwsze 125 Money kup silnik w punkcie UPGRADE. Sprawdź poziom 1 i +2 km/h aktywnego pojazdu. Próba level 2 przy Level 1 ma odmówić. Nieposiadanej G4 nie można ulepszyć; bateria ma status WKRÓTCE i nie pobiera pieniędzy.
6. **Dostawa:** punkt DOSTAWY → zadanie; jedź na zielony marker minimapy. Wymagany dystans i czas. Powinien nastąpić jeden reward i cooldown 120 s. Sprawdź timeout 180 s, anulowanie oraz brak ukończenia pieszo.
7. **Świat:** przejedź Residential/City/MainRoad/Highway, obserwuj limity 30/50/70/90 i bardziej restrykcyjny limit na skrzyżowaniu. Obejrzyj NPC zatrzymujące się przed węzłami i cały cykl 20 minut; przyspieszenie cyklu do testu zmień wyłącznie w WorldConfig i przywróć po teście. NPC są bezkolizyjnymi placeholderami.
8. **Mobile:** Test → Device Emulator, telefon portrait, telefon landscape i tablet. Sprawdź widoczność HUD/menu/minimapy, scrolling, dwa palce gaz+skręt, skok i zejście, zmianę UI Scale, menu hamujące i brak zablokowanego gazu. Potem użyj prawdziwego telefonu: emulator nie potwierdza wydajności urządzenia.
9. **Multiplayer:** Test → Server & Clients → 2 Players. Każdy ma osobny profil i własną hulajnogę; nie można dosiąść cudzej ani schować jej za kogoś. Sprawdź równoległe dostawy i widoczność modeli drugiego gracza.
10. **Zapis:** osobne opublikowane doświadczenie, osobny DataStoreName `_DEV`, API access i UseStudioDataStore=true. Zarób i ulepsz, Stop i ponowne Play/rejoin. Sprawdź Money/XP/Level/upgrade/Settings/QuestCooldown. Po testach wróć do pamięci Studio. Nie testuj na magazynie produkcyjnym.
11. **Bezpieczeństwo:** w widoku klienta podczas testu spróbuj przesłać Action="Reward" lub Input z NaN/Speed — profil ma pozostać bez zmian. Nie istnieje endpoint FinishQuest ani SetMoney. Używaj wyłącznie testowego miejsca. Nie oceniaj wykrywania teleportów i ownership bez obserwacji rzeczywistego serwera.
12. **Koszt:** Developer Console/MicroProfiler, serwer dwóch graczy oraz telefon; sprawdź FPS, pamięć, network i raycast cost. Dopiero wtedy zwiększ limit graczy/NPC lub wielkość mapy.

Przed wydaniem trzeba potwierdzić zachowanie przy realnym opóźnieniu sieci i throttlingu DataStore. Mocks nie dowodzą braku exploitów ani dobrej jazdy pod obciążeniem. Ewentualny błąd zgłaszaj z komunikatem Output, nazwą systemu i sekwencją czynności.
