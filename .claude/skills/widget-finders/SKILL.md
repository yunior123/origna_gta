---
name: widget-finders
description: Key-based widget finders and selectors for Flutter integration tests. Use when writing or fixing integration tests.
---

# Widget Finders Reference (Integration Tests)

## Key-Based Finders
| Widget | Key | Type |
|--------|-----|------|
| Login Email | `login_email_field` | ModernTextField → TextFormField |
| Login Password | `login_password_field` | ModernTextField → TextFormField |
| Login Submit | `login_submit_button` | ModernButton → InkWell (NOT ElevatedButton) |
| Add Product | `home_add_product_button` | IconButton on AppBar |
| Product Name | `product_name_field` | _buildGlassTextField → TextFormField |
| Product Description | `product_description_field` | _buildGlassTextField |
| Product Price | `product_price_field` | _buildGlassTextField |
| Product Stock | `product_stock_field` | _buildGlassTextField |
| Publish Product | `find.text('Publish Product')` | InkWell |
| Cart Icon | `find.byIcon(Icons.shopping_cart_outlined)` | IconButton |
| Add to Cart | `find.text('Add to Cart')` | ModernButton → InkWell |
| Proceed to Checkout | `find.text('Proceed to Checkout')` | ModernButton |
| Place Order | `find.text('Place Order')` | ModernButton |

## Important Notes
- All buttons use `ModernButton` wrapping `InkWell`, NOT `ElevatedButton`
- Glass Toggle: `GestureDetector` > `AnimatedContainer` > `Switch.adaptive`
- Delivery Tier Card: Custom card with `Switch` + expandable children
- Use pump loops (10×1s) NOT `pumpAndSettle()`
- Only ONE `testWidgets` per file

## App Init for Tests
- Entry: `main_test.dart` → `mainTest()`
- Flow: `OrignaApp` → `AuthWrapper` (5s) → `MainScreen` (3s) → `HomeScreen`
