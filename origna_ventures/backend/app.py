from __future__ import annotations

import hashlib
import hmac
import html
import json
import os
import re
import secrets
import sqlite3
import time
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

import requests
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field


@dataclass
class Settings:
    base_url: str = os.getenv(
        "ORIGNA_VENTURES_BASE_URL", "https://www.orignaventures.ca"
    )
    api_base_url: str = os.getenv(
        "ORIGNA_VENTURES_API_BASE_URL", "https://api.orignaventures.ca"
    )
    cors_allowed_origins: str = os.getenv(
        "ORIGNA_CORS_ALLOWED_ORIGINS",
        "https://orignaventures.ca,https://www.orignaventures.ca,http://localhost:3000,http://localhost:5000,http://localhost:8080",
    )
    support_email: str = os.getenv("ORIGNA_SUPPORT_EMAIL", "support@orignaventures.ca")
    support_phone: str = os.getenv("ORIGNA_SUPPORT_PHONE", "4167865517")
    company_legal_name: str = os.getenv(
        "ORIGNA_COMPANY_LEGAL_NAME", "1001475263 ONTARIO CORPORATION"
    )
    company_bn: str = os.getenv("ORIGNA_COMPANY_BN", "708286364TZ0001")
    sqlite_path: str = os.getenv("ORIGNA_SQLITE_PATH", "./storage/origna_ventures.db")
    storage_dir: str = os.getenv("ORIGNA_STORAGE_DIR", "./storage")
    stripe_secret_key: str = os.getenv("ORIGNA_STRIPE_SECRET_KEY", "")
    stripe_webhook_secret: str = os.getenv("ORIGNA_STRIPE_WEBHOOK_SECRET", "")
    stripe_success_url: str = os.getenv(
        "ORIGNA_STRIPE_SUCCESS_URL", "https://orignaventures.ca/?status=success"
    )
    stripe_cancel_url: str = os.getenv(
        "ORIGNA_STRIPE_CANCEL_URL", "https://orignaventures.ca/?status=cancelled"
    )
    environment: str = os.getenv("ENVIRONMENT", "dev")
    mailjet_api_key: str = os.getenv("ORIGNA_MAILJET_API_KEY", "")
    mailjet_secret_key: str = os.getenv("ORIGNA_MAILJET_SECRET_KEY", "")
    mailjet_api_url: str = os.getenv(
        "ORIGNA_MAILJET_API_URL", "https://api.mailjet.com/v3.1/send"
    )
    mailjet_from_email: str = os.getenv(
        "ORIGNA_MAILJET_FROM_EMAIL", "support@orignaventures.ca"
    )
    mailjet_from_name: str = os.getenv(
        "ORIGNA_MAILJET_FROM_NAME", "Origna Ventures Services"
    )
    github_token: str = os.getenv("ORIGNA_GITHUB_TOKEN", "")
    github_org: str = os.getenv("ORIGNA_GITHUB_ORG", "")
    github_template_repo: str = os.getenv("ORIGNA_GITHUB_TEMPLATE_REPO", "")
    github_permission: str = os.getenv("ORIGNA_GITHUB_PERMISSION", "pull")
    github_api_version: str = os.getenv(
        "ORIGNA_GITHUB_API_VERSION", "2022-11-28"
    )
    admin_api_key: str = os.getenv("ORIGNA_ADMIN_API_KEY", "")


settings = Settings()
Path(settings.storage_dir).mkdir(parents=True, exist_ok=True)
Path(settings.sqlite_path).parent.mkdir(parents=True, exist_ok=True)

SERVICE_CATALOG = {
    "origna_code": {
        "name_en": "OrignaCode",
        "name_fr": "OrignaCode",
        "price_cad": 500,
        "summary_en": "Lifetime source-code access with updates.",
        "summary_fr": "Accès à vie au code source avec mises à jour.",
    },
    "origna_launch": {
        "name_en": "OrignaLaunch",
        "name_fr": "OrignaLaunch",
        "price_cad": 3000,
        "summary_en": "Lifetime software access + launch + first-year Hetzner hosting (8 GB RAM + 80 GB disk) + first-year store enrollment + 20 human testers (20h QA).",
        "summary_fr": "Accès logiciel à vie + lancement + hébergement Hetzner première année (8 Go RAM + 80 Go disque) + inscription boutique première année + 20 testeurs humains (20h QA).",
    },
    "origna_team": {
        "name_en": "OrignaTeam",
        "name_fr": "OrignaTeam",
        "price_cad": 1000,
        "summary_en": "Dedicated developer outsourcing at up to 1,000 CAD/month with optional tracked time and separate third-party costs.",
        "summary_fr": "Externalisation avec développeur dédié jusqu'à 1 000 CAD/mois avec suivi du temps optionnel et coûts tiers séparés.",
    },
}


class PaymentSessionRequest(BaseModel):
    payer_email: Optional[EmailStr] = None
    payment_provider: str = Field(default="stripe", pattern="^(stripe)$")
    service_code: str = Field(
        default="", pattern="^(|origna_code|origna_launch|origna_team)$"
    )


class ContactFormRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    company: str = Field(default="", max_length=160)
    service: str = Field(default="general", max_length=40)
    message: str = Field(min_length=10, max_length=2000)


class EmailTestRequest(BaseModel):
    to_email: EmailStr
    subject: str = Field(default="Origna Ventures test email")
    body: str = Field(default="Mailjet integration test.")


app = FastAPI(title="Origna Ventures Payment API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip()
        for origin in settings.cors_allowed_origins.split(",")
        if origin.strip()
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Stripe-Signature"],
)

_USERNAME_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$")
_REFERRAL_RE = re.compile(r"^[A-Za-z0-9_-]{0,64}$")
_TRUSTED_PROXY_COUNT = int(
    os.getenv(
        "ORIGNA_TRUSTED_PROXY_COUNT",
        os.getenv("TRUSTED_PROXY_COUNT", "0"),
    )
)
_MAX_USER_AGENT_LENGTH = 512
_STRIPE_SIGNATURE_TOLERANCE_SECONDS = 300
_RATE_LIMITS: Dict[str, List[float]] = {}
_rate_limit_counter = 0

_admin_api_key: str = os.getenv("ORIGNA_ADMIN_API_KEY", "")


def require_admin_key(request: Request) -> None:
    if not _admin_api_key:
        raise HTTPException(status_code=503, detail="Admin API not configured")
    auth = request.headers.get("authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    provided = auth[7:]
    if not secrets.compare_digest(provided.encode(), _admin_api_key.encode()):
        raise HTTPException(status_code=401, detail="Unauthorized")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(settings.sqlite_path)
    conn.row_factory = sqlite3.Row
    return conn


@contextmanager
def db_conn():
    conn = db()
    try:
        yield conn
    finally:
        conn.close()


def init_db() -> None:
    conn = db()
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS contracts (
            id TEXT PRIMARY KEY,
            service_code TEXT NOT NULL,
            locale TEXT NOT NULL,
            client_name TEXT NOT NULL,
            client_email TEXT NOT NULL,
            client_company TEXT NOT NULL,
            client_phone TEXT NOT NULL,
            client_address TEXT NOT NULL,
            signer_full_name TEXT NOT NULL,
            signer_title TEXT NOT NULL,
            github_username TEXT,
            bitbucket_username TEXT,
            referral_code TEXT,
            typed_signature TEXT NOT NULL,
            consent_checked INTEGER NOT NULL,
            consent_version TEXT NOT NULL,
            signer_ip TEXT NOT NULL,
            user_agent TEXT NOT NULL,
            document_sha256 TEXT NOT NULL,
            pdf_path TEXT NOT NULL,
            status TEXT NOT NULL,
            stripe_session_id TEXT,
            stripe_payment_status TEXT,
            payer_email TEXT,
            provider TEXT,
            repo_unlock_status TEXT,
            repo_unlock_error TEXT,
            github_invitation_id TEXT,
            created_at TEXT NOT NULL,
            signed_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS webhook_events (
            id TEXT PRIMARY KEY,
            event_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        );
        """
    )
    conn.commit()
    existing = {
        row["name"] for row in conn.execute("PRAGMA table_info(contracts)").fetchall()
    }
    for column, ddl in [
        ("payer_email", "ALTER TABLE contracts ADD COLUMN payer_email TEXT"),
        (
            "repo_unlock_status",
            "ALTER TABLE contracts ADD COLUMN repo_unlock_status TEXT",
        ),
        (
            "repo_unlock_error",
            "ALTER TABLE contracts ADD COLUMN repo_unlock_error TEXT",
        ),
        (
            "github_invitation_id",
            "ALTER TABLE contracts ADD COLUMN github_invitation_id TEXT",
        ),
    ]:
        if column not in existing:
            conn.execute(ddl)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    conn.close()


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.post("/api/contact")
def submit_contact(payload: ContactFormRequest, request: Request) -> Dict[str, Any]:
    enforce_rate_limit(f"contact:{client_ip(request)}", limit=5, window_seconds=300)
    safe_name = html_escape(payload.name)
    safe_email = html_escape(payload.email)
    safe_company = html_escape(payload.company)
    safe_service = html_escape(payload.service)
    safe_message = html_escape(payload.message)
    subject = f"Contact form: {safe_service} — {safe_name}"
    html_body = (
        f"<h2>New contact form submission</h2>"
        f"<p><b>Name:</b> {safe_name}</p>"
        f"<p><b>Email:</b> {safe_email}</p>"
        f"<p><b>Company:</b> {safe_company or 'N/A'}</p>"
        f"<p><b>Service:</b> {safe_service}</p>"
        f"<p><b>Message:</b></p><p>{safe_message}</p>"
        f"<hr><p><small>IP: {client_ip(request)} · Time: {utc_now()}</small></p>"
    )
    text_body = (
        f"Name: {safe_name}\nEmail: {safe_email}\nCompany: {safe_company or 'N/A'}\n"
        f"Service: {safe_service}\nMessage: {safe_message}\nIP: {client_ip(request)}"
    )
    if settings.mailjet_api_key and settings.mailjet_secret_key:
        try:
            send_mailjet_email(settings.support_email, subject, html_body, text_body)
        except Exception:
            pass
    conn = db()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS contacts (id TEXT PRIMARY KEY, name TEXT, email TEXT, company TEXT, service TEXT, message TEXT, ip TEXT, created_at TEXT)",
    )
    contact_id = f"ct-{secrets.token_hex(8)}"
    conn.execute(
        "INSERT INTO contacts (id, name, email, company, service, message, ip, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            contact_id,
            payload.name,
            payload.email,
            payload.company,
            payload.service,
            payload.message,
            client_ip(request),
            utc_now(),
        ),
    )
    conn.commit()
    conn.close()
    return {"status": "ok", "id": contact_id}


@app.get("/health")
@app.get("/api/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/api/meta")
def meta() -> Dict[str, Any]:
    return {
        "company": settings.company_legal_name,
        "bn": settings.company_bn,
        "supportEmail": settings.support_email,
        "supportPhone": settings.support_phone,
        "services": SERVICE_CATALOG,
    }


def client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "")
    if forwarded and _TRUSTED_PROXY_COUNT > 0:
        parts = [p.strip() for p in forwarded.split(",")]
        if len(parts) >= _TRUSTED_PROXY_COUNT:
            return parts[-_TRUSTED_PROXY_COUNT][:64]
    return (request.client.host if request.client else "unknown")[:64]


def normalize_optional_username(value: Optional[str], field_name: str) -> Optional[str]:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if not _USERNAME_RE.fullmatch(normalized):
        raise HTTPException(status_code=400, detail=f"Invalid {field_name}")
    return normalized


def normalize_optional_referral(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if not _REFERRAL_RE.fullmatch(normalized):
        raise HTTPException(status_code=400, detail="Invalid referral_code")
    return normalized


def sanitize_user_agent(value: str) -> str:
    return value.strip()[:_MAX_USER_AGENT_LENGTH] or "unknown"


def _cleanup_rate_limits() -> None:
    global _rate_limit_counter
    _rate_limit_counter += 1
    if _rate_limit_counter % 100 != 0:
        return
    cutoff = time.time() - 600
    stale = [k for k, v in _RATE_LIMITS.items() if not v or v[-1] < cutoff]
    for k in stale:
        del _RATE_LIMITS[k]


def enforce_rate_limit(key: str, limit: int, window_seconds: int) -> None:
    _cleanup_rate_limits()
    now = time.time()
    window_start = now - window_seconds
    bucket = [
        timestamp
        for timestamp in _RATE_LIMITS.get(key, [])
        if timestamp >= window_start
    ]
    if len(bucket) >= limit:
        raise HTTPException(status_code=429, detail="Too many requests")
    bucket.append(now)
    _RATE_LIMITS[key] = bucket


def html_escape(value: str) -> str:
    return html.escape(value, quote=True)


def send_mailjet_email(
    to_email: str, subject: str, html_body: str, text_body: str
) -> Dict[str, Any]:
    if not settings.mailjet_api_key or not settings.mailjet_secret_key:
        raise HTTPException(status_code=500, detail="Mailjet credentials missing")

    is_sandbox = settings.environment.lower() not in ["production", "prod"]

    response = requests.post(
        settings.mailjet_api_url,
        auth=(settings.mailjet_api_key, settings.mailjet_secret_key),
        json={
            "SandboxMode": is_sandbox,
            "Messages": [
                {
                    "From": {
                        "Email": settings.mailjet_from_email,
                        "Name": settings.mailjet_from_name,
                    },
                    "To": [{"Email": to_email}],
                    "Subject": subject,
                    "TextPart": text_body,
                    "HTMLPart": html_body,
                }
            ],
        },
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


def stripe_headers() -> Dict[str, str]:
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=500, detail="Stripe key missing")
    return {
        "Authorization": f"Bearer {settings.stripe_secret_key}",
        "Content-Type": "application/x-www-form-urlencoded",
    }


def github_repo_target() -> tuple[str, str]:
    repo = settings.github_template_repo.strip()
    if not repo:
        raise HTTPException(status_code=500, detail="GitHub target repo missing")
    if "/" in repo:
        owner, repo_name = repo.split("/", 1)
        return owner, repo_name
    if settings.github_org:
        return settings.github_org, repo
    raise HTTPException(status_code=500, detail="GitHub org missing for repo target")


def github_headers() -> Dict[str, str]:
    if not settings.github_token:
        raise HTTPException(status_code=500, detail="GitHub token missing")
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {settings.github_token}",
        "X-GitHub-Api-Version": settings.github_api_version,
    }


def create_checkout_session_from_service(
    service_code: str, service: dict, payer_email: Optional[str] = None
) -> Dict[str, Any]:
    base_cents = service["price_cad"] * 100
    hst_cents = round(service["price_cad"] * 0.13) * 100
    is_subscription = service_code == "origna_team"
    payload = {
        "mode": "subscription" if is_subscription else "payment",
        "success_url": settings.stripe_success_url,
        "cancel_url": settings.stripe_cancel_url,
        "billing_address_collection": "required",
        "payment_method_types[0]": "card",
        "metadata[service_code]": service_code,
    }
    if not is_subscription:
        payload["submit_type"] = "pay"
        payload["payment_method_types[1]"] = "klarna"
        payload["line_items[0][price_data][currency]"] = "cad"
        payload["line_items[0][price_data][unit_amount]"] = str(base_cents)
        payload["line_items[0][price_data][product_data][name]"] = service["name_en"]
        payload["line_items[0][price_data][product_data][description]"] = "Service base price"
        payload["line_items[0][quantity]"] = "1"
        payload["line_items[1][price_data][currency]"] = "cad"
        payload["line_items[1][price_data][unit_amount]"] = str(hst_cents)
        payload["line_items[1][price_data][product_data][name]"] = "HST (13%)"
        payload["line_items[1][price_data][product_data][description]"] = "Ontario Harmonized Sales Tax"
        payload["line_items[1][quantity]"] = "1"
    else:
        payload["line_items[0][price_data][currency]"] = "cad"
        payload["line_items[0][price_data][unit_amount]"] = str(base_cents)
        payload["line_items[0][price_data][recurring][interval]"] = "month"
        payload["line_items[0][price_data][product_data][name]"] = service["name_en"]
        payload["line_items[0][price_data][product_data][description]"] = "Monthly dedicated developer outsourcing"
        payload["line_items[0][quantity]"] = "1"
        payload["subscription_data[metadata][service_code]"] = service_code
    if payer_email:
        payload["customer_email"] = payer_email
        payload["metadata[client_email]"] = payer_email
    response = requests.post(
        "https://api.stripe.com/v1/checkout/sessions",
        headers={
            **stripe_headers(),
            "Idempotency-Key": f"checkout:{service_code}:{payer_email or 'anon'}",
        },
        data=payload,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


@app.post("/api/payments/create-checkout-session")
def payment_session(payload: PaymentSessionRequest, request: Request) -> Dict[str, Any]:
    ip = client_ip(request)
    enforce_rate_limit(f"pay:{ip}", limit=20, window_seconds=300)
    service_code = payload.service_code
    if not service_code or service_code not in SERVICE_CATALOG:
        raise HTTPException(status_code=400, detail="Valid service_code is required")
    service = SERVICE_CATALOG[service_code]
    session = create_checkout_session_from_service(
        service_code, service, payload.payer_email
    )
    conn = db()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS payments (id TEXT PRIMARY KEY, service_code TEXT, payer_email TEXT, stripe_session_id TEXT, status TEXT, subscription_id TEXT, subscription_status TEXT, created_at TEXT)",
    )
    payment_id = f"pay-{secrets.token_hex(8)}"
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            payment_id,
            service_code,
            payload.payer_email,
            session.get("id"),
            "awaiting_payment",
            None,
            None,
            utc_now(),
        ),
    )
    conn.commit()
    conn.close()
    return {
        "provider": "stripe",
        "sessionId": session.get("id"),
        "checkoutUrl": session.get("url"),
        "status": "awaiting_payment",
    }


@app.post("/api/email/test")
def email_test(payload: EmailTestRequest, request: Request) -> Dict[str, Any]:
    require_admin_key(request)
    ip = client_ip(request)
    enforce_rate_limit(f"email:{ip}", limit=5, window_seconds=300)
    send_mailjet_email(
        payload.to_email,
        payload.subject,
        f"<p>{html_escape(payload.body)}</p>",
        payload.body,
    )
    return {"success": True}


def verify_stripe_signature(payload: bytes, header: str) -> bool:
    if not settings.stripe_webhook_secret:
        raise HTTPException(status_code=500, detail="Stripe webhook secret missing")
    pieces = dict(part.split("=", 1) for part in header.split(",") if "=" in part)
    ts = pieces.get("t")
    sig = pieces.get("v1")
    if not ts or not sig:
        return False
    try:
        timestamp = int(ts)
    except ValueError:
        return False
    if abs(int(time.time()) - timestamp) > _STRIPE_SIGNATURE_TOLERANCE_SECONDS:
        return False
    signed_payload = f"{ts}.".encode("utf-8") + payload
    expected = hmac.new(
        settings.stripe_webhook_secret.encode("utf-8"),
        signed_payload,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, sig)


@app.post("/api/stripe/webhook")
async def stripe_webhook(request: Request) -> Dict[str, Any]:
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")
    if not verify_stripe_signature(payload, sig_header):
        raise HTTPException(status_code=400, detail="Invalid Stripe signature")

    try:
        event = json.loads(payload.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise HTTPException(status_code=400, detail="Invalid JSON payload")
    event_id = event.get("id", secrets.token_hex(8))
    event_type = event.get("type", "")

    try:
        with db_conn() as conn:
            already = conn.execute(
                "SELECT id FROM webhook_events WHERE id = ?", (event_id,)
            ).fetchone()
            if already:
                return {"status": "duplicate", "eventId": event_id}

            conn.execute(
                "INSERT INTO webhook_events (id, event_type, payload_json, created_at) VALUES (?, ?, ?, ?)",
                (event_id, event_type, json.dumps(event), utc_now()),
            )

            if event_type == "checkout.session.completed":
                session = event.get("data", {}).get("object", {})
                service_code = session.get("metadata", {}).get(
                    "service_code", "unknown"
                )
                client_email = session.get("metadata", {}).get("client_email", "")
                payer_email = session.get("customer_email", client_email)
                mode = session.get("mode", "payment")
                conn.execute(
                    "UPDATE payments SET status = ? WHERE stripe_session_id = ?",
                    ("paid", session.get("id")),
                )
                if service_code == "origna_team" and mode == "subscription":
                    subscription_id = session.get("subscription")
                    if subscription_id:
                        conn.execute(
                            "UPDATE payments SET subscription_id = ? WHERE stripe_session_id = ?",
                            (subscription_id, session.get("id")),
                        )
                if (
                    payer_email
                    and settings.mailjet_api_key
                    and settings.mailjet_secret_key
                ):
                    try:
                        subject = (
                            "Subscription confirmed — Origna Ventures"
                            if mode == "subscription"
                            else "Payment confirmed — Origna Ventures"
                        )
                        send_mailjet_email(
                            payer_email,
                            subject,
                            "<p>Your payment is confirmed. Thank you!</p>",
                            "Payment confirmed. Thank you!",
                        )
                    except Exception:
                        pass

            elif event_type == "checkout.session.expired":
                session = event.get("data", {}).get("object", {})
                conn.execute(
                    "UPDATE payments SET status = ? WHERE stripe_session_id = ? AND status = ?",
                    ("expired", session.get("id"), "awaiting_payment"),
                )

            elif event_type in (
                "customer.subscription.updated",
                "customer.subscription.deleted",
            ):
                subscription = event.get("data", {}).get("object", {})
                sub_id = subscription.get("id")
                sub_status = subscription.get("status", "unknown")
                if sub_id:
                    conn.execute(
                        "UPDATE payments SET subscription_status = ? WHERE subscription_id = ?",
                        (sub_status, sub_id),
                    )

            elif event_type == "invoice.payment_failed":
                invoice = event.get("data", {}).get("object", {})
                sub_id = invoice.get("subscription")
                if sub_id:
                    conn.execute(
                        "UPDATE payments SET subscription_status = ? WHERE subscription_id = ?",
                        ("past_due", sub_id),
                    )

            conn.commit()
    except Exception:
        raise HTTPException(status_code=500, detail="Webhook processing failed")

    return {"status": "ok", "eventId": event_id, "type": event_type}


@app.get("/api/contracts")
def list_contracts(request: Request) -> Dict[str, Any]:
    require_admin_key(request)
    with db_conn() as conn:
        rows = conn.execute(
            "SELECT id, service_code, client_company, client_email, payer_email, github_username, status, repo_unlock_status, repo_unlock_error, github_invitation_id, created_at FROM contracts ORDER BY created_at DESC LIMIT 100"
        ).fetchall()
    return {"contracts": [dict(row) for row in rows]}
