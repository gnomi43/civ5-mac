#!/bin/bash
# Двойной щелчок в Finder. Ставит весь пакет, а если он уже стоит — переустанавливает
# (это же нужно после обновления игры в Steam или «Проверки целостности файлов»).
ROOT="$(cd "$(dirname "$0")" && pwd)"; . "$ROOT/Civ5-ru-patch/common.sh"
title "установка / обновление"
check_game
wait_game_closed
chmod +x "$RU"/*.sh "$XP"/crossplay.sh "$TR"/terrain.sh 2>/dev/null

step "Русификация (тексты, озвучка, шрифты, советник)"
if [ ! -d "$RU/payload/Assets" ]; then
  warn "пропущено: нет папки Civ5-ru-patch/payload (в публичной версии пакета её нет — это файлы игры)"
else
  if installed_ru; then run "старая версия убрана" "$RU/install.sh" uninstall || true; fi
  run "русификация установлена" "$RU/install.sh"
fi

step "Скрытые опции партии"
if installed_options; then run "старые опции убраны" bash "$RU/options.sh" uninstall || true; fi
run "опции включены" bash "$RU/options.sh"

step "Настройки графики"
if installed_tweaks; then run "старые настройки возвращены" bash "$RU/tweaks.sh" uninstall || true; fi
run "настройки применены" bash "$RU/tweaks.sh"

step "Текстуры карты TTE 2k"
if [ -f "$TERRAIN_OFF" ]; then
  warn "пропущено: текстуры выключены файлом «3. Текстуры карты вкл-выкл»"
elif [ ! -f "$TR/payload/TTE_2k/TTE_2k.Civ5Pkg" ]; then
  warn "пропущено: нет Civ5-terrain/payload/TTE_2k — скачай мод (ссылка в Civ5-terrain/README.txt)"
else
  run "текстуры установлены" "$TR/terrain.sh" install
fi

step "Кроссплей с Windows и подпись приложения (всегда последним)"
run "игра сообщает билд как у Windows, подпись валидна" "$XP/crossplay.sh" install

if [ "$ERRORS" -eq 0 ]; then
  echo
  echo "Всё установлено. Запускай игру из Steam как обычно."
  echo "Если игра не запустится — открой «4. Починить запуск»."
fi
finish
