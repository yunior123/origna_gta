# /add-semantics — Add Playwright Semantics to Flutter Screens

**Usage**: `/add-semantics [screen_name|all]`

## Why Semantics
Flutter renders to a Canvas — Playwright sees nothing by default. The `FORCE_SEMANTICS=true`
dart-define flag enables `SemanticsDebugger` that surfaces semantic trees as DOM elements
(`flt-semantics` nodes). Every interactive element needs a `Semantics` wrapper.

## Semantic Label Conventions (ALWAYS follow)
| Element Type | Prefix | Example |
|---|---|---|
| Buttons | `btn-` | `btn-add-to-cart`, `btn-checkout` |
| Text inputs | `input-` | `input-email`, `input-search` |
| Navigation items | `nav-` | `nav-home`, `nav-cart` |
| Product cards | `product-card-{id}` | `product-card-abc123` |
| Screen containers | `screen-` | `screen-home`, `screen-login` |
| Images | `img-` | `img-product-hero` |
| Dropdowns/selects | `select-` | `select-category` |
| Checkboxes | `checkbox-` | `checkbox-remember-me` |
| List items | `list-item-{id}` | `list-item-order-xyz` |
| Dialogs | `dialog-` | `dialog-confirm-delete` |
| Error messages | `error-` | `error-email-invalid` |

## How to Add Semantics (Dart)
```dart
// Button
Semantics(
  label: 'btn-add-to-cart',
  button: true,
  child: ModernButton(onPressed: ..., label: 'Add to Cart'),
)

// Text field (use existing ModernTextField — it has a semanticsLabel param)
ModernTextField(
  semanticsLabel: 'input-email',
  controller: emailController,
  ...
)

// Product card
Semantics(
  label: 'product-card-${product.id}',
  button: true,
  child: ProductCard(product: product),
)

// Navigation item
Semantics(
  label: 'nav-home',
  selected: currentIndex == 0,
  child: BottomNavigationBarItem(icon: ...),
)

// Screen container (top-level Scaffold)
Semantics(
  label: 'screen-home',
  child: Scaffold(...),
)
```

## Screen-by-Screen Checklist
For each screen, run:
1. Add `screen-*` to Scaffold
2. Add `btn-*` to every tappable element
3. Add `input-*` to every text field (via `semanticsLabel` param)
4. Add `product-card-{id}` to every product card
5. Add `nav-*` to bottom nav + drawer items

### Priority Screens (do these first)
- [ ] `login_screen.dart` — `screen-login`, `btn-login`, `btn-google-signin`, `input-email`, `input-password`
- [ ] `home_screen.dart` — `screen-home`, `input-search`, `btn-filter`, `product-card-{id}`, `nav-*`
- [ ] `product_details_screen.dart` — `screen-product-details`, `btn-add-to-cart`, `btn-favorite`, `img-product-hero`
- [ ] `cart_screen.dart` — `screen-cart`, `btn-checkout`, `btn-remove-item-{id}`, `btn-qty-plus-{id}`, `btn-qty-minus-{id}`
- [ ] `checkout_screen.dart` — `screen-checkout`, `btn-place-order`, `select-address`, `select-payment`
- [ ] `orders_screen.dart` — `screen-orders`, `list-item-order-{id}`, `btn-reorder`
- [ ] `profile_screen.dart` — `screen-profile`, `btn-edit-profile`, `btn-logout`
- [ ] `auth screens` — `screen-register`, `input-name`, `input-email`, `input-password`, `btn-register`
- [ ] `seller screens` — `screen-seller-dashboard`, `btn-add-product`

## Build with Semantics
```bash
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/dev/current/
```

## Verify in Playwright
```typescript
// After semantics added, element should be findable:
await page.getByRole('button', { name: 'btn-add-to-cart' }).click();
await page.locator('[aria-label="product-card-abc123"]').click();
await page.locator('flt-semantics[aria-label="screen-home"]').waitFor();
```

## Auto-Generate Semantics (Gemini approach)
```bash
# Scan a screen file and get Semantics suggestions
cat lib/screens/home_screen.dart | delegate gemini \
  "List every button, input, nav item, and list item in this Flutter file.
   For each, output the Dart Semantics wrapper code using these prefixes:
   btn-, input-, nav-, product-card-, screen-, img-, select-.
   Output only code snippets with line numbers where to insert them."
```

## Documentation
After adding semantics to each screen, update:
- `e2e/SEMANTICS.md` — full label inventory per screen
- `e2e/INSTRUCTIONS.md` — how to run Playwright tests

## On Failure
- If `flt-semantics` not appearing → check `FORCE_SEMANTICS=true` was passed at build time
- If label not found in test → check spelling, check it wasn't wrapped in an ExcludeSemantics parent
- Never use `ExcludeSemantics` on interactive elements
