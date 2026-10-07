# Wydanie prototypu 0.5.0

Zaimplementowano rzeczywisty kod Luau dla foundation, world/zones, scooter/garage/progression, squad, combat, downed/revive, economy, objective, fishing, shops/cosmetics i responsive UI. Cała funkcjonalna pętla jest połączona w domyślnym ZoneGame. Dalsze dekoracje i animacje mają jawne placeholdery, audio puste ID.

## Pliki

77 źródeł i ich ścieżki w Studio są w FILES.md. W tej iteracji dodano: 6 kontrolerów klienta i ZoneMenus, 14 usług serwera, 2 configi i 4 czyste moduły shared. Zmieniono bootstrapy server/client, Network/Snapshot/Economy/Scooter/Shop, centralne configi, ProfileSchema/Validation/typy/ProjectInfo, projekt Rojo, runner testów i dokumentację. Dodano RuntimeMocks oraz 5 suite'ów strefy, rozszerzono testy network/foundation/shop. Pełna lista wynika z zatwierdzonego diff tej wersji, bez plików generated/build/tools w repo.

## Znalezione i poprawione problemy

- Niepoprawne ciągi wieloliniowe i błędy ścisłej analizy typów naprawiono, cały kod przechodzi Luau/Roblox types.
- UserId >2 miliardy był odrzucany: walidacja target IDs obsługuje bezpieczne integer i Studio testowe ujemne ID.
- Zmiana slotu/equip nie resetuje ammo; fire/reload są własnością serwera.
- Once settlement i stale fish revision blokują podwójne rozliczenia; sprzedaż z odmową dokładnego Credit zachowuje ryby.
- SAFE boundary nie usuwa combat tag; DOWNED, revive i spawn protection mają odrębne ograniczenia.
- Rate limiter jest niezależny dla Input i Action; Shoot/Hold nie wywołują natychmiast pełnego snapshotu na każde poprawne żądanie.
- Shot origin musi być przy zatwierdzonym root postaci; zmieniona/NaN pozycja głowy nie pozwala strzelać. ProximityPrompt ma niezależny limiter.
- Stop/release/focus loss oraz drugi palec nie pozostawiają heldfire/holdrevive/gazu.
- Motion guard obejmuje rolling speed i flight; mount/dismount resetują odpowiedni budżet bez darmowego klientowego teleportu.
- Okna anti-farm PvP/revive są utrwalone w profilu: restart usługi/reload/rejoin nie resetują Money cooldown.
- Respawn ma retry; avatar i połączenia mają ochronę przed zdarzeniami starej postaci.
- HUD czyści stare dane po utracie gotowości profilu; łowienie ma bezpośredni przycisk STOP.

## Ograniczenia

Nie przetestowano Play w Roblox Studio. Prawdziwe raycast/collision/weld/VehicleSeat/latency/mobile UI oraz trwały DataStore mają checklistę w TESTING. AvatarPresentation jest blokowym placeholderem, audio/animacje nie są gotową produkcyjną oprawą. Leaderboard pokazuje aktualny serwer, bez globalnej agregacji. Nie ma Robux monetyzacji ani nowych sideactivities; nie należą do podstawowej kompaktowej pętli. Konieczny jest odbiór silnika przed publikacją dla graczy. PHASE10 w config oznacza połączony zakres prototypu, nie zakończone QA wydania.
