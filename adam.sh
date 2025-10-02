#!/bin/bash
cd "$(dirname "$0")"

LOGFILE="adam.log"
PIDFILE=".server.pid"
DEPENDENCY_FILE=""
LAST_DEP_HASH_FILE=".last_dep_hash"
MAX_LOG_SIZE=1048576

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_tools() {
  local missing=0
  for cmd in git npm python3; do
    if ! command -v $cmd >/dev/null 2>&1; then
      echo -e "${RED}Ошибка: утилита '$cmd' не установлена или не доступна в PATH${NC}"
      missing=1
    fi
  done

  # Проверяем pip или pip3, только если есть requirements.txt
  if [ -f "requirements.txt" ]; then
    if ! command -v pip >/dev/null 2>&1 && ! command -v pip3 >/dev/null 2>&1; then
      echo -e "${RED}Ошибка: утилита 'pip' или 'pip3' не установлена или недоступна${NC}"
      missing=1
    fi
  fi

  if [ $missing -eq 1 ]; then
    echo "Пожалуйста, установите отсутствующие утилиты и повторите запуск."
    exit 1
  fi
}

rotate_log() {
  if [ -f "$LOGFILE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      log_size=$(stat -f%z "$LOGFILE")
    else
      log_size=$(stat -c%s "$LOGFILE")
    fi
    if [ "$log_size" -ge "$MAX_LOG_SIZE" ]; then
      mv "$LOGFILE" "${LOGFILE}.$(date +%Y%m%d%H%M%S).old"
      echo "Лог $LOGFILE ротирован" >> "$LOGFILE"
    fi
  fi
}

log() {
  rotate_log
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGFILE"
}

print_header() {
  echo -e "${BLUE}==============================${NC}"
  echo -e "${BLUE} $1 ${NC}"
  echo -e "${BLUE}==============================${NC}"
}

calculate_hash() {
  if [ -f "$DEPENDENCY_FILE" ]; then
    shasum "$DEPENDENCY_FILE" | awk '{print $1}'
  else
    echo ""
  fi
}

check_dependencies_changed() {
  if [ ! -f "$LAST_DEP_HASH_FILE" ]; then
    echo "yes"
    return
  fi
  current_hash=$(calculate_hash)
  last_hash=$(cat "$LAST_DEP_HASH_FILE")
  if [ "$current_hash" != "$last_hash" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

update_dep_hash() {
  if [ -f "$DEPENDENCY_FILE" ]; then
    calculate_hash > "$LAST_DEP_HASH_FILE"
  fi
}

get_port() {
  PORT=$(sed 's/\x1b\[[0-9;]*m//g' "$LOGFILE" | grep 'Local:' | tail -1 | grep -o 'http://localhost:[0-9]*' | sed 's/http:\/\/localhost://')
  echo "$PORT"
}

get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main"
}

is_github_connected() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ "$remote_url" == *github.com* ]]; then
      echo "yes"
      return
    fi
  fi
  echo "no"
}

status() {
  print_header "Проверка статуса окружения"
  if [ "$(is_github_connected)" == "yes" ]; then
    log "${GREEN}Связь с GitHub есть${NC}"
  else
    log "${YELLOW}GitHub не подключен${NC}"
  fi
  if [ -f package.json ]; then
    DEPENDENCY_FILE="package.json"
    log "Node.js проект обнаружен"
    if check_dependencies_changed | grep -q "yes"; then
      log "${YELLOW}Обнаружены изменения в package.json, обновляю зависимости...${NC}"
      if npm install >> "$LOGFILE" 2>&1; then
        log "${GREEN}npm зависимости успешно обновлены${NC}"
        update_dep_hash
      else
        log "${RED}Ошибка при установке npm зависимостей. Подробности в $LOGFILE${NC}"
      fi
    else
      log "${GREEN}Зависимости npm актуальны${NC}"
    fi
  elif [ -f requirements.txt ]; then
    DEPENDENCY_FILE="requirements.txt"
    log "Python проект обнаружен"
    if [ ! -d venv ]; then
      log "${YELLOW}Виртуальное окружение не найдено, создаю и устанавливаю зависимости...${NC}"
      if python3 -m venv venv >> "$LOGFILE" 2>&1 && source venv/bin/activate && pip install -r requirements.txt >> "$LOGFILE" 2>&1 && deactivate; then
        log "${GREEN}Виртуальное окружение создано и зависимости установлены${NC}"
        update_dep_hash
      else
        log "${RED}Ошибка при создании окружения или установке зависимостей. Подробности в $LOGFILE${NC}"
      fi
    else
      if check_dependencies_changed | grep -q "yes"; then
        log "${YELLOW}Обнаружены изменения в requirements.txt, обновляю зависимости...${NC}"
        source venv/bin/activate
        if pip install -r requirements.txt >> "$LOGFILE" 2>&1; then
          log "${GREEN}Зависимости Python успешно обновлены${NC}"
          update_dep_hash
        else
          log "${RED}Ошибка при обновлении зависимостей pip. Подробности в $LOGFILE${NC}"
        fi
        deactivate
      else
        log "${GREEN}Виртуальное окружение и зависимости актуальны${NC}"
      fi
    fi
  else
    log "${RED}Проект с неизвестной технологией или отсутствуют основные файлы конфигурации${NC}"
  fi
  echo
}

is_running() {
  if [ ! -f "$PIDFILE" ]; then
    echo "no"
    return
  fi
  PID=$(cat "$PIDFILE")
  if ps -p $PID > /dev/null 2>&1; then
    echo "yes"
  else
    echo "no"
  fi
}

start() {
  print_header "Запуск локального сервера"
  if [ "$(is_running)" = "yes" ]; then
    log "${RED}Сервер уже запущен с PID $(cat $PIDFILE). Остановите его перед новым запуском.${NC}"
    return
  fi
  if [ -f package.json ]; then
    npm run dev >> "$LOGFILE" 2>&1 &
    echo $! > "$PIDFILE"
    sleep 2
    if [ "$(is_running)" = "yes" ]; then
      PORT=$(get_port)
      log "${GREEN}Node.js сервер успешно запущен с PID $(cat $PIDFILE)${NC}"
      if [ -n "$PORT" ]; then
        echo -e "${GREEN}Ссылка для доступа: http://localhost:$PORT${NC}"
      else
        log "${YELLOW}Не удалось определить порт сервера для отображения ссылки${NC}"
      fi
    else
      log "${RED}Не удалось запустить Node.js сервер. См. $LOGFILE${NC}"
      rm "$PIDFILE"
    fi
  elif [ -f requirements.txt ]; then
    source venv/bin/activate
    python app.py >> "$LOGFILE" 2>&1 &
    echo $! > "$PIDFILE"
    sleep 2
    if [ "$(is_running)" = "yes" ]; then
      PORT=$(get_port)
      log "${GREEN}Python сервер успешно запущен с PID $(cat $PIDFILE)${NC}"
      if [ -n "$PORT" ]; then
        echo -e "${GREEN}Ссылка для доступа: http://localhost:$PORT${NC}"
      else
        log "${YELLOW}Не удалось определить порт сервера для отображения ссылки${NC}"
      fi
    else
      log "${RED}Не удалось запустить Python сервер. См. $LOGFILE${NC}"
      rm "$PIDFILE"
    fi
    deactivate
  else
    log "${RED}Неизвестная технология для запуска${NC}"
  fi
  echo
}

stop() {
  print_header "Остановка локального сервера"
  if [ "$(is_running)" = "no" ]; then
    log "${YELLOW}Сервер не запущен или PID файл отсутствует${NC}"
    rm -f "$PIDFILE"
    return
  fi
  PID=$(cat "$PIDFILE")
  log "${YELLOW}Останавливаю сервер с PID $PID...${NC}"
  if kill $PID >> "$LOGFILE" 2>&1; then
    log "${GREEN}Сервер успешно остановлен${NC}"
    rm "$PIDFILE"
  else
    log "${RED}Ошибка при остановке сервера. См. $LOGFILE${NC}"
  fi
  echo
}

restart() {
  print_header "Перезапуск локального сервера"
  stop
  start
}

show_logs() {
  print_header "Просмотр логов (нажмите Ctrl+C для выхода)"
  tail -f "$LOGFILE"
  echo -e "${YELLOW}\nВы вышли из просмотра логов.${NC}"
  read -p "Нажмите Enter, чтобы вернуться в меню..."
}

local_commit() {
  if [ "$(is_github_connected)" == "no" ]; then
    echo -e "${RED}Проект не подключен к GitHub, локальный коммит невозможен${NC}"
    return
  fi
  changes=$(git status -s)
  if [ -z "$changes" ]; then
    echo "Нет изменений для коммита"
    return
  fi
  message="Обновления:\n"
  while IFS= read -r line; do
    status_code=$(echo "$line" | awk '{print $1}')
    file_name=$(echo "$line" | awk '{print $2}')
    case $status_code in
      M) msg="Изменён $file_name" ;;
      A) msg="Добавлен $file_name" ;;
      D) msg="Удалён $file_name" ;;
      *) msg="Изменение $file_name" ;;
    esac
    message+="$msg\n"
  done <<< "$changes"
  git add .
  git commit -m "$(echo -e "$message")"
  echo "Создан локальный коммит с сообщением об изменениях"
}

push_commit() {
  if [ "$(is_github_connected)" == "no" ]; then
    echo -e "${RED}Проект не подключен к GitHub, пуш невозможен${NC}"
    return
  fi
  changes=$(git status -s)
  if [ -z "$changes" ]; then
    echo "Нет изменений для коммита и пуша"
    return
  fi
  local_commit
  branch=$(get_current_branch)
  git push origin "$branch"
  echo "Коммит отправлен на GitHub в ветку $branch"
}

connect_github() {
  if [ "$(is_github_connected)" == "yes" ]; then
    echo "Проект уже подключен к GitHub"
    return
  fi
  read -p "Введите URL удалённого репозитория GitHub: " repo_url
  git init
  git remote add origin "$repo_url"
  echo "Проект подключён к GitHub с репозиторием $repo_url"
}

show_recent_commits() {
  if [ "$(is_github_connected)" == "no" ]; then
    echo -e "${RED}GitHub не подключён, показать последние коммиты невозможно${NC}"
    return
  fi
  echo "Последние 5 коммитов:"
  git log -5 --oneline
  echo
  read -p "Нажмите Enter для возврата в меню..."
}

git_pull() {
  if [ "$(is_github_connected)" == "no" ]; then
    echo -e "${RED}GitHub не подключён, git pull невозможен${NC}"
    return
  fi
  branch=$(get_current_branch)
  echo "Выполняется git pull для ветки $branch ..."
  git pull origin "$branch"
  echo "Обновление завершено."
}

git_new_branch() {
  read -p "Введите имя новой ветки: " new_branch
  if [ -z "$new_branch" ]; then
    echo "Имя ветки не может быть пустым."
    return
  fi
  git checkout -b "$new_branch"
  echo "Создана и переключена на ветку $new_branch."
}

git_status_verbose() {
  git status -v
  echo
  read -p "Нажмите Enter для возврата в меню..."
}

git_diff() {
  git diff
  echo
  read -p "Нажмите Enter для возврата в меню..."
}

show_menu() {
  echo -e "${BLUE}Выберите действие:${NC}"

  echo "Общее:"
  echo "1) Проверить и установить зависимости"

  local running=$(is_running)
  local github_connected=$(is_github_connected)

  if [ "$running" == "yes" ]; then
    echo "Работа с сервером:"
    echo "2) Остановить сервер"
    echo "3) Перезапустить сервер"
    echo "4) Показать статус сервера"

    echo "Логи:"
    echo "5) Просмотреть логи сервера"
  else
    echo "2) Запустить локальный сервер"
    echo "5) Просмотреть логи сервера"
  fi

  echo "Работа с GitHub:"
  if [ "$github_connected" == "yes" ]; then
    echo "6) Создать локальный коммит с изменениями"
    echo "7) Создать коммит и отправить на GitHub"
    echo "8) Показать последние 5 коммитов"
    echo "9) Обновить проект (git pull)"
    echo "10) Создать новую ветку git"
    echo "11) Просмотреть подробный статус git"
    echo "12) Просмотреть git diff"
  else
    echo "6) Подключить проект к GitHub"
  fi

  echo "0) Выйти"
  
  read -p "Номер команды: " choice

  case $choice in
    0) echo "Выход"; exit 0 ;;
    1) status ;;
    2)
      if [ "$running" == "yes" ]; then stop; else start; fi ;;
    3)
      if [ "$running" == "yes" ]; then restart; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    4)
      if [ "$running" == "yes" ]; then server_status; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    5) show_logs ;;
    6)
      if [ "$github_connected" == "yes" ]; then local_commit; else connect_github; fi ;;
    7)
      if [ "$github_connected" == "yes" ]; then push_commit; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    8)
      if [ "$github_connected" == "yes" ]; then show_recent_commits; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    9)
      if [ "$github_connected" == "yes" ]; then git_pull; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    10)
      if [ "$github_connected" == "yes" ]; then git_new_branch; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    11)
      if [ "$github_connected" == "yes" ]; then git_status_verbose; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    12)
      if [ "$github_connected" == "yes" ]; then git_diff; else echo -e "${RED}Неверный выбор${NC}"; fi ;;
    *)
      echo -e "${RED}Неверный выбор${NC}" ;;
  esac
}

check_tools

while true; do
  show_menu
done
