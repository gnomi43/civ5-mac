#!/bin/bash
# Скрытые опции партии + экспериментальные ключи ini для Civilization V (Steam, macOS).
#   bash options.sh            включить
#   bash options.sh uninstall  вернуть как было
set -euo pipefail

# ---- что включать (0/1) ----
PERSIST_ADVANCED=1     # запоминать расширенные настройки между партиями (экспериментально)
PLAY_LAST_WORLD=0      # новая партия на карте предыдущей (экспериментально)
CITY_SCREEN_BLOCKED=0  # 1 = запретить вход в экран города
# ----------------------------

LIB="${STEAM_LIBRARY:-$HOME/Library/Application Support/Steam/steamapps}"
ASSETS="$LIB/common/Sid Meier's Civilization V/Civilization V.app/Contents/Assets/Assets"
DEFAULT_USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
USERDIR="${CIV5_USERDIR:-$DEFAULT_USERDIR}"
CONFIG="$USERDIR/config.ini"
BACKUP="$USERDIR/options-backup"
STATE="$BACKUP/ini-state.txt"
FILES=(
  "Gameplay/XML/GameInfo/CIV5GameOptions.xml"
  "DLC/Expansion/Gameplay/XML/GameInfo/CIV5GameOptions_Expansion.xml"
  "DLC/Expansion2/Gameplay/XML/GameInfo/CIV5GameOptions_Expansion2.xml"
  "DLC/Expansion2/Gameplay/XML/GameInfo/CIV5GameOptions_Inherited_Expansion2.xml"
)

die() { echo "Ошибка: $*" >&2; exit 1; }
[ -d "$ASSETS" ] || die "игра не найдена: $ASSETS"
[ -f "$CONFIG" ] || die "нет $CONFIG — запустите игру один раз и закройте"
pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null && die "закройте игру"

clear_cache() { rm -f "$USERDIR/cache/Civ5CoreDatabase.db" "$USERDIR/cache/Civ5DebugDatabase.db"; }
CR=""; grep -q $'\r' "$CONFIG" && CR=$'\r'   # игра пишет config.ini с CRLF

# ini_set раздел ключ значение описание — правит config.ini, запоминая старое значение
ini_set() {
  local sec="$1" key="$2" val="$3" cmt="$4" old
  if old=$(grep -m1 -E "^$key = " "$CONFIG"); then
    old="${old#*= }"; old="${old%$'\r'}"
    echo "KEY|$key|$old" >> "$STATE"
    sed -i '' -E "s|^$key = .*|$key = $val$CR|" "$CONFIG"
  else
    echo "KEY|$key|<ABSENT>" >> "$STATE"
    if ! grep -q -E "^\[$sec\]$CR\$" "$CONFIG"; then
      echo "SECTION|$sec" >> "$STATE"
      printf '%s\n[%s]%s\n' "$CR" "$sec" "$CR" >> "$CONFIG"
    fi
    awk -v sec="[$sec]" -v c="; options.sh: $key — $cmt$CR" -v k="$key = $val$CR" \
      '{print; t=$0; sub(/\r$/,"",t); if (t==sec) {print c; print k}}' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
  fi
}

if [ "${1:-}" = "uninstall" ]; then
  [ -d "$BACKUP" ] || die "опции не включались"
  cp -R "$BACKUP/xml/." "$ASSETS/"
  if [ -f "$STATE" ]; then
    while IFS='|' read -r kind a b; do
      case "$kind" in
        KEY) if [ "$b" = "<ABSENT>" ]; then
               sed -i '' -e "/^$a = /d" -e "/^; options\.sh: $a /d" "$CONFIG"
             else
               sed -i '' -E "s|^$a = .*|$a = $b$CR|" "$CONFIG"
             fi ;;
        SECTION) awk -v sec="[$a]" '{l[NR]=$0; t=$0; sub(/\r$/,"",t); s[NR]=t}
                 END{for(i=1;i<=NR;i++) if(s[i]==sec){d[i]=1; if(i>1&&s[i-1]=="")d[i-1]=1}
                 for(i=1;i<=NR;i++) if(!d[i]) print l[i]}' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG" ;;
      esac
    done < <(tail -r "$STATE")
  fi
  rm -rf "$BACKUP"; clear_cache
  echo "Готово: всё возвращено как было."
  exit 0
fi

[ -d "$BACKUP" ] && die "уже включено (вернуть: bash options.sh uninstall)"
for f in "${FILES[@]}"; do [ -f "$ASSETS/$f" ] || die "нет файла $f"; done
mkdir -p "$BACKUP/xml"; : > "$STATE"
cp -p "$CONFIG" "$BACKUP/config.ini.before"

for f in "${FILES[@]}"; do
  mkdir -p "$BACKUP/xml/$(dirname "$f")"
  cp -p "$ASSETS/$f" "$BACKUP/xml/$f"
  sed -i '' 's|<Visible>0</Visible>|<Visible>1</Visible>|' "$ASSETS/$f"
done
ini_set "UserSettings" "PersistAdvancedSettings" "$PERSIST_ADVANCED" "хранить расширенные настройки партии"
ini_set "GAME" "PlayLastWorld" "$PLAY_LAST_WORLD" "карта из предыдущей партии"
ini_set "GAME" "CityScreenBlocked" "$CITY_SCREEN_BLOCKED" "запрет экрана города"
clear_cache

echo "Готово: 11 скрытых опций появятся в «Дополнительных настройках» и в настройке сетевой игры."
echo "Ключи ini: PersistAdvancedSettings=$PERSIST_ADVANCED PlayLastWorld=$PLAY_LAST_WORLD CityScreenBlocked=$CITY_SCREEN_BLOCKED"
echo "После обновления игры или «Проверки целостности» в Steam: bash options.sh uninstall && bash options.sh"
