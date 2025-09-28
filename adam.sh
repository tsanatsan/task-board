#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 АДАМ - Первый универсальный Git скрипт
# Простой, надежный, с полной визуализацией всех процессов
# БЕЗОПАСНАЯ ВЕРСИЯ - только ручное управление
# ═══════════════════════════════════════════════════════════════════════════════

# КРИТИЧЕСКИЕ ПРОВЕРКИ БЕЗОПАСНОСТИ
set -e  # Остановить выполнение при любой ошибке
set -u  # Остановить при использовании неопределенных переменных

# Проверяем, что мы в безопасной директории
safe_check() {
    local current_path="$(pwd)"
    
    # Запрещаем работу в системных папках
    case "$current_path" in
        "/"|"$HOME"|"$HOME/Desktop"|"$HOME/Documents"|"$HOME/Downloads"|"$HOME/Music"|"$HOME/Pictures"|"$HOME/Videos"|"$HOME/Movies"|"$HOME/Public"|"$HOME/Library"|"$HOME/.Trash"|"$HOME/.ssh"|"$HOME/.config"|"$HOME/Applications"|"$HOME/bin"|"$HOME/usr"|"$HOME/usr"*|"/usr"*|"/bin"*|"/sbin"*|"/etc"*|"/var"*|"/tmp"*|"/System"*|"/Library"*|"/Applications"*|"/Volumes"*)
            echo "❌ ОШИБКА: Адам не может работать в системной или важной папке!"
            echo "   Текущая папка: $current_path"
            echo "   Запустите Адама только в папке конкретного проекта!"
            exit 1
            ;;
    esac
    
    # Проверяем признаки проектной папки
    local is_project_folder=false
    
    # Признаки проекта: наличие Git, package.json, README, src/, .gitignore и т.д.
    if [ -d ".git" ] || [ -f "package.json" ] || [ -f "README.md" ] || [ -f "README.txt" ] || [ -d "src" ] || [ -f ".gitignore" ] || [ -f "Cargo.toml" ] || [ -f "pom.xml" ] || [ -f "requirements.txt" ] || [ -f "Gemfile" ] || [ -f "go.mod" ] || [ -f "composer.json" ] || [ -f "yarn.lock" ] || [ -f "package-lock.json" ]; then
        is_project_folder=true
    fi
    
    # Показываем где мы находимся
    local project_name=$(basename "$current_path")
    echo "📍 Папка проекта: $project_name"
    
    if [ "$is_project_folder" = true ]; then
        echo "✅ Обнаружены признаки проекта - запуск безопасен"
        return 0
    fi
    
    # Если не обнаружили признаки проекта, но это подпапка в проектах
    case "$current_path" in
        "$HOME/Desktop/"*|"$HOME/Documents/"*|"$HOME/Projects/"*|"$HOME/Code/"*|"$HOME/Dev/"*|"$HOME/GitHub/"*|"$HOME/git/"*)
            echo "⚠️ Возможно это папка проекта, но признаки не найдены"
            echo "❓ Продолжить выполнение в папке '$project_name'?"
            read -p "   Введите 'да' для подтверждения: " confirmation
            
            case "$confirmation" in
                [Дд]|[Да]|да|Да|ДА|[Yy]|[Yy][Ee][Ss]|yes|Yes|YES)
                    echo "✅ Подтверждено пользователем"
                    return 0
                    ;;
                *)
                    echo "❌ Операция отменена"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "❌ ОШИБКА: Не похоже на папку проекта!"
            echo "   Запустите Адама в папке с проектом (где есть .git, package.json, src/ и т.д.)"
            exit 1
            ;;
    esac
}

# Запускаем проверку безопасности СРАЗУ
safe_check

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # Без цвета

# ═══════════════════════════════════════════════════════════════════════════════
# ФУНКЦИИ ВИЗУАЛЬНОГО ОФОРМЛЕНИЯ
# ═══════════════════════════════════════════════════════════════════════════════

# Красивый заголовок
show_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                            🤖 АДАМ - Git Автоматизация                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${GRAY}                       Первый скрипт для всех проектов                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Функция прогресс-бара
show_progress() {
    local message="$1"
    local duration="$2"
    echo -e "${CYAN}⏳ $message${NC}"
    
    local bar_length=50
    local sleep_time=$(echo "scale=3; $duration / $bar_length" | bc -l 2>/dev/null || echo "0.02")
    
    echo -n "   ["
    for ((i=0; i<bar_length; i++)); do
        echo -n "━"
        sleep "$sleep_time"
    done
    echo -e "] ${GREEN}✅ Готово!${NC}"
    echo ""
}

# Пошаговая визуализация
show_step() {
    local step_num="$1"
    local step_name="$2"
    local status="$3"  # start, success, error, warning
    
    case $status in
        "start")
            echo -e "${BLUE}┌─ Шаг $step_num: $step_name${NC}"
            echo -e "${BLUE}│${NC}  🔄 Выполняется..."
            ;;
        "success")
            echo -e "${BLUE}└─${NC} ${GREEN}✅ Шаг $step_num завершен успешно!${NC}"
            echo ""
            ;;
        "error")
            echo -e "${BLUE}└─${NC} ${RED}❌ Ошибка в шаге $step_num!${NC}"
            echo ""
            ;;
        "warning")
            echo -e "${BLUE}└─${NC} ${YELLOW}⚠️ Предупреждение в шаге $step_num${NC}"
            echo ""
            ;;
    esac
}

# Детальная информация о процессе
show_process_details() {
    local title="$1"
    local details="$2"
    echo -e "${CYAN}📋 $title:${NC}"
    echo -e "${GRAY}   $details${NC}"
    echo ""
}

# Разделитель разделов
show_section_separator() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Подтверждение действия
ask_confirmation() {
    local question="$1"
    local default="$2"  # y или n
    
    if [ "$default" = "y" ]; then
        echo -e "${YELLOW}❓ $question [Y/n]:${NC}"
    else
        echo -e "${YELLOW}❓ $question [y/N]:${NC}"
    fi
    
    read -p "   👉 " answer
    case $answer in
        [Yy]|[Дд]|[Да]|да|Да|ДА) return 0 ;;
        [Nn]|[Нн]|[Нет]|нет|Нет|НЕТ) return 1 ;;
        "") 
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *) return 1 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# ОСНОВНЫЕ ФУНКЦИИ GIT
# ═══════════════════════════════════════════════════════════════════════════════

# Проверка Git репозитория с усиленной безопасностью
check_git_repository() {
    show_step 1 "Проверка Git репозитория" "start"
    
    # Показываем, где мы находимся
    local current_path="$(pwd)"
    local project_name="$(basename "$current_path")"
    echo -e "${CYAN}📁 Текущая папка: $project_name${NC}"
    echo -e "${GRAY}📂 Полный путь: $current_path${NC}"
    echo ""
    
    if ! git status &>/dev/null; then
        show_step 1 "Git репозиторий не найден" "error"
        
        echo -e "${RED}⚠️  ВНИМАНИЕ: Инициализация Git в папке: $project_name${NC}"
        echo -e "${YELLOW}Это создаст новый Git репозиторий в текущей папке.${NC}"
        
        if ask_confirmation "Создать новый Git репозиторий в папке '$project_name'?" "n"; then
            git init
            show_progress "Инициализация Git репозитория" 1
            show_step 1 "Git репозиторий создан" "success"
        else
            echo -e "${RED}❌ Адам работает только в Git репозиториях${NC}"
            echo -e "${BLUE}📝 Подсказка: Перейдите в папку с Git репозиторием${NC}"
            exit 1
        fi
    else
        show_step 1 "Git репозиторий найден" "success"
        
        # Показываем информацию о репозитории
        local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
        local repo_info=$(git remote get-url origin 2>/dev/null || echo "Локальный репозиторий")
        echo -e "${CYAN}🌳 Ветка: $current_branch${NC}"
        echo -e "${CYAN}💻 Репозиторий: $repo_info${NC}"
    fi
}

# Проверка и показ статуса файлов
check_file_status() {
    show_step 2 "Анализ изменений в проекте" "start"
    
    # Получаем информацию о проекте
    local project_name=$(basename "$(pwd)")
    local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
    
    show_process_details "Информация о проекте" "Папка: $project_name | Ветка: $current_branch"
    
    echo -e "${CYAN}📊 Статус файлов:${NC}"
    git status --porcelain | while IFS= read -r line; do
        local status="${line:0:2}"
        local file="${line:3}"
        
        case $status in
            "M "|" M") echo -e "   ${YELLOW}📝 Изменен:${NC} $file" ;;
            "A "|" A") echo -e "   ${GREEN}➕ Добавлен:${NC} $file" ;;
            "D "|" D") echo -e "   ${RED}➖ Удален:${NC} $file" ;;
            "??") echo -e "   ${BLUE}❓ Новый файл:${NC} $file" ;;
            "R ") echo -e "   ${PURPLE}🔄 Переименован:${NC} $file" ;;
            *) echo -e "   ${GRAY}📄 $status${NC} $file" ;;
        esac
    done
    
    local files_count=$(git status --porcelain | wc -l | tr -d ' ')
    
    if [ "$files_count" -eq 0 ]; then
        show_step 2 "Изменений не найдено" "warning"
        echo -e "${YELLOW}⚠️ Нет файлов для коммита${NC}"
        echo ""
        show_last_commits
        return 1
    else
        show_step 2 "Найдено изменений: $files_count" "success"
        return 0
    fi
}

# Добавление файлов в staging с подтверждением
add_files_to_staging() {
    show_step 3 "Добавление файлов в staging area" "start"
    
    # Проверяем признаки проекта для упрощения процесса
    local is_known_project=false
    if [ -d ".git" ] || [ -f "package.json" ] || [ -d "src" ] || [ -f ".gitignore" ]; then
        is_known_project=true
    fi
    
    # Показываем какие файлы будут добавлены
    if [ "$is_known_project" = true ]; then
        echo -e "${CYAN}📦 Добавляю все изменения в проекте...${NC}"
    else
        echo -e "${YELLOW}⚠️  Предупреждение: Будут добавлены ВСЕ изменения в папке!${NC}"
        
        if ! ask_confirmation "Продолжить добавление всех файлов?" "n"; then
            echo -e "${YELLOW}❌ Операция отменена пользователем${NC}"
            return 1
        fi
    fi
    
    show_progress "Добавление всех изменений" 1.5
    
    git add . 2>/dev/null
    
    if [ $? -eq 0 ]; then
        local staged_count=$(git diff --cached --numstat | wc -l | tr -d ' ')
        show_step 3 "Добавлено файлов в staging: $staged_count" "success"
        
        echo -e "${CYAN}📦 Файлы готовы к коммиту:${NC}"
        git diff --cached --name-status | while IFS= read -r line; do
            local status="${line:0:1}"
            local file="${line:2}"
            case $status in
                "M") echo -e "   ${YELLOW}📝 $file${NC}" ;;
                "A") echo -e "   ${GREEN}➕ $file${NC}" ;;
                "D") echo -e "   ${RED}➖ $file${NC}" ;;
                *) echo -e "   ${GRAY}📄 $file${NC}" ;;
            esac
        done
        echo ""
        return 0
    else
        show_step 3 "Ошибка добавления файлов" "error"
        return 1
    fi
}

# Создание коммита
create_commit() {
    show_step 4 "Создание коммита" "start"
    
    echo -e "${CYAN}💬 Введите сообщение коммита:${NC}"
    echo -e "${GRAY}   (оставьте пустым для автоматического сообщения)${NC}"
    read -p "   👉 " commit_message
    
    if [ -z "$commit_message" ]; then
        local current_date=$(date "+%d.%m.%Y %H:%M")
        commit_message="Обновление: $current_date"
        show_process_details "Автоматическое сообщение" "$commit_message"
    else
        show_process_details "Ваше сообщение" "$commit_message"
    fi
    
    show_progress "Создание коммита" 2
    
    git commit -m "$commit_message" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        show_step 4 "Коммит успешно создан" "success"
        
        # Показываем информацию о созданном коммите
        local commit_hash=$(git rev-parse --short HEAD)
        local commit_time=$(git log -1 --format="%cd" --date=format:"%H:%M:%S")
        
        echo -e "${GREEN}🎉 КОММИТ СОЗДАН УСПЕШНО!${NC}"
        echo -e "${CYAN}📝 Хеш коммита:${NC} $commit_hash"
        echo -e "${CYAN}⏰ Время создания:${NC} $commit_time"
        echo -e "${CYAN}💬 Сообщение:${NC} $commit_message"
        echo ""
        
        return 0
    else
        show_step 4 "Ошибка создания коммита" "error"
        return 1
    fi
}

# Статистика коммита
show_commit_stats() {
    show_step 5 "Анализ изменений" "start"
    
    show_progress "Подсчет статистики" 1
    
    echo -e "${CYAN}📊 Статистика коммита:${NC}"
    git diff --stat HEAD~1 | while IFS= read -r line; do
        echo -e "   ${GRAY}$line${NC}"
    done
    echo ""
    
    show_step 5 "Анализ завершен" "success"
}

# Проверка remote и push
handle_remote_push() {
    show_step 6 "Проверка удаленного репозитория" "start"
    
    if git remote | grep -q origin; then
        local remote_url=$(git remote get-url origin 2>/dev/null)
        show_process_details "Найден remote" "$remote_url"
        show_step 6 "Remote репозиторий найден" "success"
        
        if ask_confirmation "Отправить изменения на сервер (git push)?" "y"; then
            show_step 7 "Отправка на сервер" "start"
            show_progress "Загрузка изменений на сервер" 3
            
            git push 2>/dev/null
            
            if [ $? -eq 0 ]; then
                show_step 7 "Изменения успешно отправлены на сервер" "success"
                echo -e "${GREEN}🚀 ВСЕ ИЗМЕНЕНИЯ СОХРАНЕНЫ И ОТПРАВЛЕНЫ!${NC}"
            else
                show_step 7 "Ошибка отправки на сервер" "error"
                echo -e "${YELLOW}⚠️ Коммит создан локально, но не отправлен на сервер${NC}"
            fi
        else
            echo -e "${BLUE}📝 Коммит создан только локально${NC}"
        fi
    else
        show_step 6 "Remote репозиторий не настроен" "warning"
        echo -e "${YELLOW}⚠️ Удаленный репозиторий не найден${NC}"
        echo -e "${GRAY}   Коммит создан только локально${NC}"
    fi
    echo ""
}

# Показ последних коммитов
show_last_commits() {
    echo -e "${CYAN}📜 Последние 5 коммитов:${NC}"
    git log --oneline --color=always -5 | while IFS= read -r line; do
        echo -e "   ${GRAY}$line${NC}"
    done
    echo ""
}

# Финальное резюме
show_final_summary() {
    show_section_separator
    echo -e "${GREEN}🎯 АДАМ ЗАВЕРШИЛ РАБОТУ УСПЕШНО!${NC}"
    echo ""
    echo -e "${CYAN}📋 Что было сделано:${NC}"
    echo -e "   ${GREEN}✅ Проверен Git репозиторий${NC}"
    echo -e "   ${GREEN}✅ Проанализированы изменения${NC}"
    echo -e "   ${GREEN}✅ Файлы добавлены в staging${NC}"
    echo -e "   ${GREEN}✅ Создан коммит${NC}"
    echo -e "   ${GREEN}✅ Показана статистика${NC}"
    echo -e "   ${GREEN}✅ Обработан remote push${NC}"
    echo ""
    
    local project_name=$(basename "$(pwd)")
    echo -e "${PURPLE}🤖 Адам работает надежно для проекта: ${WHITE}$project_name${NC}"
    show_section_separator
}

# ═══════════════════════════════════════════════════════════════════════════════
# ГЛАВНАЯ ФУНКЦИЯ
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    # Показываем заголовок
    show_header
    
    # Выполняем все шаги по порядку
    check_git_repository
    
    if check_file_status; then
        add_files_to_staging
        if [ $? -eq 0 ]; then
            create_commit
            if [ $? -eq 0 ]; then
                show_commit_stats
                handle_remote_push
                show_final_summary
            fi
        fi
    fi
    
    # Пауза перед завершением
    echo ""
    echo -e "${GRAY}Нажмите Enter для завершения...${NC}"
    read
}

# Обработка сигналов
trap 'echo -e "\n${RED}❌ Адам прерван пользователем${NC}"; exit 1' INT TERM

# Запуск скрипта
main "$@"