#!/bin/bash
# Двойной щелчок в Finder. Возвращает игру в исходное состояние: английский язык,
# без опций, твиков, текстур и кроссплея. Копии оригиналов берутся из резервных копий.
ROOT="$(cd "$(dirname "$0")" && pwd)"; . "$ROOT/Civ5-ru-patch/common.sh"
title "удалить всё"
check_game
echo
echo "Игра вернётся к исходному виду: английский язык, без скрытых опций и текстур,"
echo "без кроссплея с Windows (с ними будет «несовпадение версии»)."
read -r -p "Точно удалить? Напиши да и нажми Enter: " answer
case "$answer" in да|Да|ДА|yes|y) ;; *) echo "Отменено."; finish ;; esac
wait_game_closed
chmod +x "$RU"/*.sh "$XP"/crossplay.sh "$TR"/terrain.sh 2>/dev/null

step "Текстуры карты"
if installed_terrain; then run "убраны" "$TR/terrain.sh" uninstall; else ok "не стояли"; fi
rm -f "$TERRAIN_OFF"
step "Настройки графики"
if installed_tweaks; then run "возвращены" bash "$RU/tweaks.sh" uninstall; else ok "не применялись"; fi
step "Скрытые опции"
if installed_options; then run "выключены" bash "$RU/options.sh" uninstall; else ok "не включались"; fi
step "Русификация"
if installed_ru; then run "убрана, игра на английском" "$RU/install.sh" uninstall; else ok "не стояла"; fi
step "Кроссплей и подпись"
run "оригинальный билд возвращён, игра переподписана" "$XP/crossplay.sh" restore

echo
echo "Полностью оригинальные файлы (с подписью Aspyr) вернёт только Steam:"
echo "Steam → Civilization V → Свойства → Установленные файлы → Проверить целостность."
finish
