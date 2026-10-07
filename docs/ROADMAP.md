# Plan implementacji i kryteria gotowości

Każdy wycinek kończy się testami dostępnymi w środowisku. Gdy Studio nie jest dostępne, rozwój niezależnej logiki może trwać, lecz odbiór gameplayu pozostaje jawnie niepotwierdzony. Konfiguracja nie oznacza gotowej mechaniki. Przed wydaniem trzeba odebrać fizykę, multiplayer, mobile i zapis w silniku.

**Stan 0.3.0:** PHASE 0 — dokumentacja; PHASE 1 — zaimplementowany core; PHASE 2 — 13 blockoutów dzielnic, drogi, limity, punkty sklepów/garażu, 6 NPC i dzień/noc; PHASE 3 — jedna dostawa, zakup i sześć aktywnych upgrade. Testy kodu przechodzą; Studio i prawdziwy telefon są nadal do sprawdzenia. Całe fazy 2/3 nie są ukończone.

## PHASE 0 — architektura

**Zakres:** podział klient/serwer/shared, katalogi konfiguracji, typy trwałych danych i projekcji, kierunki komunikacji, zależności usług, session locking, plan etapów i wymagania assetów.

**Wynik:** [ARCHITECTURE.md](ARCHITECTURE.md), ten plan i szkielet wymagany przez PHASE 1. Brak pustych modułów wyścigu/policji sugerujących, że te systemy już działają.

**Gotowe, gdy:** wiadomo, kto może zmieniać każdy ważny stan, co jest zapisywane, jakie remotes istnieją i jak dodać nową funkcję bez obejścia ekonomii.

## PHASE 1 — core

**Zakres:** load/save, Money, XP, Level, starter, serwerowe spawn/despawn i jazda, proste nagrody za zweryfikowany dystans, HUD, klawiatura i przyciski dotykowe. Pierwotny plac core jest teraz otoczony generowanym blockoutem miasta.

**Gotowe, gdy:** Rojo buduje miejsce i kod kompiluje się; pojedynczy gracz i dwaj gracze mogą sterować niezależnymi pojazdami; nagrody pochodzą z serwera; wyjście/respawn sprzątają pojazd; opublikowana gra poprawnie zapisuje profil i blokadę. Domyślne Studio świadomie używa pamięci.

**Ręczny odbiór:** [PHASE_1_TESTING.md](PHASE_1_TESTING.md). Przed wydaniem i uznaniem fundamentu za odebrany trzeba potwierdzić zachowanie fizyki, HUD i multiplayer w Roblox Studio. Kompilacja w Linux nie potwierdza tych elementów.

## PHASE 2 — world

**Zakres:** oryginalna mapa placeholder, początkowo mały Downtown + Residential + tor testowy. Modułowe RoadData, 30/50/70/90 km/h według typu drogi, sklepy i garaż jako miejsca interakcji. Kilka pojazdów NPC w ograniczonej puli, światła i proste trasy.

**Architektura całej mapy:** Downtown, Residential, Industrial, Suburbs, Beach, Highway, Shopping, Old Town, Hills, Park, Police, Race i obszary sekretne. Dzielnice mają własne konfiguracje, punkty spawnu i wymagania odblokowania. Nie budujemy wszystkich naraz.

**Gotowe, gdy:** gracz na PC i urządzeniu dotykowym porusza się po pierwszych dzielnicach bez blokad; drogi poprawnie wskazują limit; streaming nie psuje klienta; ruch NPC zatrzymuje się na światłach i ma akceptowalny koszt. Test na rzeczywistym telefonie jest wymagany do oceny wydajności.

## PHASE 3 — gameplay

**Zakres:** dostawa i quest dystansowy, Sprint/Time Trial z lobby i checkpointami, zakup/ulepszenia hulajnóg, pierwszy rozpoznawalny trick i EventManager. Następnie Circuit, Street/Highway/Trick Race, kolekcjonowanie i rozbudowa eventów.

**Zasady:** Engine/Battery/Brakes/Tires/Suspension/Handling/Acceleration mają poziomy i realny wpływ na statystyki. Klient nie przesyła czasu przejazdu ani nowych statystyk. Quest i event rozdzielają nagrodę najwyżej raz. Combo i trick reward mają limity, aby powtarzana czynność nie tworzyła nieskończonego zarobku.

**Gotowe, gdy:** próby skrócenia trasy teleportem, pominięcia checkpointu, powtórzenia odbioru nagrody i zakupu bez pieniędzy są odrzucane. Da się rozegrać wyścig co najmniej dwóch graczy, a rozłączenie nie blokuje lobby.

## PHASE 4 — social

**Zakres:** pets/inventory/equip i ograniczone bonusy, hatch za walutę gry, ubrania z placeholderów, garaż/kolekcja, crew/party, osiągnięcia, Daily/Weekly i rankingi.

**Pet rarity:** Common, Uncommon, Rare, Epic, Legendary, Mythic. Bonusy XP/Money/RaceReward/TrickScore mają wspólne górne granice; warstwy mnożników nie mogą zrujnować ekonomii. Płatne losowe przedmioty wymagają osobnej implementacji zasad Roblox i nie są domyślną funkcją hatchowania.

**Gotowe, gdy:** dane kolekcji i zaproszeń działają po ponownym wejściu; gracz nie może wyposażyć nieposiadanego przedmiotu; nazwy crew przechodzą filtr; wynik rankingowy bierze się tylko z serwera; party radzi sobie z odejściem lidera.

## PHASE 5 — police

**Zakres:** role Civilian/Police z wymaganiami i cooldownem, policyjny placeholder i uniform, serwerowy radar, dowody wykroczeń, mandaty, Wanted/pościgi, GPS/radio/UI, reputacja kierowcy i legalna jazda.

**Progres policji:** PoliceXP, PoliceReputation, PoliceCredits oraz Cadet → Officer → Senior Officer → Sergeant → Lieutenant → Captain. Credits służą głównie kosmetykom. Pojazd policji nie dostaje automatycznej przewagi statystyk.

**Wykroczenia:** Minor +1–10 km/h, Major +11–25, Severe +26 i więcej; wartości i wysokości kar są w konfiguracji. Pościg jest arcade’owy. Zatrzymanie wymaga poprawnego pomiaru, odległości i warunków ruchu, a nie żądania klienta.

**Eventy:** Speed Trap, Highway Patrol, Traffic Control, Wanted Driver, City Chase. Limit nagród dla tej samej pary graczy, cooldown i ograniczenie nadużywającego policjanta.

**Gotowe, gdy:** policja nie może ukarać niewinnego/odległego gracza, spamować ani wielokrotnie nagradzać jednego dowodu. Wychodzący gracz i zmiana roli nie pozostawiają aktywnego pościgu bez właściciela.

## PHASE 6 — monetization

**Zakres:** rzeczywiste Game Passes/Developer Products, rangi VIP/PREMIUM/ELITE, kosmetyki, dodatkowe sloty i wygoda; Battle Pass z sezonem, XP oraz darmową i premium ścieżką.

**Wymagania:** użytkownik tworzy produkty we własnej grze i przekazuje ich niesekretne ID do konfiguracji. MarketplaceService oraz `ProcessReceipt` działają na serwerze. ID receipt jest zapisane, nadanie jest trwałe i idempotentne. Niedostępny DataStore powoduje ponowienie później, nie utratę zakupu.

**Gotowe, gdy:** powtórzony receipt nie daje drugiej nagrody; rejoin nie usuwa uprawnień; brak ID uniemożliwia zakup; sezon nie usuwa stałych kolekcji. Nie sprzedajemy nieograniczonej prędkości, dużej przewagi wyścigowej ani ekonomicznej dominacji policji.

## PHASE 7 — polish

**Zakres:** prawdziwe modele i animacje, atmosfera dnia/nocy/pogody, legalne audio i efekty, tutorial możliwy do pominięcia, map/minimap/GPS, rozbudowane UI i ustawienia, balans, profilowanie oraz podstawowe narzędzia administracyjne.

**Priorytet mobile:** duże przyciski gaz/hamulec/skręt/skok/interakcja/radar; drift dopiero po gotowej mechanice. UI Scale, Graphics Quality, Music/SFX Volume, Reduced Effects. HUD nie może zasłaniać standardowych elementów Roblox ani wymagać precyzyjnego stukania.

**Tutorial:** spawn → starter → jazda → zadanie → zarobek → upgrade → wyścig → policja → garaż. Krok potwierdza serwerowe zdarzenie, nie klient.

**Admin:** uprawnienia tylko z serwerowej allowlisty UserId. Testowanie ekonomii, logi, reset/start eventu i teleport administratora są oddzielone od zwykłych żądań graczy.

**Gotowe, gdy:** kontrolna sesja multiplayer na PC/telefon/tablet nie wykazuje regresji danych, pamięci i połączeń; sterowanie i interfejs są czytelne; nieaktywne systemy nie pracują co klatkę; budżet części, efektów i NPC jest zmierzony na urządzeniu docelowym.

## Rozwój po premierze

Nowe hulajnogi, dzielnice, pets, trasy, policyjne wydarzenia i sezony powinny zaczynać się od wpisu w katalogu oraz testu zgodności z istniejącym schematem. Crew Wars to osobna funkcja z nowymi regułami, a nie dopisany bonus do każdej nagrody. Migrację danych i balans testujemy przed opublikowaniem aktualizacji.

## Najbliższa kolejność

1. Odbiór obecnego prototypu według TESTING.md i korekty fizyki/UI na rzeczywistym telefonie oraz serwerze 2 graczy.
2. Serwerowy Sprint/Time Trial: lobby, countdown, checkpointy w kolejności, minimalny czas segmentu, finish raz, rejoin/leave i leaderboard sesji.
3. Kolejne delivery/dystansowe questy, tutorial, zużycie/ładowanie baterii i odblokowanie jej upgrade.
4. Dopiero potem trick scoring, wydarzenia, trwałe rankingi i systemy społecznościowe.
