#!/bin/bash
# Двойной щелчок в Finder. Ничего не меняет — только показывает состояние.
ROOT="$(cd "$(dirname "$0")" && pwd)"; . "$ROOT/Civ5-ru-patch/common.sh"
title "проверка"
check_game

step "Игра"
if game_running; then warn "сейчас запущена"; else ok "закрыта"; fi

step "Русификация"
if installed_ru; then ok "установлена"; else bad "не установлена — открой «1. Установить или обновить»"; fi
lang="$(tr -d '\r' < "$USERDIR/config.ini" | sed -n 's/^Language = //p' | head -1)"
if [ "$lang" = "ru_RU" ]; then ok "язык игры: русский"; else warn "язык игры: $lang"; fi

step "Опции и настройки графики"
if installed_options; then ok "скрытые опции включены"; else warn "скрытые опции не включены"; fi
if installed_tweaks; then ok "настройки графики применены"; else warn "настройки графики не применены"; fi

step "Текстуры карты TTE 2k"
if installed_terrain; then ok "установлены"
elif [ -f "$TERRAIN_OFF" ]; then ok "выключены вручную"
else warn "не установлены"; fi
M="$USERDIR/cache/Localization-Merged.db"
if [ -f "$M" ] && [ ! -s "$M" ]; then bad "кэш текстов испорчен — игра будет закрываться. Открой «4. Починить запуск»"; fi

step "Кроссплей и подпись"
xp="$("$XP/crossplay.sh" status 2>&1)"
printf '%s\n' "$xp" | sed -nE 's/^(Состояние|Подпись): *//p' | sed 's/^/    /'
printf '%s\n' "$xp" | grep -q "ПАТЧ ПРИМЕНЁН" || bad "билд не как у Windows — открой «1. Установить или обновить»"
printf '%s\n' "$xp" | grep -q "Подпись:     валидна" || bad "подпись нарушена — открой «4. Починить запуск»"

step "Последние сбои игры (отчёты macOS)"
crash="$(ls -t "$HOME/Library/Logs/DiagnosticReports" 2>/dev/null | grep -i "civilization" | head -3)"
if [ -n "$crash" ]; then printf '%s\n' "$crash" | sed 's/^/    /'; else ok "нет"; fi

finish
