#!/bin/bash
# Русификатор Civilization V (Steam, macOS). Использование:
#   ./install.sh            установить
#   ./install.sh uninstall  вернуть как было
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload"
LIB="${STEAM_LIBRARY:-$HOME/Library/Application Support/Steam/steamapps}"
APP="$LIB/common/Sid Meier's Civilization V/Civilization V.app"
ASSETS="$APP/Contents/Assets"
USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
STATE="$USERDIR/ru-patch"   # бэкап и список файлов — на этом Маке

die() { echo "Ошибка: $*" >&2; exit 1; }
[ -d "$ASSETS" ] || die "игра не найдена: $APP
Если библиотека Steam в другом месте: STEAM_LIBRARY=/путь/к/steamapps ./install.sh"
pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null && die "закройте игру"

set_lang() {
  local cfg="$USERDIR/config.ini"
  [ -f "$cfg" ] || die "нет $cfg — запустите игру один раз и закройте, потом повторите"
  [ -f "$STATE/config.ini.orig" ] || cp "$cfg" "$STATE/config.ini.orig"
  local CR=""; grep -q $'\r' "$cfg" && CR=$'\r'
  sed -i '' -E "s/^(Audio)?Language = .*/\1Language = $1$CR/" "$cfg"
  rm -f "$USERDIR"/cache/Localization-*.db
}

if [ "${1:-}" = "uninstall" ]; then
  [ -d "$STATE" ] || die "патч не установлен"
  while IFS= read -r f; do rm -f "$ASSETS/$f"; done < "$STATE/added.txt"
  [ -d "$STATE/backup" ] && cp -R "$STATE/backup/." "$ASSETS/"
  CR=""; grep -q $'\r' "$USERDIR/config.ini" && CR=$'\r'
  sed -i '' -E "s/^(Audio)?Language = .*/\1Language = en_US$CR/" "$USERDIR/config.ini"
  rm -f "$USERDIR"/cache/Localization-*.db
  rm -rf "$STATE"
  echo "Готово: игра снова на английском."
  echo "Файлы игры изменились — перед запуском: cd ~/Downloads/Civ5-Mac/Civ5-crossplay && ./crossplay.sh sign"
  exit 0
fi

[ -d "$PAYLOAD/Assets" ] || die "нет папки payload рядом со скриптом"
[ -f "$STATE/added.txt" ] && die "патч уже установлен (сначала ./install.sh uninstall)"
mkdir -p "$STATE/backup"; : > "$STATE/added.txt"

cd "$PAYLOAD"
find Assets -type f | while IFS= read -r f; do
  if [ -e "$ASSETS/$f" ]; then
    mkdir -p "$STATE/backup/$(dirname "$f")"
    cp -p "$ASSETS/$f" "$STATE/backup/$f"
  else
    echo "$f" >> "$STATE/added.txt"
  fi
  mkdir -p "$ASSETS/$(dirname "$f")"
  cp "$f" "$ASSETS/$f"
done

set_lang ru_RU
echo "Готово: $(wc -l < "$STATE/added.txt" | tr -d ' ') файлов добавлено, $(find "$STATE/backup" -type f | wc -l | tr -d ' ') заменено (оригиналы в $STATE/backup)."
echo "После обновления игры или «Проверки целостности» в Steam: ./install.sh uninstall && ./install.sh"
echo "Последним шагом всегда: cd ~/Downloads/Civ5-Mac/Civ5-crossplay && ./crossplay.sh install  (переподписывает игру)"
