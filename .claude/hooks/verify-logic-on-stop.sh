#!/bin/bash
# Hook: Stop — Before Claude finishes, verify that logic has been checked
# This is a prompt-based stop hook alternative as a command hook

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Don't loop — if we're already in a stop hook, let it finish
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Get the transcript to check if any files were edited in this session
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

exit 0
