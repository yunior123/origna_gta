# SQL Injection Audit Checklist

Use this when triaging a suspicious query path.

## False-Positive Filter

A finding is usually not a real injection if all are true:

- the interpolated fragment is a compile-time constant
- the fragment is not influenced by request data, DB data, env vars, or headers
- values are still bound with parameters
- any dynamic identifier comes from a closed allowlist or enum

If one of those fails, keep digging.

## Quick Triage Questions

1. Where is the SQL sink?
2. Which exact fragment is interpolated?
3. Can a user influence it directly or indirectly?
4. Is the fragment a value or an identifier?
5. If it is an identifier, where is the allowlist?
6. If it is a value, why is it not bound?
7. Is there a test covering malicious input?

## High-Risk Patterns

- `format!("... {}", user_input)`
- `push_str(request.query(...))`
- pass-through sort keys
- pass-through JSONB field names
- raw filter expression builders
- concatenated `WHERE` clauses
- string-built `IN (...)` lists from request input
- handcrafted pagination or search query builders

## Safer Replacements

- values: `$1`, `$2`, `.bind(...)`
- identifiers: enum or hardcoded allowlist mapping
- sort direction: bool to `ASC` / `DESC`
- pagination: parse to integer, clamp bounds, then interpolate if binding is unsupported

## Regression Test Ideas

- malicious quote payload in filter value
- malicious `ORDER BY` field
- malformed JSONB field selector
- oversized or negative `LIMIT` / `OFFSET`
- multi-step path where a helper returns a partially-built SQL fragment
