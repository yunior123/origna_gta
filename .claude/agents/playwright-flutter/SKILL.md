---
name: playwright-flutter
description: Essential guidelines and workflows for testing Flutter Web apps using Playwright. Use when modifying or running Playwright E2E tests for the Flutter Web project.
---

# Playwright for Flutter Web — Complete Testing Guide

## Core Architecture

Flutter Web (CanvasKit/Skwasm) renders to `<canvas>` — Playwright **cannot** read the DOM inside canvas.

**Solution:** Flutter exposes a parallel accessibility DOM tree (`<flt-semantics>`) when semantics are enabled. Playwright interacts with ARIA attributes on these elements.

**How to enable semantics:**
- **Build flag**: `--dart-define=FORCE_SEMANTICS=true` (always set in dev/staging builds)
- **Runtime**: Press `S` key in Flutter debug mode, or call `SemanticsBinding.instance.ensureSemantics()`
- **Production**: Semantics enabled by default via `flutter build web --dart-define=FORCE_SEMANTICS=true`

---

## Semantic Label Conventions

**Mandatory format:** `kebab-case`, descriptive, unique per screen context.

| Prefix | Widget type | Example |
|--------|-------------|---------|
| `btn-` | Buttons, IconButtons, GestureDetectors | `btn-login`, `btn-add-to-cart` |
| `input-` | TextFields, search bars | `input-email`, `input-search` |
| `chk-` | Checkboxes, switches | `chk-remember-me` |
| `chip-` | FilterChip, ChoiceChip | `chip-category-electronics` |
| `link-` | InkWell links, TextButton links | `link-forgot-password` |
| `nav-` | BottomNavigationBar items | `nav-home`, `nav-cart`, `nav-profile` |
| `menu-` | Drawer/popup menu items | `menu-settings`, `menu-logout` |
| `tab-` | TabBar items | `tab-all-orders`, `tab-active` |
| `product-card-` | Product cards (append ID) | `product-card-abc123` |
| `order-card-` | Order cards (append ID) | `order-card-xyz789` |
| `img-` | Images with semantic meaning | `img-product-main` |
| `text-` | Important text labels | `text-total-price`, `text-order-status` |
| `section-` | Scroll sections / list headers | `section-recently-viewed` |
| `dialog-` | Dialog containers | `dialog-confirm-delete` |
| `sheet-` | Bottom sheet containers | `sheet-delivery-options` |

### Flutter Dart — How to Add Semantics

```dart
// Option 1: Semantics wrapper
Semantics(
  label: 'btn-add-to-cart',
  button: true,
  child: ElevatedButton(onPressed: onAddToCart, child: Text('Add to Cart')),
)

// Option 2: semanticsLabel property (for Image, Icon)
Icon(Icons.search, semanticsLabel: 'btn-search')

// Option 3: Tooltip as semantics label
IconButton(
  tooltip: 'btn-share-product',  // tooltip = semantics label for IconButton
  icon: Icon(Icons.share),
  onPressed: onShare,
)

// Option 4: ExcludeSemantics for decorative elements
ExcludeSemantics(child: Icon(Icons.star, color: Colors.yellow))
```

---

## Test Setup

### Config file
```typescript
// e2e/playwright.config.dev.ts
export default defineConfig({
  testDir: './tests',
  workers: 2,                    // 8GB RAM — never more than 2 workers
  fullyParallel: false,          // sequential on low-RAM machines
  timeout: 120_000,
  use: {
    baseURL: 'https://dev.orignagta.ca',
    headless: true,
    viewport: { width: 1280, height: 800 },
  },
});
```

### Flutter Helpers (`e2e/flutter-helpers.ts`)
```typescript
import { Page, Locator } from '@playwright/test';

// Wait for Flutter semantics to load
export async function waitForFlutter(page: Page): Promise<void> {
  await page.waitForSelector('flt-glass-pane', { timeout: 30_000 });
  await page.waitForSelector('flt-semantics', { timeout: 30_000 });
  await page.waitForTimeout(1000); // extra stability
}

// Find by semantic label
export function flutterByLabel(page: Page, label: string): Locator {
  return page.locator(`[aria-label="${label}"]`);
}

// Find button
export function flutterButton(page: Page, label: string): Locator {
  return page.locator(`[aria-label="${label}"]`).first();
}

// Find input
export async function flutterFillInput(page: Page, label: string, value: string): Promise<void> {
  const input = page.locator(`[aria-label="${label}"]`);
  await input.click();
  await page.keyboard.type(value);
}

// Wait for semantic label to appear
export async function waitForSemanticLabel(page: Page, label: string, timeout = 15_000): Promise<void> {
  await page.waitForSelector(`[aria-label="${label}"]`, { timeout });
}
```

---

## Known Semantic Labels by Screen

### Auth Screens
| Label | Widget | Screen |
|-------|--------|--------|
| `input-email` | Email TextField | Login, Register |
| `input-password` | Password TextField | Login, Register |
| `input-display-name` | Name TextField | Register |
| `btn-login` | Login button | Login |
| `btn-register` | Register button | Register |
| `btn-google-signin` | Google Sign-In | Login |
| `link-forgot-password` | Forgot Password link | Login |
| `link-go-to-register` | Create account link | Login |
| `link-go-to-login` | Already have account | Register |
| `chk-terms-accepted` | Terms checkbox | Register |

### Navigation
| Label | Widget |
|-------|--------|
| `nav-home` | Home tab |
| `nav-search` | Search tab |
| `nav-cart` | Cart tab |
| `nav-orders` | Orders tab |
| `nav-profile` | Profile tab |

### Home Screen
| Label | Widget |
|-------|--------|
| `input-search` | Search bar |
| `btn-search-submit` | Search submit |
| `chip-category-<name>` | Category chips |
| `chip-sort-<option>` | Sort chips (relevance, price-asc, etc.) |
| `btn-price-filter` | Price range filter |
| `section-recently-viewed` | Recently viewed section |
| `product-card-<id>` | Product cards |

### Product Details Screen
| Label | Widget |
|-------|--------|
| `img-product-main` | Main product image |
| `btn-add-to-cart` | Add to cart |
| `btn-buy-now` | Buy now |
| `btn-favorite` | Favorite toggle |
| `btn-share` | Share button |
| `input-quantity` | Quantity selector |
| `tab-description` | Description tab |
| `tab-reviews` | Reviews tab |
| `tab-qa` | Q&A tab |
| `text-product-price` | Price display |
| `text-seller-name` | Seller name |

### Cart Screen
| Label | Widget |
|-------|--------|
| `btn-remove-item-<id>` | Remove cart item |
| `input-quantity-<id>` | Item quantity |
| `btn-checkout` | Proceed to checkout |
| `text-cart-total` | Total price |
| `text-free-shipping-progress` | Free shipping progress |

### Orders Screen
| Label | Widget |
|-------|--------|
| `tab-all-orders` | All orders tab |
| `tab-active-orders` | Active orders tab |
| `tab-delivered-orders` | Delivered tab |
| `tab-cancelled-orders` | Cancelled tab |
| `order-card-<id>` | Order card |
| `btn-reorder-<id>` | Buy again button |
| `btn-track-order-<id>` | Track order |

### Profile Screen
| Label | Widget |
|-------|--------|
| `menu-edit-profile` | Edit profile |
| `menu-addresses` | Manage addresses |
| `menu-seller-dashboard` | Seller dashboard |
| `menu-settings` | Settings |
| `menu-logout` | Logout |
| `btn-theme-light` | Light theme pill |
| `btn-theme-dark` | Dark theme pill |
| `btn-theme-system` | System theme pill |

---

## Test Patterns

### Standard Test Structure
```typescript
import { test, expect } from '@playwright/test';
import { waitForFlutter, flutterButton, flutterFillInput, waitForSemanticLabel } from '../flutter-helpers';

test.describe('Login Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
  });

  test('user can log in with email/password', async ({ page }) => {
    await flutterButton(page, 'btn-login').click();
    await flutterFillInput(page, 'input-email', 'yuniorrodriguezo460@gmail.com');
    await flutterFillInput(page, 'input-password', 'REDACTED_TEST_PASSWORD');
    await flutterButton(page, 'btn-login').click();
    await waitForSemanticLabel(page, 'nav-home');
  });
});
```

### Testing Search
```typescript
test('search returns products', async ({ page }) => {
  await page.goto('/');
  await waitForFlutter(page);
  const searchInput = page.locator('[aria-label="input-search"]');
  await searchInput.click();
  await page.keyboard.type('laptop');
  await page.waitForSelector('[aria-label^="product-card-"]', { timeout: 10_000 });
  const cards = page.locator('[aria-label^="product-card-"]');
  await expect(cards).toHaveCount(await cards.count());
  expect(await cards.count()).toBeGreaterThan(0);
});
```

### Testing Cart
```typescript
test('add product to cart', async ({ page }) => {
  // Navigate to a stable test product
  await page.goto('/#/product/e2e_product_test_seller');
  await waitForFlutter(page);
  await waitForSemanticLabel(page, 'btn-add-to-cart');
  await flutterButton(page, 'btn-add-to-cart').click();
  await waitForSemanticLabel(page, 'nav-cart');
  // Cart badge should update
});
```

---

## Debugging Failed Tests

### Element not found
1. Check if `Semantics(label: 'btn-xyz')` was added to the Flutter widget
2. Verify build was done with `--dart-define=FORCE_SEMANTICS=true`
3. Run `await page.content()` to see the HTML tree
4. Check for timing issues — add `waitForSemanticLabel()` before interacting

### Tests pass locally, fail in CI
- CI uses headless Chrome — ensure no hover-dependent interactions
- CI workers: 1 (RAM constraint) — never `fullyParallel: true` in CI
- Ensure `--dart-define=FORCE_SEMANTICS=true` is set in deploy script

### RAM Management (8GB Mac)
- Never run Flutter build + Playwright simultaneously
- Close Chrome between test suites: `await browser.close()`
- Use `pkill -f "Google Chrome"` if zombie instances remain
- Run: `npx playwright test --workers=1`

---

## Running Tests

```bash
# Run all E2E tests against dev
cd e2e
npx playwright test --config=playwright.config.dev.ts

# Run single test file
npx playwright test tests/auth.spec.ts

# Run with UI (headed mode)
npx playwright test --headed

# Run with trace for debugging
npx playwright test --trace=on

# View trace
npx playwright show-trace trace.zip
```

---

## Coverage Target: 90%+

Required test coverage by area:
- Auth (login, register, Google, password reset): ✓
- Home/Search (search, filters, sort, categories): ✓
- Product Details (view, add to cart, favorite, reviews): ✓
- Cart (add, remove, quantity, checkout): ✓
- Orders (list, filter, track, reorder): ✓
- Profile (view, edit, addresses, logout): ✓
- Seller Dashboard (products, orders, payouts): ✓
- Admin Panel (user/product moderation): ✓
- Payment Flow (Stripe checkout): ✓
- Return Requests: ✓
