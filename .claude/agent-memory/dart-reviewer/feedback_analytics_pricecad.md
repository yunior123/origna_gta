---
name: analytics_pricecad_double
description: analytics service parameters use double priceCad intentionally — not a money-storage violation
type: feedback
---

`priceCad: double` in `AnalyticsService` / `FavoritesController.toggleFavorite` is an analytics-event parameter passed to GA4/logging. It is NOT stored as a monetary value and NOT used in business calculations. Do not flag as a money-float violation.

**Why:** Analytics SDKs accept floating-point currency values. The actual order/product money is always stored in integer cents fields (`priceCents`, `subtotalCents`, etc.).

**How to apply:** Only flag `double` for money when it appears in model fields, cart calculations, order totals, or Stripe calls — not in analytics event parameters.
