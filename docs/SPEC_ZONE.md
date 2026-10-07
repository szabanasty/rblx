# Specyfikacja użytkownika — KUKIRIN ZONE

Poniżej pełne przekazane wytyczne. Doprecyzowanie użytkownika: **Kukiriny pozostają**. Aktualizacja polecenia użytkownika: pracować autonomicznie i kontynuować implementację bez potwierdzania kolejnych faz. Historyczne polecenia STOP poniżej zostały zastąpione tą nowszą instrukcją. Stan aktualnego prototypu: README i IMPLEMENTATION.md.

```text
Jesteś głównym programistą, game designerem i architektem mojej gry Roblox.

Chcę stworzyć od podstaw dopracowaną grę multiplayer Roblox.

GŁÓWNĄ INSPIRACJĄ dla stylu rozgrywki, tempa, stref, drużyn, powaleń, revive, progresji i ogólnego gameplay loop mają być serwery/strefy multiplayer w stylu Clowns.cool / ClownRP / FiveM.

BARDZO WAŻNE:

Inspiruj się sposobem, w jaki tego typu gry organizują rozgrywkę, ale NIE kopiuj ich kodu, mapy, UI, modeli, grafik, logo, nazw, muzyki ani innych assetów.

Nasza gra ma mieć:
- własną mapę,
- własne UI,
- własne modele,
- własne nazwy,
- własną ekonomię,
- własne systemy.

Chcę uzyskać podobne ODCZUCIE Z GAMEPLAYU, ale jako oryginalną grę Roblox.

Robocza nazwa:

KUKIRIN ZONE

To NIE ma być klasyczny RolePlay.

Gra ma być nastawiona na:

MULTIPLAYER
+
KUKIRINY
+
SQUADS
+
COMBAT ZONE
+
ARCADE PvP
+
DOWNED/REVIVE
+
PROGRESJA
+
ZARABIANIE
+
ULEPSZANIE POJAZDÓW.

System PvP ma być fikcyjny i zręcznościowy, odpowiedni dla Roblox, bez krwi, gore, realistycznych ran i bez odwzorowywania realnej obsługi prawdziwej broni.

==================================================
1. GŁÓWNY GAMEPLAY LOOP
==================================================

Gracz wchodzi do gry.

SPAWN
→ SAFE ZONE
→ wybiera swój loadout
→ wybiera Kukirina
→ tworzy/dołącza do Squad
→ wyjeżdża z Safe Zone
→ jedzie Kukirinem do Combat Zone
→ spotyka inne drużyny
→ rozpoczyna PvP
→ zdobywa statystyki i Money
→ może zostać DOWNED
→ pojawia się "ZGINIĘTY"
→ teammate może go ocucić
→ jeżeli nikt go nie ocuci przez 60 sekund, następuje respawn
→ wraca do Safe Zone
→ kupuje rzeczy
→ ulepsza Kukirina
→ zmienia loadout
→ ponownie wyjeżdża.

ALTERNATYWNY LOOP:

Gracz nie chce walczyć.

SPAWN
→ bierze Kukirina
→ jedzie nad jezioro
→ rozpoczyna automatyczne łowienie
→ zdobywa ryby
→ sprzedaje ryby
→ otrzymuje Money
→ kupuje/ulepsza Kukirina
→ kupuje kosmetyki
→ może później pojechać na Zone.

Nie zmuszaj gracza do PvP, żeby mógł rozwijać konto.

==================================================
2. MAPA
==================================================

Nie chcę ogromnego miasta.

Chcę jedną średniej wielkości, dopracowaną mapę multiplayer.

Mapa powinna być na tyle kompaktowa, żeby gracze regularnie się spotykali.

Główne obszary:

1. SPAWN / SAFE ZONE

2. GARAGE

3. SCOOTER DEALERSHIP

4. SCOOTER WORKSHOP

5. EQUIPMENT SHOP

6. COSMETICS SHOP

7. GŁÓWNA DROGA

8. COMBAT ZONE

9. FISHING AREA

10. FISH BUYER

11. SIDE ACTIVITIES

12. MIEJSCA SPOTKAŃ GRACZY

Mapa powinna zawierać:

- drogi,
- skrzyżowania,
- tunele,
- parkingi,
- rampy,
- magazyny,
- małe budynki,
- murki,
- kontenery,
- alejki,
- wzniesienia,
- most,
- jezioro/rzekę,
- pomost.

Combat Zone musi być zaprojektowana specjalnie pod multiplayer.

Ma posiadać wiele dróg poruszania się i elementów osłony.

==================================================
3. SAFE ZONE
==================================================

Spawn jest Safe Zone.

W Safe Zone:

PvP = OFF
Damage = OFF
Downed = OFF

Gracz może:

- korzystać z Garage,
- spawn/despawn Kukirina,
- kupować Kukiriny,
- ulepszać Kukiriny,
- kupować wyposażenie,
- zmieniać loadout,
- kupować kosmetyki,
- tworzyć Squad,
- zapraszać graczy.

HUD pokazuje:

SAFE ZONE

Po wyjechaniu:

OPUSZCZASZ SAFE ZONE

Dodaj zabezpieczenie przed Safe Zone abuse.

Jeżeli gracz ma aktywny CombatTag, samo dotknięcie granicy Safe Zone nie może natychmiast anulować konsekwencji aktywnej walki.

==================================================
4. KUKIRINY
==================================================

Głównymi pojazdami są elektryczne hulajnogi.

Mogą być inspirowane klasą pojazdów typu Kukirin.

Jeżeli użycie prawdziwych nazw/modeli/logo wymaga licencji, podczas developmentu używaj własnych placeholderowych marek/modeli.

Każdy model:

ScooterId
DisplayName
Price
TopSpeed
Acceleration
Handling
Braking
Battery
Weight
Rarity
UpgradeSlots

==================================================
5. KLASY KUKIRINÓW
==================================================

Przygotuj kilka klas.

STARTER

- tani,
- łatwy w prowadzeniu,
- słabsze osiągi.

CITY

- dobre prowadzenie,
- dobre hamowanie,
- średnia prędkość.

SPORT

- większa prędkość,
- dobre przyspieszenie.

DUAL MOTOR

- bardzo dobre przyspieszenie,
- większa masa.

PRO

- drogi model end-game,
- bardzo dobre osiągi,
- ale nie może całkowicie niszczyć balansu.

Rarity:

COMMON
UNCOMMON
RARE
EPIC
LEGENDARY

==================================================
6. SCOOTER DEALERSHIP
==================================================

Dodaj fizyczny salon.

Po interakcji otwiera się:

SCOOTER DEALERSHIP

Dla modelu pokazuj:

MODEL
PRICE
TOP SPEED
ACCELERATION
HANDLING
BRAKING
BATTERY
RARITY

Opcje:

PREVIEW
BUY

Serwer sprawdza:

- Money,
- ownership,
- cenę z konfiguracji.

Klient nigdy nie przesyła ceny zakupu.

==================================================
7. GARAGE
==================================================

Gracz posiada Garage.

Pokazuje wszystkie jego Kukiriny.

Opcje:

SELECT
SPAWN
DESPAWN
UPGRADE
CUSTOMIZE

Tylko jeden osobisty Kukirin może być aktywny jednocześnie.

Po:
- respawnie,
- wyjściu gracza,
- zmianie pojazdu

poprzedni pojazd musi zostać poprawnie usunięty.

==================================================
8. JAZDA
==================================================

Jazda ma być arcade i responsywna.

PC:

W = gaz
S = hamowanie
A/D = skręcanie

Mobile:

JOYSTICK
GAS
BRAKE

HUD:

SPEED
BATTERY
SCOOTER NAME

Prędkość pokazuj w km/h.

Postać:

R15.

Pierwszy prototyp może korzystać z VehicleSeat.

Jednak system musi być modularny:

ScooterController
ScooterService
ScooterConfig

żeby później można było ulepszyć fizykę bez przebudowy całej gry.

==================================================
9. PERFORMANCE UPGRADES
==================================================

Dodaj Workshop.

MOTOR
Level 0–5

Wpływa na acceleration i częściowo TopSpeed.

CONTROLLER
Level 0–5

Wpływa na reakcję hulajnogi.

BATTERY
Level 0–5

Zwiększa czas działania/zasięg.

BRAKES
Level 0–5

Poprawia hamowanie.

TIRES
Level 0–5

Poprawia handling.

SUSPENSION
Level 0–5

Poprawia stabilność.

Każdy kolejny poziom jest droższy.

Przykładowa progresja cen może być:

Level 1 = tanie
Level 2 = średnie
Level 3 = droższe
Level 4 = bardzo drogie
Level 5 = end-game

Dokładne ceny trzymaj w UpgradeConfig.

==================================================
10. VISUAL TUNING
==================================================

Dodaj:

COLORS
GRIPS
DECK
LIGHTS
WHEEL DETAILS
DECALS
COSMETIC EFFECTS

Visual tuning nie zwiększa przewagi PvP.

==================================================
11. SQUAD SYSTEM
==================================================

Maksymalnie:

4 graczy.

Opcje:

CREATE SQUAD
INVITE PLAYER
ACCEPT
DECLINE
LEAVE
KICK

Squad:

SquadId
Leader
Members

Friendly Fire:

OFF

Teammates nie mogą zadawać sobie damage.

==================================================
12. TEAMMATE MARKERS
==================================================

Nad teammate pokazuj:

USERNAME
DISTANCE

Przykład:

PLAYER123
38m

Jeżeli teammate jest Downed:

PLAYER123
ZGINIĘTY
38m

Dodaj wyraźny marker pozwalający znaleźć kolegę do revive.

==================================================
13. PLAYER STATES
==================================================

Utwórz jeden centralny state system.

PlayerState:

SAFE
ALIVE
COMBAT
DOWNED
REVIVING
RESPAWNING
FISHING

SAFE:
Safe Zone.

ALIVE:
normalna gra.

COMBAT:
aktywny CombatTag.

DOWNED:
gracz został pokonany.

REVIVING:
trwa revive.

RESPAWNING:
gracz wraca na Spawn.

FISHING:
automatyczne łowienie.

Serwer kontroluje prawdziwy PlayerState.

==================================================
14. COMBAT SYSTEM
==================================================

System walki ma być szybki i responsywny.

Inspiruj się tempem rozgrywki multiplayerowych stref PvP, ale stwórz własny system odpowiedni dla Roblox.

Priorytety:

RESPONSIVENESS
FAIRNESS
SKILL
MULTIPLAYER
MOBILE
ANTI-CHEAT

Bez:
- krwi,
- gore,
- realistycznych ran.

==================================================
15. FIKCYJNE WYPOSAŻENIE PvP
==================================================

Stwórz fikcyjne klasy wyposażenia dystansowego.

Nie odwzorowuj realnej obsługi prawdziwej broni.

Kategorie:

LIGHT
STANDARD
CLOSE RANGE
PRECISION
HEAVY

LIGHT:
- duża mobilność,
- szybkie tempo,
- niższa siła pojedynczej akcji.

STANDARD:
- najbardziej uniwersalne.

CLOSE RANGE:
- najlepsze blisko,
- słabsze wraz ze wzrostem dystansu.

PRECISION:
- nagradza dokładne celowanie,
- wolniejsze tempo.

HEAVY:
- większa siła,
- mniejsza mobilność.

Nadaj przedmiotom fikcyjne nazwy stworzone specjalnie dla naszej gry.

==================================================
16. EQUIPMENT CONFIG
==================================================

Każdy przedmiot posiada:

EquipmentId
DisplayName
Category
Damage
Cooldown
EffectiveRange
Accuracy
MobilityModifier
Capacity
ReloadDuration
Price
Rarity

Wszystkie wartości przechowuj w:

EquipmentConfig

Nie rozrzucaj statystyk po wielu skryptach.

==================================================
17. LOADOUT
==================================================

Gracz posiada:

PRIMARY
SECONDARY
UTILITY

W Safe Zone może otworzyć:

LOADOUT

i wybrać posiadane wyposażenie.

Opcje:

EQUIP
UNEQUIP
SWITCH

==================================================
18. COMBAT CONTROLS
==================================================

PC:

LMB = użycie
RMB = aim
R = reload
1/2/3 = zmiana slotu

Mobile:

FIRE
AIM
RELOAD
SWITCH

Dodaj dynamiczny crosshair.

Crosshair reaguje na:

- ruch,
- aim,
- użycie,
- skok.

==================================================
19. HIT FEEDBACK
==================================================

Po potwierdzonym trafieniu:

- hitmarker,
- krótki SFX,
- delikatny efekt UI.

Opcjonalnie:

damage direction indicator.

Nie pokazuj krwi.

==================================================
20. SERVER-AUTHORITATIVE COMBAT
==================================================

BARDZO WAŻNE.

Klient odpowiada głównie za:

- input,
- kamerę,
- crosshair,
- lokalne animacje,
- lokalne efekty.

Serwer jest ostatecznym autorytetem dla:

- PlayerState,
- możliwości wykonania akcji,
- cooldownów,
- Health,
- Damage,
- Downed,
- Revive,
- Kills,
- Deaths,
- Rewards.

Nie ufaj komunikatowi klienta:

"zadałem graczowi X damage".

Serwer musi sprawdzić, czy akcja jest prawidłowa.

==================================================
21. HEALTH
==================================================

Każdy gracz:

MaxHealth
CurrentHealth

Jeżeli:

CurrentHealth > 0

gracz pozostaje aktywny.

Jeżeli:

CurrentHealth <= 0

uruchom DOWNED.

==================================================
22. DOWNED — "ZGINIĘTY"
==================================================

To jest jeden z najważniejszych systemów gry.

Po osiągnięciu 0 Health:

NIE wykonuj zwykłego natychmiastowego Roblox respawnu.

Ustaw:

PlayerState = DOWNED

HUD:

ZGINIĘTY

OCZEKUJ NA POMOC DRUŻYNY

ODRODZENIE ZA:

00:60

Timer:

60
59
58
57
...

Downed player nie może:

- normalnie walczyć,
- jeździć Kukirinem,
- używać sklepów,
- łowić,
- wykonywać zwykłych aktywności.

==================================================
23. REVIVE
==================================================

Teammate może podejść do Downed gracza.

PC:

PRZYTRZYMAJ [E]
OCUĆ

Mobile:

OCUĆ

Pokaż progress bar.

OCUCANIE...
████████░░

Revive trwa kilka sekund.

Przerwij revive, jeżeli:
- gracz odejdzie,
- reviver przestanie przytrzymywać,
- reviver sam zostanie Downed,
- warunki przestaną być prawidłowe.

Po ukończeniu:

DOWNED → ALIVE

Przywróć część Health.

Dodaj krótką ochronę po revive, jeżeli testy pokażą, że jest potrzebna dla balansu.

==================================================
24. RESPAWN
==================================================

Jeżeli timer osiągnie:

00:00

ustaw:

DOWNED → RESPAWNING

Gracz wraca do Safe Zone.

Następnie:

RESPAWNING → SAFE

Przywróć pełne Health.

Wyczyść jego stary aktywny pojazd, jeśli nadal istnieje.

==================================================
25. COMBAT TAG
==================================================

Po uczestniczeniu w aktywnym PvP:

CombatTag = ACTIVE

CombatTag trwa przez konfigurowalny czas od ostatniej akcji PvP.

HUD:

COMBAT

CombatTag służy między innymi do ograniczenia nadużywania granic Safe Zone.

==================================================
26. STATYSTYKI PvP
==================================================

Zapisuj:

Kills
Deaths
Assists
Revives
CurrentStreak
BestStreak
ZoneTime

Serwer kontroluje wszystkie statystyki.

==================================================
27. PODSTAWOWA NAGRODA PvP
==================================================

Bazowa nagroda za prawidłowo rozliczoną eliminację:

+100 Money
+1 Kill
+1 CurrentStreak

Nie dawaj Money za samo trafienie.

Nie wypłacaj nagrody kilka razy za to samo zdarzenie.

==================================================
28. ASSISTS
==================================================

Jeżeli inny gracz faktycznie uczestniczył w tym samym starciu:

+35 Money
+1 Assist

Assist powinien wymagać prawdziwego udziału w starciu w określonym oknie czasowym.

==================================================
29. REVIVE REWARD
==================================================

Prawidłowy revive:

+40 Money
+1 Revive

Dodaj anti-farming.

Wielokrotne celowe revive tej samej osoby nie może generować nieskończonego Money.

==================================================
30. STREAK REWARDS
==================================================

3 streak:
+100 bonus

5 streak:
+200

10 streak:
+500

15 streak:
+750

20 streak:
+1000

Każdy milestone wypłacaj tylko raz podczas danego streaka.

Downed resetuje:

CurrentStreak = 0

==================================================
31. HIGH VALUE TARGET
==================================================

Przy wysokim streaku gracz może zostać:

HIGH VALUE TARGET

10 streak:
bounty +150

15:
+250

20+:
+400

Bounty wypłacaj tylko po prawidłowym zakończeniu danego streaka.

==================================================
32. ANTI-FARMING PvP
==================================================

Nie pozwalaj dwóm graczom farmić siebie nawzajem.

Dla tego samego przeciwnika w krótkim okresie:

pierwsza nagradzana eliminacja:
100% Money

druga:
50%

trzecia:
25%

czwarta i następne:
0%

Po odpowiednim czasie multiplier może wracać do 100%.

Przechowuj to jako konfigurowalny system.

==================================================
33. ENCOUNTER SYSTEM
==================================================

Każde rozliczane starcie powinno mieć unikalny:

EncounterId

Serwer pilnuje:

RewardPaid = false/true

Nie pozwalaj rozliczyć tego samego Encounter dwa razy.

==================================================
34. TEAM OBJECTIVES
==================================================

Przygotuj system celów w Combat Zone.

Przykłady:

CONTROL POINT
ZONE HOLD
TEAM CHALLENGE

Przykładowe nagrody:

Small Objective:
+150 Money

Medium:
+300

Large:
+500

Cele drużynowe powinny być ekonomicznie atrakcyjne, żeby Zone nie polegała wyłącznie na zdobywaniu Kills.

==================================================
35. MONEY
==================================================

Główna waluta:

Money

Money zdobywa się przez:

PvP
Assists
Revives
Zone Objectives
Fishing
Side Activities

Money wydaje się na:

Kukiriny
Scooter Upgrades
Equipment
Cosmetics
Visual Tuning

==================================================
36. AUTOMATYCZNE FISHING
==================================================

Fishing ma być główną spokojną metodą zarabiania.

Dodaj:

FISHING AREA

np.:

jezioro + pomost.

Fishing Area jest bezpieczną strefą aktywności.

Gracz podchodzi do miejsca.

PC:

[E] ROZPOCZNIJ ŁOWIENIE

Mobile:

ŁÓW

Po rozpoczęciu:

PlayerState = FISHING

FishingState = ACTIVE

ŁOWIENIE JEST AUTOMATYCZNE.

NIE CHCĘ MINIGRY.

System:

START
→ losowy czas oczekiwania
→ serwer losuje wynik
→ jeżeli sukces, ryba trafia do FishingInventory
→ następne automatyczne łowienie
→ następne
→ następne

aż gracz kliknie:

STOP

lub odejdzie od łowiska.

==================================================
37. FISHING RNG
==================================================

RNG wykonuje SERWER.

Klient nie może powiedzieć:

"złowiłem Legendary".

FishingConfig określa:

- czas między próbami,
- szanse rarity,
- zakres wag,
- ceny,
- limity inventory.

==================================================
38. FISH RARITY
==================================================

COMMON
UNCOMMON
RARE
EPIC
LEGENDARY

Przykładowe fikcyjne ryby:

River Fish
Silver Carp
Blue Pike
Night Catfish
Golden Fish

FishData:

FishId
DisplayName
Rarity
MinWeight
MaxWeight
BaseValue

==================================================
39. FISH VALUE
==================================================

Cena zależy od:

BaseValue
× WeightModifier
× RarityModifier

Dokładną formułę trzymaj po stronie serwera.

Klient jedynie wyświetla wynik.

==================================================
40. FISH INVENTORY
==================================================

Dodaj:

FishingInventory

Każdy wpis:

FishId
Weight
Rarity

Dodaj limit inventory.

Po osiągnięciu limitu:

INVENTORY FULL

Fishing zostaje zatrzymany.

==================================================
41. FISH BUYER
==================================================

Przy łowisku znajduje się:

FISH BUYER

Menu:

YOUR FISH

SELL SELECTED
SELL ALL

Serwer sam:
- sprawdza inventory,
- oblicza wartość,
- usuwa sprzedane ryby,
- dodaje Money.

Klient nigdy nie podaje serwerowi kwoty Money.

==================================================
42. BALANS FISHING
==================================================

Fishing:

spokojny,
automatyczny,
stabilny,
ale wolniejszy.

PvP:

aktywny,
ryzykowny,
zmienny.

Objectives:

nagradzają współpracę.

Chcę, żeby wszystkie trzy style gry miały sens.

Fishing nie może generować absurdalnych ilości Money podczas AFK.

Dodaj:
- rozsądne tempo,
- limit inventory,
- walidację pozycji,
- server-side RNG.

==================================================
43. SIDE ACTIVITIES
==================================================

Przygotuj architekturę pod:

DELIVERY
TIME TRIAL
SCOOTER CHALLENGE
PACKAGE RUN

Nie implementuj wszystkich na początku.

Fishing jest pierwszą pełną aktywnością poza PvP.

==================================================
44. EQUIPMENT SHOP
==================================================

Dodaj sklep w Safe Zone.

UI:

ITEM
CATEGORY
STATS
PRICE
RARITY
OWNED

Opcje:

BUY
EQUIP

Zakup:

klient wysyła tylko EquipmentId.

Serwer sam sprawdza prawdziwą cenę oraz Money gracza.

==================================================
45. COSMETICS
==================================================

Dodaj:

ubrania,
tagi,
kolory,
animacje,
efekty,
Scooter cosmetics,
Squad cosmetics.

Kosmetyki nie wpływają na combat stats.

==================================================
46. MAIN HUD
==================================================

Pokazuj:

Money
Health
Current Area
Squad

==================================================
47. SCOOTER HUD
==================================================

Pokazuj:

SPEED
BATTERY
SCOOTER

==================================================
48. COMBAT HUD
==================================================

Pokazuj:

HEALTH
SQUAD
KILLS
DEATHS
STREAK
COMBAT STATUS

==================================================
49. DOWNED HUD
==================================================

Duży napis:

ZGINIĘTY

Pod nim:

ODRODZENIE ZA
00:60

OCZEKUJ NA OCUCENIE PRZEZ TEAMMATE'A

==================================================
50. FISHING HUD
==================================================

Pokazuj:

ŁOWIENIE...

LAST CATCH
INVENTORY: X/Y

STOP

==================================================
51. LEADERBOARD
==================================================

Dodaj:

PLAYER
KILLS
DEATHS
ASSISTS
REVIVES
STREAK

Dodatkowo:

TOP KILLS
TOP STREAK

==================================================
52. MOBILE
==================================================

Gra musi być projektowana MOBILE-FIRST.

Scooter:

GAS
BRAKE

Combat:

FIRE
AIM
RELOAD
SWITCH

Interactions:

INTERACT

Revive:

OCUĆ

Fishing:

START
STOP

Przyciski muszą być odpowiednio duże.

Nie zasłaniaj całego ekranu.

==================================================
53. DATASTORE
==================================================

PlayerData:

Money

OwnedScooters
SelectedScooter
ScooterUpgrades
ScooterCustomization

OwnedEquipment
EquippedLoadout

FishingInventory

Kills
Deaths
Assists
Revives
BestStreak

Cosmetics

Settings

Dane przechowuj sensownie pod jednym profilem gracza, jeśli mieszczą się w limitach.

Podczas sesji pracuj przede wszystkim na kopii danych w pamięci.

Dodaj:
- autosave,
- save przy PlayerRemoving,
- save przy zamykaniu serwera,
- retry/backoff dla przejściowych błędów,
- bezpieczną obsługę błędów.

==================================================
54. ANTI-CHEAT
==================================================

Zakładaj, że klient może zostać zmodyfikowany przez exploiterów.

Serwer jest źródłem prawdy dla:

Money
Purchases
Health
Damage
PlayerState
Downed
Revive
Kills
Deaths
Assists
Rewards
Fishing
Fish RNG
Scooter Ownership
Scooter Upgrades
Equipment Ownership

Każdy RemoteEvent:

TYPE VALIDATION
STATE VALIDATION
PERMISSION VALIDATION
DISTANCE VALIDATION
RATE LIMITING

Nie kickuj automatycznie za jedno dziwne zdarzenie.

Loguj podejrzane zachowania i reaguj na powtarzalne naruszenia.

==================================================
55. REMOTES
==================================================

Nie twórz RemoteEvent do każdej najmniejszej rzeczy bez potrzeby.

Przykładowe grupy:

PlayerRemotes
ScooterRemotes
ShopRemotes
SquadRemotes
CombatRemotes
ReviveRemotes
FishingRemotes

RemoteEvents trzymaj w:

ReplicatedStorage

Server-side handlers znajdują się w odpowiednich Services.

==================================================
56. CONFIG SYSTEM
==================================================

Utwórz:

GameConfig
EconomyConfig
ScooterConfig
UpgradeConfig
EquipmentConfig
CombatConfig
PvPRewardConfig
FishingConfig
ZoneConfig

Chcę móc zmieniać:

- ceny,
- damage w systemie arcade,
- cooldowny,
- nagrody,
- rarity,
- parametry Kukirinów,
- upgrade costs,
- Fishing rates

bez przepisywania systemów.

==================================================
57. ARCHITEKTURA
==================================================

Użyj modularnej architektury podobnej do:

ReplicatedStorage
    Shared
        Config
            GameConfig
            EconomyConfig
            ScooterConfig
            UpgradeConfig
            EquipmentConfig
            CombatConfig
            PvPRewardConfig
            FishingConfig
            ZoneConfig

        Types
        Utils

    Remotes
        PlayerRemotes
        ScooterRemotes
        ShopRemotes
        SquadRemotes
        CombatRemotes
        ReviveRemotes
        FishingRemotes

ServerScriptService
    Services
        PlayerDataService
        EconomyService
        ScooterService
        UpgradeService
        ShopService
        SquadService
        ZoneService
        CombatService
        DownedService
        ReviveService
        RewardService
        EquipmentService
        FishingService
        AntiCheatService

StarterPlayer
    StarterPlayerScripts
        Controllers
            InputController
            UIController
            ScooterController
            SquadController
            ZoneController
            CombatController
            ReviveController
            FishingController

StarterGui
    MainHUD
    ScooterHUD
    CombatHUD
    DownedHUD
    FishingHUD
    GarageUI
    ShopUI
    SquadUI

ServerStorage
    ScooterModels
    EquipmentTemplates

Workspace
    Map
        SafeZone
        Roads
        CombatZone
        FishingArea
        Garage
        Shops
        Buildings
        Cover

==================================================
58. OPTYMALIZACJA
==================================================

Priorytet:

PC + MOBILE.

Włącz/przygotuj projekt pod:

StreamingEnabled.

Nie wykonuj ciężkich obliczeń bez potrzeby co frame.

Nie spamuj RemoteEvents.

Nie twórz niepotrzebnych NPC.

Czyść:
- connections,
- stare pojazdy,
- tymczasowe obiekty,
- zakończone Encounter,
- stare Squad,
- niepotrzebne efekty.

==================================================
59. TESTY MULTIPLAYER
==================================================

Każdy ważny system testuj minimum dla:

1 PLAYER

2 PLAYERS

4 PLAYERS

Testuj także sztuczne opóźnienie sieciowe.

Sprawdź:

- czy UI działa,
- czy Squad się synchronizuje,
- czy Kukiriny są widoczne,
- czy Downed synchronizuje się poprawnie,
- czy Revive działa,
- czy timer jest zgodny,
- czy Reward nie wypłaca się dwa razy,
- czy Fishing nie duplikuje ryb,
- czy zakupy nie duplikują przedmiotów.

==================================================
60. KOLEJNOŚĆ DEVELOPMENTU
==================================================

NIE RÓB CAŁEJ GRY NARAZ.

PHASE 0 — FOUNDATION

- architektura,
- foldery,
- Config,
- Remotes,
- PlayerData,
- Snapshot klienta,
- save/load.

PHASE 1 — MAP / ZONES

- placeholder map,
- Safe Zone,
- Combat Zone,
- Fishing Area,
- area detection,
- Main HUD.

PHASE 2 — KUKIRIN

- R15,
- placeholder Scooter,
- VehicleSeat,
- spawn,
- despawn,
- jazda,
- speedometer,
- cleanup po respawnie.

PHASE 3 — GARAGE / PROGRESSION

- Garage,
- Dealership,
- kilka modeli,
- ownership,
- Workshop,
- upgrades,
- visual customization.

PHASE 4 — SQUADS

- Create,
- Invite,
- Accept,
- Leave,
- Kick,
- markers,
- distance,
- Friendly Fire OFF.

PHASE 5 — COMBAT FOUNDATION

- EquipmentConfig,
- Loadout,
- arcade PvP,
- Health,
- server validation,
- CombatTag,
- Combat HUD.

PHASE 6 — DOWNED / REVIVE

- ZGINIĘTY,
- Downed State,
- 60 seconds,
- teammate marker,
- revive interaction,
- revive progress,
- respawn,
- Safe Zone return.

PHASE 7 — PvP ECONOMY

- Kills,
- Deaths,
- Assists,
- Revives,
- Streak,
- Rewards,
- Bounty,
- EncounterId,
- Anti-farming,
- Leaderboard.

PHASE 8 — FISHING

- Fishing Area,
- automatic fishing,
- FishingState,
- server RNG,
- rarity,
- weight,
- inventory,
- Fish Buyer,
- Sell Selected,
- Sell All,
- Fishing economy.

PHASE 9 — SHOPS / COSMETICS

- Equipment Shop,
- Cosmetics,
- Scooter visual items,
- UI polish.

PHASE 10 — FINAL POLISH

- mobile,
- animations,
- audio,
- performance,
- anti-cheat,
- balancing,
- network tests,
- bug fixing.

==================================================
61. ZASADA "NIE IDŹ DALEJ"
==================================================

Po każdej PHASE:

STOP.

Najpierw:

1. Pokaż utworzone pliki.

2. Pokaż dokładną strukturę Explorer.

3. Wyjaśnij, co zrobiłeś.

4. Powiedz mi dokładnie, co mam zrobić w Roblox Studio.

5. Zakładaj, że jestem kompletnie początkujący.

6. Jeżeli trzeba coś kliknąć, napisz dokładnie:

KLIKNIJ:
ServerScriptService

NASTĘPNIE:
Insert Object

WYBIERZ:
Folder

NAZWIJ:
Services

7. Podaj checklistę testów.

8. Poczekaj na wynik testu.

9. Jeżeli test nie działa, naprawiamy go.

10. Dopiero po potwierdzeniu przechodzimy dalej.

==================================================
62. ZASADY KODU
==================================================

Pisz prawdziwy Luau.

Nie dawaj pseudokodu zamiast działającej implementacji.

Każdy system:
- modularny,
- czytelny,
- udokumentowany,
- łatwy do rozszerzenia.

Nie twórz jednego gigantycznego Script.

Oddziel:

SERVER LOGIC
CLIENT LOGIC
CONFIG
UI
DATA
NETWORKING

==================================================
63. PLACEHOLDERY
==================================================

Jeżeli nie posiadamy jeszcze:

modelu Kukirina,
animacji,
ikon,
dźwięków,
mapy,
modeli wyposażenia,

NIE udawaj, że asset istnieje.

Utwórz prosty placeholder albo dokładnie napisz, co trzeba dodać później.

Nie pobieraj przypadkowych assetów zawierających skrypty.

==================================================
64. PRIORYTETY
==================================================

Priorytety developmentu:

1. STABILNOŚĆ

2. MULTIPLAYER

3. FUN GAMEPLAY

4. SERVER AUTHORITY

5. ANTI-CHEAT

6. MOBILE

7. PERFORMANCE

8. PROGRESJA

9. UI

10. WYGLĄD

==================================================
65. TWOJE PIERWSZE ZADANIE
==================================================

ZACZNIJ TYLKO OD PHASE 0.

Nie implementuj jeszcze Combat, Fishing ani Kukirinów.

PHASE 0 ma przygotować fundament całej gry.

Zaprojektuj:

- dokładną strukturę projektu,
- wszystkie potrzebne foldery,
- Config,
- Services,
- Controllers,
- Remotes,
- PlayerData schema,
- Snapshot system,
- save/load,
- komunikację client-server.

Następnie napisz potrzebny kod Luau dla PHASE 0.

Na końcu:

1. pokaż dokładnie wszystkie utworzone pliki,

2. pokaż pełne drzewo Explorer,

3. wyjaśnij mi bardzo prostym językiem, co zostało zrobione,

4. napisz dokładnie krok po kroku, jak mam to uruchomić w Roblox Studio,

5. podaj checklistę PHASE 0,

6. NIE PRZECHODŹ DO PHASE 1, dopóki nie potwierdzę, że PHASE 0 działa.
```
