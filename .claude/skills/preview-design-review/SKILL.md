---
name: preview-design-review
description: "Capture Flutter widget preview screenshots and send to Gemini for design feedback. Produces graded UI improvement tasks. Integrates with harness-loop Evaluator."
---

# Preview Design Review

Automated design review pipeline: capture screenshots of Flutter screens, send to Gemini for expert UI/UX feedback, produce prioritized improvement tasks.

## When to Use

- After building or modifying UI screens
- As part of `harness-loop` Evaluator phase (design grading)
- Before releases to catch visual regressions
- When you want a second opinion on design quality
- NOT for: backend-only changes, test-only changes

## Prerequisites

One of these must be running (never both — 8GB RAM):
- **Full app** via `flutter run` (preferred — shows real screens with data)
- **Preview server** via `./start-preview.sh` (shows individual widgets in device frames)

## Design System Reference

These values are the ground truth for grading:

| Token | Value | Usage |
|-------|-------|-------|
| `DesignTokens.primary` | `#667EEA` | Primary actions, links, active states |
| `DesignTokens.secondary` | `#764BA2` | Secondary accents, gradients |
| `DesignTokens.darkBackground` | `#0F0F1E` | Page backgrounds |
| `DesignTokens.darkCard` | `#1E1E32` | Card/surface backgrounds |
| Spacing grid | 8pt increments | All padding, margins, gaps |
| Border radius | 8/12/16/20/24/32px | Component corners |
| Min touch target | 48x48dp | All interactive elements |
| Text contrast | >= 4.5:1 on dark | WCAG AA compliance |

## Workflow

### Step 1: Identify Target Screens

Choose screens to review. Priority order:

**Tier 1 — Revenue critical:**
- `home_screen.dart` — first impression
- `productdetails_screen.dart` — purchase decision
- `cart_screen.dart` — conversion funnel
- `checkout_screen.dart` — payment flow

**Tier 2 — User journey:**
- `login_screen.dart`, `register_screen.dart` — onboarding
- `profile_screen.dart` — user identity
- `orders_screen.dart` — post-purchase

**Tier 3 — Seller/Admin:**
- `admin_panel_screen.dart` — admin dashboard
- `seller_orders_screen.dart` — seller management
- `addproduct_screen.dart`, `editproduct_screen.dart` — product CRUD

### Step 2: Capture Screenshots

**Mode A — Flutter Pilot MCP** (full app running):

```
1. flutter_connect — connect to running app
2. flutter_get_navigation — find current route
3. Navigate to target screen (flutter_tap on nav items)
4. flutter_screenshot — capture current screen
5. Save screenshot path
6. Repeat for each target screen
```

**Mode B — Playwright MCP** (preview server running):

```
1. browser_navigate to http://localhost:<preview-port>
2. Find preview for target widget
3. browser_take_screenshot — capture preview
4. Save screenshot path
5. Repeat for each target widget
```

**Mode C — Static analysis only** (nothing running):

Skip screenshots. Grade based on code-only analysis:
- Grep for hardcoded colors (`Colors.`, `Color(0x`, hex literals)
- Grep for missing Semantics labels on interactive widgets
- Check DesignTokens usage patterns
- Review responsive breakpoint handling

### Step 3: Send to Gemini for Design Feedback

Use `delegate gemini` with screenshots and this prompt template:

```
You are a senior UI/UX designer reviewing a Flutter e-commerce app (dark theme, Canada marketplace).

Design System:
- Primary: #667EEA (indigo-blue gradient)
- Secondary: #764BA2 (purple)
- Dark background: #0F0F1E
- Card surface: #1E1E32
- 8pt spacing grid
- Border radius: 8-32px scale
- Min touch target: 48x48dp

For each screenshot, grade on these criteria:

1. DESIGN QUALITY (weight: 30%)
   Does the composition feel unified? Do colors, typography, layout combine into a coherent identity?
   Penalize: fragmented layouts, inconsistent spacing, competing focal points

2. ORIGINALITY (weight: 25%)
   Evidence of deliberate design choices vs AI-generated defaults?
   Penalize: purple gradients over white cards, stock component feel, generic "AI slop"

3. CRAFT (weight: 20%)
   Typography hierarchy, spacing consistency, color harmony, contrast ratios
   Penalize: broken alignment, inconsistent padding, poor contrast

4. FUNCTIONALITY (weight: 15%)
   Can users understand interface purpose and find primary actions?
   Penalize: unclear CTAs, hidden navigation, confusing flows

5. ACCESSIBILITY (weight: 10%)
   Touch targets >= 48dp, text contrast >= 4.5:1, semantic labels present
   Penalize: tiny tap targets, low contrast text, missing alt text

Output format for EACH screenshot:
- Screen: [name]
- Grade: A/B/C/D/F
- Scores: Design [X/10], Originality [X/10], Craft [X/10], Functionality [X/10], Accessibility [X/10]
- Weighted Score: [X/10]
- Top 3 Issues:
  1. [SEVERITY: HIGH/MED/LOW] Description — Fix: [specific action]
  2. ...
  3. ...
- What's Working Well: [1-2 things to keep]
```

If `delegate gemini` fails (rate limit, timeout), fall back to the `uiux-expert` agent for code-only review.

### Step 4: Collect and Format Results

Write `UI_IMPROVEMENTS.md` to the project root:

```markdown
# UI Design Review — [date]

## Summary
- Screens reviewed: [N]
- Average score: [X/10]
- Grade distribution: [N]A, [N]B, [N]C, [N]D, [N]F

## Findings by Priority

### HIGH (must fix before release)
- [ ] [screen_name.dart:line] — [issue] — Fix: [action]

### MEDIUM (should fix)
- [ ] [screen_name.dart:line] — [issue] — Fix: [action]

### LOW (nice to have)
- [ ] [screen_name.dart:line] — [issue] — Fix: [action]

## Per-Screen Reports

### [Screen Name]
Grade: [X] | Score: [X/10]
[Detailed feedback from Gemini]

## Design Strengths (keep these)
- [pattern that works well]
```

### Step 5: Integration with Harness Loop

When invoked as part of `harness-loop` Evaluator phase:
- Return the weighted average score as the "Visual Coherence" grade (1-10)
- Include top 3 HIGH issues in `EVAL.md` improvement list
- Skip writing `UI_IMPROVEMENTS.md` (feedback goes to EVAL.md instead)

## Example Invocation

```
User: /preview-design-review

→ Connects to running app via Flutter Pilot
→ Screenshots: home, product detail, cart, login (4 screens)
→ Sends to Gemini with design system reference
→ Gemini grades: Home B(7.2), ProductDetail A(8.5), Cart B(7.8), Login C(6.1)
→ UI_IMPROVEMENTS.md: 3 HIGH, 5 MEDIUM, 4 LOW findings
→ Average: 7.4/10 — "Good foundation, login screen needs work"
```

## Limitations

- Gemini cannot see runtime animations or transitions — only static screenshots
- Widget previews show individual components, not full user flows
- 8GB RAM: cannot run preview server + full app simultaneously
- `delegate gemini` uses browser automation — may be slow or rate-limited
- Design grading is subjective — use as input, not gospel
