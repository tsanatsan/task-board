#!/bin/bash

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
    echo -e "${PURPLE}║${WHITE}                     GIT COMMIT AUTOMATION                    ${PURPLE}║${NC}"
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
    echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
}

# Функция для показа истории коммитов
show_commit_history() {
    echo -e "${CYAN}История последних 10 коммитов:${NC}"
    echo ""
    git log --oneline --decorate --color=always -10
    echo ""
}

# Функция для отката коммитов
rollback_commits() {
    show_commit_history
    
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
                echo -e "${RED}⚠️  ВНИМАНИЕ! Жесткий откат удалит ВСЕ изменения безвозвратно!${NC}"
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
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Функция главного меню
show_main_menu() {
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo -e "${CYAN}1)${NC} Создать новый коммит"
    echo -e "${CYAN}2)${NC} Показать историю коммитов"
    echo -e "${CYAN}3)${NC} Откатить коммиты"
    echo -e "${CYAN}4)${NC} Показать текущий статус"
    echo -e "${CYAN}5)${NC} Выйти"
    echo ""
    read -p "> " menu_choice
    
    case $menu_choice in
        1)
            return 1  # Создать коммит
            ;;
        2)
            show_commit_history
            read -p "Нажмите Enter для продолжения..."
            return 0  # Показать меню снова
            ;;
        3)
            rollback_commits
            return 0  # Показать меню снова
            ;;
        4)
            echo -e "${CYAN}Текущий статус репозитория:${NC}"
            git status
            echo ""
            read -p "Нажмите Enter для продолжения..."
            return 0  # Показать меню снова
            ;;
        5)
            exit 0
            ;;
        *)
            print_error "Неверный выбор!"
            return 0  # Показать меню снова
            ;;
    esac
}

# Очистка экрана и показ заголовка
clear
print_header

# Основной цикл для множественных коммитов
while true; do
    # Переход в директорию проекта
    PROJECT_DIR="/Users/tsan.s/Desktop/qoder shtuchki/task board"
    print_status "Переход в директорию проекта: ${CYAN}$PROJECT_DIR${NC}"
    cd "$PROJECT_DIR" || {
        print_error "Не удалось перейти в директорию проекта!"
        exit 1
    }
    print_success "Директория проекта найдена"
    echo ""

    # Проверка статуса git
    print_status "Проверка статуса Git репозитория..."
    if ! git status &>/dev/null; then
        print_error "Это не Git репозиторий!"
        exit 1
    fi

    # Показ главного меню
    print_separator
    show_main_menu
    menu_result=$?
    
    # Если не выбрали создание коммита, показываем меню снова
    if [ $menu_result -eq 0 ]; then
        clear
        print_header
        continue
    fi
    
    clear
    print_header
    print_separator

    # Показ текущего статуса
    echo -e "${CYAN}Текущий статус репозитория:${NC}"
    git status --short
    echo ""

    # Проверка наличия изменений
    if [[ -z $(git status --porcelain) ]]; then
        print_warning "Нет изменений для коммита"
        echo ""
        echo -e "${BLUE}Последний коммит:${NC}"
        git log --oneline -1
        echo ""
        
        # Предложение подождать изменений или выйти
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1)${NC} Подождать и проверить снова"
        echo -e "${CYAN}2)${NC} Выйти"
        read -p "> " no_changes_choice
        
        if [[ $no_changes_choice == "1" ]]; then
            echo ""
            print_status "Ожидание изменений... Нажмите Enter когда будете готовы проверить снова"
            read
            clear
            print_header
            continue
        else
            exit 0
        fi
    fi

    # Добавление всех файлов
    print_status "Добавление всех изменений в staging area..."
    git add .
    if [ $? -eq 0 ]; then
        print_success "Все файлы добавлены в staging area"
    else
        print_error "Ошибка при добавлении файлов!"
        exit 1
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
        
        # Финальное сообщение
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${WHITE}                    КОММИТ ЗАВЕРШЕН УСПЕШНО!                  ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
    else
        print_error "Ошибка при создании коммита!"
        exit 1
    fi

    # Предложение push (если есть remote)
    if git remote | grep -q origin; then
        echo -e "${YELLOW}Хотите отправить изменения на сервер? (y/n):${NC}"
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

    # Предложение сделать еще один коммит
    echo -e "${YELLOW}Выберите следующее действие:${NC}"
    echo -e "${CYAN}1)${NC} Сделать еще один коммит"
    echo -e "${CYAN}2)${NC} Вернуться в главное меню"
    echo -e "${CYAN}3)${NC} Выйти"
    read -p "> " continue_choice
    
    case $continue_choice in
        1)
            echo ""
            print_status "Подготовка к следующему коммиту..."
            echo ""
            echo -e "${BLUE}Нажмите Enter когда будете готовы продолжить...${NC}"
            read
            clear
            print_header
            continue
            ;;
        2)
            clear
            print_header
            continue
            ;;
        3)
            break
            ;;
        *)
            print_error "Неверный выбор!"
            clear
            print_header
            continue
            ;;
    esac
done

# Финальное сообщение при выходе
echo -e "${BLUE}Спасибо за использование Git Commit Automation!${NC}"
echo -e "${BLUE}Нажмите Enter для выхода...${NC}"
read