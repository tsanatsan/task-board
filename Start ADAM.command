#!/bin/bash

# Set proper encoding for UTF-8 support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Change to script directory
cd "$(dirname "$0")"

# Enhanced color scheme
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
LIGHT_BLUE='\033[1;34m'
LIGHT_CYAN='\033[1;36m'
NC='\033[0m'

# Simple header function
print_header() {
    clear
    local title="$1"
    local subtitle="$2"
    
    echo
    echo -e "${LIGHT_CYAN}+--------------------------------------------------------------------------------+"
    printf "${LIGHT_CYAN}|%*s${WHITE}%s${LIGHT_CYAN}%*s|\n" $(((80-${#title})/2)) "" "$title" $(((80-${#title})/2)) ""
    if [ -n "$subtitle" ]; then
        printf "${LIGHT_CYAN}|%*s${GRAY}%s${LIGHT_CYAN}%*s|\n" $(((80-${#subtitle})/2)) "" "$subtitle" $(((80-${#subtitle})/2)) ""
    fi
    echo -e "+--------------------------------------------------------------------------------+${NC}"
    echo
}

# Status message function
status_msg() {
    local type="$1"
    local message="$2"
    
    case $type in
        "success") echo -e "  [OK] ${GREEN}${message}${NC}" ;;
        "error") echo -e "  [ERROR] ${RED}${message}${NC}" ;;
        "warning") echo -e "  [WARN] ${YELLOW}${message}${NC}" ;;
        "info") echo -e "  [INFO] ${LIGHT_BLUE}${message}${NC}" ;;
        "loading") echo -e "  [...] ${CYAN}${message}${NC}" ;;
    esac
}

# Check if server is running
is_running() {
    if [ -f ".server.pid" ]; then
        pid=$(cat ".server.pid")
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

# Main menu
show_menu() {
    local running=$(is_running)
    local github_connected=$(is_github_connected)
    
    print_header "ADAM CONTROL CENTER" "Project Management System"
    
    echo -e "${WHITE}[SETUP] MAIN OPERATIONS${NC}"
    echo -e "  ${LIGHT_BLUE}1${NC}) Check and install dependencies"
    echo
    
    echo -e "${WHITE}[SERVER] SERVER MANAGEMENT${NC}"
    if [ "$running" == "yes" ]; then
        echo -e "  ${LIGHT_BLUE}2${NC}) Stop server"
        echo -e "  ${LIGHT_BLUE}3${NC}) Restart server"
        echo -e "  ${LIGHT_BLUE}4${NC}) Show server status"
    else
        echo -e "  ${LIGHT_BLUE}2${NC}) Start local server"
        echo -e "  ${LIGHT_BLUE}4${NC}) Show server status"
    fi
    echo -e "  ${LIGHT_BLUE}5${NC}) View server logs"
    echo
    
    if [ "$github_connected" == "yes" ]; then
        echo -e "${WHITE}[GIT] GITHUB OPERATIONS${NC}"
        echo -e "  ${LIGHT_BLUE}6${NC}) Create commit and push to GitHub"
        echo -e "  ${LIGHT_BLUE}7${NC}) Show last 5 commits"
        echo -e "  ${LIGHT_BLUE}8${NC}) Update project (git pull)"
        echo
    fi
    
    echo -e "${WHITE}[EXIT]${NC}"
    echo -e "  ${LIGHT_BLUE}0${NC}) Exit ADAM"
    echo
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
    else
        status_msg "warning" "No package.json found"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

# Start server
start_server() {
    print_header "STARTING SERVER" "Initializing local development server"
    
    if [ "$(is_running)" = "yes" ]; then
        status_msg "error" "Server already running. Stop it first."
        read -p "Press Enter to return to menu..."
        return
    fi
    
    if [ -f package.json ]; then
        status_msg "loading" "Starting Node.js server..."
        npm run dev > adam.log 2>&1 &
        echo $! > .server.pid
        sleep 2
        
        if [ "$(is_running)" = "yes" ]; then
            status_msg "success" "Server started successfully"
            echo -e "  Check adam.log for server output"
        else
            status_msg "error" "Failed to start server"
            rm -f .server.pid
        fi
    else
        status_msg "error" "No package.json found"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

# Stop server
stop_server() {
    print_header "STOPPING SERVER" "Terminating local development server"
    
    if [ "$(is_running)" = "no" ]; then
        status_msg "warning" "Server not running"
        read -p "Press Enter to return to menu..."
        return
    fi
    
    PID=$(cat ".server.pid")
    status_msg "loading" "Stopping server with PID $PID..."
    
    if kill $PID 2>/dev/null; then
        status_msg "success" "Server stopped successfully"
        rm -f ".server.pid"
    else
        status_msg "error" "Error stopping server"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

# Show server status
show_status() {
    print_header "SERVER STATUS" "Current server information"
    
    if [ "$(is_running)" = "yes" ]; then
        PID=$(cat ".server.pid")
        status_msg "success" "Server is running with PID $PID"
    else
        status_msg "info" "Server is not running"
    fi
    
    if [ "$(is_github_connected)" = "yes" ]; then
        status_msg "success" "Project connected to GitHub"
        remote_url=$(git remote get-url origin 2>/dev/null)
        echo -e "  Repository: ${WHITE}$remote_url${NC}"
    else
        status_msg "warning" "Project not connected to GitHub"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

# View logs
view_logs() {
    print_header "VIEW LOGS" "Server activity monitoring (Ctrl+C to exit)"
    if [ -f "adam.log" ]; then
        tail -f "adam.log"
    else
        status_msg "warning" "Log file not found"
    fi
    echo
    read -p "Press Enter to return to menu..."
}

# Git operations
git_commit_push() {
    print_header "COMMIT & PUSH" "Creating commit and pushing to GitHub"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "Press Enter to return to menu..."
        return
    fi
    
    changes=$(git status -s)
    if [ -z "$changes" ]; then
        status_msg "info" "No changes to commit"
        read -p "Press Enter to return to menu..."
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
    read -p "Press Enter to return to menu..."
}

# Show recent commits
show_commits() {
    print_header "RECENT COMMITS" "Last 5 commits"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "Press Enter to return to menu..."
        return
    fi
    
    git log --oneline -5
    echo
    read -p "Press Enter to return to menu..."
}

# Git pull
git_pull() {
    print_header "UPDATE PROJECT" "Pulling latest changes from GitHub"
    
    if [ "$(is_github_connected)" == "no" ]; then
        status_msg "error" "Project not connected to GitHub"
        read -p "Press Enter to return to menu..."
        return
    fi
    
    status_msg "loading" "Pulling changes from GitHub..."
    if git pull; then
        status_msg "success" "Project updated successfully"
    else
        status_msg "error" "Failed to update project"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case $choice in
            1) install_deps ;;
            2) 
                if [ "$(is_running)" = "yes" ]; then
                    stop_server
                else
                    start_server
                fi
                ;;
            3) 
                if [ "$(is_running)" = "yes" ]; then
                    stop_server
                    start_server
                fi
                ;;
            4) show_status ;;
            5) view_logs ;;
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