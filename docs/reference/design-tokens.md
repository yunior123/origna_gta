# Design Tokens Reference

> **Single Source of Truth**: All visual constants live in `lib/utils/design_tokens.dart`. Never use `Colors.*`, hex literals, or `Theme.of(context).colorScheme` directly.

---

## Philosophy

Design tokens are **named entities that store visual design decisions**. They:

1. **Enable consistency** — Same color/spacing used everywhere
2. **Support theming** — Light/dark mode handled automatically
3. **Prevent errors** — Typos caught at compile time
4. **Speed development** — IDE autocomplete for all values
5. **Simplify updates** — Change in one file, propagate everywhere

---

## Color System

### Primary Palette

| Token | Value | Usage |
|-------|-------|-------|
| `DesignTokens.primary` | `#7B93FF` | Primary buttons, links, focus rings |
| `DesignTokens.secondary` | `#764BA2` | Secondary actions, badges |
| `DesignTokens.tertiary` | `#FF6B6B` | Accent highlights, notifications |
| `DesignTokens.accent` | `#5CE1E6` | Cyan accent, loading states |
| `DesignTokens.digital` | `#7C3AED` | Digital product badges |

```dart
// Usage
Container(
  color: DesignTokens.primary,  // ✅ Correct
  // color: Colors.blue,        // ❌ Wrong - use DesignTokens
  // color: Color(0xFF7B93FF),  // ❌ Wrong - no hex literals
)
```

### Gradients

| Token | Colors | Usage |
|-------|--------|-------|
| `primaryGradient` | `#7B93FF` → `#764BA2` | Primary CTA buttons, headers |
| `secondaryGradient` | `#764BA2` → `#7B93FF` | Secondary buttons |
| `premiumGradient` | `#FF6B6B` → `#7B93FF` | Premium/paywall UI |
| `backgroundGradient({isDark})` | Adaptive | Screen backgrounds |
| `surfaceGradient({isDark})` | Adaptive | Card surfaces |

```dart
// Usage
Container(
  decoration: BoxDecoration(
    gradient: DesignTokens.primaryGradient,
  ),
)

// Adaptive background
Container(
  decoration: BoxDecoration(
    gradient: DesignTokens.backgroundGradient(
      isDark: Theme.of(context).brightness == Brightness.dark,
    ),
  ),
)
```

### Semantic Colors

| Token | Value | WCAG | Usage |
|-------|-------|------|-------|
| `success` | `#10B981` | ✓ | Success messages, checkmarks |
| `warning` | `#F59E0B` | N/A | Warning backgrounds/icons (not text) |
| `warningText` | `#92400E` | ✓ 7:1 | Warning text (WCAG AA compliant) |
| `error` | `#EF4444` | ✓ | Error messages, destructive actions |
| `info` | `#3B82F6` | ✓ | Info messages, tooltips |

```dart
// Correct semantic usage
Text(
  'Warning: Stock low',
  style: TextStyle(color: DesignTokens.warningText),  // Text
)
Container(
  color: DesignTokens.warningSubtle,  // Background
  child: Icon(Icons.warning, color: DesignTokens.warningIcon),  // Icon
)
```

### Status Colors

| Token | Value | Usage |
|-------|-------|-------|
| `statusShipped` | `#06B6D4` | Shipped order status |
| `statusInTransit` | `#14B8A6` | In-transit status |
| `canadaRed` | `#D80027` | Canada-only badge |

### Dark Mode Colors

| Token | Value | Usage |
|-------|-------|-------|
| `darkBackground` | `#0F0F1E` | Main dark background |
| `darkSurface` | `#1A1A2E` | Dark surface/cards |
| `darkSurfaceVariant` | `#16213E` | Elevated dark surfaces |
| `darkCard` | `#1E1E32` | Dark card backgrounds |
| `darkOutline` | `#444B63` | Dark borders/dividers |

### Text Colors

| Token | Value | WCAG | Usage |
|-------|-------|------|-------|
| `textPrimary` | `#1A1A2E` | ✓ 16:1 | Primary text (light theme) |
| `textSecondary` | `#6B7280` | ✓ 5.3:1 | Secondary/muted text |
| `textTertiary` | `#6B7280` | ✓ 5.3:1 | Tertiary text, captions |
| `textDisabled` | `#9CA3AF` | ⚠ 3.7:1 | Disabled state (decorative) |
| `textOnPrimary` | `white` | ✓ | Text on primary color |
| `textOnDark` | `white` | ✓ | Text on dark backgrounds |
| `textOnDarkSecondary` | `#BDBDBD` | ✓ | Secondary text on dark |

**WCAG Compliance**: All text colors meet ≥4.5:1 contrast ratio against their intended backgrounds, except `textDisabled` which is decorative only.

### Brand Colors

| Token | Value | Brand |
|-------|-------|-------|
| `stripeViolet` | `#635BFF` | Stripe brand |
| `stripeCyan` | `#00D4AA` | Stripe secondary |
| `paypalNavy` | `#003087` | PayPal brand |
| `paypalBlue` | `#009CDE` | PayPal secondary |
| `wiseGreen` | `#9FE870` | Wise brand |
| `wiseSky` | `#00B9FF` | Wise secondary |
| `googleBlue` | `#4285F4` | Google Sign-In |
| `googleRed` | `#EA4335` | Google Sign-In |
| `googleYellow` | `#FBBC05` | Google Sign-In |
| `googleGreen` | `#34A853` | Google Sign-In |

```dart
// Usage in Google Sign-In button
Row(
  children: [
    Container(
      color: DesignTokens.googleBlue,
      child: Icon(Icons.mail, color: Colors.white),
    ),
    Text('Sign in with Google'),
  ],
)
```

### Medal/Rank Colors

| Token | Value | Usage |
|-------|-------|-------|
| `goldPrimary` | `#FFD700` | Gold medal/badge |
| `goldDark` | `#FFA000` | Gold shadow/gradient |
| `silverPrimary` | `#B0BEC5` | Silver medal/badge |
| `silverDark` | `#78909C` | Silver shadow/gradient |
| `bronzePrimary` | `#CD7F32` | Bronze medal/badge |
| `bronzeDark` | `#8B4513` | Bronze shadow/gradient |

---

## Spacing System

Based on **4px base unit**. All spacing is a multiple of 4.

| Token | Value | Usage |
|-------|-------|-------|
| `spacing0` | 0px | No spacing |
| `spacing4` | 4px | Tight spacing (icon + text) |
| `spacing8` | 8px | Compact spacing (button padding) |
| `spacing12` | 12px | Small spacing (card internal) |
| `spacing16` | 16px | Default spacing (card padding) |
| `spacing20` | 20px | Medium spacing |
| `spacing24` | 24px | Section spacing |
| `spacing32` | 32px | Large spacing |
| `spacing40` | 40px | XL spacing |
| `spacing48` | 48px | XXL spacing |
| `spacing64` | 64px | Hero spacing |
| `spacing80` | 80px | Page section spacing |

```dart
// Usage
Padding(
  padding: const EdgeInsets.all(DesignTokens.spacing16),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: DesignTokens.spacing8),
      Text('Subtitle'),
    ],
  ),
)
```

### Spacing Guidelines

| Context | Recommended Token |
|---------|-------------------|
| Icon-to-text gap | `spacing4` - `spacing8` |
| Button padding | `spacing8` - `spacing12` |
| Card padding | `spacing16` |
| Section header-to-content | `spacing12` - `spacing16` |
| Between sections | `spacing24` - `spacing32` |
| Screen edge padding | `spacing16` - `spacing24` |
| Bottom sheet padding | `spacing16` - `spacing24` |

---

## Typography

### Font Family

| Token | Value | Usage |
|-------|-------|-------|
| `fontFamily` | `'Inter'` | Primary font (all text) |

### Font Sizes

| Token | Value | Usage |
|-------|-------|-------|
| `fontSizeXs` | 11px | Captions, labels, badges |
| `fontSizeSm` | 13px | Secondary text, buttons |
| `fontSizeMd` | 15px | Body text, inputs |
| `fontSizeLg` | 18px | Subheadings, emphasis |
| `fontSizeXl` | 22px | Headings, titles |
| `fontSizeDisplay` | 28px | Large headings, hero |

```dart
// Usage
Text(
  'Product Title',
  style: TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeLg,
    fontWeight: FontWeight.w600,
    color: DesignTokens.textPrimary,
  ),
)
```

### Typography Guidelines

| Context | Size | Weight |
|---------|------|--------|
| App bar title | `fontSizeLg` | `w600` |
| Card title | `fontSizeMd` | `w500` |
| Card body | `fontSizeSm` | `w400` |
| Button text | `fontSizeSm` | `w600` |
| Input label | `fontSizeSm` | `w500` |
| Input text | `fontSizeMd` | `w400` |
| Error message | `fontSizeSm` | `w400` |
| Badge text | `fontSizeXs` | `w600` |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius8` | 8px | Small buttons, chips |
| `radius12` | 12px | Medium buttons, inputs |
| `radius16` | 16px | Cards, modals |
| `radius20` | 20px | Large cards |
| `radius24` | 24px | XL cards, bottom sheets |
| `radius32` | 32px | Hero cards, fullscreen |

```dart
// Usage
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DesignTokens.radius12),
  ),
)

// Or use BorderRadius directly
BorderRadius.circular(DesignTokens.radius16)
```

### Radius Guidelines

| Context | Recommended Radius |
|---------|-------------------|
| Buttons | `radius8` - `radius12` |
| Text fields | `radius12` |
| Cards | `radius12` - `radius16` |
| Modals/dialogs | `radius16` - `radius24` |
| Bottom sheets | `radius24` (top corners only) |
| Chips | `radius8` |
| Badges | `radius8` |

---

## Elevation & Shadows

| Token | Blur | Offset | Usage |
|-------|------|--------|-------|
| `shadowSm` | 2px | 0, 1px | Subtle lift (chips, badges) |
| `shadowMd` | 4px | 0, 2px | Cards, buttons |
| `shadowLg` | 12px | 0, 4px | Modals, dropdowns |
| `shadowXl` | 20px | 0, 8px | Hero elements, dialogs |

```dart
// Usage
Container(
  decoration: BoxDecoration(
    boxShadow: DesignTokens.shadowMd,
  ),
)

// Apply multiple shadows
Container(
  decoration: BoxDecoration(
    boxShadow: [
      ...DesignTokens.shadowSm,
      BoxShadow(
        color: DesignTokens.primary.withValues(alpha: 0.1),
        blurRadius: 8,
      ),
    ],
  ),
)
```

---

## Glassmorphism

| Token | Value | Usage |
|-------|-------|-------|
| `glassOpacity` | 0.8 | Background opacity |
| `gloopBlur` | 15px | Backdrop blur |

### GlassContainer Widget

```dart
// Pre-built glassmorphism container
GlassContainer(
  child: Text('Frosted glass content'),
)

// Custom parameters
GlassContainer(
  blur: 20,  // Custom blur
  opacity: 0.7,  // Custom opacity
  borderRadius: BorderRadius.circular(DesignTokens.radius24),
  padding: const EdgeInsets.all(DesignTokens.spacing24),
  shadows: DesignTokens.shadowLg,
  child: YourContent(),
)
```

**When to use:**
- Overlaying content on images/gradients
- Modal backgrounds
- Floating action buttons
- Premium UI elements

---

## Animation

### Durations

| Token | Value | Usage |
|-------|-------|-------|
| `durationFast` | 150ms | Hover, tap feedback |
| `durationNormal` | 300ms | Page transitions, modals |
| `durationSlow` | 600ms | Hero animations, complex transitions |

### Curves

| Token | Value | Usage |
|-------|-------|-------|
| `easeOutCubic` | `Cubic(0.33, 1, 0.68, 1)` | Elements entering |
| `easeInOutCubic` | `Cubic(0.65, 0, 0.35, 1)` | Elements moving |

```dart
// Usage
AnimatedContainer(
  duration: DesignTokens.durationNormal,
  curve: DesignTokens.easeOutCubic,
  child: YourWidget(),
)
```

---

## Hot/Trending Badge Colors

| Token | Value | Usage |
|-------|-------|-------|
| `hotStart` | `#FF6B35` | Hot badge gradient start |
| `hotEnd` | `#FF3D00` | Hot badge gradient end |
| `trendingStart` | `#00BFA5` | Trending badge gradient start |
| `trendingEnd` | `#1DE9B6` | Trending badge gradient end |

```dart
// Usage in trending badge
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [DesignTokens.trendingStart, DesignTokens.trendingEnd],
    ),
  ),
  child: Text('TRENDING'),
)
```

---

## Complete Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final int priceCents;
  final String imageUrl;
  final bool isNew;

  const ProductCard({
    super.key,
    required this.title,
    required this.priceCents,
    required this.imageUrl,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: DesignTokens.shadowMd,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with NEW badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                child: Image.network(imageUrl),
              ),
              if (isNew)
                Positioned(
                  top: DesignTokens.spacing8,
                  left: DesignTokens.spacing8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacing8,
                      vertical: DesignTokens.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary,
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: DesignTokens.textOnPrimary,
                        fontSize: DesignTokens.fontSizeXs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacing12),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: DesignTokens.spacing8),
          
          // Price
          Text(
            '\$${(priceCents / 100).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: DesignTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Common Mistakes to Avoid

### ❌ Using Colors directly

```dart
// Wrong
Container(color: Colors.blue)
Container(color: Color(0xFF7B93FF))
Container(color: Theme.of(context).colorScheme.primary)
```

### ✅ Using DesignTokens

```dart
// Correct
Container(color: DesignTokens.primary)
```

---

### ❌ Hardcoded spacing

```dart
// Wrong
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 8)
```

### ✅ Using spacing tokens

```dart
// Correct
Padding(padding: EdgeInsets.all(DesignTokens.spacing16))
SizedBox(height: DesignTokens.spacing8)
```

---

### ❌ Hardcoded radius

```dart
// Wrong
BorderRadius.circular(12)
```

### ✅ Using radius tokens

```dart
// Correct
BorderRadius.circular(DesignTokens.radius12)
```

---

### ❌ Hardcoded font sizes

```dart
// Wrong
TextStyle(fontSize: 15)
```

### ✅ Using font size tokens

```dart
// Correct
TextStyle(fontSize: DesignTokens.fontSizeMd)
```

---

## Quick Reference Table

| Property | Token Pattern | Example |
|----------|---------------|---------|
| Color | `DesignTokens.<name>` | `DesignTokens.primary` |
| Spacing | `DesignTokens.spacing<value>` | `DesignTokens.spacing16` |
| Font size | `DesignTokens.fontSize<size>` | `DesignTokens.fontSizeMd` |
| Radius | `DesignTokens.radius<value>` | `DesignTokens.radius12` |
| Shadow | `DesignTokens.shadow<size>` | `DesignTokens.shadowMd` |
| Duration | `DesignTokens.duration<speed>` | `DesignTokens.durationNormal` |
| Curve | `DesignTokens.<curveName>` | `DesignTokens.easeOutCubic` |

---

*Last updated: 2026-03-25 | Source: `lib/utils/design_tokens.dart`*
