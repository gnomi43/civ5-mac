# Civilization V on Mac — multiplayer with Windows, fixes and tweaks

[Русский](#русский) · [English](#english)

Scripts for the **Steam Mac version of Sid Meier's Civilization V** (Aspyr port, runs under Rosetta on Apple Silicon). Tested on an M4 Pro MacBook with macOS 27, in real games with Mac and Windows players.

---

## Русский

### Что умеет
| Папка / файл | Что делает |
|---|---|
| `Civ5-crossplay/crossplay.sh` | Игра по сети с Windows: меняет номер сборки 180925 → 403694 и переподписывает приложение |
| `Civ5-ru-patch/options.sh` | 11 скрытых опций партии в «Дополнительных настройках» и в сетевой игре |
| `Civ5-ru-patch/tweaks.sh` | 23 настройки графики и удобства под Apple Silicon |
| `Civ5-terrain/terrain.sh` | Ставит текстуры карты [TTE 2k](https://forums.civfanatics.com/threads/terrain-texture-enhancement-2k.570307/) как DLC (сам мод скачать у автора) |
| `Civ5-ru-patch/install.sh` | Русификация. **Файлов игры в репозитории нет**: payload собирается из русской Windows-версии (см. ниже) |
| `1.…5. *.command` | То же двойным щелчком в Finder, без Терминала |

У каждого скрипта есть откат (`uninstall` / `restore`), а оригиналы сохраняются в
`~/Library/Application Support/Sid Meier's Civilization 5/*-backup`.

### Как поставить без Терминала
1. Скачай репозиторий (Code → Download ZIP), распакуй и переименуй папку в `Civ5-Mac`. Положи её в «Загрузки».
2. Один раз запусти игру из Steam, дойди до главного меню и выйди.
3. Двойной щелчок по **«1. Установить или обновить»**. Если macOS не пускает: правый щелчок → «Открыть» → «Открыть».
4. Подробности — в файле **«0. Инструкция.txt»**.

### Терминалом
```bash
cd ~/Downloads/Civ5-Mac
bash Civ5-ru-patch/options.sh
bash Civ5-ru-patch/tweaks.sh
Civ5-terrain/terrain.sh install        # если положил TTE_2k в Civ5-terrain/payload/
Civ5-crossplay/crossplay.sh install    # всегда последним — переподписывает приложение
```

### Важно
- **Любая правка файлов игры ломает подпись Aspyr.** Потом Steam пишет «OS Error 256», а macOS — «приложение не может быть открыто». Иногда это проявляется только через несколько дней. Лечится командой `crossplay.sh sign`. Xcode не нужен.
- **Никогда не удаляй весь `cache/*.db` разом.** Mac-версия соберёт пустой `Localization-Merged.db` и будет закрываться через ~20 с после запуска. Лечится удалением только `cache/Localization-*.db` (`terrain.sh fixcache` или «4. Починить запуск»).
- Обновление в Steam или «Проверить целостность файлов» откатывает всё. После этого снова запусти «1. Установить или обновить».

### Русификация
В Mac-сборке русского нет. `install.sh` ставит содержимое `Civ5-ru-patch/payload/Assets`, но эта папка не публикуется: в ней тексты и озвучка самой игры. Её собирают из русских файлов Windows-версии из своего Steam-аккаунта. Ещё нужны:
- шрифтовые атласы с кириллицей (Tw Cen MT);
- `UseExtendedFont=0` в `Russian.xml` (с 1 Mac-версия падает);
- замена `Locale.Compare` в нескольких Lua-файлах интерфейса (иначе в сетевой настройке пустые списки).

---

## English

### What's inside
| Folder / file | What it does |
|---|---|
| `Civ5-crossplay/crossplay.sh` | Multiplayer with Windows: changes the build number 180925 → 403694 and re-signs the app |
| `Civ5-ru-patch/options.sh` | 11 hidden game options in Advanced Setup and multiplayer setup |
| `Civ5-ru-patch/tweaks.sh` | 23 graphics and convenience settings for Apple Silicon |
| `Civ5-terrain/terrain.sh` | Installs the [TTE 2k](https://forums.civfanatics.com/threads/terrain-texture-enhancement-2k.570307/) map textures as a DLC (get the mod from its author) |
| `Civ5-ru-patch/install.sh` | Russian language. **No game files in this repo**: the payload is built from the Russian Windows version (see below) |
| `1.…5. *.command` | The same, by double-click in Finder, no Terminal |

Every script can be rolled back (`uninstall` / `restore`). Originals are kept in
`~/Library/Application Support/Sid Meier's Civilization 5/*-backup`.

### Install without Terminal
1. Download the repo (Code → Download ZIP), unzip, rename the folder to `Civ5-Mac` and put it in Downloads.
2. Launch the game once from Steam, get to the main menu and quit.
3. Double-click **"1. Установить или обновить"** (Install or update). If macOS blocks it: right-click → Open → Open.
4. The script messages and `0. Инструкция.txt` are in Russian. The commands below do the same.

### Terminal
```bash
cd ~/Downloads/Civ5-Mac
bash Civ5-ru-patch/options.sh
bash Civ5-ru-patch/tweaks.sh
Civ5-terrain/terrain.sh install        # if you put TTE_2k into Civ5-terrain/payload/
Civ5-crossplay/crossplay.sh install    # always last: re-signs the app
```

### Important
- **Any change to the game files breaks Aspyr's signature.** Steam then says "OS Error 256" and macOS says "the application can't be opened". Sometimes this only shows up days later. Fix: `crossplay.sh sign`. No Xcode needed.
- **Never delete all of `cache/*.db` at once.** The Mac version then builds an empty `Localization-Merged.db` and quits ~20 s after launch. Fix: delete only `cache/Localization-*.db` (`terrain.sh fixcache` or "4. Починить запуск").
- A Steam update or "Verify integrity of game files" reverts everything. Run "1. Установить или обновить" again afterwards.

### Russian language
The Mac build has no Russian. `install.sh` installs `Civ5-ru-patch/payload/Assets`, but that folder isn't published: it holds the game's own text and voice-over files. You build it from the Russian files of the Windows version on your own Steam account. You also need:
- Cyrillic font atlases (Tw Cen MT);
- `UseExtendedFont=0` in `Russian.xml` (with 1 the Mac version crashes);
- replacing `Locale.Compare` in a few UI Lua files (otherwise multiplayer setup shows empty lists).

---

Scripts: MIT license. Civilization V © 2K / Firaxis / Aspyr; TTE 2k © Estebanium. Not affiliated with them.
