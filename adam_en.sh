#!/bin/bash

# Set proper encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

cd "$(dirname "$0")"

LOGFILE="adam.log"
PIDFILE=".server.pid"
DEPENDENCY_FILE=""
LAST_DEP_HASH_FILE=".last_dep_hash"
MAX_LOG_SIZE=1048576

# Enhanced color scheme
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
LIGHT_GREEN='\033[1;32m'
LIGHT_BLUE='\033[1;34m'
LIGHT_CYAN='\033[1;36m'
ORANGE='\033[0;38;5;208m'
PINK='\033[0;38;5;213m'
NC='\033[0m'

# Box drawing characters (ASCII fallback)
BOX_H='-'
BOX_V='|'
BOX_TL='+'
BOX_TR='+'
BOX_BL='+'
BOX_BR='+'

# Icons and symbols (simple ASCII)
ICON_SUCCESS='[OK]'
ICON_ERROR='[ERROR]'
ICON_WARNING='[WARN]'
ICON_INFO='[INFO]'
ICON_LOADING='[...]'
ICON_SERVER='[SERVER]'
ICON_GITHUB='[GIT]'
ICON_FOLDER='[DIR]'
ICON_FILE='[FILE]'
ICON_GEAR='[SETUP]'
ICON_ARROW='->'
ICON_CHECK='[v]'
ICON_CROSS='[x]'
ICON_ROCKET='[START]'
ICON_WRENCH='[TOOL]'
ICON_COMPUTER='[PC]'

# Enhanced header function
print_header() {
    clear
    local title="$1"
    local subtitle="$2"
    local box_width=80
    
    echo
    echo -e "${LIGHT_CYAN}"
    echo -n "${BOX_TL}"
    for ((i=0; i<box_width; i++)); do echo -n "${BOX_H}"; done
    echo "${BOX_TR}"
    
    # Title line
    echo -n "${BOX_V}"
    local title_len=${#title}
    local padding=$(( (box_width - title_len) / 2 ))
    for ((i=0; i<padding; i++)); do echo -n " "; done
    echo -n "${WHITE}${title}${LIGHT_CYAN}"
    for ((i=0; i<$((box_width - title_len - padding)); i++)); do echo -n " "; done
    echo "${BOX_V}"
    
    # Subtitle line if provided
    if [ -n "$subtitle" ]; then
        echo -n "${BOX_V}"
        local sub_len=${#subtitle}
        local sub_padding=$(( (box_width - sub_len) / 2 ))
        for ((i=0; i<sub_padding; i++)); do echo -n " "; done
        echo -n "${GRAY}${subtitle}${LIGHT_CYAN}"
        for ((i=0; i<$((box_width - sub_len - sub_padding)); i++)); do echo -n " "; done
        echo "${BOX_V}"
    fi
    
    echo -n "${BOX_BL}"
    for ((i=0; i<box_width; i++)); do echo -n "${BOX_H}"; done
    echo -e "${BOX_BR}${NC}"
    echo
}

# Status message with icons
status_msg() {
    local type="$1"
    local message="$2"
    
    case $type in
        "success")
            echo -e "  ${ICON_SUCCESS} ${GREEN}${message}${NC}"
            ;;
        "error")
            echo -e "  ${ICON_ERROR} ${RED}${message}${NC}"
            ;;
        "warning")
            echo -e "  ${ICON_WARNING} ${YELLOW}${message}${NC}"
            ;;
        "info")
            echo -e "  ${ICON_INFO} ${LIGHT_BLUE}${message}${NC}"
            ;;
        "loading")
            echo -e "  ${ICON_LOADING} ${CYAN}${message}${NC}"
            ;;
    esac
}

# Check if server is running
is_running() {
    if [ -f "$PIDFILE" ]; then
        pid=$(cat "$PIDFILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "yes"
        else
            echo "no"
        fi
    else
        echo "no"
    fi
}

# Check GitHub connection
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

# Get port from logs
get_port() {
    PORT=$(sed 's/\x1b\[[0-9;]*m//g' "$LOGFILE" | grep 'Local:' | tail -1 | grep -o 'http://localhost:[0-9]*' | sed 's/http:\/\/localhost://')
    echo "$PORT"
}

# Check tools availability
check_tools() {
    print_header "TOOLS CHECK" "Checking availability of required tools"
    
    status_msg "loading" "Checking git... "
    if command -v git >/dev/null 2>&1; then
        status_msg "success" "git found"
    else
        status_msg "error" "git not found"
        echo
        echo -e "${RED}Please install git first${NC}"
        read -p "${ICON_ARROW} Press Enter to continue..."
        return 1
    fi
    
    status_msg "loading" "Checking npm... "
    if command -v npm >/dev/null 2>&1; then
        status_msg "success" "npm found"
    else
        status_msg "error" "npm not found"
        echo
        echo -e "${RED}Please install Node.js and npm first${NC}"
        read -p "${ICON_ARROW} Press Enter to continue..."
        return 1
    fi
    
    status_msg "loading" "Checking python3... "
    if command -v python3 >/dev/null 2>&1; then
        status_msg "success" "python3 found"
    else
        status_msg "warning" "python3 not found (only needed for Python projects)"
    fi
    
    status_msg "success" "All required tools are available"
    echo
    read -p "${ICON_ARROW} Press Enter to continue..."
    return 0
}

# Install dependencies
install_deps() {
    print_header "INSTALL DEPENDENCIES" "Installing project dependencies"
    
    if [ -f package.json ]; then
        status_msg "loading" "Installing npm packages..."
        if npm install; then
            status_msg "success" "npm packages installed successfully"
        else
            status_msg "error" "Failed to install npm packages"
        fi
    elif [ -f requirements.txt ]; then
        status_msg "loading" "Installing Python packages..."
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
        source venv/bin/activate
        if pip install -r requirements.txt; then
            status_msg "success" "Python packages installed successfully"
        else
            status_msg "error" "Failed to install Python packages"
        fi
        deactivate
    else
        status_msg "warning" "No package.json or requirements.txt found"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Start server function
start() {
    print_header "STARTING SERVER" "Initializing local development server"
    
    if [ "$(is_running)" = "yes" ]; then
        status_msg "error" "Server already running with PID $(cat $PIDFILE). Stop it before starting a new one"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    if [ -f package.json ]; then
        status_msg "loading" "Starting Node.js server..."
        npm run dev >> "$LOGFILE" 2>&1 &
        echo $! > "$PIDFILE"
        sleep 2
        
        if [ "$(is_running)" = "yes" ]; then
            PORT=$(get_port)
            status_msg "success" "Node.js server started successfully with PID $(cat $PIDFILE)"
            if [ -n "$PORT" ]; then
                echo -e "  ${ICON_ROCKET} ${GREEN}Access URL: ${WHITE}http://localhost:$PORT${NC}"
            else
                status_msg "warning" "Could not determine server port for URL display"
            fi
        else
            status_msg "error" "Failed to start Node.js server. Check $LOGFILE"
            rm "$PIDFILE"
        fi
        
    elif [ -f requirements.txt ]; then
        status_msg "loading" "Starting Python server..."
        source venv/bin/activate
        python app.py >> "$LOGFILE" 2>&1 &
        echo $! > "$PIDFILE"
        sleep 2
        
        if [ "$(is_running)" = "yes" ]; then
            PORT=$(get_port)
            status_msg "success" "Python server started successfully with PID $(cat $PIDFILE)"
            if [ -n "$PORT" ]; then
                echo -e "  ${ICON_ROCKET} ${GREEN}Access URL: ${WHITE}http://localhost:$PORT${NC}"
            else
                status_msg "warning" "Could not determine server port for URL display"
            fi
        else
            status_msg "error" "Failed to start Python server. Check $LOGFILE"
            rm "$PIDFILE"
        fi
        deactivate
    else
        status_msg "error" "Unknown technology for starting server"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Stop server function
stop() {
    print_header "STOPPING SERVER" "Terminating local development server"
    
    if [ "$(is_running)" = "no" ]; then
        status_msg "warning" "Server not running or PID file missing"
        rm -f "$PIDFILE"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    PID=$(cat "$PIDFILE")
    status_msg "loading" "Stopping server with PID $PID..."
    
    if kill $PID >> "$LOGFILE" 2>&1; then
        status_msg "success" "Server stopped successfully"
        rm "$PIDFILE"
    else
        status_msg "error" "Error stopping server. Check $LOGFILE"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Show server status
status() {
    print_header "SERVER STATUS" "Current server information"
    
    if [ "$(is_running)" = "yes" ]; then
        PID=$(cat "$PIDFILE")
        PORT=$(get_port)
        status_msg "success" "Server is running with PID $PID"
        if [ -n "$PORT" ]; then
            echo -e "  ${ICON_ROCKET} ${GREEN}Access URL: ${WHITE}http://localhost:$PORT${NC}"
        fi
    else
        status_msg "info" "Server is not running"
    fi
    
    if [ "$(is_github_connected)" = "yes" ]; then
        status_msg "success" "Project connected to GitHub"
        remote_url=$(git remote get-url origin 2>/dev/null)
        echo -e "  ${ICON_GITHUB} ${GREEN}Repository: ${WHITE}$remote_url${NC}"
    else
        status_msg "warning" "Project not connected to GitHub"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Show logs
show_logs() {
    print_header "VIEW LOGS" "Server activity monitoring (Ctrl+C to exit)"
    if [ -f "$LOGFILE" ]; then
        tail -f "$LOGFILE"
    else
        status_msg "warning" "Log file not found"
    fi
    echo
    status_msg "info" "Exited log viewing"
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Main menu
show_menu() {
    local running=$(is_running)
    local github_connected=$(is_github_connected)
    
    print_header "ADAM CONTROL CENTER" "Project Management System"
    
    echo -e "${WHITE}${ICON_GEAR} MAIN OPERATIONS${NC}"
    echo -e "  ${LIGHT_BLUE}1${NC}) ${ICON_FOLDER} Check and install dependencies"
    echo
    
    echo -e "${WHITE}${ICON_SERVER} SERVER MANAGEMENT${NC}"
    if [ "$running" == "yes" ]; then
        echo -e "  ${LIGHT_BLUE}2${NC}) ${ICON_CROSS} Stop server"
        echo -e "  ${LIGHT_BLUE}3${NC}) ${ICON_LOADING} Restart server"
        echo -e "  ${LIGHT_BLUE}4${NC}) ${ICON_INFO} Show server status"
    else
        echo -e "  ${LIGHT_BLUE}2${NC}) ${ICON_ROCKET} Start local server"
        echo -e "  ${LIGHT_BLUE}4${NC}) ${ICON_INFO} Show server status"
    fi
    echo -e "  ${LIGHT_BLUE}5${NC}) ${ICON_FILE} View server logs"
    echo
    
    if [ "$github_connected" == "yes" ]; then
        echo -e "${WHITE}${ICON_GITHUB} GITHUB OPERATIONS${NC}"
        echo -e "  ${LIGHT_BLUE}6${NC}) ${ICON_ARROW} Create commit and push to GitHub"
        echo -e "  ${LIGHT_BLUE}7${NC}) ${ICON_INFO} Show last 5 commits"
        echo -e "  ${LIGHT_BLUE}8${NC}) ${ICON_LOADING} Update project (git pull)"
        echo
    fi
    
    echo -e "${WHITE}${ICON_CROSS} EXIT${NC}"
    echo -e "  ${LIGHT_BLUE}0${NC}) Exit ADAM"
    echo
}

# Git operations
git_commit_push() {
    print_header "COMMIT & PUSH" "Creating commit and pushing to GitHub"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    changes=$(git status -s)
    if [ -z "$changes" ]; then
        status_msg "info" "No changes to commit"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    echo -e "${YELLOW}Current changes:${NC}"
    git status -s
    echo
    
    read -p "Enter commit message (or press Enter for auto-message): " commit_msg
    
    if [ -z "$commit_msg" ]; then
        commit_msg="Update: $(date '+%Y-%m-%d %H:%M')"
    fi
    
    status_msg "loading" "Creating commit..."
    git add .
    git commit -m "$commit_msg"
    
    status_msg "loading" "Pushing to GitHub..."
    if git push; then
        status_msg "success" "Successfully pushed to GitHub"
    else
        status_msg "error" "Failed to push to GitHub"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Show recent commits
show_commits() {
    print_header "RECENT COMMITS" "Last 5 commits"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    git log --oneline -5
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Git pull
git_pull() {
    print_header "UPDATE PROJECT" "Pulling latest changes from GitHub"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "${ICON_ARROW} Press Enter to return to menu..."
        return
    fi
    
    status_msg "loading" "Pulling changes from GitHub..."
    if git pull; then
        status_msg "success" "Project updated successfully"
    else
        status_msg "error" "Failed to update project"
    fi
    
    echo
    read -p "${ICON_ARROW} Press Enter to return to menu..."
}

# Main loop
main() {
    # Initial tools check
    if ! check_tools; then
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case $choice in
            1) install_deps ;;
            2) 
                if [ "$(is_running)" = "yes" ]; then
                    stop
                else
                    start
                fi
                ;;
            3) 
                if [ "$(is_running)" = "yes" ]; then
                    stop
                    start
                fi
                ;;
            4) status ;;
            5) show_logs ;;
            6) 
                if [ "$(is_github_connected)" = "yes" ]; then
                    git_commit_push
                fi
                ;;
            7) 
                if [ "$(is_github_connected)" = "yes" ]; then
                    show_commits
                fi
                ;;
            8) 
                if [ "$(is_github_connected)" = "yes" ]; then
                    git_pull
                fi
                ;;
            0) 
                print_header "GOODBYE" "Thank you for using ADAM Control Center"
                exit 0
                ;;
            *) 
                status_msg "error" "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main