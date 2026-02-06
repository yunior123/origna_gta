#!/bin/bash
# =============================================================
# Telegram Bot Launcher (for LaunchAgent)
# Runs the Claude Code <-> Telegram bridge bot
# =============================================================

set -euo pipefail

PROJECT_DIR="/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta"
LOG_DIR="$PROJECT_DIR/logs"
BOT_SCRIPT="$PROJECT_DIR/telegram_bot.py"
PYTHON="/usr/bin/python3"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Check internet connectivity before starting
check_internet() {
    for i in 1 2 3 4 5; do
        if curl -s --max-time 5 https://api.telegram.org > /dev/null 2>&1; then
            return 0
        fi
        echo "$(date): Waiting for internet... attempt $i/5"
        sleep 10
    done
    echo "$(date): No internet after 5 attempts, will retry via launchd restart"
    return 1
}

cd "$PROJECT_DIR"

echo "$(date): Starting Telegram Bot..."
echo "$(date): Project: $PROJECT_DIR"

# Wait for internet (important at boot/login time)
if ! check_internet; then
    exit 1
fi

# Ensure dependencies are available
if ! "$PYTHON" -c "import telegram" 2>/dev/null; then
    echo "$(date): Installing python-telegram-bot..."
    "$PYTHON" -m pip install python-telegram-bot --user --quiet
fi

echo "$(date): Internet OK, launching bot..."

# Run the bot
exec "$PYTHON" "$BOT_SCRIPT"
