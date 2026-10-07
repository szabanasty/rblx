# Placeholdery i późniejsze assety

Wersja 0.3.0 uruchamia się bez Toolboxa, zewnętrznych modeli, pakietów, płatnych assetów, animacji i dźwięków. Nazwa hulajnogi jest opisem w katalogu; projekt nie zawiera logo ani modelu producenta.

## Co faktycznie istnieje

| Element | Źródło | Przeznaczenie |
| --- | --- | --- |
| Płaska platforma i spawn | `default.project.json` | Bezpieczny obszar testu core |
| Prosta hulajnoga | Serwerowy builder modelu | Widoczny placeholder z części Roblox, zespawany do jednej konstrukcji |
| HUD i przyciski dotykowe | Controllers klienta | Test informacji o profilu i serwerowym pojeździe |

Placeholder jest pojazdem arcade. Nie odtwarza konstrukcji, zawieszenia, rzeczywistej geometrii i zachowania konkretnego produktu. Koła nie mają osobnej realistycznej symulacji. Jest to celowy, samowystarczalny fundament do sprawdzenia sterowania i autorytetu serwera.

## Zastąpienie hulajnogi

Najpierw wykonaj kopię miejsca i modelu testowego. Przygotuj własny model lub model z licencją pozwalającą na użycie w tej grze. Nie podmieniaj przypadkowego modelu z Toolboxa bez sprawdzenia zawartych skryptów.

Docelowy asset umieść w `ServerStorage/ScooterAssets/<ScooterId>` jako model. Następny etap implementacji musi jawnie dodać loader z tego katalogu: **Obecny kod jeszcze nie ładuje automatycznie modeli z ServerStorage**. Samo dodanie modelu do Studio nie zastępuje obecnego buildera.

Kontrakt docelowego loadera:

1. `PrimaryPart` lub jednoznaczny root tworzy jedną fizyczną konstrukcję.
2. Części dekoracyjne są zespawane, `Massless = true`, a zbędne kolizje wyłączone.
3. Seat, punkt kierowcy i root mają określone nazwy/attachmenty. Serwer utrzymuje network ownership.
4. Id w katalogu wskazuje model, statystyki i dozwolone kolory. Gracz nie wysyła asset ID lub nowego modelu w remote.
5. Test obejmuje odwrócenie/uderzenie, wysiadanie, rejoin, śmierć kierowcy i dwa pojazdy naraz.

Przy wersjonowaniu modeli można dodać świadome mapowanie `assets/` do Rojo lub użyć eksportów `.rbxm`/`.rbxmx`. Obiekt ręcznie dodany do Studio nie staje się automatycznie plikiem repozytorium.

## Lista na następne etapy

| Etap | Do stworzenia | Wymagania |
| --- | --- | --- |
| 2 | Budynki, drogi, rampy, mosty, tunele, znaki, światła, sklepy, garaż i NPC auta | Oryginalny układ miasta; oszczędna geometria, kolizje, podział StreamingEnabled |
| 3 | Punkty dostaw, checkpointy, dekoracje trasy, efekty tricków | Wizualizacje nie są dowodem ukończenia; serwerowe reguły trasy pozostają niezależne |
| 4 | Pets, ubrania, naklejki, trofea, dekoracje domu | Własne/legalne modele; Street Hoodie, Tech Pants i Premium Sneakers jako robocze nazwy bez cudzych logo |
| 5 | Uniform, światła, syrena, radar i marker GPS | Arcade, bez przemocy; syrena i wyposażenie nie oznaczają samodzielnego prawa do karania |
| 6 | Kosmetyki VIP, efekty i ikony sezonu | ID produktów tworzone przez właściciela gry; brak wymyślonych ID |
| 7 | Animacje jazdy/skoków, UI ikony, muzyka i SFX | Publikacja assetów z konta/grupy gry i sprawdzenie uprawnień oraz moderacji |

Nie ma muzyki OKEKELA ani innego artysty, cudzych znaków Nike/BAPE ani kopii mapy GTA. Jeśli właściciel uzyska odpowiednie prawa, katalog assetów może zostać rozszerzony o udokumentowane, legalne materiały. Dostępność modelu w Toolboxie sama nie stanowi potwierdzenia praw do znaków i muzyki.

## Audio

Docelowy AudioConfig ma oddzielać muzykę, SFX pojazdu, UI i policję. Puste lub brakujące SoundId oznacza ciszę. Nie tworzymy fikcyjnego `rbxassetid://...` i nie pobieramy dźwięku z losowego źródła.

W Studio później trzeba: wgrać/wybrać legalny dźwięk, nadać doświadczeniu uprawnienia do assetu, skopiować ID do katalogu i przetestować odsłuch w opublikowanej grze. Ustawienia Music/SFX Volume oraz Reduced Effects powinny zmieniać efekty lokalne, a nie reguły rozgrywki.

## Mapa i mobilna wydajność

Nie składaj miasta z tysięcy pojedynczych dekoracyjnych części. Grupuj dzielnice w modele, stosuj proste kolizje i powtarzalne elementy, ogranicz cienie oraz przezroczystość. LOD i streaming pomagają dopiero po testach na rzeczywistym urządzeniu. Nazwy obszarów i metadane dróg przechowuj w konfiguracji; nie ukrywaj reguł gry wyłącznie w modelach dostępnych klientowi.

## Miasto obecnej wersji

WorldBuilder i WorldService tworzą z Partów drogi/chodniki/oznaczenia, budynki, drzewa, rampy, piach plaży i punkty interakcji. TrafficService używa sześciu prostych aut bez kolizji. Nie ma assetów reklam, prawdziwych logo, odtwarzanej muzyki ani modeli marek. Dzielnice Hills/Beach/Secret i Police/Race są placeholderami charakteru terenu oraz miejscem przyszłego level designu; nie zawierają gotowych aktywności.

Ręcznie dodawane modele umieść w istniejących folderach Map poza Generated. Generator nie importuje ich do swoich tras automatycznie: konfigurację RoadConfig/WorldConfig oraz trasy trzeba dostosować przy wymianie mapy. Duże modele dekoracji podziel na mniejsze modele Atomic i sprawdź streaming. Nie deklarujemy zrealizowanego LOD assetów mesh, których jeszcze nie ma.
