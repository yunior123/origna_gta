#!/bin/bash
# =============================================================
# Manage Telegram Claude Bot (macOS App)
# Usage:
#   ./manage_telegram_bot.sh start    - Start the bot
#   ./manage_telegram_bot.sh stop     - Stop the bot
#   ./manage_telegram_bot.sh restart  - Restart the bot
#   ./manage_telegram_bot.sh status   - Check bot status
#   ./manage_telegram_bot.sh logs     - Tail the bot logs
#   ./manage_telegram_bot.sh install  - Add to Login Items
#   ./manage_telegram_bot.sh uninstall - Remove from Login Items
# =============================================================

set -euo pipefail

APP_PATH="$HOME/Applications/TelegramClaudeBot.app"
LOG_FILE="$HOME/.local/logs/telegram_bot.log"
ERROR_LOG="$HOME/.local/logs/telegram_bot_error.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

start_bot() {
    if pgrep -f "TelegramClaudeBot" > /dev/null 2>&1; then
        echo -e "${YELLOW}Bot is already running${NC}"
        status_bot
        return
    fi
    echo -e "${GREEN}🤖 Starting Telegram Claude Bot...${NC}"
    open "$APP_PATH"
    sleep 3
    status_bot
}

stop_bot() {
    echo -e "${YELLOW}🛑 Stopping Telegram Claude Bot...${NC}"
    pkill -f "TelegramClaudeBot" 2>/dev/null || true
    pkill -f "telegram_bot.py" 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✅ Bot stopped${NC}"
}

restart_bot() {
    stop_bot
    sleep 2
    start_bot
}

status_bot() {
    echo -e "${YELLOW}📊 Bot Status:${NC}"
    echo "---"
    if pgrep -f "telegram_bot.py" > /dev/null 2>&1; then
        PID=$(pgrep -f "telegram_bot.py" | head -1)
        echo -e "  Status:    ${GREEN}RUNNING${NC} (PID: $PID)"
    elif pgrep -f "TelegramClaudeBot" > /dev/null 2>&1; then
        echo -e "  Status:    ${YELLOW}STARTING...${NC}"
    else
        echo -e "  Status:    ${RED}NOT RUNNING${NC}"
    fi
    echo "  App:       $APP_PATH"
    echo "  Log:       $LOG_FILE"
    echo "  Error Log: $ERROR_LOG"
    echo "---"
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "Last 5 log lines:"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "(empty)"
    fi
}

install_login() {
    echo -e "${GREEN}📌 Adding to Login Items...${NC}"
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$APP_PATH\", hidden:true}" 2>/dev/null
    echo -e "${GREEN}✅ Bot will start automatically at login${NC}"
}

uninstall_login() {
    echo -e "${YELLOW}📌 Removing from Login Items...${NC}"
    osascript -e "tell application \"System Events\" to delete login item \"TelegramClaudeBot\"" 2>/dev/null || true
    echo -e "${GREEN}✅ Bot removed from auto-start${NC}"
}

logs_bot() {
    echo -e "${YELLOW}📋 Following bot logs (Ctrl+C to stop)...${NC}"
    echo "---"
    tail -f "$LOG_FILE" "$ERROR_LOG" 2>/dev/null
}

case "${1:-help}" in
    start)     start_bot ;;
    stop)      stop_bot ;;
    restart)   restart_bot ;;
    status)    status_bot ;;
    logs)      logs_bot ;;
    install)   install_login ;;
    uninstall) uninstall_login ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|install|uninstall}"
        echo ""
        echo "  start     - Start the bot"
        echo "  stop      - Stop the bot"
        echo "  restart   - Restart the bot"
        echo "  status    - Check if the bot is running"
        echo "  logs      - Follow the bot logs in real-time"
        echo "  install   - Add to macOS Login Items (auto-start at login)"
        echo "  uninstall - Remove from Login Items"
        ;;
esac
