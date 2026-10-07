# Modele, placeholdery i czynności ręczne

## Stan PHASE 0

Rojo tworzy Baseplate 800×20×800 oraz neutralny SpawnLocation. Foldery `Workspace.Map.SafeZone`, `CombatZone`, `FishingArea`, `Roads`, `Garage`, `Shops`, `Buildings`, `Cover` i `Workspace.Vehicles` są puste w czystym zbudowanym miejscu. `ServerStorage.ScooterModels` i `EquipmentTemplates` są pustymi kontenerami. Nie są to działające strefy ani modele.

HUD `ZoneFoundation` powstaje kodem w PlayerGui podczas Play. Nie używa ikon ani asset ID. Postać, kamera, domyślne animacje i reset są natywne dla Roblox. Obecne Health jest odczytem Humanoid, nie systemem downed.

W repozytorium zachowano wcześniejszy WorldBuilder i ScooterFactory, lecz PHASE 0 ich nie uruchamia. Nowe katalogi to definicje danych, nie obietnica istniejących assetów. Brak muzyki, dźwięków wyposażenia, animacji walki, modeli ryb, modeli Kukirina i logo marek.

## Późniejsze dodatki

| Etap | Placeholder kodowy | Co dodamy ręcznie lub zastąpimy po odbiorze |
| --- | --- | --- |
| 1 | Własny blockout z prostych części, oznaczone obszary | Oryginalna geometria/mapa; bez skryptów z przypadkowego Toolboxa |
| 2 | Dostosowany ScooterFactory i VehicleSeat | Własny model hulajnogi z PrimaryPart, weldami i kontraktem fabryki; R15 w ustawieniach Avatar |
| 3 | Proste kolory/materialy modeli | Legalne naklejki i warianty; ownership zawsze na serwerze |
| 5 | Fikcyjne wyposażenie bez realistycznego brandingu | Własne modele w EquipmentTemplates, animacje R15 i efekty bez przemocy graficznej |
| 8 | Karty ryb tekstowe | Własne ikony/modelki ryb; niepotrzebne do poprawnego serwerowego RNG |
| 10 | Brak muzyki i SFX | Własne/licencjonowane audio opublikowane dla tego doświadczenia, dopiero potem ID w konfigu |

Nie musisz dodawać nic ręcznie, aby sprawdzić PHASE 0. R15 będzie skonfigurowane i sprawdzone w fazie jazdy, a nie zakładane jako istniejący niestandardowy asset. Ręcznych modeli nie zapisuj pod nazwą zarezerwowaną dla runtime generatora `Map.Generated`.

Foldery Rojo mają `ignoreUnknownInstances`; Studio może zachować starsze modele/skrypty, których repozytorium nie zna. Do odbioru nowego kierunku otwórz czysty Baseplate. Potem importuj wyłącznie potrzebne własne elementy. Logo, muzyka artystów i cudze mapy wymagają praw, nie kopiujemy ich jako placeholderów.
