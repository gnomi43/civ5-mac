Civilization V (Steam, macOS) — набор патчей
=============================================

Без Терминала: в корне Civ5-Mac есть файлы «1. Установить или обновить», «2. Проверить»,
«3. Текстуры карты вкл-выкл», «4. Починить запуск», «5. Удалить всё» (двойной щелчок)
и «0. Инструкция.txt». Ниже — то же самое командами, для помощника.

Что внутри
----------
  install.sh   русификация: тексты (база, G&K, BNW, DLC-цивилизации), русская озвучка,
               шрифты Tw Cen MT с кириллицей, 7 Lua-файлов с исправленной сортировкой
               (иначе в сетевой настройке пустые списки), советник (экспорт партии)
  options.sh   11 скрытых опций партии в «Дополнительных настройках» и в сетевой игре,
               ключи ini: PersistAdvancedSettings=1, PlayLastWorld=0, CityScreenBlocked=0
  tweaks.sh    23 настройки графики и удобства под Apple Silicon
  advisor.py   читалка снимков партии, которые пишет советник
  common.sh    общие функции для файлов *.command в корне (сам ничего не делает)
  payload/     файлы, которые install.sh кладёт в игру (≈108 МБ)

Кроссплей с Windows (несовпадение версии) — отдельная папка Civ5-crossplay.
Текстуры карты TTE 2k (по желанию) — отдельная папка Civ5-terrain.

Установка на новом Маке
-----------------------
1. Скопировать папку в Загрузки. Запустить игру один раз и закрыть
   (чтобы появились config.ini и остальные ini). Закрыть игру.
2. В Терминале:
     cd ~/Downloads/Civ5-Mac/Civ5-ru-patch
     chmod +x *.sh
     ./install.sh
     bash options.sh
     bash tweaks.sh
3. Текстуры карты (по желанию):
     cd ~/Downloads/Civ5-Mac/Civ5-terrain && chmod +x terrain.sh && ./terrain.sh install
4. Кроссплей: cd ~/Downloads/Civ5-Mac/Civ5-crossplay && chmod +x crossplay.sh && ./crossplay.sh install
   Этот шаг всегда последний: он переподписывает приложение после всех правок.
5. Запускать игру из Steam как обычно. Язык и озвучка уже переключены на русский.

Если игра не запускается
------------------------
- Steam пишет «OS Error 256», macOS — «can't be opened»: сломана подпись.
  Лечится: ./crossplay.sh sign в папке Civ5-crossplay.
- Игра открывается и через ~20 секунд сама закрывается, отчёта о сбое нет,
  в Logs/Database.log «no such table: Languages»: сломался кэш текстов
  (пустой cache/Localization-Merged.db). Лечится: ./terrain.sh fixcache в папке
  Civ5-terrain (или вручную удалить cache/Localization-*.db).
  Никогда не удаляй весь cache/*.db разом — именно так этот сбой и получается.

Откат
-----
     ./install.sh uninstall       — игра снова на английском, оригиналы на месте
     bash options.sh uninstall
     bash tweaks.sh uninstall
     ./terrain.sh uninstall       — в папке Civ5-terrain
     ./crossplay.sh restore       — в папке Civ5-crossplay
Копии оригиналов лежат в ~/Library/Application Support/Sid Meier's Civilization 5/
  ru-patch/ · options-backup/ · tweaks-backup/ · crossplay-backup/

После обновления игры в Steam или «Проверить целостность файлов»
-----------------------------------------------------------------
Steam вернёт оригиналы, скрипты об этом не узнают. Делать так:
     ./install.sh uninstall && ./install.sh
     bash options.sh uninstall && bash options.sh
     bash tweaks.sh uninstall && bash tweaks.sh
     ./terrain.sh install         — если ставил текстуры
     ./crossplay.sh install

Советник
--------
Advisor.lua сам пишет снимок партии в начале и в конце каждого твоего хода
(ModUserData/Civ5Advisor-1.db). Правила игры не трогает, о чужих державах
пишет только то, что видно игроку. Читать:
     python3 advisor.py            краткая сводка последнего снимка
     python3 advisor.py --json     полный JSON
     python3 advisor.py --list     какие снимки есть
     python3 advisor.py --turn 57  снимок конкретного хода

Заметки
-------
- Шрифты: Avenir Next Medium, подогнанный под оригинальный Tw Cen MT по размеру,
  слоям свечения и тени. UseExtendedFont в Russian.xml выключен — с ним Mac-сборка
  падает на загрузке.
- В официальном переводе исправлено 38 мест в 11 файлах: ошибки синтаксиса
  множественного числа и рода (Конгресс, тултипы голосов, уведомления о
  юнитах и пантеоне, сценарии). Признак таких ошибок — строки ERR в
  Logs/Localization.log (при LoggingEnabled = 1 в config.ini).
- Советник кэширует справочники (промоушены, здания, институты, типы юнитов)
  и пишет в Lua.log время снимка: «[Advisor] turn 57 start: … 40 ms collect».
  Если цифра растёт до сотен миллисекунд — присылай Lua.log.
- Сетевая игра: перевод, опции и твики на синхронизацию не влияют (проверено
  партией на 160 ходов с двумя Windows-игроками).
