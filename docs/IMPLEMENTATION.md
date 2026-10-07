# Aktualizacja świata i hulajnóg 0.6.0

Najnowsza zmiana: Riverside, rzeka z rzeczywistą przerwą lądu, most, Iron Island ponad 1000 studów od spawnu, sklepy z wnętrzami, ekspozycja 5 modeli, warsztat, plac/fountain/trees/lights, jezioro. Podgląd mapy działa w edytorze. Hulajnogi mają szczegółową oryginalną grafikę; własny pojazd odbierasz przed garażem. Mount ma osobny moduł, zaufaną relokację i retry; R15 dostaje proceduralne IK, R6 native fallback. Granice, minimapa, objective i zabezpieczenia zostały przeniesione razem z mapą.

Nowe pliki: SceneBuilder, CityScene, IslandScene, ScooterMount, ScooterPose; assets/map-preview.model.json; SceneMock, scooter-mount/pose testy; skrypty export-scene/check-scene/generate-preview/render-scene; WORLD_060 i podglądy PNG. Pełna lista bieżących źródeł: FILES.md.

Poprawki: salon jasno odróżnia modele wystawowe; garaż ma fizyczne stanowisko odbioru; menu zamyka się po spawnie/wsiadaniu; ruch rozpoznaje dozwoloną relokację do siedzenia; wejścia mają otwór20studów; promień zakupu obejmuje wnętrze; spadek do rzeki przywraca punkt na lądzie; nakładające się powierzchnie skrzyżowań zastąpiono pojedynczą nawierzchnią. Dane gracza/ekonomia nie zostały zresetowane.

Testy: 82 źródła kompilowane i analizowane z API Roblox, Rojo build, 18 zestawów Luau, geometria 1092 części / 168 collidable, zgodność podglądu edytora, rendery Blender. Rzeczywiste wsiadanie/IK/fizyka/mobile i zapis nadal wymagają Roblox Studio; nie ma w tej chmurze silnika. Jest to dopracowana iteracja kodu/grafiki, a nie deklaracja zamkniętego QA produkcji.

## Historia prototypu 0.5.0



Zaimplementowano rzeczywisty kod Luau dla foundation, world/zones, scooter/garage/progression, squad, combat, downed/revive, economy, objective, fishing, shops/cosmetics i responsive UI. Cała funkcjonalna pętla jest połączona w domyślnym ZoneGame. Dalsze dekoracje i animacje mają jawne placeholdery, audio puste ID.

## Pliki

82 źródeł i ich ścieżki w Studio są w FILES.md. W tej iteracji dodano: 6 kontrolerów klienta i ZoneMenus, 14 usług serwera, 2 configi i 4 czyste moduły shared. Zmieniono bootstrapy server/client, Network/Snapshot/Economy/Scooter/Shop, centralne configi, ProfileSchema/Validation/typy/ProjectInfo, projekt Rojo, runner testów i dokumentację. Dodano RuntimeMocks oraz 5 suite'ów strefy, rozszerzono testy network/foundation/shop. Pełna lista wynika z zatwierdzonego diff tej wersji, bez plików generated/build/tools w repo.

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
