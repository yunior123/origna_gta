---
paths:
  - "origna_gta/lib/**"
  - "origna_gta/test/**"
  - "origna_gta/integration_test/**"
---

# Flutter & Dart Rules

## Architecture
- MVVM only — ViewModels in `features/`, Screens in `screens/`
- No business logic in screens — screens only call ViewModel methods
- Riverpod for state management
- Repositories in `core/repositories/` for all Firestore operations

## Code Safety
- **No passing BuildContext into async methods** — resolve ScaffoldMessenger BEFORE await
- **Always check `mounted` after await** in StatefulWidgets
- **Prefer const constructors** everywhere possible
- **`withOpacity` is DEPRECATED** → use `withValues` or `Color.withValues`
- **`DropdownButtonFormField.value` is DEPRECATED** → use `initialValue` + `key: ValueKey(stateValue)`
- **All async code must be cancellation-safe** — explicit error handling, no silent failures
- **Fix all Dart compiler warnings** — code must be clean

## Models
- Primary: `lib/models/generated/*.dart` (Freezed + json_serializable)
- Legacy: `lib/models/models.dart` — still used by some screens
- **NEVER import both** `models/generated/models.dart` AND `models/models.dart` in the same file — `Address` collision. Use `hide Address`.
- Use `Order.fromFirestore(doc)`, `User.fromFirestore(doc)` for Firestore reads

## EnvConfig
- `lib/utils/env_config.dart` — Factory constructor singleton
- Access via `EnvConfig()`, NOT `EnvConfig.instance`

## Cross-Stack Rule
- When editing ANY Dart file that interacts with Firestore, verify field names match `schema_constants.dart` AND `functions/schema_constants.py`
- When editing a ViewModel, check the corresponding screen AND the backend handler it calls
