---
paths:
  - "**/test*"
  - "e2e/**"
  - "functions/tests/**"
  - "origna_gta/test/**"
  - "origna_gta/integration_test/**"
---

# Testing Rules

## Backend Tests (288 tests)
```bash
cd functions && source venv/bin/activate && pytest -v
pytest --cov=. --cov-report=html  # with coverage
```
- Fixtures in `conftest.py`
- Mock Firebase with fixtures, not monkeypatching
- Test every state transition, edge case, and error path

## E2E Tests (161+ tests)
```bash
cd e2e && npm test          # headless
cd e2e && npm run test:ui   # with browser UI
```
- **Requires emulators running** via `./start-dev.sh`
- Seed data: `cd e2e && npx ts-node mega-seed.ts`
- `product_002` can run out of stock — prefer `product_001` (25 stock) or `product_007` (60 stock)

## Integration Tests (Flutter)
```bash
cd origna_gta && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server --browser-name=chrome
```
- **Use pump loops (10×1s) NOT pumpAndSettle()** — persistent animations cause timeout
- **Only ONE testWidgets per file** — "Cannot set URL strategy a second time" error
- Entry: `main_test.dart` → `mainTest()` (skips URL strategy, always emulators)

## Widget Finders (Key-based)
- Login: `Key('login_email_field')`, `Key('login_password_field')`, `Key('login_submit_button')`
- Products: `Key('product_name_field')`, `Key('product_price_field')`, `Key('product_stock_field')`
- Cart: `find.byIcon(Icons.shopping_cart_outlined)`
- All buttons use `ModernButton` wrapping `InkWell` (NOT `ElevatedButton`)

## Test Philosophy
- Every code change must have corresponding test updates
- Logic failure tests (`logic-failures-e2e.spec.ts`) cover adversarial scenarios
- Regression tests (`regression-e2e.spec.ts`) prevent re-introduction of fixed bugs
