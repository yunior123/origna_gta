#!/usr/bin/env bash
# scripts/monitor-agents.sh
# Runs continuously in the background, checking agent logs every 5 minutes.

while true; do
  echo "[$(date)] Checking Agent Swarm Status..."
  
  # 1. Check Codex (Performance & Security)
  if ! pgrep -f "codex exec" > /dev/null; then
    echo "Codex finished or died. Restarting Security Audit..."
    codex exec -m gpt-5.4 -s danger-full-access "Use all skills to perform a deep security audit on ob-auth and ob-realtime. Output findings to /tmp/codex-security.log" > /tmp/codex-security.log 2>&1 &
  fi

  # 2. Check Gemini (Magic Strings & General Refactoring)
  if ! pgrep -f "gemini" > /dev/null; then
    echo "Gemini finished or died. Restarting Magic String Audit..."
    cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta && gemini -m gemini-3-pro-preview -y -p "Audit origna_gta/lib/features/ for magic strings and replace them using schema_constants.dart. Document in STATE.md." > /tmp/gemini-magic.log 2>&1 &
  fi

  # 3. Check Mimo/OpenCode (Code Correctness & Documentation)
  if ! pgrep -f "opencode" > /dev/null; then
    echo "OpenCode finished or died. Restarting Frontend Audit..."
    /opt/homebrew/bin/opencode run -m opencode/mimo-v2-pro-free "Audit the Flutter viewmodels for state leaks and proper Riverpod disposal. Add findings to STATE.md." > /tmp/mimo-frontend.log 2>&1 &
  fi
  
  sleep 300 # Sleep for 5 minutes before checking again
done