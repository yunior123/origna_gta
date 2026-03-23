# Security Deny Rules — origna_gta

Adapted from [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config).

## Never Read These Files
- `~/.ssh/*` — SSH keys
- `~/.aws/*` — AWS credentials
- `~/.gnupg/*` — GPG keys
- `~/Library/Keychains/*` — macOS Keychain files (use `get-secret` CLI instead)
- `~/.config/gh/*` — GitHub CLI tokens
- `~/.netrc` — plain-text credentials
- `~/.vault-token` — Vault tokens
- Any file matching `*.pem`, `*.key`, `*credentials*`, `*secret*` outside the project

## Never Edit These Files
- `~/.bashrc`, `~/.zshrc`, `~/.profile`, `~/.zprofile` — shell configs (prevents backdoor injection)
- `~/.gitconfig` — git config (prevents credential manipulation)
- `/etc/*` — system config

## Never Run These Commands
- `rm -rf` — use `trash` or delete specific files by name
- `git push --force` to any branch — data loss risk
- `git commit --no-verify` — hooks exist for a reason
- `git push --no-verify` — same
- `chmod 777` — overly permissive
- `curl | sh` or `curl | bash` — blind execution
- `eval` with user-supplied input

## Never Store or Log
- Passwords or password hashes
- API keys (Stripe, Meilisearch, SurrealDB, etc.)
- PII (emails, phone numbers, addresses) in logs or debug output
- Card numbers, CVVs, or any payment card data
- JWT tokens in committed code
- Session tokens or cookies

## Push Policy
This project uses main-only workflow (no branches). Before any `git push`:
- Get explicit approval from the user
- Ensure `flutter analyze --no-fatal-infos && flutter test` passes
- Ensure `cargo clippy -D warnings && cargo test` passes (if Rust changed)
- Never force push

## Credential Access
Use the project's secret management:
- `get-secret KEY_NAME` — read from macOS Keychain vault
- `set-secret KEY_NAME VALUE` — write to vault
- `list-secrets` — list available keys
- Never access `~/.secrets/vault.keychain-db` directly

## If You Need a Blocked Resource
Ask the user. Explain what you need and why. Never work around these restrictions.
