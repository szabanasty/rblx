# rblx — projekt Roblox/Luau

Czysty punkt startowy do tworzenia gry w Roblox Studio. Kod Luau jest przechowywany w plikach, a **Rojo 7.7.1** synchronizuje go ze Studio. Projekt zawiera tylko konfigurację, wspólny moduł, dwa skrypty sprawdzające synchronizację oraz prostą platformę ze spawnem. Nie zawiera jeszcze mechaniki gry ani zewnętrznych bibliotek.

## Struktura projektu

```text
rblx/
├── default.project.json       # konfiguracja i drzewo obiektów Rojo
├── src/
│   ├── server/
│   │   └── init.server.luau   # serwerowy Script
│   ├── client/
│   │   └── init.client.luau   # kliencki LocalScript
│   └── shared/
│       └── ProjectInfo.luau   # współdzielony ModuleScript
├── scripts/
│   └── install-tools.sh      # opcjonalna instalacja narzędzi na Linux x86_64
├── .gitignore
└── README.md
```

Mapowanie zapisane w `default.project.json`:

| Plik lub katalog | Obiekt w Roblox Studio |
| --- | --- |
| `src/server/init.server.luau` | `ServerScriptService.Server` — `Script` |
| `src/client/init.client.luau` | `StarterPlayer.StarterPlayerScripts.Client` — `LocalScript` |
| `src/shared/` | `ReplicatedStorage.Shared` — `Folder` |
| `src/shared/ProjectInfo.luau` | `ReplicatedStorage.Shared.ProjectInfo` — `ModuleScript` |

Plik `init` sprawia, że odpowiadający mu katalog staje się skryptem. Dlatego `Server` i `Client` są skryptami, a kolejne pliki w tych katalogach zostaną ich dziećmi. Zwykły plik `.luau` tworzy `ModuleScript`; `.server.luau` tworzy `Script`, a `.client.luau` tworzy `LocalScript`.

Konfiguracja tworzy też `Workspace.Baseplate` i `Workspace.SpawnLocation`, żeby można było uruchomić pustą scenę i zobaczyć postać.

## Co trzeba zainstalować na komputerze

Wymagane są:

1. **Roblox Studio** na Windows lub macOS: [oficjalna instrukcja instalacji](https://create.roblox.com/docs/studio/setup). Uruchom je i zaloguj się na konto Roblox.
2. **Rojo CLI 7.7.1**: [oficjalne wydanie](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1).
3. **Wtyczka Rojo do Roblox Studio**, instalowana z tego samego CLI poleceniem `rojo plugin install`.

Edytor jest dowolny. Opcjonalnie możesz zainstalować Visual Studio Code i rozszerzenie [Luau Language Server — `JohnnyMorganz.luau-lsp`](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp). Nie jest ono wymagane do synchronizacji. Projekt nie wymaga Node.js, Wally ani menedżera narzędzi.

### Windows

Pobierz odpowiednie archiwum z oficjalnego wydania:

| Komputer | Archiwum |
| --- | --- |
| Zwykły Windows z procesorem Intel/AMD | [rojo-7.7.1-windows-x86_64.zip](https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-windows-x86_64.zip) |
| Windows na ARM | [rojo-7.7.1-windows-aarch64.zip](https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-windows-aarch64.zip) |

Rozpakuj `rojo.exe` do `%USERPROFILE%\Tools\Rojo\7.7.1`. W PowerShell ustaw ścieżkę dla bieżącej sesji i sprawdź wersję:

```powershell
$env:Path = "$env:USERPROFILE\Tools\Rojo\7.7.1;$env:Path"
rojo --version
```

Oczekiwany wynik: `Rojo 7.7.1`. Aby polecenie było dostępne po otwarciu kolejnego terminala, dodaj ten katalog do zmiennej użytkownika `Path` w ustawieniach zmiennych środowiskowych Windows.

### macOS

Pobierz archiwum dla swojego procesora:

| Komputer | Archiwum |
| --- | --- |
| Apple Silicon, np. M1/M2/M3/M4 | [rojo-7.7.1-macos-aarch64.zip](https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-macos-aarch64.zip) |
| Mac z procesorem Intel | [rojo-7.7.1-macos-x86_64.zip](https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-macos-x86_64.zip) |

Rozpakuj archiwum. W terminalu przejdź do katalogu zawierającego rozpakowany plik `rojo` i wykonaj:

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 ./rojo "$HOME/.local/bin/rojo"
export PATH="$HOME/.local/bin:$PATH"
rojo --version
```

Oczekiwany wynik: `Rojo 7.7.1`. Dopisz `export PATH="$HOME/.local/bin:$PATH"` do `~/.zshrc`, żeby ustawienie działało również w kolejnych terminalach.

### Wtyczka Studio

Po zainstalowaniu i pierwszym uruchomieniu Roblox Studio zamknij je, a w terminalu wykonaj:

```sh
rojo plugin install
```

Polecenie instaluje wtyczkę do lokalnego katalogu wtyczek Studio. Otwórz Studio ponownie; Rojo powinno pojawić się na karcie **Plugins/Wtyczki**. CLI zawiera zgodną wtyczkę, więc nie trzeba instalować drugiej kopii z Marketplace. Jeśli Rojo nie potrafi znaleźć Studio, sprawdź, czy Studio jest zainstalowane i było uruchomione na tym samym koncie systemowym.

## Pierwsze uruchomienie

### 1. Otwórz lokalną kopię repozytorium

Na komputerze, na którym działa Studio, otwórz [repozytorium na GitHub](https://github.com/szabanasty/rblx) i wybierz **Code → Download ZIP**. Możesz też użyć [bezpośredniego linku do ZIP](https://github.com/szabanasty/rblx/archive/refs/heads/main.zip). Jeśli repozytorium jest prywatne, zaloguj się na GitHub na konto mające do niego dostęp.

Rozpakuj archiwum i otwórz folder `rblx-main`, w którym znajdują się `default.project.json` i `src/`. Zamiast pobierania ZIP możesz sklonować repozytorium:

```sh
git clone https://github.com/szabanasty/rblx.git
cd rblx
```

Polecenia poniżej wykonuj z katalogu zawierającego `default.project.json`. Archiwum z GitHub zawiera źródła; katalog `build/` i plik miejsca `build/rblx.rbxlx` powstaną po wykonaniu kolejnego kroku.

### 2. Zbuduj plik miejsca

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
rojo build default.project.json --output build/rblx.rbxlx
```

macOS lub Linux:

```sh
mkdir -p build
rojo build default.project.json --output build/rblx.rbxlx
```

Otwórz `build/rblx.rbxlx` w Roblox Studio przez **File → Open from File**. Zobaczysz platformę, spawn i drzewo projektu. Katalog `build/` zawiera wygenerowane pliki i jest ignorowany przez Git.

### 3. Włącz synchronizację

W terminalu na **tym samym komputerze co Studio** uruchom:

```sh
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

Pozostaw terminal otwarty. W Studio otwórz panel wtyczki Rojo, ustaw adres serwera **`localhost`** i port **`34872`**, a następnie wybierz **Connect**. Jeśli pojawi się podgląd zmian lub prośba o ich zastosowanie, sprawdź wymienione obiekty projektu i zaakceptuj synchronizację.

Do pierwszego połączenia użyj zbudowanego miejsca lub nowego, pustego miejsca. Przed podłączeniem do istniejącej gry zapisz jej kopię. Rojo zarządza obiektami zapisanymi w konfiguracji i może nadpisywać ich właściwości oraz kod.

### 4. Sprawdź działający kod

Otwórz panel **Output/Wyjście** w Studio i uruchom **Play** (`F5`). Po uruchomieniu serwera i klienta powinny pojawić się oba komunikaty:

```text
[rblx][server] Sync ready (version 0.1.0).
[rblx][client] Sync ready (version 0.1.0).
```

Pierwszy pochodzi ze skryptu w `ServerScriptService`, drugi z `LocalScript` kopiowanego ze `StarterPlayerScripts` do gracza. Oba odczytują moduł `ReplicatedStorage.Shared.ProjectInfo`. W panelu Output włącz widoczność komunikatów zarówno serwera, jak i klienta.

### 5. Sprawdź aktualizację plików

Zatrzymaj grę (**Stop**), pozostawiając Rojo podłączone. W `src/shared/ProjectInfo.luau` zmień `Version = "0.1.0"` na `Version = "0.1.1"` i zapisz plik. Sprawdź w Studio, czy kod modułu został zaktualizowany, a następnie uruchom **Play** ponownie. Oba komunikaty powinny teraz zawierać `version 0.1.1`.

Ponowne uruchomienie jest potrzebne, ponieważ już uruchomione skrypty nie wykonują się od nowa po synchronizacji, a wynik `require` jest przechowywany w pamięci. Po sprawdzeniu możesz przywrócić wersję `0.1.0`.

## Codzienna praca

- Edytuj kod w `src/`; pliki są źródłem prawdy. Zmian wykonanych bezpośrednio w edytorze skryptów Studio Rojo nie zapisuje automatycznie do repozytorium.
- Utrzymuj `rojo serve` i połączenie wtyczki podczas pracy. Zakończ serwer przez `Ctrl+C`.
- Dodawaj kod serwera do `src/server`, kod klienta do `src/client`, a moduły używane po obu stronach do `src/shared`. Kod w `ReplicatedStorage` jest dostępny klientom, więc nie przechowuj tam sekretów ani logiki wymagającej zaufania serwerowi.
- Zmieniaj `default.project.json`, kiedy chcesz rozszerzyć strukturę usług lub dodać obiekty zarządzane przez Rojo.
- Po zmianie struktury uruchom `rojo build default.project.json --output build/rblx.rbxlx`, żeby sprawdzić, czy Rojo potrafi zbudować projekt.
- Przed zapisem zmian do Git sprawdź `git status`. Eksporty miejsca w katalogu głównym, pliki lokalne i `build/` są ignorowane. Modele `.rbxm`/`.rbxmx` przeznaczone do wersjonowania możesz później umieszczać np. w `assets/`; reguły ignorowania nie wykluczają ich w tym katalogu.

`$ignoreUnknownInstances` w konfiguracji pozwala zachować dodatkowe obiekty na wskazanych poziomach drzewa Studio. Nie zapisuje ich jednak do plików. Nowe mapy i modele wymagają osobnej, świadomie wybranej metody wersjonowania.

## Środowisko chmurowe Codex

Chmura obsługuje edycję plików, budowanie przez Rojo oraz sprawdzanie składni Luau. Roblox Studio wymaga Windows lub macOS i nie uruchamia się w tym środowisku Linux. Końcowy test **Play** wykonaj na swoim komputerze zgodnie z instrukcją powyżej.

Rojo uruchomione w chmurze pod adresem `127.0.0.1` nie jest serwerem `localhost` Twojego komputera. Do pracy ze Studio korzystaj z lokalnej kopii projektu i lokalnie uruchomionego Rojo.

Na Linux x86_64 instalację przypiętych narzędzi można odtworzyć skryptem:

```sh
bash scripts/install-tools.sh
export PATH="/workspace/.tools/rojo/7.7.1:/workspace/.tools/luau/0.741:$PATH"
rojo --version
mkdir -p build
rojo build default.project.json --output build/rblx.rbxlx
luau-compile src/server/init.server.luau src/client/init.client.luau src/shared/ProjectInfo.luau > /dev/null
```

Skrypt instaluje Rojo 7.7.1 oraz narzędzia Luau 0.741; wymaga `bash`, `curl`, `unzip`, `sha256sum` i standardowych narzędzi systemowych, w tym `mktemp`. Pobiera oficjalne archiwa i sprawdza ich sumy SHA-256. Domyślnie używa `/workspace/.tools`. Na własnym komputerze z Linux możesz wskazać inny katalog:

```sh
RBLX_TOOLS_DIR="$PWD/.tools" bash scripts/install-tools.sh
export PATH="$PWD/.tools/rojo/7.7.1:$PWD/.tools/luau/0.741:$PATH"
```

Kompilacja Luau sprawdza składnię; nie zastępuje testu działania skryptów w silniku Roblox. Do startu projektu nie są potrzebne żadne sekrety ani dodatkowe zmienne aplikacji.

## Gdy połączenie lub test nie działa

| Objaw | Co sprawdzić |
| --- | --- |
| `rojo` nie jest rozpoznawane | Katalog z binarką musi być w `PATH`; uruchom `rojo --version` w tym samym terminalu. |
| Wtyczka nie pojawia się w Studio | Wykonaj `rojo plugin install`, uruchom Studio ponownie i sprawdź kartę Plugins. |
| Wtyczka nie łączy się | Serwer musi działać lokalnie, na porcie `34872`; sprawdź adres, port i komunikaty terminala. |
| Port jest zajęty | Zakończ poprzedni własny proces Rojo lub wybierz inny port w poleceniu i wtyczce. |
| Jest tylko komunikat serwera | Użyj Play, które tworzy gracza, oraz włącz widok klienta w Output. Samo Run nie uruchamia pełnego testu klienta. |
| Zmiana wersji nie pojawia się w logach | Zapisz plik, sprawdź aktywne połączenie Rojo, a następnie wykonaj Stop i ponownie Play. |
| Skrypt czeka na `Shared` lub `ProjectInfo` | Sprawdź mapowanie i drzewo `ReplicatedStorage`; odbuduj miejsce i połącz Rojo. |
