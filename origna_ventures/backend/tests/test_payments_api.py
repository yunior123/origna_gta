from __future__ import annotations

import hashlib
import hmac
import json
import sqlite3
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

sys.path.append(str(Path(__file__).resolve().parents[1]))
import app as backend_app


def sign_stripe_payload(secret: str, raw_body: bytes, timestamp: int | None = None) -> str:
    timestamp = timestamp or int(time.time())
    signed_payload = f"{timestamp}.".encode("utf-8") + raw_body
    digest = hmac.new(secret.encode("utf-8"), signed_payload, hashlib.sha256).hexdigest()
    return f"t={timestamp},v1={digest}"


def ensure_payments_table(db_path: Path) -> None:
    conn = sqlite3.connect(db_path)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS payments (id TEXT PRIMARY KEY, service_code TEXT, payer_email TEXT, stripe_session_id TEXT, status TEXT, subscription_id TEXT, subscription_status TEXT, created_at TEXT)"
    )
    conn.commit()
    conn.close()


@pytest.fixture()
def client(tmp_path, monkeypatch):
    db_path = tmp_path / "origna_ventures_test.db"
    storage_dir = tmp_path / "storage"
    storage_dir.mkdir(parents=True, exist_ok=True)

    monkeypatch.setattr(backend_app.settings, "sqlite_path", str(db_path))
    monkeypatch.setattr(backend_app.settings, "storage_dir", str(storage_dir))
    backend_app.init_db()
    ensure_payments_table(db_path)

    with TestClient(backend_app.app) as test_client:
        yield test_client, db_path


def test_create_checkout_session_one_time_payload_includes_hst_and_klarna(monkeypatch):
    captured = {}

    def fake_post(url, headers, data, timeout):
        captured["url"] = url
        captured["headers"] = headers
        captured["data"] = dict(data)
        captured["timeout"] = timeout
        return SimpleNamespace(
            raise_for_status=lambda: None,
            json=lambda: {"id": "cs_launch", "url": "https://checkout/launch"},
        )

    monkeypatch.setattr(backend_app.requests, "post", fake_post)
    monkeypatch.setattr(backend_app.settings, "stripe_secret_key", "STRIPE_SECRET_KEY_REDACTED")

    session = backend_app.create_checkout_session_from_service(
        "origna_launch",
        backend_app.SERVICE_CATALOG["origna_launch"],
        "buyer@example.com",
    )

    payload = captured["data"]
    assert session["id"] == "cs_launch"
    assert captured["url"] == "https://api.stripe.com/v1/checkout/sessions"
    assert captured["timeout"] == 30
    assert payload["mode"] == "payment"
    assert payload["submit_type"] == "pay"
    assert payload["payment_method_types[0]"] == "card"
    assert payload["payment_method_types[1]"] == "klarna"
    assert payload["line_items[0][price_data][unit_amount]"] == "300000"
    assert payload["line_items[1][price_data][unit_amount]"] == "39000"
    assert payload["metadata[service_code]"] == "origna_launch"
    assert payload["customer_email"] == "buyer@example.com"
    assert payload["metadata[client_email]"] == "buyer@example.com"
    assert captured["headers"]["Idempotency-Key"] == "checkout:origna_launch:buyer@example.com"


def test_create_checkout_session_subscription_payload_is_monthly(monkeypatch):
    captured = {}

    def fake_post(url, headers, data, timeout):
        captured["data"] = dict(data)
        return SimpleNamespace(
            raise_for_status=lambda: None,
            json=lambda: {"id": "cs_team", "url": "https://checkout/team"},
        )

    monkeypatch.setattr(backend_app.requests, "post", fake_post)
    monkeypatch.setattr(backend_app.settings, "stripe_secret_key", "STRIPE_SECRET_KEY_REDACTED")

    backend_app.create_checkout_session_from_service(
        "origna_team",
        backend_app.SERVICE_CATALOG["origna_team"],
        "team@example.com",
    )

    payload = captured["data"]
    assert payload["mode"] == "subscription"
    assert payload["line_items[0][price_data][unit_amount]"] == "100000"
    assert payload["line_items[0][price_data][recurring][interval]"] == "month"
    assert payload["subscription_data[metadata][service_code]"] == "origna_team"
    assert "submit_type" not in payload
    assert "payment_method_types[1]" not in payload
    assert "line_items[1][price_data][unit_amount]" not in payload


def test_create_checkout_session_without_email_uses_anon_idempotency(monkeypatch):
    captured = {}

    def fake_post(url, headers, data, timeout):
        captured["headers"] = headers
        captured["data"] = dict(data)
        return SimpleNamespace(
            raise_for_status=lambda: None,
            json=lambda: {"id": "cs_code", "url": "https://checkout/code"},
        )

    monkeypatch.setattr(backend_app.requests, "post", fake_post)
    monkeypatch.setattr(backend_app.settings, "stripe_secret_key", "STRIPE_SECRET_KEY_REDACTED")

    backend_app.create_checkout_session_from_service(
        "origna_code",
        backend_app.SERVICE_CATALOG["origna_code"],
    )

    payload = captured["data"]
    assert "customer_email" not in payload
    assert "metadata[client_email]" not in payload
    assert captured["headers"]["Idempotency-Key"] == "checkout:origna_code:anon"


def test_contracts_endpoint_requires_admin_key(client, monkeypatch):
    test_client, _ = client
    monkeypatch.setattr(backend_app, "_admin_api_key", "secret-admin")

    unauthorized = test_client.get("/api/contracts")
    assert unauthorized.status_code == 401

    authorized = test_client.get(
        "/api/contracts", headers={"Authorization": "Bearer secret-admin"}
    )
    assert authorized.status_code == 200
    assert authorized.json() == {"contracts": []}


def test_payment_session_rejects_invalid_service_code(client):
    test_client, _ = client

    response = test_client.post(
        "/api/payments/create-checkout-session",
        json={"service_code": "bad_code", "payment_provider": "stripe"},
    )

    assert response.status_code == 422


def test_payment_session_persists_payment_row(client, monkeypatch):
    test_client, db_path = client

    monkeypatch.setattr(
        backend_app,
        "create_checkout_session_from_service",
        lambda service_code, service, payer_email=None: {
            "id": "cs_test_123",
            "url": "https://checkout/session/test",
        },
    )

    response = test_client.post(
        "/api/payments/create-checkout-session",
        json={
            "service_code": "origna_team",
            "payment_provider": "stripe",
            "payer_email": "client@example.com",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "provider": "stripe",
        "sessionId": "cs_test_123",
        "checkoutUrl": "https://checkout/session/test",
        "status": "awaiting_payment",
    }

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status FROM payments"
    ).fetchone()
    conn.close()

    assert row == (
        "origna_team",
        "client@example.com",
        "cs_test_123",
        "awaiting_payment",
        None,
        None,
    )


def test_stripe_webhook_completed_payment_updates_status_and_sends_email(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    sent = {}
    monkeypatch.setattr(
        backend_app,
        "send_mailjet_email",
        lambda to_email, subject, html_body, text_body: sent.update(
            {
                "to_email": to_email,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
            }
        ),
    )
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "mj_key")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "mj_secret")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_1",
            "origna_team",
            "client@example.com",
            "cs_team_done",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_checkout_completed",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_team_done",
                "mode": "subscription",
                "customer_email": "client@example.com",
                "subscription": "sub_123",
                "metadata": {"service_code": "origna_team", "client_email": "client@example.com"},
            }
        },
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT status, subscription_id FROM payments WHERE stripe_session_id = ?",
        ("cs_team_done",),
    ).fetchone()
    event_row = conn.execute(
        "SELECT id, event_type FROM webhook_events WHERE id = ?",
        ("evt_checkout_completed",),
    ).fetchone()
    conn.close()

    assert row == ("paid", "sub_123")
    assert event_row == ("evt_checkout_completed", "checkout.session.completed")
    assert sent["to_email"] == "client@example.com"
    assert "Subscription confirmed" in sent["subject"]


def test_stripe_webhook_completed_one_time_payment_keeps_subscription_null(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    sent = {}
    monkeypatch.setattr(
        backend_app,
        "send_mailjet_email",
        lambda to_email, subject, html_body, text_body: sent.update(
            {
                "to_email": to_email,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
            }
        ),
    )
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "mj_key")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "mj_secret")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_launch_1",
            "origna_launch",
            "launch@example.com",
            "cs_launch_done",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_checkout_completed_launch",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_launch_done",
                "mode": "payment",
                "customer_email": "launch@example.com",
                "metadata": {
                    "service_code": "origna_launch",
                    "client_email": "launch@example.com",
                },
            }
        },
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT status, subscription_id, subscription_status FROM payments WHERE stripe_session_id = ?",
        ("cs_launch_done",),
    ).fetchone()
    conn.close()

    assert row == ("paid", None, None)
    assert sent["to_email"] == "launch@example.com"
    assert "Payment confirmed" in sent["subject"]


def test_stripe_webhook_checkout_session_expired_marks_payment_expired(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_expired",
            "origna_launch",
            "buyer@example.com",
            "cs_expired_123",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_checkout_expired",
        "type": "checkout.session.expired",
        "data": {"object": {"id": "cs_expired_123"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 200

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT status FROM payments WHERE stripe_session_id = ?",
        ("cs_expired_123",),
    ).fetchone()
    conn.close()

    assert row == ("expired",)


def test_stripe_webhook_duplicate_event_is_idempotent(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_duplicate",
            "origna_team",
            "buyer@example.com",
            "cs_duplicate_123",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_duplicate_once",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_duplicate_123",
                "mode": "subscription",
                "subscription": "sub_duplicate",
                "customer_email": "buyer@example.com",
                "metadata": {"service_code": "origna_team"},
            }
        },
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    first = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )
    second = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["status"] == "duplicate"

    conn = sqlite3.connect(db_path)
    payment_row = conn.execute(
        "SELECT status, subscription_id FROM payments WHERE stripe_session_id = ?",
        ("cs_duplicate_123",),
    ).fetchone()
    event_count = conn.execute(
        "SELECT COUNT(*) FROM webhook_events WHERE id = ?",
        ("evt_duplicate_once",),
    ).fetchone()
    conn.close()

    assert payment_row == ("paid", "sub_duplicate")
    assert event_count == (1,)


def test_stripe_webhook_invoice_payment_failed_marks_subscription_past_due(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_past_due",
            "origna_team",
            "buyer@example.com",
            "cs_past_due_123",
            "paid",
            "sub_past_due",
            "active",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_invoice_failed",
        "type": "invoice.payment_failed",
        "data": {"object": {"subscription": "sub_past_due"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 200

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT subscription_status FROM payments WHERE subscription_id = ?",
        ("sub_past_due",),
    ).fetchone()
    conn.close()

    assert row == ("past_due",)


def test_stripe_webhook_duplicate_event_is_idempotent(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    event = {
        "id": "evt_duplicate_case",
        "type": "totally.unknown.event",
        "data": {"object": {"id": "obj_1"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)
    headers = {"Stripe-Signature": signature, "Content-Type": "application/json"}

    first = test_client.post("/api/stripe/webhook", content=raw, headers=headers)
    second = test_client.post("/api/stripe/webhook", content=raw, headers=headers)

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["status"] == "duplicate"

    conn = sqlite3.connect(db_path)
    count = conn.execute("SELECT COUNT(*) FROM webhook_events WHERE id = ?", ("evt_duplicate_case",)).fetchone()[0]
    conn.close()
    assert count == 1


def test_stripe_webhook_invoice_payment_failed_sets_subscription_past_due(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_2",
            "origna_team",
            "client@example.com",
            "cs_team_active",
            "paid",
            "sub_past_due",
            "active",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_invoice_failed",
        "type": "invoice.payment_failed",
        "data": {"object": {"subscription": "sub_past_due"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 200

    conn = sqlite3.connect(db_path)
    status = conn.execute(
        "SELECT subscription_status FROM payments WHERE subscription_id = ?",
        ("sub_past_due",),
    ).fetchone()[0]
    conn.close()
    assert status == "past_due"


def test_stripe_webhook_malformed_json_returns_400_not_500(client, monkeypatch):
    test_client, _ = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    raw = b'{"id":"evt_bad_json","type":"checkout.session.completed"'
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid JSON payload"
