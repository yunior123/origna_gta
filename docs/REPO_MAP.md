# Repository Map — OrignaGta

> **Purpose:** Condensed index of every module, file, and its responsibility. Use this to navigate the codebase efficiently without reading every file.

---

## 🔧 Backend — `functions/`

### Entry Point
| File | Exports | Responsibility |
|------|---------|----------------|
| `main.py` | All Cloud Functions | Function registration, Stripe init, validation helpers |

### Handlers — `functions/handlers/` (57 Cloud Functions total)
| File | Key Functions | Responsibility |
|------|---------------|----------------|
| `payment_stripe.py` | `create_checkout_session`, `verify_cart_prices`, `stripe_webhook`, `capture_payment`, `create_connect_account`, `get_connect_account_status`, `create_account_link`, `process_charge_refunded`, `process_dispute_created`, `process_dispute_closed`, `process_dispute_updated`, `process_dispute_funds_reinstated` | Stripe payments: checkout, capture, webhooks, Connect onboarding, dispute handling |
| `payment_airwallex.py` | `airwallex_create_seller_account`, `airwallex_process_payment`, `airwallex_capture_payment`, `airwallex_webhook` | Alternative payment provider (gated, post-launch) |
| `payment_providers.py` | `get_payment_providers`, `update_payment_provider`, `get_provider_status` | Admin payment provider management (enable/disable) |
| `orders.py` | `confirm_order_receipt`, `update_order_status`, `update_item_status`, `refund_order_item`, `cancel_order`, `approve_shipping_cost`, `update_shipping_cost`, `on_order_status_changed` | Order state machine, item status, refunds, shipping approval. Note: orders are created in `create_checkout_session` |
| `products.py` | `upload_product_images`, `delete_product`, `submit_product_rating`, `configure_algolia`, `get_products_paginated`, `get_seller_products_paginated`, `get_product_ratings_paginated`, `on_product_created`, `on_product_updated`, `on_product_deleted` | Product management, Algolia sync triggers, image upload, ratings. Note: product create/update via Firestore triggers |
| `admin.py` | `update_user_roles`, `suspend_seller`, `unsuspend_seller`, `admin_update_product_stock`, `admin_mfa_enroll`, `admin_mfa_verify`, `admin_mfa_verify_backup`, `admin_mfa_disable`, `delete_account`, `export_my_data`, `unsubscribe_email` | Role management, seller suspension, MFA (4 endpoints), CASL/PIPEDA compliance (export, unsubscribe, delete) |
| `users.py` | `update_user_profile`, `get_user_profile`, `update_email_consent` | User profile CRUD, email consent management |
| `cron_jobs.py` | `auto_capture_confirmed_receipts`, `check_expired_authorizations`, `auto_archive_old_orders`, `monitor_algolia_sync`, `cleanup_stale_rate_limits`, `cleanup_orphaned_r2_images`, `cleanup_stale_webhook_events`, `cleanup_stale_security_alerts`, `retry_failed_algolia_syncs` | 9 scheduled cron jobs: payment capture, authorization expiry, archiving, Algolia monitoring, cleanup tasks |

### Models — `functions/models/`
| File | Classes | Fields of Note |
|------|---------|----------------|
| `base.py` | `OrderStatus`, `PaymentStatus`, enums | Shared enums and base types |
| `order.py` | `Order`, `OrderItem` (Pydantic) | `status`, `items[]`, `totalAmount`, `sellerId`, `buyerId` |
| `product.py` | `Product` (Pydantic) | `price`, `stock`, `sellerId`, `shippingConfig`, `isActive` |
| `user.py` | `User` (Pydantic) | `roles[]`, `stripeAccountId`, `emailVerified`, `suspended` |

### Services
| File | Responsibility |
|------|----------------|
| `schema_constants.py` | All Firestore field names, collection names, enum values (525 lines) |
| `shipping_service.py` | Shipping cost calculation: distance, province, tiers, weight surcharge. Exports `calculate_shipping_cost` Cloud Function |
| `email_service.py` | Mailjet email sending, all HTML templates (~733 lines) |
| `algolia_service.py` | Algolia index sync |
| `rate_limiter.py` | API rate limiting by IP/user |
| `utils.py` | Auth validation, error helpers |
| `config.py` | Environment config |

### Tests — `functions/tests/` (288 tests)
| File | Coverage Area |
|------|---------------|
| `test_critical_flow_scenarios.py` | End-to-end business flows |
| `test_handlers_payment_stripe.py` | Payment handler unit tests |
| `test_handlers_products_orders.py` | Product/order handler tests |
| `test_handlers_admin_cron.py` | Admin + cron job tests |
| `test_payment_security.py` | Payment security edge cases |
| `test_payment_integration.py` | Payment integration flows |
| `test_shipping_service_estimates.py` | Shipping calculation tests |
| `test_shipping_security.py` | Shipping manipulation tests |
| `test_schema_consistency.py` | Python↔JSON schema sync |
| `test_schema_contract.py` | Schema contract validation |
| `test_webhook_security.py` | Webhook HMAC verification |
| `test_edge_cases_advanced.py` | Advanced edge cases |
| `test_pydantic_models.py` | Model validation |
| `test_tax_audit.py` | Tax calculation |
| `test_algolia_indexing.py` | Algolia sync |
| `test_backend_integration.py` | Backend integration |

---

## 📱 Frontend — `origna_gta/lib/`

### Core — `lib/core/`
| File | Responsibility |
|------|----------------|
| `providers.dart` | Global Riverpod providers |
| `schema/schema_constants.dart` | Dart mirror of Python schema_constants (465 lines) |
| `repositories/auth_repository.dart` | Firebase Auth operations |
| `repositories/cart_repository.dart` | Cart Firestore CRUD |
| `repositories/order_repository.dart` | Order Firestore queries |
| `repositories/product_repository.dart` | Product Firestore CRUD |
| `repositories/user_repository.dart` | User profile operations |
| `repositories/location_repository.dart` | Geoapify location services |
| `repositories/algolia_product_repository.dart` | Algolia search queries |

### Features — `lib/features/` (MVVM ViewModels + State)
| Feature | Files | Responsibility |
|---------|-------|----------------|
| **auth** | `auth_provider.dart`, `login_viewmodel.dart`, `login_state.dart` | Authentication state, login/register logic |
| **cart** | `cart_provider.dart` | Cart management, add/remove/update items |
| **checkout** | `checkout_provider.dart` | Checkout orchestration: address, shipping, payment |
| **home** | `home_viewmodel.dart`, `home_state.dart` | Home screen: product listing, search, filters |
| **orders** | `buyer_orders_viewmodel.dart`, `seller_orders_viewmodel.dart`, `seller_orders_state.dart`, `orders_provider.dart`, `shipping_approval_viewmodel.dart` | Order management for buyers and sellers |
| **products** | `add_product_viewmodel.dart`, `edit_product_viewmodel.dart`, `product_detail_viewmodel.dart`, `product_actions_viewmodel.dart`, `product_rating_viewmodel.dart`, `products_provider.dart` + states | Product CRUD, rating, detail view |
| **seller** | `seller_registration_view_model.dart`, `seller_registration_state.dart` | Seller onboarding flow |
| **app** | `seller_account_status_viewmodel.dart` | Seller account status monitoring |
| **terms** | `terms_provider.dart` | Terms acceptance tracking |

### Screens — `lib/screens/` (28 screens)
| Screen | ViewModel/Provider | Backend Handler |
|--------|-------------------|-----------------|
| `login_screen.dart` | `login_viewmodel` | Firebase Auth (direct) |
| `home_screen.dart` | `home_viewmodel` | Algolia (direct search) |
| `productdetails_screen.dart` | `product_detail_viewmodel` | Firestore (direct read) |
| `addproduct_screen.dart` | `add_product_viewmodel` | Firestore write → `on_product_created` trigger |
| `editproduct_screen.dart` | `edit_product_viewmodel` | Firestore write → `on_product_updated` trigger |
| `cart_screen.dart` | `cart_provider` | — (local Firestore) |
| `checkout_screen.dart` | `checkout_provider` | `payment_stripe.create_checkout_session` |
| `orders_screen.dart` | `buyer_orders_viewmodel` | Firestore query (direct) |
| `seller_orders_screen.dart` | `seller_orders_viewmodel` | `orders.update_shipping_cost`, `orders.capture_payment` |
| `shipping_approval_screen.dart` | `shipping_approval_viewmodel` | `orders.approve_shipping_cost` |
| `ordersuccess_screen.dart` | — | — |
| `seller_registration_screen.dart` | `seller_registration_view_model` | `payment_stripe.create_connect_account` |
| `profile_screen.dart` | — | `users.get_user_profile` |
| `addressmanagement_screen.dart` | — | user_repository (Firestore) |
| `favorites_screen.dart` | — | product_repository (Firestore) |

### Models — `lib/models/`
| File | Classes | Note |
|------|---------|------|
| `generated/base_models.dart` | `Address`, `OrderStatus`, enums | Freezed — primary |
| `generated/order_models.dart` | `Order`, `OrderItem` | Freezed — primary |
| `generated/product_models.dart` | `Product`, `ShippingConfig` | Freezed — primary |
| `generated/user_models.dart` | `User`, `SellerProfile` | Freezed — primary |
| `models.dart` | Legacy: `UserModel`, `CartItemModel`, `ProductModel`, `OrderModel` | ⚠️ `Address` collision |
| `models_compat.dart` | Compatibility layer | Bridges legacy → generated |
| `enum_extensions.dart` | Enum helpers | String↔enum conversion |

### Services — `lib/services/`
| File | Responsibility |
|------|----------------|
| `algolia_service.dart` | Algolia client configuration |
| `analytics_service.dart` | Analytics tracking |
| `conf_services.dart` | Service configuration |
| `session_timeout_service.dart` | Session management |
| `splash_service.dart` | App splash/loading |

### Widgets — `lib/widgets/`
| File | Responsibility |
|------|----------------|
| `modern_button.dart` | Reusable button component |
| `modern_textfield.dart` | Reusable text input |
| `modern_card.dart` | Reusable card |
| `modern_appbar.dart` | App bar |
| `modern_product_card.dart` | Product card |
| `custom_app_bar.dart` | Custom app bar |
| `rating_dialog.dart` | Rating dialog |
| `animations.dart` | Shared animations |
| `legal_screen_body.dart` | Legal content display |

### Utils — `lib/utils/`
| File | Responsibility |
|------|----------------|
| `env_config.dart` | Environment singleton (emulator/production) |
| `design_tokens.dart` | Color tokens, gradients, theme |

---

## 🧪 E2E Tests — `e2e/` (161+ tests)

| File | Tests | Coverage |
|------|-------|----------|
| `fullstack-e2e.spec.ts` | 37 | Core marketplace flow |
| `payment-workflow-e2e.spec.ts` | 54 | Payment edge cases, multi-seller |
| `regression-e2e.spec.ts` | 38 | Regression (statuses, schema, formula) |
| `logic-failures-e2e.spec.ts` | 29 | Logic attack vectors (financial, state machine, permissions) |
| `admin-email-test.spec.ts` | 3 | Real email delivery |
| `mega-seed.ts` | — | Seed 75 users, 30 products, 20 carts |
| `seed-emulator.ts` | — | Seed 25 users, 16 products |

---

## 📜 Scripts — `scripts/`

| Script | Purpose |
|--------|---------|
| `deploy_with_validation.sh` | Full deploy with pre-checks |
| `deploy_rules.sh` | Deploy Firestore rules only |
| `validate_schema_consistency.sh` | Check Python↔Dart↔JSON schema sync |
| `generate_dart_models.sh` | Run build_runner for Freezed models |
| `run_all_tests.sh` | All test suites |
| `install_git_hooks.sh` | Install pre-push hooks |
| `start-emulators.sh` | Start Firebase emulators |

---

## 🔍 Audit System — `audit/`

| Directory | Contents |
|-----------|----------|
| `audit/runners/` | Domain audit scripts (Kimi/Qwen): `audit_payment.py`, `audit_orders.py`, etc. |
| `audit/prompts/` | Prompt templates for each audit domain |
| `audit/hooks/` | Claude-powered composable audit hooks with auto-fix |
| `audit/common.py` | Shared utilities: API calls, file bundling, report saving |
| `audit/collect_files.py` | Project file collector with extension/dir filters |
| `audit/doc_crawler.py` | External documentation crawler with disk cache |
| `audit/run_hooks.py` | CLI entrypoint for Claude audit hooks |

---

## 📄 Documentation — `docs/`

| File/Dir | Content |
|----------|---------|
| `database_schema.json` | Complete Firestore schema (1421 lines, v2.0.0) |
| `json_schemas/individual/*.json` | 18 individual collection schemas |
| `diagrams/*.puml` | 7 PlantUML diagrams (architecture, sequences, state) |
| `STRIPE_CONNECT_REFERENCE.md` | Stripe Connect integration guide |
| `SELLER_TERMS_AND_POLICIES.md` | Seller terms of service |
| `setup/*.md` | Setup guides (Algolia, Stripe, CI/CD, Airwallex) |
| `testing/*.md` | Testing documentation |
