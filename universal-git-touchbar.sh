#!/bin/bash

# Универсальный Git Commit Script с поддержкой Touch Bar
# Работает в любой папке с Git репозиторием
# Специально для MacBook Pro с Touch Bar

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Функция для красивого заголовка
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}           УНИВЕРСАЛЬНЫЙ GIT AUTOMATION + TOUCH BAR           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Функция для печати статуса
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Функция для печати успеха
print_success() {
    echo -e "${GREEN}✓ [SUCCESS]${NC} $1"
}

# Функция для печати ошибки
print_error() {
    echo -e "${RED}✗ [ERROR]${NC} $1"
}

# Функция для печати предупреждения
print_warning() {
    echo -e "${YELLOW}⚠ [WARNING]${NC} $1"
}

# Функция для печати разделителя
print_separator() {
    echo -e "${PURPLE}────────────────────────────────────────────────────────────────${NC}"
}

# Функция для настройки Touch Bar
setup_touchbar() {
    # Определяем текущую папку проекта
    current_dir=$(basename "$(pwd)")
    
    print_status "Настройка Touch Bar для проекта: ${CYAN}$current_dir${NC}"
    
    # Создаем AppleScript для Touch Bar уведомлений
    osascript << EOF
tell application "System Events"
    display notification "🎮 Touch Bar активирован для проекта: $current_dir
    
F1 - 💾 Коммит
F2 - 📜 История  
F3 - ↩️ Откат
F4 - 📊 Статус
F5 - ❌ Выход" with title "Git Touch Bar" sound name "Glass"
end tell
EOF
    
    print_success "Touch Bar готов для работы!"
    echo ""
    print_separator
    echo -e "${YELLOW}📱 TOUCH BAR КНОПКИ:${NC}"
    echo -e "${WHITE}   F1${NC} - 💾 Создать коммит"
    echo -e "${WHITE}   F2${NC} - 📜 Показать историю коммитов"
    echo -e "${WHITE}   F3${NC} - ↩️ Откат коммитов"
    echo -e "${WHITE}   F4${NC} - 📊 Показать статус"
    echo -e "${WHITE}   F5${NC} - ❌ Выход из скрипта"
    print_separator
    echo ""
}

# Функция для проверки Git репозитория
check_git_repo() {
    if ! git status &>/dev/null; then
        print_error "Это не Git репозиторий!"
        echo -e "${CYAN}Инициализировать новый Git репозиторий? (y/n):${NC}"
        read -p "> " init_choice
        if [[ $init_choice =~ ^[Yy]$ ]]; then
            git init
            print_success "Git репозиторий инициализирован!"
            echo ""
        else
            print_error "Скрипт работает только в Git репозиториях"
            exit 1
        fi
    fi
}

# Функция создания коммита
create_commit() {
    print_separator
    echo -e "${CYAN}Текущий статус репозитория:${NC}"
    git status --short
    echo ""
    
    # Проверка наличия изменений
    if [[ -z $(git status --porcelain) ]]; then
        print_warning "Нет изменений для коммита"
        echo ""
        echo -e "${BLUE}Последний коммит:${NC}"
        git log --oneline -1
        return
    fi
    
    # Добавление всех файлов
    print_status "Добавление всех изменений в staging area..."
    git add .
    if [ $? -eq 0 ]; then
        print_success "Все файлы добавлены в staging area"
    else
        print_error "Ошибка при добавлении файлов!"
        return
    fi
    echo ""
    
    # Запрос сообщения коммита
    echo -e "${YELLOW}Введите сообщение для коммита:${NC}"
    echo -e "${CYAN}(или нажмите Enter для автоматического сообщения)${NC}"
    read -p "> " commit_message
    
    # Автоматическое сообщение если пользователь не ввел
    if [ -z "$commit_message" ]; then
        current_date=$(date "+%d.%m.%Y %H:%M")
        commit_message="Обновление: $current_date"
        print_status "Используется автоматическое сообщение: ${CYAN}$commit_message${NC}"
    fi
    echo ""
    
    # Выполнение коммита
    print_status "Выполнение коммита..."
    git commit -m "$commit_message"
    if [ $? -eq 0 ]; then
        print_success "Коммит успешно создан!"
        echo ""
        
        # Показ информации о коммите
        echo -e "${CYAN}Информация о последнем коммите:${NC}"
        git log --oneline -1 --decorate --color=always
        echo ""
        
        # Показ статистики коммита
        echo -e "${CYAN}Статистика изменений:${NC}"
        git diff --stat HEAD~1
        echo ""
        
        # Предложение push (если есть remote)
        if git remote | grep -q origin; then
            echo -e "${YELLOW}Отправить изменения на сервер? (y/n):${NC}"
            read -p "> " push_choice
            if [[ $push_choice =~ ^[Yy]$ ]]; then
                print_status "Отправка изменений на сервер..."
                git push
                if [ $? -eq 0 ]; then
                    print_success "Изменения успешно отправлены на сервер!"
                else
                    print_error "Ошибка при отправке на сервер!"
                fi
                echo ""
            fi
        fi
        
    else
        print_error "Ошибка при создании коммита!"
    fi
}

# Функция показа истории
show_history() {
    print_separator
    echo -e "${CYAN}История последних 15 коммитов:${NC}"
    echo ""
    git log --oneline --decorate --color=always --graph -15
    echo ""
}

# Функция отката коммитов
rollback_commits() {
    print_separator
    echo -e "${CYAN}История последних 10 коммитов:${NC}"
    echo ""
    git log --oneline --decorate --color=always -10
    echo ""
    
    echo -e "${YELLOW}Выберите действие для отката:${NC}"
    echo -e "${CYAN}1)${NC} Мягкий откат (soft reset) - сохранить изменения в staging area"
    echo -e "${CYAN}2)${NC} Смешанный откат (mixed reset) - сохранить изменения как unstaged"
    echo -e "${CYAN}3)${NC} Жесткий откат (hard reset) - удалить все изменения НАВСЕГДА"
    echo -e "${CYAN}4)${NC} Вернуться в главное меню"
    echo ""
    read -p "> " reset_type
    
    case $reset_type in
        1|2|3)
            echo -e "${YELLOW}Введите хеш коммита или количество коммитов назад (например: 2):${NC}"
            echo -e "${CYAN}(или 'q' для отмены)${NC}"
            read -p "> " target
            
            if [[ $target == "q" ]]; then
                return
            fi
            
            # Проверяем, число ли это
            if [[ $target =~ ^[0-9]+$ ]]; then
                target="HEAD~$target"
            fi
            
            # Подтверждение для жесткого отката
            if [[ $reset_type == "3" ]]; then
                echo -e "${RED}⚠️ ВНИМАНИЕ! Жесткий откат удалит ВСЕ изменения безвозвратно!${NC}"
                echo -e "${YELLOW}Вы уверены? Введите 'ДА' для подтверждения:${NC}"
                read -p "> " confirmation
                if [[ $confirmation != "ДА" ]]; then
                    print_warning "Жесткий откат отменен"
                    return
                fi
            fi
            
            # Выполняем откат
            case $reset_type in
                1)
                    print_status "Выполняется мягкий откат до $target..."
                    git reset --soft "$target"
                    ;;
                2)
                    print_status "Выполняется смешанный откат до $target..."
                    git reset --mixed "$target"
                    ;;
                3)
                    print_status "Выполняется жесткий откат до $target..."
                    git reset --hard "$target"
                    ;;
            esac
            
            if [ $? -eq 0 ]; then
                print_success "Откат выполнен успешно!"
                echo ""
                echo -e "${CYAN}Текущее состояние:${NC}"
                git status --short
                echo ""
            else
                print_error "Ошибка при выполнении отката!"
            fi
            ;;
        4)
            return
            ;;
        *)
            print_error "Неверный выбор!"
            ;;
    esac
}

# Функция показа статуса
show_status() {
    print_separator
    current_dir=$(basename "$(pwd)")
    echo -e "${CYAN}Статус репозитория: ${WHITE}$current_dir${NC}"
    echo ""
    git status
    echo ""
    
    # Показываем информацию о ветке
    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$current_branch" ]; then
        echo -e "${CYAN}Текущая ветка: ${WHITE}$current_branch${NC}"
    fi
    
    # Показываем информацию о remote
    if git remote | grep -q origin; then
        remote_url=$(git remote get-url origin 2>/dev/null)
        echo -e "${CYAN}Remote репозиторий: ${WHITE}$remote_url${NC}"
    fi
    echo ""
}

# Функция для обработки Touch Bar input
handle_touchbar_input() {
    current_dir=$(basename "$(pwd)")
    echo -e "${YELLOW}Проект: ${WHITE}$current_dir${NC}"
    echo -e "${YELLOW}Выберите действие (или используйте Touch Bar):${NC}"
    echo -e "${CYAN}1)${NC} 💾 Создать коммит"
    echo -e "${CYAN}2)${NC} 📜 История коммитов"  
    echo -e "${CYAN}3)${NC} ↩️ Откат коммитов"
    echo -e "${CYAN}4)${NC} 📊 Статус репозитория"
    echo -e "${CYAN}5)${NC} ❌ Выход"
    echo ""
    
    # Читаем ввод с поддержкой функциональных клавиш
    read -p "Выбор (1-5 или F1-F5): " choice
    
    # Обрабатываем выбор
    case $choice in
        1|F1) return 1 ;;  # Коммит
        2|F2) return 2 ;;  # История
        3|F3) return 3 ;;  # Откат
        4|F4) return 4 ;;  # Статус
        5|F5|q|Q) return 5 ;;  # Выход
        *) 
            print_error "Неверный выбор!"
            return 0 ;;
    esac
}

# Функция очистки Touch Bar
cleanup_touchbar() {
    current_dir=$(basename "$(pwd)")
    osascript -e "display notification \"Touch Bar отключен\" with title \"Git: $current_dir\"" 2>/dev/null
}

# Главная функция
main() {
    clear
    print_header
    
    # Проверяем Git репозиторий
    check_git_repo
    
    # Настраиваем Touch Bar
    setup_touchbar
    
    # Основной цикл с Touch Bar поддержкой
    while true; do
        handle_touchbar_input
        action=$?
        
        case $action in
            1) 
                create_commit
                ;;
            2)
                show_history
                ;;
            3)
                rollback_commits
                ;;
            4)
                show_status
                ;;
            5)
                print_status "Завершение работы..."
                cleanup_touchbar
                echo -e "${BLUE}Спасибо за использование Universal Git Touch Bar!${NC}"
                exit 0
                ;;
            0)
                continue
                ;;
        esac
        
        echo ""
        read -p "Нажмите Enter для продолжения..."
        clear
        print_header
        setup_touchbar
    done
}

# Обработка сигналов для корректного завершения
trap cleanup_touchbar EXIT INT TERM

# Запуск
main "$@"