# Recommended Hooks — origna_gta

Best hooks extracted from ECC + Anthropic security-guidance + gstack. Add to `.claude/settings.json` or `.claude/settings.local.json`.

## High-Value Hooks to Add

### 1. Block --no-verify (prevent skipping git hooks)
```json
"PreToolUse": [{
  "matcher": "Bash",
  "hooks": [{"type": "command", "command": "echo \"$TOOL_INPUT\" | python3 -c \"import sys,json; cmd=json.load(sys.stdin).get('command',''); sys.exit(2) if '--no-verify' in cmd or '--no-gpg-sign' in cmd else sys.exit(0)\""}],
  "description": "Block git hook bypass flags"
}]
```

### 2. Warn before dangerous commands (adapted from gstack /careful)
```json
"PreToolUse": [{
  "matcher": "Bash",
  "hooks": [{"type": "command", "command": "echo \"$TOOL_INPUT\" | python3 -c \"import sys,json; cmd=json.load(sys.stdin).get('command',''); dangerous=['rm -rf','DROP TABLE','git push --force','git reset --hard','git checkout .','git clean -f']; matches=[d for d in dangerous if d in cmd]; print(f'WARNING: dangerous command detected: {matches}') if matches else None; sys.exit(2) if matches else sys.exit(0)\""}],
  "description": "Block dangerous commands"
}]
```

### 3. Check for console.log/print() in modified files (Stop hook)
```json
"Stop": [{
  "matcher": "*",
  "hooks": [{"type": "command", "command": "git diff --name-only --diff-filter=AM | grep -E '\\.(dart|rs)$' | xargs grep -n 'print(' 2>/dev/null | grep -v '// ignore-print' | head -5; exit 0"}],
  "description": "Warn about print() in modified Dart/Rust files"
}]
```

### 4. Config protection (prevent weakening linter configs)
Block modifications to `analysis_options.yaml`, `.clippy.toml`, `eslintrc` — force fixing code instead.

### 5. Auto-format Dart on Stop
```json
"Stop": [{
  "matcher": "*",
  "hooks": [{"type": "command", "command": "cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta && git diff --name-only --diff-filter=AM | grep '.dart$' | head -20 | xargs dart format --line-length=120 2>/dev/null; exit 0"}],
  "description": "Auto-format modified Dart files"
}]
```

## Already Have (via existing config)
- `dart format` PostToolUse hook (from audit_fix_session)
- GSD hooks (session management)
- CCG hooks (multi-model workflows)
