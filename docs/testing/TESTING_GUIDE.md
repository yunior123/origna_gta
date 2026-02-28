# Testing Guide

> **Source of truth:** `.claude/skills/e2e-test-suites/SKILL.md` (34 specs, kept current)

## E2E Tests (Playwright)
- **Config:** `e2e/playwright.config.dev.ts`
- **Specs:** `e2e/playwright_ui/*.spec.ts` (34 files)
- **Helpers:** `e2e/playwright_ui/api-helpers.ts`, `flutter-helpers.ts`
- **Base URL:** `https://orignagta-dev.web.app`
- **Run all:** `npx playwright test --config=e2e/playwright.config.dev.ts`
- **Run one:** `npx playwright test e2e/playwright_ui/<spec>.spec.ts --config=e2e/playwright.config.dev.ts`

## Backend Tests (pytest)
- **Run:** `cd functions && pytest`
- **Config:** `functions/pytest.ini`

## Non-Negotiable Rules
- Never `fill()` — always `pressSequentially()`
- Never `page.goto()` after login — use `page.goBack()`
- No dynamic product creation in `beforeAll` — use stable product IDs from MEMORY.md
- Tests run against dev Firebase only — emulators forbidden (8GB RAM)
- `DELIVERED` status = admin-only — sign in as admin for that transition
