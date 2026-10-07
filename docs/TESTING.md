# Testy wersji 0.6.0

## Faktycznie wykonane w chmurze

`python3 scripts/check-project.py`: kompilacja 82 prawdziwych źródeł Luau, analiza typów z API Roblox, Rojo build i sourcemap, porównanie Source/klasy/ścieżki każdego pliku, 4 RemoteEvents, StreamingEnabled oraz 10 pustych kontenerów statycznych. Statyczny build ma także ScenePreview, porównany z 1092 częściami eksportu źródłowej geometrii. Przy Play podgląd zastępowany jest modułowym światem z interakcjami.

18 uruchomionych zestawów: shared, player-data, economy, network, snapshot, input, shop, quest, world-stats, foundation, player-state, scooter-mount, scooter-pose, zone-rules, zone-economy, zone-gameplay, zone-fishing, zone-world. Testy usług wykonują rzeczywisty kod usług z mockami granic API, a nie kopie implementacji. Nie emulują fizyki ani pełnej semantyki Roblox.

Nowe scenariusze obejmują: tag po przekroczeniu SAFE, Health/DOWNED/protection, friendly fire, cover raycast, cooldown/ammo/reload, release/keepalive revive, once settlement, assist/streak/bounty, malejące nagrody, anti-farm po ponownym załadowaniu profilu, exact-credit daily caps, sprzedaż bez utraty ryb przy odmowie, stale revision, AFK/full inventory, teleport/rolling speed/flight, zwykłe mount/dismount, objective contested/2-player/cooldown, ścisłe requesty Shoot/Revive/Sell, replay, spam i UserId ponad 2 miliardy. Stare suite'y obejmują sesję/zapis/retry/lost lock, upgrade, input i kompatybilność schematu.

`PYTHONPATH=/workspace/.tools/python python3 scripts/check-rojo-server.py --check-reload`: odczyt żywego API Rojo, porównanie wszystkich 82 źródeł, remotes i streamingu, chwilowa zmiana ProjectInfo dociera do API, potem oryginał przywrócony i sprawdzony. Test przeprowadza synchronizację do Rojo, nie połączenie z Roblox Studio.

## Odbiór w Roblox Studio — do wykonania

1. Nowy Baseplate, aktualny ZIP, serve/Connect/Play według README. Sprawdź Output: 0.6.0, brak czerwonych błędów. Po 1 s Movement daje zgodę na aktywności.
2. SAFE ma rzeczywiste otwarte sklepy/garage/workshop/equipment/cosmetics; wejdź przez środkowe drzwi. COMBAT znajduje się na X800–1300 za mostem X410–630 i ma magazyny, kontenery, cover, rampy i control point. FISHING ma pomost i buyer. Mapa jest widoczna w edytorze, a interakcje powstają przy Play; stare puste foldery są kontenerami ręcznych dekoracji.
3. Garaż: Pickup E przed garażem oraz menu spawn/sit, ponowne E/WSIĄDŹ, W/A/D, S hamulec, Space skok, E zejdź, schowaj/ponownie przywołaj. Bateria nie uzupełnia się przez respawn modelu. Podejdź po zejściu do garażu i naładuj. Sprawdź zderzenia, rampę, skok i prowadzenie przy słabszym FPS/pingu.
4. Fish dock: rozpocznij, odczekaj 18–28 s, następne próby losowane przez serwer; inventory rośnie przy sukcesach, brak minigry. STOP i przejdź do buyer. Sprzedaj 1/all, Money rośnie według wartości fish. Ponowne użycie tej samej starej revision nie sprzedaje nic drugi raz.
5. Za Money kup Motor upgrade i kosmetyk przy odpowiedniej stacji. Za mało Money, zły Level, poza zasięgiem lub combat tag → odmowa bez zmiany kolekcji. Zakupy droższych modeli wymagają progresji.
6. **Server & Clients / Start Server z 2 klientami**: w COMBAT naprzeciwko siebie, strzel Spark. LMB/RMB/R, sloty1/2/3, amunicja maleje; ściana blokuje trafienie, daleki cel poza range nie dostaje damage. Safe bez tagu nie przyjmuje damage. Po trafieniu tag20s pozostaje po wejściu Safe; spawn protection3s i revive protection2s.
7. DOWNED po odpowiednich trafieniach: HUD Health0, 60s, brak jazdy/zakupów/walki. Native Humanoid ma co najmniej1, więc nie powinien umrzeć przed timerem. Po60s safe respawn; kill/death/reward raz. Reset lub logout podczas aktywnej walki nie powinien unieważniać prawidłowego encounter.
8. **3 klienty**: A tworzy squad, zaprasza B, B akceptuje; C przeciwnik. A/B nie mogą zadać sobie damage. C downuje B, A trzyma E5s przy B →35HP i brak kill za anulowany encounter. Puszczenie E/odległość/ściana/nowe DOWNED medyka przerywa postęp. Sprawdź transfer leader/kick/leave/wyjście. Czwarty slot działa, piąty odrzucony.
9. Powtórz eliminacje tej samej pary: 100/50/25/0% Money, zgodnie z aktualnym streak/bounty; reconnect z prawdziwym DEV DataStore zachowuje okno. Revive tej samej pary przed180s nie daje kolejnej waluty.
10. Dwóch teammate przy control point30s dostaje po150; wróg contest resetuje progress; single player/Downed/rider nie liczy się. Przez180s brak ponownej wypłaty.
11. Sprawdź leaderboard po5s, teammate markery, DOWNED i revive progress, minimapę. Ranking jest aktualnego serwera; BestStreak z profilu.
12. **Device Emulator**: telefon portrait/landscape/tablet, menu przewijanie, NativeMove/Jump + GAZ/brake/left/right, duże combatbuttons i holdrevive. Dwa palce: zwolnienie drugiego nie puszcza FIRE lub revive. Focus loss i otwarcie menu nie zostawiają gazu/fire/hold. Sprawdź UI scale .75–1.5, reduced effects i graphics1–3.
13. Osobne DEV doświadczenie: R15, Publish, API Services, UseStudioDataStoretrue/osobna nazwa; autosave/exit/rejoin, battery/ownedfish/cosmetic/upgrades/settings zachowane. StudioMemory reset po Stop to prawidłowe zachowanie. Rejoin po błędzie sesji nie powinien kasować profilu.
14. Profilery Studio: 10–30 pojazdów, kilku strzelających i łowiących, streaming odległych modeli, ping100–200ms. Odbiór wydajności telefonu wymaga rzeczywistego urządzenia.

## Granice testów

Nie uruchomiono Roblox Studio/Play, GUI/renderingu, fizyki Vehicles/seat/weld/raycast w silniku, prawdziwych klientów z opóźnieniem, telefonu ani Roblox DataStore/Marketplace. Mock raycast kontroluje decyzję przy zadanym wyniku; nie dowodzi, że geometria/stawy zachowają się identycznie w silniku. W szczególności MovementGuard tolerancje i vehicle stability wymagają pomiarów z prawdziwym ruchem. Nie włączono Robux zakupów ani cudzych assetów.

Możliwe błędy odbioru: nakładanie dotykowego UI na native controls, zasięg proceduralnego IK R15 i fallback seated R6, jitter serwerowej fizyki, zbyt surowy motion guard przy lag/skoku/rampie, collision cover/dock, synchronizacja wyposażenia przy opóźnionym appearance loading oraz błędy/quota backendu. Zgłoszenie powinno zawierać czynność, Output, liczbę klientów i użyty tryb pamięci.

Dodatkowo wykonano eksport rzeczywistego kodu geometrii przez mock API: 1092 części, 168 collidable, ciągłość mostu przez rzeczywistą przerwę lądu, odległa granica areny, wejścia sześciu sklepów i szczegóły pięciu modeli. Regenerowany asset ScenePreview jest porównywany z eksportem. Trzy rendery Blender sprawdzono wizualnie; nie dowodzą zachowania raycast/fizyki/IK/renderingu Roblox.
