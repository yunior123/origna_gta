---
name: ai-e2e-testing
description: "AI-powered E2E testing for OrignaGTA. You are the autonomous tester — use agent-browser CLI to navigate the app, capture screenshots and accessibility snapshots, then analyze UI/UX quality, accessibility, user flows, and visual regressions with your own reasoning. No external AI APIs needed. Use when asked to 'run AI tests', 'ai ux review', 'ai accessibility audit', 'ai e2e', 'test the app visually', or 'ai test the app'."
---

# AI E2E Testing — OrignaGTA

You are an autonomous UI/UX tester. You use `agent-browser` CLI to interact with the live app, capture screenshots and accessibility snapshots, then analyze them with your own reasoning. No external API calls — your analysis IS the test.

## Prerequisites

```bash
npm install -g agent-browser
agent-browser install  # first time only
```

## Target

- **URL:** `https://dev.orignagta.ca` (override: `E2E_TARGET_URL` env)
- **App:** Flutter Web with accessibility semantics tree
- **Theme:** Dark (#0F0F1E bg, #7B93FF primary, #764BA2 secondary)
- **Languages:** EN/FR bilingual

## Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | e2e-admin@test.origna.ca | REDACTED_TEST_PASSWORD |
| Seller | e2e-seller@test.origna.ca | REDACTED_TEST_PASSWORD |
| Buyer | e2e-buyer@test.origna.ca | REDACTED_TEST_PASSWORD |

## Workflow

### Phase 1: Guest Screens (no auth)

For each guest screen, execute these steps:

1. Open the URL: `agent-browser open <url>`
2. Wait for Flutter to render:
   ```bash
   # Poll until refs appear (Flutter takes time)
   for i in {1..15}; do
     REFS=$(agent-browser snapshot -i 2>/dev/null)
     echo "$REFS" | grep -q "btn-" && break
     sleep 1
   done
   ```
3. Wait 5 more seconds for full render: `sleep 5`
4. Capture accessibility snapshot: `agent-browser snapshot -i > /tmp/snapshot-<screen>.txt`
5. Capture screenshot: `agent-browser screenshot /tmp/ai-<screen>.png`
6. **Analyze the snapshot text** for:
   - Missing labels on interactive elements
   - Wrong ARIA roles
   - Missing bilingual (EN/FR) labels
   - Convention violations (missing `btn-*`, `input-*`, `nav-*`, `product-card-*`)
7. **Analyze the screenshot image** (use Read tool on the PNG) for:
   - Layout alignment issues
   - Spacing inconsistencies
   - Color contrast problems
   - Typography hierarchy
   - Visual hierarchy
8. Write findings to report

**Guest screens to test:**
| Screen | URL | What to check |
|--------|-----|---------------|
| Home | `/` | Product grid, search, categories, nav, cart badge |
| Login dialog | Home → click `btn-home-settings` → click "Se connecter" | Form fields, validation, bilingual labels |

### Phase 2: Login Flow

Login is a DIALOG triggered from settings menu, NOT a `/login` route.

```bash
# 1. Open home and wait for full render
agent-browser open "https://dev.orignagta.ca"
sleep 5

# 2. Click settings button
agent-browser snapshot -i
# Find the ref for btn-home-settings
agent-browser click @<settings-ref>
sleep 2

# 3. Click sign in button
agent-browser snapshot -i
# Find the ref for "Se connecter" or "Sign in"
agent-browser click @<sign-in-ref>
sleep 2

# 4. Fill login form
agent-browser snapshot -i
# Find refs for login_email_field, login_password_field, login_submit_button
agent-browser fill @<email-ref> "e2e-admin@test.origna.ca"
agent-browser fill @<password-ref> "REDACTED_TEST_PASSWORD"
agent-browser click @<submit-ref>
sleep 3

# 5. Press Escape to close any remaining dialog
agent-browser press Escape
sleep 1
```

**IMPORTANT:** After login, press Escape to close any remaining dialog overlay.

### Phase 3: Authenticated Screens

For each authenticated screen, do a FRESH browser session (Chrome session pollution causes issues):

```bash
agent-browser close
agent-browser open "https://dev.orignagta.ca"
# ... login flow from Phase 2 ...
# ... navigate to screen ...
# ... snapshot + screenshot + analyze ...
```

**Authenticated screens:**
| Screen | Post-login action | What to check |
|--------|------------------|---------------|
| Home (auth) | Already on home | Personalized grid, cart badge, seller/admin tabs |
| Cart | Navigate to `/cart` | Items, quantities, checkout button |
| Settings/Profile | Click settings | Orders, favorites, addresses |
| Seller home | Login as seller | Seller tools, add product |
| Admin home | Login as admin | Admin panel, user management |

### Phase 4: User Flow Testing

Navigate multi-step flows, analyze at each step:
1. **Guest browse:** Home → Search → Scroll → Product click
2. **Login → Profile:** Login → Settings → Orders → Favorites
3. **Cart → Checkout:** Login → Cart → Checkout entry

At each step: take snapshot + screenshot, note the step, analyze friction and UX quality.

### Phase 5: Visual Regression (optional)

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
Check the screenshot image for:
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
```

## Quick Commands

```bash
# Quick smoke check
agent-browser open https://dev.orignagta.ca
sleep 5
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
- **Screenshot analysis:** Use the Read tool to load the PNG file, then analyze the image visually
