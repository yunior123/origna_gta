# Security Audit - 2026-05-04

Scope: Flutter web clients, OrignaBase Rust services, OrignaVentures FastAPI backend, PostgreSQL, Caddy, Docker Compose, and Hetzner VPS controls.

## Sources Checked

- Flutter security guidance: https://docs.flutter.dev/security
- OWASP API Security Top 10 2023: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- RustSec and cargo-audit guidance: https://rustsec.org/
- tower-http request body limits: https://docs.rs/tower-http/latest/tower_http/limit/
- PostgreSQL authentication methods: https://www.postgresql.org/docs/current/auth-methods.html
- PostgreSQL TLS connections: https://www.postgresql.org/docs/current/ssl-tcp.html
- Caddy automatic HTTPS: https://caddyserver.com/docs/automatic-https
- Caddy header directive: https://caddyserver.com/docs/caddyfile/directives/header
- Hetzner Cloud Firewalls: https://docs.hetzner.com/cloud/firewalls/overview/

## Changes Applied

- OrignaVentures FastAPI now disables `/docs`, `/redoc`, and `/openapi.json` when `ENVIRONMENT` is `prod` or `production`.
- OrignaVentures FastAPI now enforces `TrustedHostMiddleware` with `ORIGNA_TRUSTED_HOSTS`.
- OrignaVentures CORS parsing now strips blank entries and limits allowed methods/headers.
- DocuSeal Docker Compose no longer uses `docuseal/docuseal:latest`.
- DocuSeal PostgreSQL credentials and database URL are required at compose interpolation time.
- DocuSeal PostgreSQL volume now mounts to `/var/lib/postgresql/data`.
- OrignaBase SQLx dependency now disables default features and uses Rustls TLS explicitly.
- `rustls-webpki` was updated from `0.103.9` to `0.103.13` in `Cargo.lock`.

## Verified

- `origna_ventures/backend/.venv/bin/python -m pytest tests/test_payments_api.py -q`: 42 passed.
- `cd orignabase && cargo check -p ob-database`: passed.
- `cd orignabase && cargo check -p ob-handlers`: passed.
- `ruby -e 'require "yaml"; YAML.load_file("docker-compose.yml"); puts "yaml ok"'`: passed for `orignabase/docker/docker-compose.yml`.
- `cd orignabase && cargo tree -i sqlx-mysql --target all`: no active dependency tree printed.
- `git diff --check`: passed.

## Residual Risks

- `cargo audit` still fails on older transitive Rust crates: `rustls-webpki` via Stripe/AWS/NATS paths, feature-agnostic `sqlx-mysql`/`rsa` lock metadata, and several unmaintained/yanked crates. Do not ignore these globally; resolve by upgrading the owning crates or removing the feature paths.
- Flutter web currently stores OrignaBase access and refresh tokens in `localStorage`; this is a known XSS blast-radius risk. Preferred architecture is Secure, HttpOnly, SameSite cookie refresh tokens with short-lived access tokens.
- Root Caddy CSP still needs Flutter/Stripe/Google/Turnstile allowances, including inline/eval allowances. Treat any future third-party script additions as high-risk.
- Docker Compose verification was limited to YAML parsing because the local Docker CLI lacks `docker compose` and `docker-compose`.
- Python dependency scan was limited to `pip list --outdated`; `pip-audit` is not installed in the current backend venv.
