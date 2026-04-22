# Security Audit Report - Origna Ventures Website

**Date**: 21 April 2026
**Auditor**: Security Review
**Project**: orignaventures.ca Flutter Web Application + FastAPI Backend

## Executive Summary

Security audit completed with **HIGH** security rating after implementing critical fixes across the FastAPI backend and Flutter frontend. Firebase has been fully removed — backend is Python FastAPI with SQLite, deployed to Hetzner VPS via Caddy.

---

## Architecture

- **Frontend**: Flutter web (single-page app) — served by Caddy at `/var/www/orignaventures/production/current`
- **Backend**: Python FastAPI (`backend/app.py`) — Stripe checkout, PDF generation (reportlab), Mailjet email, SQLite
- **Database**: SQLite (`contracts.db`) with WAL mode for concurrent access safety
- **Deployment**: rsync to Hetzner VPS (204.168.137.16), Caddy reverse proxy, no Firebase
- **Payment**: Stripe Checkout Sessions (3 service tiers)
- **Email**: Mailjet for order confirmations and contract notifications

---

## Security Fixes Applied (April 2026)

### Critical Fixes

| # | Vulnerability | Fix |
|---|--------------|-----|
| 1 | Unauthenticated `/api/contracts` — anyone could list all client data | Added `require_admin_key()` |
| 2 | Unauthenticated `/api/contracts/{id}/pdf` — anyone could download contracts | Added admin auth + path traversal protection |
| 3 | Unauthenticated `/api/email/test` with XSS in HTML email body | Added admin auth + `html_escape()` |
| 4 | IP spoofing via `X-Forwarded-For` — bypassed all rate limits | `TRUSTED_PROXY_COUNT` env var |
| 5 | SQLite without WAL mode — concurrent access corruption risk | `PRAGMA journal_mode=WAL` |
| 6 | Rate limiter memory leak — unbounded growth | Periodic cleanup every 100 requests |
| 7 | `invite_github_collaborator()` still in codebase | Deleted entirely — manual repo access only |
| 8 | Missing `checkout.session.expired` webhook handler | Added handler — contract → `expired` |
| 9 | Mailjet API response exposure in email test endpoint | Only return `{"success": True}` |
| 10 | PDF path traversal — no containment check | `is_relative_to(storage_dir)` check |
| 11 | No `contract_id` format validation | Regex `^ovc_[0-9a-f]{16}$` |
| 12 | Webhook email XSS — raw URL in `href` | `html_escape(pdf_url)` |

### Manual Repository Access Policy

GitHub collaborator auto-invite has been **permanently removed**. Repository access is handled manually:
- Client requests access after payment
- Support team sends a clone or grants access manually
- No automated email with GitHub invite

---

## Security Features by Category

### A. Input Security
| Feature | Status | Details |
|---------|--------|---------|
| Name validation | DONE | Regex: letters, spaces, hyphens, apostrophes only |
| Email validation | DONE | RFC 5322 compliant, length-limited |
| Phone validation | DONE | 10-15 digits, format checking |
| Message validation | DONE | Min 10 chars, max 1000 chars |
| Input sanitization | DONE | Removes HTML/script injection characters |
| Length limits | DONE | All fields have max length |
| Contract ID validation | DONE | Strict regex `^ovc_[0-9a-f]{16}$` |

### B. Web Security
| Feature | Status | Details |
|---------|--------|---------|
| XSS Protection | DONE | Input sanitization + html_escape |
| Clickjacking Protection | DONE | X-Frame-Options: DENY |
| MIME Sniffing Protection | DONE | X-Content-Type-Options: nosniff |
| Content Security Policy | DONE | Strict CSP implemented |
| HTTPS Only | DONE | Caddy enforces HTTPS |
| Path Traversal | DONE | is_relative_to() containment check |
| Rate Limiting | DONE | Per-IP with trusted proxy count |
| Admin API Key | DONE | Required for protected admin endpoints; see `docs/admin_api_runbook.md` |

### C. Data Privacy
| Feature | Status | Details |
|---------|--------|---------|
| SQLite WAL mode | DONE | Safe concurrent access |
| No cookies | DONE | No tracking or session storage |
| No analytics | DONE | No third-party trackers |
| Form cleared after submit | DONE | Data not retained in memory |
| No Mailjet response exposure | DONE | Stripped in API responses |

### D. Secrets Management
| Feature | Status | Details |
|---------|--------|---------|
| STRIPE_WEBHOOK_SECRET | DONE | Environment variable, not in code |
| ADMIN_API_KEY | DONE | Environment variable, not in code |
| MAILJET_API_KEY/PUBLIC | DONE | Environment variables, not in code |
| No hardcoded secrets | DONE | All secrets via env vars |
| .gitignore protection | DONE | Key files excluded from repo |

---

## Risk Assessment

| Category | Risk Level | Mitigation |
|----------|------------|------------|
| XSS Attacks | LOW | Input sanitization + html_escape + CSP |
| SQL Injection | NONE | Parameterized queries (SQLite) |
| CSRF | LOW | No sessions/cookies; Stripe handles auth |
| Data Breaches | LOW | SQLite + admin auth on sensitive endpoints |
| DDoS | MEDIUM | Caddy + rate limiting per IP |
| Man-in-the-Middle | LOW | HTTPS enforced by Caddy |
| Path Traversal | LOW | is_relative_to() containment |
| IP Spoofing | LOW | TRUSTED_PROXY_COUNT env var |

---

## Remaining Considerations

### 1. Monitoring (Recommended)
Set up monitoring for:
- Error tracking (Sentry)
- Performance monitoring
- Uptime alerts

### 2. DDoS Protection
Caddy provides:
- HTTPS enforcement
- Connection limiting
- Consider Cloudflare proxy for high-traffic scenarios

### 3. Regular Audits
- Quarterly security reviews
- Dependency updates
- Monitor CVEs

---

## Service Tiers

| Tier | Price | Type |
|------|-------|------|
| OrignaCode | $500 CAD | One-time |
| OrignaLaunch | $3,000 CAD | One-time |
| OrignaTeam | $1,000 CAD/month | Subscription |

Seller: OrignaVentures (support@orignaventures.ca) — no seller onboarding, OrignaVentures IS the seller.

---

## Security Contact

For security issues or concerns:
- **Email**: support@orignaventures.ca
- **Website**: orignaventures.ca

Operational runbook:
- `docs/admin_api_runbook.md` — protected admin endpoint usage, bearer auth, curl smoke checks

---

*Last Updated: 21 April 2026*
