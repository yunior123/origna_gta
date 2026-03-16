#!/bin/bash
# Hook: PreToolUse — Protect production-critical files from accidental edits
# Warns when editing deployment configs, production secrets, or VPS config

FILE_PATH="${1:-}"
if echo "$FILE_PATH" | grep -qE "\.claude/(agents|hooks|rules|commands)/"; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Production-critical file patterns
BLOCKED=false
REASON=""

case "$FILE_PATH" in
  *serviceAccountKey*)
    BLOCKED=true
    REASON="SERVICE ACCOUNT KEY — This is a production secret. Edit manually."
    ;;
  *deploy_web.sh)
    REASON="VPS DEPLOY SCRIPT — Changes affect all environments. Test staged releases."
    ;;
  *Caddyfile*)
    REASON="CADDYFILE — Changes affect VPS reverse proxy for all environments."
    ;;
  *orignabase.toml*)
    REASON="ORIGNABASE CONFIG — Changes affect backend behaviour across all envs."
    ;;
  *.env.production*|*prod.env*)
    BLOCKED=true
    REASON="PRODUCTION ENV — Cannot edit production environment variables directly."
    ;;
esac

if [ "$BLOCKED" = true ]; then
  echo "{\"decision\":\"block\",\"reason\":\"$REASON\"}"
  exit 0
fi

if [ -n "$REASON" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"$REASON\"}}"
fi

exit 0
