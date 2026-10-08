# Stan faz i następny rozwój

Najnowsze polecenie użytkownika znosi wcześniejsze zatrzymywanie po każdej fazie. 0.7.0 implementuje połączony prototyp według PHASE0–9 oraz podstawowe elementy PHASE10. Kompilacja/testy logiki nie zastępują odbioru silnika.

| Faza | Stan |
| --- | --- |
| 0 Foundation | Moduły, typy, config, dane, ekonomia, networking, bootstrap i testy. |
| 1 Map/Zones | Riverside z wnętrzami, rzeka i most, odległe Iron Island, drogi/rampy/cover/shops/dock, zgodne granice, server state i tag. |
| 2 Kukirin | 5 klas, własność/spawn/despawn, serwerowe prowadzenie, bateria/ładowanie. |
| 3 Garage/Progression | XP/Level, dealer/workshop, 6 upgrade kategorii0–5, kosmetyki. |
| 4 Squads | 4 members, leader/invite/accept/leave/kick/transfer, markery i friendly fire off. |
| 5 Combat | 5 fikcyjnych kategorii, loadout3slot, ammo/reload/raycast/range/cooldown/aim. |
| 6 Downed/Revive | 60s, teammatehold5s/LOS, health35/protection2, respawn i UI. |
| 7 PvP Economy | Kill/assist/revive/streak/bounty, idempotencja, persisted anti-farm i limity, ranking serwera. |
| 8 Fishing | Automat bez minigry, rarity/weight/price, inventory60, sell1/all i timeout. |
| 9 Shops/Cosmetics | Oddzielne strony menu, walidacja zakupów, placeholdery ubrań/tagów/części. |
| 11 Robux/Season | 6 Game Passes, 2 produkty, premium wyposażenie, VIP/kosmetyki, presety, kredyty, karnet 12 poziomów. Kod wdrożony, prawdziwe ID/zakupy wymagają Roblox. |
| 10 Polish | Rozdzielony HUD z testami układu/mobile controls/minimap/daynight/hitmarker/trace/settings. Oryginalna grafika proceduralna i R15 IK są wdrożone; docelowe audio/pozostałe animacje, odbiór wydajności/balansu i engine QA pozostają. |

Następny etap: konfiguracja ofert Robux według MONETIZATION, odbiór transakcji/Workshop/karnetu oraz gry w Studio według TESTING, korekty rzeczywistej fizyki, input/UI i zapisów. Potem autorska dekoracja mapy/LOD, prawdziwe animacje R15 i legalne audio. Następnie tuning gospodarki/prędkości/TTK pod mobilne multiplayer i opcjonalny globalny ranking (OrderedDataStore z budżetem zapisu). Delivery/time trial oraz kolejne objective są rozszerzeniami, nie aktywnymi endpointami nagród.

Duży stary GTA/police/pets/crew plan został zastąpiony kompaktową specyfikacją KUKIRIN ZONE. Robux i karnet dodano ponownie w 0.7.0 na wyraźne polecenie użytkownika. Nie uruchamiamy niepowiązanych systemów tylko po to, żeby zwiększyć liczbę funkcji. Legacy moduły zachowano dla kompatybilności i dalszej świadomej migracji.
