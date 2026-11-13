#!/bin/bash
# Настройки графики и удобства для Civilization V на Apple Silicon (M-серия).
#   bash tweaks.sh            применить
#   bash tweaks.sh uninstall  вернуть прежние значения
set -euo pipefail

DEFAULT_USERDIR="$HOME/Library/Application Support/Sid Meier's Civilization 5"
USERDIR="${CIV5_USERDIR:-$DEFAULT_USERDIR}"
BACKUP="$USERDIR/tweaks-backup"
STATE="$BACKUP/ini-state.txt"
GFX="GraphicsSettingsDX9.ini"; CFG="config.ini"; USR="UserSettings.ini"

# ---- что ставим: файл|раздел|ключ|значение ----
SETTINGS=(
 # графика: без ограничителя кадров VSync бережёт батарею и убирает разрывы
 "$GFX|GraphicsSettings|WaitForVSync|1"
 # сцены лидеров: по умолчанию стоит минимум
 "$GFX|LeaderheadSettings|LeaderTextureReduction|0"
 "$GFX|LeaderheadSettings|LeaderQuality|2"
 "$GFX|LeaderheadSettings|MaxResidentScenes|3"
 "$GFX|LeaderheadSettings|SkinQuality|1"
 "$GFX|LeaderheadSettings|EnableBloom|1"
 "$GFX|LeaderheadSettings|EnableShadows|1"
 # карта
 "$GFX|GraphicsDetailSettings|HDStrategicView|1"
 "$GFX|GraphicsDetailSettings|OverlayLevel|2"
 "$GFX|GraphicsDetailSettings|ShadowLevel|3"
 "$GFX|GraphicsDetailSettings|FOWLevel|3"
 "$GFX|GraphicsDetailSettings|TerrainWaterQuality|2"
 "$GFX|GraphicsDetailSettings|TerrainDetailLevel|3"
 "$GFX|GraphicsDetailSettings|TerrainTessLevel|2"
 "$GFX|GraphicsDetailSettings|TerrainShadowQuality|3"
 "$GFX|GraphicsDetailSettings|ReflectionLevel|1"
 # движок
 "$CFG|User Settings|ThrottleOnLossOfFocus|1"
 "$CFG|User Settings|MaxSimultaneousThreads|12"
 "$CFG|User Settings|Minimum Zoom Level|4.000000"
 # удобство
 "$USR|User Settings|Tooltip1Seconds|50"
 "$USR|User Settings|Tooltip2Seconds|200"
 "$USR|User Settings|SinglePlayerQuickCombatEnabled|1"
 "$USR|User Settings|SinglePlayerQuickMovementEnabled|1"
)
# по желанию: миникарта крупнее (рамка может лечь неидеально)
MINIMAP=0
[ "$MINIMAP" = 1 ] && SETTINGS+=("$CFG|MiniMap|Width|480" "$CFG|MiniMap|Height|285")
# ------------------------------------------------

die() { echo "Ошибка: $*" >&2; exit 1; }
for f in "$GFX" "$CFG" "$USR"; do [ -f "$USERDIR/$f" ] || die "нет $USERDIR/$f — запустите игру один раз и закройте"; done
pgrep -f "Civilization V.app/Contents/MacOS" >/dev/null && die "закройте игру"

cr_of() { grep -q $'\r' "$1" && printf '\r' || printf ''; }

# ini_set файл раздел ключ значение — правит значение, запоминая старое
ini_set() {
  local path="$USERDIR/$1" sec="$2" key="$3" val="$4" old CR; CR=$(cr_of "$path")
  if old=$(grep -m1 -E "^$key = " "$path"); then
    old="${old#*= }"; old="${old%$'\r'}"
    echo "KEY|$1|$key|$old" >> "$STATE"
    sed -i '' -E "s|^$key = .*|$key = $val$CR|" "$path"
  else
    echo "KEY|$1|$key|<ABSENT>" >> "$STATE"
    if ! grep -q -E "^\[$sec\]$CR\$" "$path"; then
      echo "SECTION|$1|$sec" >> "$STATE"; printf '%s\n[%s]%s\n' "$CR" "$sec" "$CR" >> "$path"
    fi
    awk -v sec="[$sec]" -v c="; tweaks.sh: $key$CR" -v k="$key = $val$CR" \
      '{print; t=$0; sub(/\r$/,"",t); if (t==sec) {print c; print k}}' "$path" > "$path.tmp" && mv "$path.tmp" "$path"
  fi
}

if [ "${1:-}" = "uninstall" ]; then
  [ -f "$STATE" ] || die "настройки не применялись"
  while IFS='|' read -r kind file a b; do
    path="$USERDIR/$file"; CR=$(cr_of "$path")
    case "$kind" in
      KEY) if [ "$b" = "<ABSENT>" ]; then sed -i '' -e "/^$a = /d" -e "/^; tweaks\.sh: $a\r*$/d" "$path"
           else sed -i '' -E "s|^$a = .*|$a = $b$CR|" "$path"; fi ;;
      SECTION) awk -v sec="[$a]" '{l[NR]=$0; t=$0; sub(/\r$/,"",t); s[NR]=t}
               END{for(i=1;i<=NR;i++) if(s[i]==sec){d[i]=1; if(i>1&&s[i-1]=="")d[i-1]=1}
               for(i=1;i<=NR;i++) if(!d[i]) print l[i]}' "$path" > "$path.tmp" && mv "$path.tmp" "$path" ;;
    esac
  done < <(tail -r "$STATE")
  rm -rf "$BACKUP"
  echo "Готово: настройки возвращены."
  exit 0
fi

[ -f "$STATE" ] && die "уже применено (вернуть: bash tweaks.sh uninstall)"
mkdir -p "$BACKUP"; : > "$STATE"
for f in "$GFX" "$CFG" "$USR"; do cp -p "$USERDIR/$f" "$BACKUP/$f.before"; done
for s in "${SETTINGS[@]}"; do IFS='|' read -r file sec key val <<< "$s"; ini_set "$file" "$sec" "$key" "$val"; done
echo "Готово: применено ${#SETTINGS[@]} настроек (копии файлов в $BACKUP)."
echo "Если игра стала подтормаживать в поздней партии — снизьте разрешение в её настройках."
