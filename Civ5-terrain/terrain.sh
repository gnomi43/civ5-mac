#!/bin/bash
# Текстуры карты TTE 2k (Terrain Texture Enhancement 2k v12, Estebanium) для Civilization V на Mac.
# Ставится как DLC-папка: Contents/Assets/Assets/DLC/TTE_2k. Файлы игры не заменяются,
# игра сама берёт текстуры из DLC с приоритетом поверх Resource/DX9/TerrainTextures.fpk.
#   ./terrain.sh install    поставить (и переподписать игру)
#   ./terrain.sh uninstall  убрать (и переподписать игру)
#   ./terrain.sh status     показать состояние
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/payload/TTE_2k"
LIB="${STEAM_LIBRARY:-$HOME/Library/Application Support/Steam/steamapps}"
APP="$LIB/common/Sid Meier's Civilization V/Civilization V.app"
DLC="$APP/Contents/Assets/Assets/DLC"
DEST="$DLC/TTE_2k"
USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
CROSSPLAY="$HERE/../Civ5-crossplay/crossplay.sh"

die() { echo "Ошибка: $*" >&2; exit 1; }
[ -d "$DLC" ] || die "игра не найдена: $APP
Если библиотека Steam в другом месте: STEAM_LIBRARY=/путь/к/steamapps $0 ${1:-}"

running() { pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null; }

# Чистим ТОЛЬКО базы текстов (как install.sh): игра пересканирует DLC и пересоберёт их.
# НЕ удалять весь cache/*.db: после этого Mac-сборка собрала пустой Localization-Merged.db
# («Languages table not found») и закрывалась на каждом запуске (2026-11-13).
clear_cache() { rm -f "$USERDIR"/cache/Localization-*.db 2>/dev/null || true; }

sign() {
  if [ -f "$CROSSPLAY" ]; then
    bash "$CROSSPLAY" sign
  else
    echo "ВНИМАНИЕ: не найден $CROSSPLAY — переподпиши игру вручную, иначе она не запустится:"
    echo "  codesign --force --deep --sign - \"$APP\""
  fi
}

case "${1:-status}" in
  install)
    running && die "закройте игру"
    [ -f "$SRC/TTE_2k.Civ5Pkg" ] || die "нет $SRC
Скачай TTE 2k: https://forums.civfanatics.com/threads/terrain-texture-enhancement-2k.570307/
распакуй и положи папку TTE_2k в $HERE/payload/"
    if [ -d "$DEST" ] && diff -rq "$SRC" "$DEST" >/dev/null; then
      echo "TTE 2k уже установлен."
    else
      rm -rf "$DEST"
      cp -R "$SRC" "$DEST"
      diff -rq "$SRC" "$DEST" >/dev/null || die "копия не совпала с payload: $DEST"
      clear_cache
      echo "Готово: TTE 2k установлен в $DEST ($(find "$DEST" -name '*.dds' | wc -l | tr -d ' ') текстур)."
    fi
    sign
    echo "После обновления игры или «Проверки целостности» в Steam: ./terrain.sh install"
    ;;
  uninstall)
    running && die "закройте игру"
    [ -d "$DEST" ] || { echo "TTE 2k не установлен."; exit 0; }
    rm -rf "$DEST"
    clear_cache
    echo "Готово: TTE 2k удалён."
    sign
    ;;
  fixcache)
    running && die "закройте игру"
    clear_cache
    echo "Базы текстов удалены — игра пересоберёт их при запуске."
    ;;
  status)
    M="$USERDIR/cache/Localization-Merged.db"
    if [ -f "$M" ] && [ ! -s "$M" ]; then
      echo "ВНИМАНИЕ: $M пустой — игра будет закрываться при запуске. Лечится: $0 fixcache"
    fi
    if [ -d "$DEST" ]; then
      if diff -rq "$SRC" "$DEST" >/dev/null 2>&1; then echo "TTE 2k: установлен ($DEST)"
      else echo "TTE 2k: установлен, но отличается от payload — запусти install"; fi
    else
      echo "TTE 2k: не установлен"
    fi
    ;;
  *) echo "Использование: $0 install | uninstall | status | fixcache"; exit 2 ;;
esac
