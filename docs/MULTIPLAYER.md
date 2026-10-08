# Multiplayer — wersja 0.6.1

## Lokalnie w Roblox Studio

Zatrzymaj Play. Pobierz nowy ZIP i uruchom Rojo z nowego katalogu zgodnie z README. Connect, synchronizacja; Output ma pokazać 0.6.1. Test → Server & Clients / Serwer i klienci: uruchom 2 klientów, a następnie 3 do sprawdzenia revive i friendly fire. Zwykłe Play uruchamia tylko jednego gracza.

Każdy gracz odbiera własną hulajnogę. Drugi gracz nie może prowadzić cudzej. Przejedź przez most na Iron Island (COMBAT od X800). A tworzy squad i zaprasza B w menu; B akceptuje. C jest przeciwnikiem. A/B nie zadają sobie damage; C może ich powalić, a teammate może przytrzymać E przez 5 s, aby ocucić. Puść E, odejdź, otwórz menu albo rozłącz medyka: revive powinien się przerwać. Sprawdź także odejście leadera, restart postaci i ponowne wejście.

Spark ma 12 nabojów i 12 damage. Przeładowuj R także w SAFE; strzały są aktywne w COMBAT lub podczas combat tagu. Nie testuj damage przez pierwsze 3 s ochrony spawnu i 2 s po revive. Eliminacja oraz nagroda czekają na definitywny respawn/reset/wyjście, a nie sam moment DOWNED.

## Gra ze znajomymi przez Roblox

1. Stop w Studio, aktualna synchronizacja, File → Publish to Roblox. Publikujesz **miejsce z synchronizowanym kodem**, nie sam ZIP. Zachowaj własny istniejący identyfikator doświadczenia, jeśli chcesz zachować jego dane.
2. W Creator Dashboard ustaw dostęp do doświadczenia dla wybranej grupy testerów/znajomych. Konto i doświadczenie muszą spełniać aktualne wymagania Roblox dotyczące publikacji i dostępu. Ustawienia doświadczenia wybierają dostęp; skrypt nie nadaje tych uprawnień.
3. Ustaw avatar R15. Na pierwszy wspólny test rozsądny limit serwera to 12 osób; limit hulajnóg w kodzie wynosi 30, ale nie oznacza potwierdzonej wydajności telefonu przy 30 graczach.
4. Wejdźcie przez aplikację Roblox do **tego samego serwera**. Squad, invite, control point i leaderboard są w ramach jednego serwera; nie łączą osób z różnych instancji.
5. Opublikowana gra używa DataStore automatycznie. `UseStudioDataStore = false` wyłącza prawdziwy zapis wyłącznie w Studio, nie w produkcji. Nie zmieniaj produkcyjnej nazwy DataStore podczas aktualizacji.

Do testu prawdziwego zapisu **w Studio** użyj osobnego doświadczenia DEV, włącz API Services i ustaw `UseStudioDataStore = true` oraz osobną nazwę magazynu, zgodnie z README. StudioMemory resetuje postęp po Stop. Legalne audio/animacje pozostają opcjonalną konfiguracją; do bieżącej gry nie jest wymagane pobieranie cudzych assetów.

## HUD

Strefa i squad: lewa góra. Money/Level/XP: prawa góra. HP i K/D/streak: dół po lewej. Minimap: osobno, nad HP na PC. Wyposażenie/ammo: prawa strona; na krótkim ekranie dolny środek. Podczas jazdy panel prędkości/baterii zastępuje wyposażenie. Łowienie/control point pojawiają się tylko podczas odpowiedniej aktywności.

Telefon: HUD rezerwuje miejsce dla native ruchu/skoku i dużych przycisków jazdy/walki. Na małym ekranie minimapę otwiera MENU → POKAŻ / UKRYJ MINIMAPĘ. Otwarta mapa i dostępny revive czasowo ukrywają kolidujące informacje. Menu puszcza gaz, przywraca FOV i przerywa fire/hold; zamknięcie menu nie powinno samo rozpoczynać jazdy ani ognia.

Przed szerszym udostępnieniem wykonaj [checklistę silnika](TESTING.md). W chmurze przeszły testy kodu i mocków, nie realny test sieci Roblox, fizyki czy telefonu.
