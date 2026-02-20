# Airwallex — Archived Code

Removed from active codebase on 2026-02-20. Not using Airwallex at launch (Stripe only).
Keep in case Airwallex integration is needed post-launch.

## Contents

| File | Original Location |
|------|------------------|
| `airwallex_service.py` | `functions/services/airwallex_service.py` |
| `payment_airwallex.py` | `functions/handlers/payment_airwallex.py` |
| `test_airwallex_service.py` | `functions/tests/test_airwallex_service.py` |
| `AIRWALLEX_KYC_SETUP_CHECKLIST.md` | `docs/setup/AIRWALLEX_KYC_SETUP_CHECKLIST.md` |

## To Restore

1. Move files back to their original locations
2. Re-add Airwallex config to `functions/config.py` (SecretParams + getter functions)
3. Re-add Airwallex fields to `functions/schema_constants.py` (Fields class + PaymentProviderValues)
4. Re-add Airwallex fields to `functions/models/user.py` (airwallexAccountId, airwallexCustomerId, airwallexStatus)
5. Re-add Airwallex import + registrations to `functions/main.py`
6. Re-add Airwallex to `functions/handlers/payment_providers.py` (PaymentProvider class + DEFAULT_PROVIDER_CONFIG)
7. Re-add Airwallex fields to Dart schema_constants + user_models
8. Re-add Airwallex UI to seller_registration_screen.dart + admin_payment_providers_tab.dart
9. Re-add `send_3ds_authentication_email` to `functions/services/email_service.py`
