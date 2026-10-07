# Odbiór mapy i stref

Aktualny pełny odbiór znajduje się w [TESTING.md](TESTING.md). Ta karta dotyczy PHASE1, już połączonego z resztą gry w 0.5.0.

Play tworzy Map.ZoneGenerated. SAFE: X/Z -80..80; COMBAT: X100..340/Z-130..130; FISHING: X-285..-155/Z95..225. Granice Y±30. Poza strefami CITY. HUD pokazuje aktualny obszar zatwierdzony przez Movement. Sprawdź pieszo i hulajnogą przekroczenie granic, stacje w SAFE, pomost/buyer, cover/rampy i objective.

Po trafieniu combat tag20s zachowuje się po wejściu SAFE; nigdy nie resetuje się od samej granicy. Bez tagu SAFE i FISHING chronią przed damage. Nie wolno teleportem uruchomić sklepu/fishing/objective: MovementGuard ma cofnąć postać i krótko odmówić akcji, bez kicku za jedną flagę. Pomiary tolerancji lag/ramp/dismount nadal wymagają silnika.
