#!/usr/bin/env bash
# PostToolUse hook: auto-format Dart files after Edit/Write operations
# Reads the hook input JSON from stdin, extracts file path, formats if .dart

FILE_PATH=$(jq -r '.tool_response.filePath // .tool_input.file_path' 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -q '\.dart$'; then
  /Users/yuniorrodriguezosorio/flutter/bin/dart format "$FILE_PATH" 2>/dev/null || true
fi

exit 0
