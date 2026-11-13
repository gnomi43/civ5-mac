#!/bin/bash
# Двойной щелчок в Finder. Если текстуры TTE 2k стоят — убирает их, если нет — ставит.
# Пригодится, если в сетевой игре лобби ругается на DLC или не нравится вид карты.
ROOT="$(cd "$(dirname "$0")" && pwd)"; . "$ROOT/Civ5-ru-patch/common.sh"
title "текстуры карты TTE 2k"
check_game
wait_game_closed
chmod +x "$TR"/terrain.sh "$XP"/crossplay.sh 2>/dev/null

if installed_terrain; then
  step "Текстуры сейчас стоят — убираю"
  run "текстуры убраны, игра переподписана" "$TR/terrain.sh" uninstall && touch "$TERRAIN_OFF"
  echo; echo "  Вернуть — открой этот файл ещё раз."
else
  step "Текстур сейчас нет — ставлю"
  run "текстуры установлены, игра переподписана" "$TR/terrain.sh" install && rm -f "$TERRAIN_OFF"
  echo; echo "  Убрать — открой этот файл ещё раз."
fi
finish
