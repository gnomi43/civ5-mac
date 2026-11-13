#!/bin/bash
# crossplay.sh — Civilization V (Steam, macOS): кроссплей Mac <-> Windows.
#
# Mac-сборка Aspyr представляется в сети номером билда 180925, Windows — 403694.
# Из-за этого при подключении к Windows-игрокам пишет «Несовпадение версии».
# Скрипт меняет номер билда в двух файлах игры на Windows-овский и умеет
# вернуть всё обратно из резервной копии.
#
#   ./crossplay.sh install   — применить (резервные копии кладутся в crossplay-backup)
#   ./crossplay.sh restore   — вернуть оригинальные файлы
#   ./crossplay.sh status    — показать текущее состояние
#   ./crossplay.sh sign      — только переподписать приложение
#
# Правка Info.plist ломает подпись Aspyr: macOS на Apple Silicon убивает лаунчер
# AppBundleExe с «Code Signature Invalid» (иногда не сразу — пока ядро держит в кэше
# старую проверку). Поэтому после правки приложение переподписывается локальной
# ad-hoc подписью: codesign --force --deep --sign -. Игре и Steam это не мешает.
#
# Переменные окружения (на случай нестандартного пути Steam):
#   CIV5_APP="/путь/к/Civilization V.app"  CIV5_BUILD=403694

set -euo pipefail

TARGET_BUILD="${CIV5_BUILD:-403694}"   # билд, который сообщают Windows-клиенты
MAC_BUILD="180925"                     # оригинальный билд Mac-сборки (для restore без копии)

DEFAULT_APP="$HOME/Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app"
APP="${CIV5_APP:-$DEFAULT_APP}"
USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
BACKUP="$USERDIR/crossplay-backup"

PLIST="$APP/Contents/Info.plist"
JSON="$APP/Contents/AspyrAssets/global/String/App.json"

die() { echo "ОШИБКА: $*" >&2; exit 1; }

check_files() {
  [ -d "$APP" ] || die "не найдена игра: $APP
Если Steam-библиотека в другом месте, задай путь: CIV5_APP=\"/путь/Civilization V.app\" $0 $1"
  [ -f "$PLIST" ] || die "нет файла $PLIST"
  [ -f "$JSON" ]  || die "нет файла $JSON"
}

game_running() { pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null 2>&1; }

plist_build() { /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST" 2>/dev/null || echo "?"; }
json_build()  { sed -n 's/.*"App\.Build"[[:space:]]*:[[:space:]]*"\([0-9][0-9]*\)".*/\1/p' "$JSON" | head -n 1; }

set_build() {  # $1 = номер билда
  plutil -replace CFBundleVersion -string "$1" "$PLIST"
  sed -i '' -E 's/("App\.Build"[[:space:]]*:[[:space:]]*")[0-9]+(")/\1'"$1"'\2/' "$JSON"
}

verify_build() {  # $1 = ожидаемый билд
  local p j
  p="$(plist_build)"; j="$(json_build)"
  [ "$p" = "$1" ] && [ "$j" = "$1" ] || die "проверка не прошла: Info.plist=$p, App.json=$j, ожидалось $1"
}

sig_ok() { codesign --verify --deep --strict "$APP" >/dev/null 2>&1; }

sign_app() {
  command -v codesign >/dev/null || die "нет команды codesign (/usr/bin/codesign) — она входит в macOS, проверь систему"
  codesign --force --deep --sign - "$APP" 2>&1 | grep -v "replacing existing signature" || true
  sig_ok || die "переподписать не удалось: codesign --verify --deep --strict \"$APP\""
  echo "Приложение переподписано (ad-hoc), подпись валидна."
}

status() {
  local p j
  p="$(plist_build)"; j="$(json_build)"
  echo "Игра:        $APP"
  echo "Info.plist:  CFBundleVersion = $p"
  echo "App.json:    App.Build       = $j"
  if [ "$p" = "$TARGET_BUILD" ] && [ "$j" = "$TARGET_BUILD" ]; then
    echo "Состояние:   ПАТЧ ПРИМЕНЁН (билд $TARGET_BUILD, как у Windows)"
  elif [ "$p" = "$MAC_BUILD" ] && [ "$j" = "$MAC_BUILD" ]; then
    echo "Состояние:   оригинал (билд $MAC_BUILD) — с Windows будет «несовпадение версии»"
  else
    echo "Состояние:   смешанное/неизвестное — запусти install или restore"
  fi
  if [ -f "$BACKUP/Info.plist" ] && [ -f "$BACKUP/App.json" ]; then
    echo "Резерв:      $BACKUP (есть)"
  else
    echo "Резерв:      нет (restore поставит билд $MAC_BUILD вручную)"
  fi
  if sig_ok; then
    echo "Подпись:     валидна ($(codesign -dv "$APP" 2>&1 | sed -n 's/^Signature=//p'))"
  else
    echo "Подпись:     НАРУШЕНА (файлы игры менялись после подписи) — перед запуском выполни: $0 sign"
  fi
  game_running && echo "ВНИМАНИЕ:    игра сейчас запущена" || true
}

install() {
  game_running && die "закрой игру, потом запусти install"
  local p j
  p="$(plist_build)"; j="$(json_build)"
  if [ "$p" = "$TARGET_BUILD" ] && [ "$j" = "$TARGET_BUILD" ]; then
    echo "Билд уже $TARGET_BUILD."
    if sig_ok; then echo "Подпись валидна. Ничего не делаю."; else sign_app; fi
    return
  fi
  # Копию снимаем только с непропатченных файлов: если Steam обновил игру,
  # копия обновится вместе с ней, старая не нужна.
  if [ "$p" != "$TARGET_BUILD" ] && [ "$j" != "$TARGET_BUILD" ]; then
    mkdir -p "$BACKUP"
    cp -p "$PLIST" "$BACKUP/Info.plist"
    cp -p "$JSON"  "$BACKUP/App.json"
    echo "Резервные копии: $BACKUP"
  fi
  set_build "$TARGET_BUILD"
  verify_build "$TARGET_BUILD"
  sign_app
  echo "Готово: игра теперь сообщает билд $TARGET_BUILD."
  echo "Помни: обновление игры в Steam или «Проверить целостность файлов» вернёт оригинал — тогда снова запусти install."
}

restore() {
  game_running && die "закрой игру, потом запусти restore"
  if [ -f "$BACKUP/Info.plist" ] && [ -f "$BACKUP/App.json" ]; then
    cp -p "$BACKUP/Info.plist" "$PLIST"
    cp -p "$BACKUP/App.json"   "$JSON"
    echo "Оригинальные файлы возвращены из $BACKUP"
  else
    echo "Резервной копии нет — ставлю билд $MAC_BUILD напрямую."
    set_build "$MAC_BUILD"
  fi
  verify_build "$(plist_build)"
  # Подпись Aspyr обратно не вернуть (её заменила ad-hoc), поэтому переподписываем
  # под оригинальный plist. Полный оригинал даст только «Проверить целостность» в Steam.
  sign_app
  echo "Текущий билд: $(plist_build)"
}

cmd="${1:-status}"
check_files "$cmd"
case "$cmd" in
  install) install ;;
  restore) restore ;;
  status)  status ;;
  sign)    game_running && die "закрой игру, потом запусти sign"; sign_app ;;
  *) echo "Использование: $0 install | restore | status | sign"; exit 2 ;;
esac
