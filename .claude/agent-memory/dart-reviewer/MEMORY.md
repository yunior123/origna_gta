# Dart Reviewer Memory — Index

## Persistent Patterns Found in Reviews

| File | Memory |
|------|--------|
| `feedback_analytics_pricecad.md` | analytics service uses `double priceCad` intentionally (not money storage) |
| `feedback_live_test_skip_pattern.md` | `skip: !runLive` is the approved live-test gate pattern, not a violation |
| `feedback_dollar_getters.md` | `double` getters on Freezed models are display-only; storage is always int cents |
