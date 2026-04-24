# OrignaBase Rust Audit — 2026-04-23

## Sources

- Rust `std::panic::set_hook`: https://doc.rust-lang.org/std/panic/fn.set_hook.html
- Rust `std::panic::catch_unwind`: https://doc.rust-lang.org/std/panic/fn.catch_unwind.html
- Tokio tracing guide: https://tokio.rs/tokio/topics/tracing
- `tracing-panic` hook reference: https://docs.rs/tracing-panic/latest/tracing_panic/fn.panic_hook.html
- Stripe webhook best practices: https://docs.stripe.com/webhooks

## Audit Findings

1. The current repo already contains the PostgreSQL query-layer fixes needed for
   dev product browsing. Fresh live probes against `https://api.dev.orignagta.ca/graphql`
   show category filters, keyword search, and multi-page browse queries returning
   `200` without GraphQL errors.
2. The server already initializes structured `tracing` early in
   `orignabase/crates/orignabase/src/main.rs`, which matches Tokio guidance.
3. Panic diagnostics were still weaker than they should be:
   the hook logged the panic payload and location, but it dropped the previous
   default hook and did not capture a backtrace into the structured log event.

## Changes Applied

- `orignabase/crates/orignabase/src/main.rs`
  - preserve the previous panic hook instead of replacing it blindly
  - capture a backtrace with `Backtrace::force_capture()`
  - emit panic location, message, and backtrace through `tracing`

## Operational Notes

- For future `500 Internal server error` browse regressions, triage in this order:
  1. Live GraphQL probe for `list(collection: "products", ...)`
  2. Seeded category coverage check
  3. Running container vs source drift
  4. Postgres query translation
- Stripe webhook handling in Ventures should continue treating webhook delivery as
  at-least-once and out-of-order. Keep dedupe keyed by `event.id`, and when
  applicable also correlate by `data.object.id + event.type`.
