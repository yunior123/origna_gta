# .github/claude.md — AI Agent Context (GitHub Copilot, Gemini, Claude Code)

> ## ⚠️ READ FIRST: Source of truth is [`CLAUDE.md`](../CLAUDE.md) in the project root.
> **ALL AI agents (Copilot, Gemini, Claude, etc.) MUST read `CLAUDE.md` before making any changes.**
> It contains the full project context, architecture rules, tech stack, conventions, and active TODOs.
> This file provides minimal context for GitHub-based workflows only.

## Project

OrignaGta — Canada-only e-commerce marketplace built with Flutter + Firebase + Stripe Connect.

## Critical Rules

1. **Read `CLAUDE.md` before doing anything** — it has ALL context
2. MVVM architecture only — frontend must not contain business logic
3. Always update tests, rules, indexes, schema when changing code
4. Fix all Dart compiler warnings — code must be clean
5. Malicious users will use the app — handle all edge cases
6. **Do NOT create new markdown files, reports, or summaries unless explicitly asked** — only update CLAUDE.md or README.md

## Tech Stack

- **Frontend:** Flutter 3.10+ (Web, Android, iOS) — Riverpod, Freezed
- **Backend:** Python 3.11 Cloud Functions — Flask, Pydantic, firebase-functions
- **Database:** Cloud Firestore
- **Payments:** Stripe Connect Express (direct charges, 2.5% fee, manual capture)
- **Search:** Algolia
- **Storage:** Firebase Storage + Cloudflare R2
- **Email:** Mailjet
- **Monitoring:** Sentry
- **Auth:** Firebase Auth + PyOTP (admin MFA)
- **CI/CD:** GitHub Actions (ci.yml, deploy.yml, secret-scan.yml)

## Quick Commands

```bash
./start-dev.sh                                    # Start emulators + Stripe
cd functions && source venv/bin/activate && pytest # Backend tests (288)
cd e2e && npm test                                 # E2E tests (132+)
cd origna_gta && flutter run -d chrome             # Flutter web
```

## GitHub Secrets

See [SECRETS_SETUP.md](SECRETS_SETUP.md) for full setup guide.

## Workflows

- `ci.yml` — Tests on PR/push (backend pytest + Flutter analyze)
- `deploy.yml` — Auto-deploy on push to main
- `secret-scan.yml` — Scan for leaked secrets