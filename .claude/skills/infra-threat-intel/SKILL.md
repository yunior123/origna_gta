---
name: infra-threat-intel
description: "Infrastructure threat intelligence for OrignaGTA. Searches latest news on hacker abuse, gathers real e-commerce attack cases, audits code based on real findings. No false positives — critical issues only. Use when asked to 'security audit', 'threat intel', 'real attacks', or 'infrastructure security'."
---

# Infrastructure Threat Intelligence — OrignaGTA

Searches latest hacker news and real-world attack cases, then audits the codebase against actual evidence. No false positives — only findings with direct code evidence.

## When to Use

- Before major releases
- After security incidents in the e-commerce ecosystem
- When asked to "audit infrastructure security", "threat intel", "real attacks"
- Quarterly security review
- After dependency updates

## Workflow

### Phase 1: Gather Threat Intelligence

Search for latest (2025-2026) attacks affecting e-commerce:

```bash
# Web searches to run
websearch "e-commerce security vulnerabilities 2026"
websearch "Stripe payment security incident 2026"
websearch "Rust axum CVE 2026"
websearch "Flutter security vulnerability 2026"
websearch "PostgreSQL security advisory 2026"
websearch "GraphQL injection attack 2026"
websearch "JWT token hijacking technique 2026"
websearch "SSRF attack e-commerce 2026"
websearch "supply chain attack npm pub.dev 2026"
```

Also check:
- GitHub Advisory Database for dependencies in `Cargo.toml` and `pubspec.yaml`
- RustSec Advisory DB (`cargo audit`)
- NVD for CVEs in used libraries

### Phase 2: Cross-Reference Against Codebase

For each threat found, check if OrignaGTA is vulnerable:

| Threat Pattern | Codebase Check |
|----------------|----------------|
| SQL injection | `format!()` in Rust handlers, unparameterized queries |
| JWT algorithm confusion | JWT validation in `ob-auth`, algorithm enforcement |
| SSRF | Image URL fetching, product URL validation |
| XSS | User input rendering without sanitization |
| CSRF | State-changing GraphQL mutations without auth |
| Supply chain | Suspicious dependencies, typosquatting |
| Deserialization | `serde_json::from_str` on untrusted input |
| Rate limiting bypass | GraphQL batching, query depth abuse |
| Token leakage | JWT in logs, error responses, URLs |
| Payment manipulation | Amount tampering, idempotency gaps |

### Phase 3: Report (Critical Only)

Only report findings that have:
1. ✅ A real-world attack reference (CVE, blog post, GitHub issue)
2. ✅ Direct evidence in our codebase (file:line)
3. ✅ Clear exploitation path (how an attacker would use it)

**Do NOT report:**
- ❌ Theoretical vulnerabilities without evidence
- ❌ Best practices without concrete exploit path
- ❌ Low-severity issues

## Attack Vector Checklist

### Payment & Financial

- [ ] Double charge via concurrent checkout (WooCommerce #3638)
- [ ] Amount miscalculation: double ×100 conversion (MedusaJS #13160)
- [ ] Platform fee bypass (Stripe Connect #2212)
- [ ] Webhook replay attacks
- [ ] Idempotency key reuse
- [ ] Stock manipulation via cart quantity bypass
- [ ] Price manipulation: client sends modified prices

### Authentication

- [ ] JWT `alg:none` bypass
- [ ] JWT `HS256` confusion when expecting RS256
- [ ] Token leakage in server logs
- [ ] Session fixation after login
- [ ] MFA bypass via direct navigation
- [ ] Refresh token rotation race condition

### API

- [ ] GraphQL batching DoS (1000 queries in one request)
- [ ] GraphQL introspection in production
- [ ] Query depth attack (recursive types)
- [ ] Missing rate limiting on GraphQL endpoint
- [ ] CORS misconfiguration

### Infrastructure

- [ ] Docker container runs as root
- [ ] Secrets in environment variables exposed via `/proc`
- [ ] PostgreSQL port exposed to internet
- [ ] Meilisearch API key in logs
- [ ] TLS certificate issues

### Supply Chain

- [ ] Compromised dependency (check `cargo audit`, `flutter pub audit`)
- [ ] Build script injection
- [ ] Dependency confusion attack vector

## Output Format

```
INFRASTRUCTURE THREAT INTEL REPORT
═══════════════════════════════════
Date: [ISO 8601]
Threats analyzed: X
Critical findings: X
High findings: X

CRITICAL FINDINGS:
─────────────────
1. [CVE-XXXX-XXXXX] [Attack Name]
   Real-world reference: [URL]
   Affected code: [file:line]
   Exploitation: [how attacker uses this]
   Impact: [what happens]
   Fix: [exact code change]

HIGH FINDINGS:
──────────────
1. ...

CLEAN (no findings):
- [area]: verified safe against [threat reference]

═══════════════════════════════════
```

## Key Files Reference

| Purpose | Path |
|---------|------|
| Rust Cargo.toml | `orignabase/Cargo.toml` |
| Flutter pubspec.yaml | `origna_gta/pubspec.yaml` |
| Auth handlers | `orignabase/crates/ob-auth/src/` |
| Payment handlers | `orignabase/crates/ob-handlers/src/payments/` |
| GraphQL resolvers | `orignabase/crates/ob-graphql/src/` |
| SDK auth | `orignabase/sdks/flutter/orignabase/lib/src/auth.dart` |
| Environment config | `lib/utils/env_config.dart` |
