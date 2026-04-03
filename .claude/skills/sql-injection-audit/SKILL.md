---
name: sql-injection-audit
description: "Audit Rust/PostgreSQL query code for SQL injection in the OrignaGTA monorepo. Use when reviewing sqlx, query_raw, format!, dynamic identifiers, JSONB field access, query builders, or any backend path that composes SQL strings."
---

# SQL Injection Audit

Use this skill when the task is specifically to find, verify, or remediate SQL injection risk in the Rust backend.

This repo has a real risk pattern: PostgreSQL queries are often assembled across handlers, adapters, and helper functions while migrating away from Surreal-style patterns. Treat any SQL string construction as suspicious until proven safe.

## When To Use

- User asks to audit SQL injection, DB injection, unsafe queries, or parameterization
- A change touches `sqlx`, `query_raw`, `query_bind`, `format!`, `push_str`, or identifier sanitation
- Reviewing auth, admin, webhook, search, checkout, reporting, or any route accepting filters/sort/pagination
- Before deploying backend query changes

## Primary Targets

- `orignabase/crates/ob-database/`
- `orignabase/crates/ob-auth/`
- `orignabase/crates/ob-admin/`
- `orignabase/crates/ob-handlers/`
- `orignabase/crates/orignabase/tests/`

Start with a code sweep:

```bash
cd orignabase
rg -n 'query_raw|query_bind|sqlx::query|sqlx::query_as|format!|push_str|SELECT |INSERT |UPDATE |DELETE |ORDER BY|LIMIT |OFFSET ' crates
```

Then narrow to suspicious construction:

```bash
cd orignabase
rg -n 'format!\\(|push_str\\(|String::from\\(|let .*sql|query_raw\\(' crates
rg -n '\\$[0-9]+|:[a-zA-Z_][a-zA-Z0-9_]*' crates
```

## Audit Rules

### 1. Never trust string-built SQL just because some parts are constants

Treat these as unsafe until each dynamic fragment is classified:

- user input
- request query params
- headers or JWT claims
- GraphQL fields
- sort keys / filter keys / collection names
- JSONB field names
- table names
- `LIMIT` / `OFFSET` / `ORDER BY`

### 2. Values must be parameterized

Safe:

```rust
sqlx::query("SELECT * FROM users WHERE id = $1")
    .bind(&user_id)
```

Unsafe:

```rust
let sql = format!("SELECT * FROM users WHERE id = '{}'", user_id);
```

### 3. Identifiers cannot be parameterized, so they must be validated before interpolation

This applies to:

- table names
- column names
- JSONB field names
- sort direction

Accept only allowlisted constants or strict validation helpers. If the code interpolates an identifier from runtime input without a closed allowlist, treat it as a likely injection bug.

### 4. `query_raw` deserves extra suspicion

`query_raw` is acceptable only when all interpolated fragments are proven safe:

- validated integers for `LIMIT` / `OFFSET`
- allowlisted identifiers
- constants from schema modules

If values are user-controlled, prefer bound parameters. If identifiers must stay dynamic, demand explicit validation in the same path or an audited helper.

### 5. JSONB field access is still injection-sensitive

Safe:

```rust
format!("data->>'{}' = $1", fields::STATUS)
```

Only if `fields::STATUS` is a constant.

Unsafe:

```rust
format!("data->>'{}' = $1", requested_field)
```

### 6. Pagination and sorting are common weak points

Check:

- `LIMIT` and `OFFSET` parsed as bounded integers before interpolation
- `ORDER BY` field comes from a fixed allowlist
- sort direction restricted to `ASC` or `DESC`
- no raw pass-through of query string fragments

### 7. Sanitizers are not automatically trustworthy

When a helper claims to sanitize identifiers:

1. read the implementation
2. verify the accepted character set is actually strict enough
3. verify it is called on every entry path before interpolation

If any path bypasses the helper, the query is still vulnerable.

## Repo-Specific Review Checklist

- Prefer adapter-layer SQL over handler-layer SQL
- Reject `format!` that injects request-derived values into SQL text
- Check migration-era code for SurrealDB leftovers like custom path syntax or identifier tricks
- Watch for helpers that bind JSON values as strings and accidentally force unsafe fallbacks
- Verify hybrid top-level/JSONB field selection does not accept runtime field names
- Review admin/auth list endpoints first; they often combine filtering, sorting, and pagination

## Verification Standard

Do not report a vulnerability on pattern match alone. Trace the value origin.

For each finding, record:

1. SQL sink
2. dynamic fragment
3. source of that fragment
4. existing validation or lack of it
5. exploitability assessment
6. precise fix

If you fix code, verify with:

```bash
cd orignabase
cargo check
cargo clippy -D warnings
cargo test
```

Save long runs to `/tmp/...`.

## Findings Format

Use this output shape:

```text
[severity] [file:line] [sink]
Issue: ...
Dynamic fragment: ...
Source: ...
Why exploitable / why safe: ...
Fix: ...
Evidence: ...
```

Severity guide:

- Critical: confirmed exploitable SQL injection on attacker-controlled input
- High: likely exploitable identifier/value interpolation with weak or missing validation
- Medium: risky pattern where safety depends on non-local assumptions
- Low: hardened today, but fragile enough to regress

## Remediation Patterns

- Replace value interpolation with bound parameters
- Move dynamic identifier selection to a closed enum/allowlist
- Parse pagination inputs to bounded integers before use
- Centralize identifier validation in one audited helper
- Add regression tests that hit the exact unsafe path with malicious payloads

## References

Read `references/checklist.md` when you need a compact false-positive filter and a remediation decision tree.
