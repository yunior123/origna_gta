---
name: ai-e2e-testing
description: |
  AI-powered E2E testing for OrignaGTA. Uses agent-browser CLI to navigate the app,
  capture screenshots, analyze accessibility trees, evaluate UI/UX quality, and test
  user flows — all autonomously. The AI agent IS the tester. Use when asked to
  "run AI tests", "ai ux review", "ai accessibility audit", "ai e2e", or "ai test the app".
allowed-tools:
  - Bash
  - Read
  - Write
  - WebFetch
---

# AI E2E Testing — OrignaGTA

## Concept

The AI agent acts as an autonomous tester. Instead of pre-coded test scripts, the agent:
1. Navigates the app using `agent-browser` CLI
2. Captures screenshots and accessibility snapshots
3. Analyzes UI/UX quality, accessibility, and user flows **in-context**
4. Produces structured Markdown reports

No external API calls needed — the agent's own reasoning IS the analysis.

## Prerequisites

```bash
# agent-browser must be installed globally
npm install -g agent-browser
agent-browser install  # first time only
```

## Target

- **URL:** `https://dev.orignagta.ca` (override: `E2E_TARGET_URL` env)
- **App:** Flutter Web with accessibility semantics tree
- **Theme:** Dark (#0F0F1E bg, #7B93FF primary, #764BA2 secondary)
- **Languages:** EN/FR bilingual

## Test Accounts

```bash
export TEST_ADMIN="e2e-admin@test.origna.ca"
export TEST_SELLER="e2e-seller@test.origna.ca"
export TEST_BUYER="e2e-buyer@test.origna.ca"
export TEST_PASS="REDACTED_TEST_PASSWORD"
```

## Workflow

### Phase 1: Guest Screens (no auth)

For each guest screen, do ALL of:
1. `agent-browser open <url>`
2. Wait for Flutter: poll `agent-browser snapshot -i` until refs appear (max 15s)
3. Wait 5s for full render (Flutter shows loading screen first)
4. `agent-browser snapshot -i` — capture accessibility tree
5. `agent-browser screenshot /tmp/ai-<name>.png` — capture screenshot
6. **Analyze the snapshot** for:
   - Missing labels on interactive elements
   - Wrong ARIA roles
   - Missing bilingual (EN/FR) labels
   - Convention violations (missing `btn-*`, `input-*`, `nav-*`, `product-card-*`)
7. **Analyze the screenshot** for:
   - Layout alignment issues
   - Spacing inconsistencies
   - Color contrast problems
   - Typography hierarchy
   - Visual hierarchy
8. Write findings to report

**Guest screens:**
| Screen | URL | Description |
|--------|-----|-------------|
| Home | `/` | Product grid, search, categories, nav |
| Login dialog | Settings → Sign in | Login form overlay |

### Phase 2: Authenticated Screens

Login flow (use for ALL authenticated screens):
```bash
agent-browser open "$URL/"
# Wait for full render
sleep 5
# Click settings
agent-browser snapshot -i
agent-browser click @<settings-ref>
sleep 2
# Click sign in
agent-browser snapshot -i
agent-browser click @<sign-in-ref>
sleep 2
# Fill login form
agent-browser snapshot -i
agent-browser fill @<email-ref> "$EMAIL"
agent-browser fill @<pass-ref> "$PASS"
agent-browser click @<submit-ref>
sleep 3
```

**Authenticated screens:**
| Screen | Post-login action | Description |
|--------|------------------|-------------|
| Home (auth) | Already on home after login | Personalized grid, cart badge |
| Cart | Navigate to `/cart` | Items, quantities, checkout |
| Settings/Profile | Click settings after login | Orders, favorites, addresses |
| Seller home | Login as seller | Seller tools, add product |
| Admin home | Login as admin | Admin panel, user mgmt |

### Phase 3: User Flow Testing

Navigate multi-step flows, analyze at each step:
1. **Guest browse:** Home → Search → Scroll → Product click
2. **Login → Profile:** Login → Settings → Orders → Favorites
3. **Cart → Checkout:** Login → Cart → Checkout entry

At each step: take snapshot + screenshot, note the step, analyze friction.

### Phase 4: Visual Regression (optional)

```bash
# Save baselines
agent-browser screenshot /tmp/ai-baseline-<screen>.png

# Compare (on subsequent runs)
# Take current screenshot and visually compare with baseline
```

## Analysis Criteria

### Accessibility Audit
Check the snapshot text output for:
- [ ] All `button` elements have non-empty labels
- [ ] All `textbox` elements have labels (not just placeholders)
- [ ] Navigation elements use `nav-*` convention
- [ ] Product cards use `product-card-<id>` convention
- [ ] Interactive elements have `btn-*` or `input-*` prefixes
- [ ] Bilingual labels present (EN/FR)
- [ ] No duplicate/ambiguous labels
- [ ] Password fields don't expose bullet chars as labels

### UI/UX Review
Check the screenshot for:
- [ ] Elements properly aligned (no overlap)
- [ ] Adequate spacing (padding, margins)
- [ ] Dark theme consistency (#0F0F1E bg, #7B93FF primary)
- [ ] Clear typography hierarchy
- [ ] Important actions prominent
- [ ] No horizontal scroll
- [ ] Empty states handled gracefully

### User Flow Feedback
For each flow, evaluate:
- [ ] Navigation clarity (obvious path between screens)
- [ ] Loading/error feedback visible
- [ ] Minimum steps to complete tasks
- [ ] Key features discoverable
- [ ] Error messages actionable

## Report Format

Save to `e2e/ai/reports/<timestamp>.md`:

```markdown
# AI E2E Analysis — <date>

## Summary
| Screen | A11y | UI/UX | Issues |
|--------|------|-------|--------|
| home | 8/10 | 7/10 | 3W |
| login | 4/10 | 8/10 | 2C 1W |

## Critical Issues
- [a11y] Empty label on login submit button
- [a11y] Password field exposes bullet chars as label

## Per-Screen Details
### Home
**A11y Score:** 8/10
**UI/UX Score:** 7/10
**Issues:**
- ⚠ [spacing] Category chips too close together
- 💡 Add product-card-* containers

### Login
...
```

## Quick Commands

```bash
# Run full AI analysis (invoke skill)
# Just say: "Run AI E2E tests" or "AI UX review the app"

# Run from e2e directory
cd e2e

# Quick smoke check
agent-browser open https://dev.orignagta.ca
agent-browser snapshot -i
agent-browser screenshot /tmp/ai-smoke.png
agent-browser close
```

## Notes

- Flutter Web needs ~5s to fully render after `waitForFlutter` returns
- Login is a DIALOG triggered from settings menu, NOT a `/login` route
- Settings button: `btn-home-settings`
- Sign in button: `Se connecter` / `Sign in` (bilingual)
- Login email field: `login_email_field` or `vous@exemple`
- Login password field: `login_password_field` or `••••••••`
- Login submit: `login_submit_button`
- After login, press Escape to close any remaining dialog overlay
- Each authenticated screen needs a fresh browser (Chrome session pollution)
- Kimi K2.5 and GLM-5 available via NVIDIA NIM if external analysis needed
