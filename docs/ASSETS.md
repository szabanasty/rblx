# Assety i konfiguracja ręczna

Projekt działa z własnymi częściami Roblox. Nie ma pobranych modeli, muzyki, animacji, logo ani prawdziwych ubrań. Mapa powstaje w `Workspace.Map.ZoneGenerated`, hulajnogi przez `Server.Modules.ScooterFactory`, wyposażenie/kamizelka/tag przez AvatarPresentationService. SAFE/COMBAT/FISHING i ceny nie zależą od zewnętrznych assetów.

| Placeholder | Co później zastąpić |
| --- | --- |
| Hulajnoga z Part/Weld/VehicleSeat | Legalny model wizualny; zachowaj Chassis, VehicleSeat, ownership i serwerowy ruch. Zmieniony model wymaga weryfikacji rozmiaru, masy, collision i ground raycast. Folder ServerStorage.ScooterModels jest przygotowany, ale loader dowolnych importowanych modeli nie jest jeszcze zaimplementowany. |
| EnergyCore/Grip w prawej dłoni | Własny model fikcyjnego wyposażenia. Template folder ServerStorage.EquipmentTemplates jest pustym miejscem integracji, nie automatycznym loaderem. |
| StreetVest/kolor taga | Własne lub legalne ubrania/accessories; Category Clothing ma obecnie kolorową kamizelkę z części, nie asset Shirt/Pants. |
| Decals/Effects | Kolorowe części/Neon jako placeholder; naklejki i zaawansowane cząsteczki wymagają własnych obrazów/VFX i integracji. |
| Jazda/Downed/Revive/Fish | Native seat i zamrożona postać. W CosmeticConfig.Animations są puste ID; samo wpisanie animacji nie uruchamia playback — dodaj Animator/AnimationTrack do odpowiedniego kontrolera i testy. |
| Music/Fire/Hit/UI | CosmeticConfig.Audio: puste wartości. EffectsController może odtwarzać skonfigurowane legalne Music/Fire/Hit/UI. Klucze Scooter/Fishing są miejscem dalszej integracji. |
| Mapa blokowa | Własna dekoracja i LOD, bez zmiany konfigurowanych stref i prompty/odległości. Dodatkowe kontenery Map.* nie są usuwane przez generator. |

Ręcznie: ustaw Avatar R15 w ustawieniach doświadczenia (UI Studio może nazywać to Avatar Settings), opublikuj oddzielny test DataStore zgodnie z README, sprawdź asset ownership/permisje po dodaniu własnych ID. Nie trzeba wklejać skryptów do StarterGui ani budować folderów; robi to Rojo.

Do komercyjnych marek, muzyki/artystów i logo używaj wyłącznie uprawnionych assetów. Nazwy Volt i modele blokowe są roboczym oryginalnym zastępstwem wizualnym Kukirinów. Nie ma gwarancji praw do znaków Kukirin ani innych firm wynikającej z tego kodu.
