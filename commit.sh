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

# Очистка экрана и показ заголовка
clear
print_header

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
    read -p "Нажмите Enter для выхода..."
    exit 0
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
    current_date=$(date "+%Y-%m-%d %H:%M")
    commit_message="Update: $current_date"
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

# Пауза перед закрытием
echo -e "${BLUE}Нажмите Enter для выхода...${NC}"
read