#!/bin/bash

# Launcher для Universal Git TouchBar Script
# Автоматически определяет путь к скрипту и запускает в новом окне терминала

# Находим путь к скрипту (ищем в той же папке, где находится launcher)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/universal-git-touchbar.sh"

# Проверяем, существует ли основной скрипт
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "Ошибка: Не найден файл universal-git-touchbar.sh в папке $SCRIPT_DIR"
    exit 1
fi

# Получаем текущую рабочую директорию
CURRENT_DIR="$(pwd)"

# Запускаем в новом окне Terminal.app
osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$CURRENT_DIR' && '$MAIN_SCRIPT'"
end tell
EOF