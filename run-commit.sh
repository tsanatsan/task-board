#!/bin/bash

# Скрипт для открытия коммита в новом окне терминала
PROJECT_DIR="/Users/tsan.s/Desktop/qoder shtuchki/task board"

# Открываем новое окно Terminal.app и выполняем commit скрипт
osascript -e "
tell application \"Terminal\"
    activate
    do script \"cd '$PROJECT_DIR' && ./commit.sh\"
end tell
"