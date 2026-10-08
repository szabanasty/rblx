# Robux i Workshop — 0.7.0

Zakupy i wyposażenie są zaimplementowane. **Robux domyślnie jest wyłączony**: `Enabled = false`, wszystkie ID = `0`. Potrzebne są prawdziwe ID ofert Twojej gry. Workshop za Money i darmowy karnet działają bez nich.

| Klucz oferty | Typ | Co dostaje gracz |
| --- | --- | --- |
| `EliteScooter` | Game Pass | Volt Elite: 65 km/h, acceleration 6, bateria 160; stała własność i normalne ulepszenia. |
| `EliteWeapon` | Game Pass | Flux Elite: 22 damage / 0,32 s / 16 nabojów / range 135 / reload 1,8 s. Pulse za Money: 20 damage / 0,40 s / 10 nabojów. |
| `VIP` | Game Pass | Kamizelka i tag VIP, +5% zweryfikowanego XP, dwa dodatkowe presety garażu. |
| `NeonStyle` | Game Pass | Złoty kolor, światła i efekt części hulajnogi, kamizelka i tag NEON. |
| `GarageSlots` | Game Pass | Trzy dodatkowe presety modelu/kosmetyków: base 1, VIP 3, ten pass 4, razem 6. |
| `SeasonRiverside` | Game Pass | Premium ścieżka tylko sezonu RIVERSIDE_01; poziomy zdobywane przez grę. |
| `UpgradeCredit` | Developer Product | Jeden kredyt zastępujący cenę Money jednego ulepszenia w Workshop. |
| `UpgradePack` | Developer Product | Pięć kredytów Workshop, zakup powtarzalny. |

Płatne wyposażenie ma wyższe statystyki zgodnie z nowym poleceniem. Serwer nadal kontroluje amunicję, cooldown, reload, range, własność, SAFE/tag i friendly fire. Sloty to presety, nie dodatkowe aktywne pojazdy.

## Jak włączyć sprzedaż

1. Nowy ZIP i Rojo według README. Output: `version 0.7.0`. W Studio **Plik / File → Publish to Roblox** opublikuj projekt w swoim doświadczeniu.
2. [Creator Dashboard](https://create.roblox.com/dashboard/creations) → **Creations → Experiences → Twoja gra → Monetization → Passes**. Utwórz sześć Game Passes z tabeli, dodaj własne ikony/opisy, włącz sprzedaż i ustaw ceny. Skopiuj **Asset ID / ID passa**, nie Place ID lub ID ikony. Oferty muszą należeć do tego doświadczenia/grupy.
3. **Monetization → Developer Products**: utwórz `1 kredyt Workshop` i `5 kredytów Workshop`, ustaw ceny, skopiuj ich **Product ID**.
4. Otwórz `src/shared/Config/MonetizationConfig.luau`. We właściwym wierszu zastąp `Id = 0` prawdziwym numerem. Zachowaj `Kind`, `ScooterId`, `EquipmentId`, `Credits`, `SeasonId` i pozostałe pola. Nie używaj ID z cudzej gry.
5. W tym samym pliku ustaw `Enabled = true`. Oferty z ID `0` nadal są niedostępne. Ceny ustawiasz w Dashboard; natywne okno Roblox pokazuje rzeczywistą cenę użytkownika.
6. Zatrzymaj Play, zsynchronizuj przez Rojo i **opublikuj ponownie w Roblox**. Uruchom nowe serwery. Sam `rojo serve` nie publikuje zmian do opublikowanej gry.
7. W SAFE **MENU → RobuxShop**. Potwierdzanie zakupu odbywa się tylko w oficjalnym oknie Roblox. Ręczne odświeżenie posiadanych passów jest w tym menu.

Sprzedaż może przynosić Robux po rozliczeniach i potrąceniach Roblox. Wypłata pieniężna wymaga spełnienia aktualnych warunków [DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange); samo dodanie ofert nie zapewnia przychodu.

## Używanie zakupów

- Volt Elite: **Garage → wybierz model → PRZYWOŁAJ**.
- Flux Elite: w SAFE **EquipmentShop → wybierz slot → WYPOSAŻ**. Walka działa w COMBAT za mostem.
- VIP/Neon: **CosmeticsShop → załóż posiadany tag, kamizelkę lub kolor**. To oryginalne modele części/kolory, bez markowych assetów lub zewnętrznych animacji.
- Presety: pieszo przy garażu wybierz model/wygląd i ZAPISZ SLOT. WCZYTAJ ustawia model i posiadane kosmetyki; następnie przywołaj go. Preset nie kopiuje ulepszeń ani nie nadaje własności.

## Naprawiony Workshop

WORKSHOP przy **(30, -58)**: wejdź środkowym wejściem, podejdź do świecącego stołu po prawej, naciśnij **E / native prompt**. Prompt przy wejściu i MENU → UpgradeShop również działają; zakup wymaga rzeczywistej bliskości warsztatu.

Zejdź z hulajnogi, wybierz swój model. Menu pokazuje sześć kategorii, obecny/max poziom, cenę, Level oraz statystyki przed/po. Jeśli siedzisz, jest **ZEJDŹ Z HULAJNOGI**. Nowy profil ma 100 Money; pierwszy silnik kosztuje **75 Money**, następny 150 i wymaga Level 4. Maksimum kategorii: 5.

Po uzyskaniu kredytów pojawia się **UŻYJ 1 KREDYTU**. Kredyt zastępuje tylko cenę Money; Level, ownership, max, proximity i dismount nadal są sprawdzane przed zużyciem. Wnętrze ma podnośnik, hulajnogę serwisową, stół, baterię i narzędzia. Hulajnoga na podnośniku jest wystawowa, nie służy do wsiadania.

## Karnet i nowy sezon

**MENU → BattlePass**: 12 poziomów po 200 XP, darmowa/premium ścieżka, Money/kredyty/kosmetyki według `SeasonConfig`. Premium nie nadaje od razu poziomów. XP pochodzi tylko z przyjętych przez EconomyService serwerowych nagród jazdy/PvP/objective; limit sezonowy 1000/dzień UTC. Działa również na maksymalnym poziomie postaci.

Nagrody odbiera się jednorazowo w SAFE bez tagu. Nieudana wypłata lub pełny portfel nie zużywają claim. `StartsAt`/`EndsAt` to Unix UTC; `0` oznacza brak granicy. Obecny sezon jest otwarty podczas developmentu.

Nowy sezon wymaga **nowego `Id`**, nowego premium passa i klucza oferty, zgodnych `PremiumOfferKey` i `SeasonId`. Nie używaj ponownie starego ID passa, klucza premium ani sezonu. Dodaj ofertę do `Order`. Walidacja startowa odrzuca niespójny sezon. Starsze Product ID zachowaj do rozliczenia zaległych rachunków.

## Zapis i testy

Game Pass potwierdza serwerowe `UserOwnsGamePassAsync`. Sygnał zakończenia promptu nie jest dowodem własności. Awaria API nie usuwa już zapisanych uprawnień.

Produkty rozlicza wyłącznie `MarketplaceService.ProcessReceipt`: kredyty i permanentny PurchaseId trafiają do **jednego profilu, jednym session-locked UpdateAsync**. `PurchaseGranted` dopiero po udanym zapisie. Błąd zapisu/offline/utrata lease/shutdown/nieznany ID → `NotProcessedYet`. Retry/rejoin nie wypłaca ponownie; klient nie może przesłać receipt ani kwoty nagrody.

StudioMemory nie otwiera promptów produktów ani nie rozlicza ich. Realne testy wymagają osobnego doświadczenia DEV, `UseStudioDataStore = true`, osobnej nazwy magazynu i API access w Studio według README. Opublikowana gra używa DataStore automatycznie. Nie przełączaj magazynu produkcyjnych profili dla testu.

Ledger mieści 10 000 permanentnych rachunków/gracza, bez usuwania najstarszych. Pełny portfel/ledger blokuje nowe prompty. Zaległy zakup przy limicie pozostaje do rozliczenia po zużyciu kredytów lub wdrożeniu migracji pojemności ledger. Nie zmieniaj znaczenia istniejącego Product ID. Wyłączenie `Enabled` blokuje nowe prompty, ale nadal rozlicza wcześniejsze skonfigurowane produkty.

Testy chmurowe uruchamiają prawdziwy kod usług/UI przez mock API: ownership, retry/save/reload/concurrency, ledger ponad 256 wpisów, limity, premium, XP/VIP/season, claims, presety, Workshop i spoofowane remotes; także Luau compile, Roblox types i Rojo.

**Nie wykonano prawdziwej transakcji Robux ani Play w Studio.** Po konfiguracji użyj oficjalnych narzędzi testowych Roblox: anulowanie promptu, pass/rejoin, produkt/pakiet, kredyt, premium claim, mobile przewijanie oraz multiplayer. Mock nie zastępuje backendu Marketplace/DataStore i fizyki silnika.
