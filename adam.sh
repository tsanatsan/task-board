#!/bin/bash
cd "$(dirname "$0")"

LOGFILE="adam.log"
PIDFILE=".server.pid"
DEPENDENCY_FILE=""
LAST_DEP_HASH_FILE=".last_dep_hash"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

server_started=0

log() {
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
  # Проверка подключения к GitHub
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
      server_started=1
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
      server_started=1
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
    server_started=0
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
  git push origin main || git push origin master
  echo "Коммит отправлен на GitHub"
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

show_menu() {
  echo -e "${BLUE}"
  echo "Выберите действие:"
  echo "1) Проверить и установить зависимости"
  echo "2) Запустить локальный сервер"
  if [ $server_started -eq 1 ]; then
    echo "3) Остановить сервер"
    echo "4) Перезапустить сервер"
    echo "5) Показать статус сервера"
    echo "6) Создать локальный коммит с изменениями"
    echo "7) Создать коммит и отправить на GitHub"
    echo "8) Подключить проект к GitHub"
    echo "0) Выйти"
  else
    echo "0) Выйти"
  fi
  echo -e "${NC}"
  read -p "Номер команды: " choice
  if [ $server_started -eq 1 ]; then
    case $choice in
      1) status ;;
      2) start ;;
      3) stop ;;
      4) restart ;;
      5) server_status ;;
      6) local_commit ;;
      7) push_commit ;;
      8) connect_github ;;
      0) echo "Выход"; exit 0 ;;
      *) echo -e "${RED}Неверный выбор${NC}" ;;
    esac
  else
    case $choice in
      1) status ;;
      2) start ;;
      0) echo "Выход"; exit 0 ;;
      *) echo -e "${RED}Неверный выбор${NC}" ;;
    esac
  fi
}

server_status() {
  print_header "Статус сервера"
  if [ "$(is_running)" = "yes" ]; then
    PORT=$(get_port)
    echo -e "${GREEN}Сервер запущен с PID $(cat $PIDFILE)${NC}"
    if [ -n "$PORT" ]; then
      echo -e "${GREEN}Доступен по адресу: http://localhost:$PORT${NC}"
    else
      echo -e "${YELLOW}Порт сервера не определён${NC}"
    fi
  else
    echo -e "${RED}Сервер не запущен${NC}"
  fi
  echo
}

while true; do
  show_menu
done
