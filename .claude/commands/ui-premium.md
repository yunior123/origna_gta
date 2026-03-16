# /ui-premium — Premium UI/UX Workflow

**Usage**: `/ui-premium [screen|all]`

## Design Philosophy
Target aesthetic: Linear + Vercel + Stripe — dark, precise, fast, confident.
Every pixel earns its place. No decorative clutter. Motion is purposeful.

## DesignTokens Reference
```dart
// Gradients (primary identity)
primary: Color(0xFF667EEA)
secondary: Color(0xFF764BA2)
gradient: LinearGradient([#667EEA, #764BA2])

// Backgrounds
darkBg: Color(0xFF0F0F1E)      // page background
darkCard: Color(0xFF1E1E32)    // card/surface
darkBorder: Color(0xFF2A2A45)  // subtle borders

// Text
textPrimary: Colors.white
textSecondary: Color(0xFFB4B4C8)
textMuted: Color(0xFF6B6B8A)

// Status
success: Color(0xFF4CAF50)
error: Color(0xFFEF5350)
warning: Color(0xFFFF9800)
```

## Premium Patterns

### Cards
```dart
Container(
  decoration: BoxDecoration(
    color: DesignTokens.darkCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: DesignTokens.darkBorder, width: 1),
    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
  ),
)
```

### Buttons
- Primary: gradient background `[#667EEA, #764BA2]`, white text, rounded 12px
- Secondary: transparent, gradient border, gradient text
- Danger: `Color(0xFFEF5350)` background
- Loading state: `SizedBox(16, 16, CircularProgressIndicator(strokeWidth: 2))`

### Animations
- Page transitions: `FadeTransition` + slight `SlideTransition` (300ms, ease-out)
- List items: staggered fade-in (50ms offset per item)
- Button press: scale down to 0.96, spring back (150ms)
- Loading shimmer: `shimmer` package, dark theme colors

### Typography
- Headings: `FontWeight.w700`, letter-spacing: -0.5
- Body: `FontWeight.w400`, line-height: 1.5
- Labels: `FontWeight.w500`, uppercase, letter-spacing: 1.2
- Numbers/prices: monospace variant, `FontWeight.w600`

### Spacing System
- 4px base unit: 4, 8, 12, 16, 24, 32, 48, 64
- Card padding: 16px
- Screen horizontal padding: 20px (mobile), 24px (tablet), 32px (desktop)
- Section spacing: 32px

## Screen Audit Checklist
For each screen:
- [ ] Background uses `DesignTokens.darkBg`
- [ ] Cards use `DesignTokens.darkCard` + border + shadow
- [ ] All buttons are `ModernButton` (no raw `ElevatedButton`)
- [ ] All text fields are `ModernTextField` (no raw `TextField`)
- [ ] Loading states use `ModernLoadingIndicator` or shimmer
- [ ] Empty states have illustration + helpful message
- [ ] Error states have icon + message + retry button
- [ ] Responsive: correct layout at mobile/tablet/desktop breakpoints
- [ ] Smooth animations on route transitions
- [ ] No overflow on any screen size

## Priority Screens to Upgrade
1. **Home** — hero section, category chips, product grid
2. **Product Details** — image gallery, pricing, CTA buttons
3. **Cart** — line items, totals, checkout CTA
4. **Checkout** — address, payment, order summary
5. **Profile** — avatar, stats, settings sections
6. **Seller Dashboard** — metrics cards, product list

## Reference Apps (study these)
- Linear (linear.app) — dark, precise, keyboard-first
- Vercel Dashboard — clean data presentation
- Stripe Dashboard — numbers + charts done right
- Shopify Mobile — e-commerce patterns
- Raycast — command palette, quick actions

## Stitch MCP Integration
Use `mcp__stitch__generate_screen_from_text` for rapid prototyping:
```
Generate: "Dark e-commerce product card with gradient price badge,
           seller rating, and add-to-cart button. Colors: #0F0F1E bg,
           #1E1E32 card, #667EEA primary"
```
Credits: 15 edit_screens/day — use wisely.
