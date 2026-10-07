# Kolejność rozwoju KUKIRIN ZONE

Nadrzędne wymagania: [SPEC_ZONE.md](SPEC_ZONE.md). Kukiriny pozostają; kierunek gry to autorski arcade squad PvP z łowieniem. Zachowany prototyp miasta nie wyznacza już roadmapy.

| Faza | Zakres | Status |
| --- | --- | --- |
| 0 — FOUNDATION | Foldery, Config, Types, Remotes, profil/migracja, snapshot, save/load, walidacja, podstawowy panel | Kod i testy chmurowe gotowe; oczekuje testu użytkownika w Studio |
| 1 — MAP / ZONES | Kompaktowy blockout, Safe/Combat/Fishing, detekcja, Main HUD | Następna po potwierdzeniu PHASE 0 |
| 2 — KUKIRIN | R15, placeholder, VehicleSeat, spawn/despawn, jazda, prędkościomierz, cleanup | Jeszcze nieaktywna; starszy kontroler wymaga dostosowania i odbioru |
| 3 — GARAGE / PROGRESSION | Garaż, Dealership, ownership, Workshop, 0–5 upgrades, wygląd | Katalog przygotowany; brak aktywnych sklepów nowej gry |
| 4 — SQUADS | Create/Invite/Accept/Leave/Kick, 4 graczy, znaczniki i dystans, friendly fire off | Plan |
| 5 — COMBAT FOUNDATION | Fikcyjne wyposażenie, loadout, serwerowe PvP, Health, combat tag, HUD | Konfig/typy przygotowane; combat nie istnieje |
| 6 — DOWNED / REVIVE | ZGINIĘTY 60 s, znaczniki, revive 5 s, bezpieczny respawn | Plan |
| 7 — PvP ECONOMY | Kills/assists/revive, streak/bounty, EncounterId, anti-farming, rankingi | Konfig/fields przygotowane; zero naliczania PvP |
| 8 — FISHING | Auto fishing, RNG serwera, rarity/waga, inventory, sell selected/all, cap | Konfig/fields przygotowane; zero fishing gameplay |
| 9 — SHOPS / COSMETICS | Equipment Shop, kosmetyki, scooter visual, UI polish | Plan |
| 10 — FINAL POLISH | Mobile, animacje, legalne audio, performance, anti-cheat, balans, sieć | Plan; bezpieczeństwo i mobile sprawdzamy też we wcześniejszych fazach |

Po każdej fazie: prawdziwa implementacja → dostępne testy → poprawki → dokumentacja → test Studio użytkownika → potwierdzenie przed kolejną fazą. Nie wdrażamy kilku nieodebranych faz naraz.

Dla PHASE 0 wymagany odbiór: poprawna synchronizacja 0.4.0, panel danych, zmiana skali, respawn bez błędów i niezależne profile klientów. Prawdziwy DataStore można sprawdzić na osobnym testowym doświadczeniu. [Procedura](TESTING.md).

Po potwierdzeniu PHASE 0 pierwszy wycinek PHASE 1 to trzy oryginalne bryły stref, oznaczone wejścia, proste drogi i serwerowa detekcja. Dopiero potem włączamy dostosowaną jazdę. Nowa mapa nie będzie kopią Los Santos ani clowns.cool.
