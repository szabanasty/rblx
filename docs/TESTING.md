# Testy PHASE 0

## Faktycznie wykonane w chmurze Linux

`python3 scripts/check-project.py`: kompilacja 50 źródeł, analiza typów Luau z API Roblox i sourcemap, Rojo build/sourcemap, kompletne klasy/treść/mapowanie źródeł, 4 RemoteEvents, StreamingEnabled oraz 10 pustych folderów przygotowawczych. 11 zestawów testów rzeczywistych modułów Luau, z mockami tylko zależności Roblox.

| Zestaw | Co sprawdza |
| --- | --- |
| shared | Progresja, sanitizacja, NaN/Infinity, payloady, token bucket |
| player-data | UpdateAsync, sesje, load/save retry, save konkurencyjny, utrata blokady, cleanup |
| economy | Serwerowe transakcje, nagrody, saldo, XP, budżety i powtórne ID |
| network | Format, limiter, replay/cooldown, cleanup; PHASE 0 blokuje jazdę/zakupy i dopuszcza ustawienia/Sync |
| snapshot | Tylko własny profil, kopie, prywatny ledger i session poza projekcją |
| input | Regresja starszego sterowania, reset i mobilne intencje — nieaktywne w PHASE 0 |
| shop | Regresja ownership, odległości, Level/Money i upgrades 0–5 — nieaktywne w PHASE 0 |
| quest | Regresja nagród, dystansu, czasu, ponownego zakończenia — nieaktywne w PHASE 0 |
| world-stats | Regresja układu dróg, statystyk i wszystkich 5-poziomowych kombinacji |
| foundation | Addytywna migracja starych profili, nowe pola/liczniki, inventory cap, brak ceny ryby z zapisu, nieaktywne katalogi, snapshot bez usług gry |
| player-state | Health, reset, opóźniony Humanoid starej postaci, izolacja graczy, odłączenie zdarzeń |

Dodatkowy test `scripts/check-rojo-server.py --check-reload` odczytuje API MessagePack działającego Rojo, sprawdza źródła/klasy/remotes/streaming i rzeczywistą reakcję watchera na tymczasowy komentarz (przywracany). Nie uruchamia gry w silniku.

Wykryte i poprawione przy zmianie: bootstrap/snapshot zakładały zawsze istniejący Scooter/World; nowy tryb ładuje wyłącznie fundament i projekcja obsługuje brak usług. Dawne żądania klienta mogły sięgać nieaktywnych usług; serwer odrzuca je przed dispatch. Stare profile nie miały nowych pól; sanitizacja uzupełnia je bez resetu. Asynchroniczny Humanoid wymaga weryfikacji generacji postaci, aby po resecie nie nadpisać nowego stanu. Analiza typów wymagała jawnej tablicy `{string}` dla kolejności modułów i pomocniczego predicate dla zakresu akcji. Testy regresji zaktualizowano do 0–5 upgrade zamiast osłabiać walidację.

## Checklista użytkownika — Play

Najpierw wykonaj instrukcję [README](../README.md). Wszystko poniżej wymaga Roblox Studio, do którego chmura nie ma dostępu.

- [ ] Rojo wyświetla listening 127.0.0.1:34872, Studio łączy się z localhost:34872.
- [ ] W Explorer jest kompletne [drzewo](EXPLORER.md), w tym PlayerStateService i FoundationController. Nie twórz drugiego Script o podobnej nazwie.
- [ ] Play/F5 uruchamia gracza, a serwer i klient wypisują `PHASE 0 ready (version 0.4.0)` bez czerwonych błędów.
- [ ] Widać płaską planszę, spawn i panel KUKIRIN ZONE. Nie pojawia się stare miasto/garaż/sterowanie.
- [ ] Nowy profil: Money 100, Health 100/100, ALIVE, Kills/Deaths/Assists/Revives 0. Profil istniejący może mieć wcześniejsze saldo.
- [ ] Status po ładowaniu wskazuje StudioMemory / pamięć testową; `Strefy w PHASE 1` oraz squad nieaktywny są zamierzone.
- [ ] OPCJE → 75/100/125/150% zmienia panel, ODŚWIEŻ DANE nie zmienia Money, ZAMKNIJ działa.
- [ ] Reset Character: przejście do RESPAWNING, potem Health 100/100 i ALIVE; HUD nie znika i nie powiela się.
- [ ] Stop/Play w StudioMemory resetuje skalę i profil. To oczekiwane, nie utrata produkcyjnych danych.

## Multiplayer i mobile

1. Zatrzymaj Play. **Test → Server & Clients**, wybierz 2 klientów i Start (nazwy zależą od języka/układu Studio).
2. Każdy klient dostaje własny panel. W jednym zmień skalę; drugi zachowuje swoją. Reset jednego gracza nie zmienia Health drugiego. Money obu nowych profili 100, bez nagród za bezczynność/chodzenie.
3. Powtórz na 4 klientach. Sprawdź brak błędów ładowania i cleanup po zamknięciu klienta. To nie test squadu: squady powstaną w PHASE 4.
4. **Test → Device Emulator**: telefon pionowo/poziomo i tablet. Sprawdź czy panel i OPCJE mieszczą się, ustawienia można przewijać i obsługiwać palcem. W razie włączonej emulacji dotyku sprawdź konflikt z przyciskami natywnego awatara.
5. Symuluj opóźnienie sieci w ustawieniach testu, jeśli opcja dostępna: UI ma czekać na dane zamiast generować saldo lokalnie. Podczas resetu Health może krótko pokazywać oczekiwanie.

## Ręczny test ochrony sieci — tylko własny test

W konsoli **klienta** podczas Play można wysłać:

```luau
game.ReplicatedStorage.Remotes.Action:FireServer({Action = "SpawnScooter", Payload = {}, RequestId = 1000})
```

Oczekiwane: komunikat o niedostępnej fazie, brak hulajnogi i zmiany Money. Po tym teście zrestartuj Play: numer 1000 celowo podnosi LastId, więc normalne niższe ID z UI będą odrzucane.

Próby `Action="SetMoney"`, `Payload={Name="Money",Value=999999}` dla SetSetting, nieprawidłowego RequestId i powtórzonego ID muszą być odrzucone. Nie spamuj produkcyjnego serwera. Serwer nie kickuje za jeden sygnał. Brak gameplayu oznacza, że nie testujemy jeszcze raycast/teleport/farming, hitów ani bezpiecznej strefy. Nie deklarujemy pełnego anti-cheatu awatara.

## Trwały zapis

Na osobnym opublikowanym doświadczeniu: Game Settings/Security API Services, `UseStudioDataStore=true`, osobna nazwa `KukirinZone_DEV_v1`. Procedura w README. Sprawdź powrót UIScale po Stop/Play, wyjściu z serwera, autosave po 60 s i zamknięciu serwera. Sprawdź logi błędów oraz blokadę dwóch prób tego samego profilu. Nie kasuj locka/profilu w odpowiedzi na błąd. Sprawdzenie migracji prawdziwej kopii danych powinno używać testowego magazynu, nie produkcyjnego zapisu.

## Czego jeszcze nie sprawdzono

Silnik Studio/Play, realny klient-serwer i streaming, wygląd dotykowego HUD, domyślna kamera/respawn, produkcyjny DataStore i zachowanie podczas awarii, zdalny CI. Nie zostały potwierdzone przez testy chmurowe. Fizyka nowej hulajnogi, walka, revive, squady i fishing nie są jeszcze zaimplementowane w nowym trybie. Po odbiorze PHASE 0 przechodzimy do PHASE 1.
