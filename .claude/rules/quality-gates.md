# Quality Gates — origna_gta

## Before Every Commit
- `flutter analyze --no-fatal-infos` — zero errors, zero warnings
- `flutter test --exclude-tags golden` — all pass, zero skip
- If Rust changed: `cd orignabase && cargo clippy -D warnings && cargo test`

## Code Quality (auto-enforced)
- No `print()` or `debugPrint()` — use `AppLogger`
- No `Colors.blue` or hex literals — use `DesignTokens.*`
- No `setState()` in screens — use Riverpod
- No `BuildContext` in ViewModels or Services
- No hardcoded strings for routes, fields, URLs — use constants
- No `FirebaseAuth`, `Firestore`, `FirebaseStorage` — Firebase is GONE
- No `double` for money — integer cents only
- No relative imports (`../`) — use `package:origna_gta/...`
- No `MediaQuery.of(context).size.width` — use responsive utilities

## Test Quality
- Never `test.skip` — fix infrastructure instead
- Never delete failing tests — fix them
- Never `sleep()` / `Future.delayed()` in tests
- No real Stripe live-mode API calls in tests
- No hardcoded UIDs or tokens — use test helpers
