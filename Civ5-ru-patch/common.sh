#!/bin/bash
# Общие функции для файлов «*.command» в корне Civ5-Mac (запуск двойным щелчком в Finder).
# Подключается через «. Civ5-ru-patch/common.sh», сам по себе ничего не делает.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RU="$ROOT/Civ5-ru-patch"
XP="$ROOT/Civ5-crossplay"
TR="$ROOT/Civ5-terrain"
USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
LIB="${STEAM_LIBRARY:-$HOME/Library/Application Support/Steam/steamapps}"
APP="$LIB/common/Sid Meier's Civilization V/Civilization V.app"
TERRAIN_OFF="$USERDIR/terrain-disabled"   # метка «текстуры выключены вручную»

ERRORS=0

title() { clear 2>/dev/null; echo "Civilization V на Mac — $*"; echo "=================================================="; }
step()  { echo; echo "▶ $*"; }
ok()    { echo "  ✓ $*"; }
warn()  { echo "  ! $*"; }
bad()   { echo "  ✗ $*"; ERRORS=$((ERRORS+1)); }

finish() {
  echo
  if [ "$ERRORS" -eq 0 ]; then echo "Готово."; else echo "Были ошибки: $ERRORS. Сфотографируй это окно или пришли текст из него."; fi
  echo
  read -r -p "Нажми Enter, чтобы закрыть окно…" _
  exit "$ERRORS"
}

game_running() { pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null 2>&1; }

wait_game_closed() {
  while game_running; do
    echo
    echo "  Игра сейчас запущена. Закрой её (из главного меню — «Выход»),"
    read -r -p "  потом нажми Enter здесь. Чтобы отменить — просто закрой это окно. " _
  done
}

check_game() {
  if [ ! -d "$APP" ]; then
    bad "Игра не найдена: $APP"
    echo "    Установи Civilization V в Steam (или библиотека Steam лежит на другом диске — тогда нужен помощник)."
    finish
  fi
  if [ ! -f "$USERDIR/config.ini" ]; then
    bad "Игру ещё ни разу не запускали на этом Маке."
    echo "    Запусти её один раз из Steam, дождись главного меню, выйди и снова открой этот файл."
    finish
  fi
}

# run «описание» команда… — выполнить, показать вывод с отступом, учесть ошибку
run() {
  local what="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/    /'
  if [ $rc -eq 0 ]; then ok "$what"; else bad "$what (код $rc)"; fi
  return $rc
}

installed_ru()      { [ -f "$USERDIR/ru-patch/added.txt" ]; }
installed_options() { [ -d "$USERDIR/options-backup" ]; }
installed_tweaks()  { [ -f "$USERDIR/tweaks-backup/ini-state.txt" ]; }
installed_terrain() { [ -d "$APP/Contents/Assets/Assets/DLC/TTE_2k" ]; }
