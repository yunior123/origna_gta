---
name: magic-string-remediation
description: "File-by-file Rust and Dart magic-string remediation for OrignaGTA. Use when replacing production-risk hardcoded field names, routes, labels, event types, status strings, and payload keys with schema constants, enums, or shared constants."
---

# Magic String Remediation

Remove production-risk magic strings without churning harmless test literals.

## Scope

Prioritize:

- schema field names
- JSON payload keys shared across backend/frontend
- route names
- status values and event types
- role names
- collection/table names
- notification payload keys

De-prioritize:

- harmless snapshot labels
- unique test fixture values
- log prose with no contract impact

## Rust Targets

- `orignabase/crates/ob-handlers`
- `orignabase/crates/ob-auth`
- `orignabase/crates/ob-mcp`
- `orignabase/crates/orignabase/tests` only when they reveal contract drift

## Dart Targets

- `origna_gta/lib`
- `orignabase/sdks/flutter/orignabase/lib`
- `e2e/` only where runtime naming/flow contracts are affected

## Replacement Order

1. Reuse existing constants first
2. If absent, add a shared constant in the nearest schema/constants module
3. Prefer enums for finite state values
4. Keep wire compatibility explicit

## Validation

After each real batch:

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/orignabase && cargo check
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta && flutter analyze --no-fatal-infos
```

## Do Not

- rename good code just for style
- touch broad test data unless it fixes a real contract mismatch
- replace strings that are already intentionally localized display text
