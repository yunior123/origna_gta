from __future__ import annotations

import hashlib
import hmac
import io
import json
import sqlite3
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient
from pypdf import PdfReader

sys.path.append(str(Path(__file__).resolve().parents[1]))
import app as backend_app


def sign_stripe_payload(
    secret: str, raw_body: bytes, timestamp: int | None = None
) -> str:
    timestamp = timestamp or int(time.time())
    signed_payload = f"{timestamp}.".encode("utf-8") + raw_body
    digest = hmac.new(
        secret.encode("utf-8"), signed_payload, hashlib.sha256
    ).hexdigest()
    return f"t={timestamp},v1={digest}"


def ensure_payments_table(db_path: Path) -> None:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    backend_app.ensure_payments_table(conn)
    conn.commit()
    conn.close()


@pytest.fixture()
def client(tmp_path, monkeypatch):
    db_path = tmp_path / "origna_ventures_test.db"
    storage_dir = tmp_path / "storage"
    storage_dir.mkdir(parents=True, exist_ok=True)

    monkeypatch.setattr(backend_app.settings, "sqlite_path", str(db_path))
    monkeypatch.setattr(backend_app.settings, "storage_dir", str(storage_dir))
    monkeypatch.setattr(backend_app, "_email_queue_sync_mode", True)
    backend_app.init_db()
    ensure_payments_table(db_path)

    with TestClient(backend_app.app) as test_client:
        yield test_client, db_path


def test_create_checkout_session_one_time_payload_uses_stripe_tax_and_klarna(
    monkeypatch,
):
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
    assert payload["customer_creation"] == "always"
    assert payload["payment_method_types[0]"] == "card"
    assert payload["payment_method_types[1]"] == "klarna"
    assert payload["automatic_tax[enabled]"] == "true"
    assert payload["tax_id_collection[enabled]"] == "true"
    assert payload["line_items[0][price_data][unit_amount]"] == "300000"
    assert "line_items[1][price_data][unit_amount]" not in payload
    assert payload["metadata[service_code]"] == "origna_launch"
    assert payload["customer_email"] == "buyer@example.com"
    assert payload["metadata[client_email]"] == "buyer@example.com"
    assert captured["headers"]["Idempotency-Key"].startswith("checkout:origna_launch:")
    assert (
        captured["headers"]["Idempotency-Key"]
        != "checkout:origna_launch:buyer@example.com"
    )


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
        "en",
        4,
    )

    payload = captured["data"]
    assert payload["mode"] == "subscription"
    assert payload["automatic_tax[enabled]"] == "true"
    assert payload["tax_id_collection[enabled]"] == "true"
    assert payload["line_items[0][price_data][unit_amount]"] == "100000"
    assert payload["line_items[0][price_data][recurring][interval]"] == "month"
    assert payload["line_items[0][quantity]"] == "4"
    assert payload["subscription_data[metadata][service_code]"] == "origna_team"
    assert payload["subscription_data[metadata][developer_count]"] == "4"
    assert payload["metadata[developer_count]"] == "4"
    assert "submit_type" not in payload
    assert "customer_creation" not in payload
    assert "payment_method_types[1]" not in payload
    assert "line_items[1][price_data][unit_amount]" not in payload


def test_create_checkout_session_without_email_uses_fresh_idempotency_key(monkeypatch):
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
    assert captured["headers"]["Idempotency-Key"].startswith("checkout:origna_code:")
    assert captured["headers"]["Idempotency-Key"] != "checkout:origna_code:anon"


def test_create_checkout_session_accepts_explicit_idempotency_key(monkeypatch):
    captured = {}

    def fake_post(url, headers, data, timeout):
        captured["headers"] = headers
        return SimpleNamespace(
            raise_for_status=lambda: None,
            json=lambda: {
                "id": "cs_code_explicit",
                "url": "https://checkout/code-explicit",
            },
        )

    monkeypatch.setattr(backend_app.requests, "post", fake_post)
    monkeypatch.setattr(backend_app.settings, "stripe_secret_key", "STRIPE_SECRET_KEY_REDACTED")

    backend_app.create_checkout_session_from_service(
        "origna_code",
        backend_app.SERVICE_CATALOG["origna_code"],
        "buyer@example.com",
        "en",
        1,
        "checkout:origna_code:explicit-token",
    )

    assert (
        captured["headers"]["Idempotency-Key"] == "checkout:origna_code:explicit-token"
    )


def test_create_checkout_session_repeated_calls_generate_fresh_idempotency_keys(
    monkeypatch,
):
    captured_headers = []

    def fake_post(url, headers, data, timeout):
        captured_headers.append(dict(headers))
        return SimpleNamespace(
            raise_for_status=lambda: None,
            json=lambda: {
                "id": f"cs_{len(captured_headers)}",
                "url": "https://checkout/repeat",
            },
        )

    monkeypatch.setattr(backend_app.requests, "post", fake_post)
    monkeypatch.setattr(backend_app.settings, "stripe_secret_key", "STRIPE_SECRET_KEY_REDACTED")

    backend_app.create_checkout_session_from_service(
        "origna_launch",
        backend_app.SERVICE_CATALOG["origna_launch"],
        "repeat@example.com",
    )
    backend_app.create_checkout_session_from_service(
        "origna_launch",
        backend_app.SERVICE_CATALOG["origna_launch"],
        "repeat@example.com",
    )

    assert len(captured_headers) == 2
    first_key = captured_headers[0]["Idempotency-Key"]
    second_key = captured_headers[1]["Idempotency-Key"]
    assert first_key.startswith("checkout:origna_launch:")
    assert second_key.startswith("checkout:origna_launch:")
    assert first_key != second_key


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
        lambda service_code, service, payer_email=None, locale="en", idempotency_key=None: {
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
        "SELECT service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, developer_count FROM payments"
    ).fetchone()
    conn.close()

    assert row == (
        "origna_team",
        "client@example.com",
        "cs_test_123",
        "awaiting_payment",
        None,
        None,
        1,
    )


def test_payment_session_persists_origna_team_developer_count(client, monkeypatch):
    test_client, db_path = client

    monkeypatch.setattr(
        backend_app,
        "create_checkout_session_from_service",
        lambda service_code, service, payer_email=None, locale="en", developer_count=1, idempotency_key=None: {
            "id": "cs_team_4",
            "url": "https://checkout/session/team-4",
        },
    )

    response = test_client.post(
        "/api/payments/create-checkout-session",
        json={
            "service_code": "origna_team",
            "payment_provider": "stripe",
            "payer_email": "team@example.com",
            "developer_count": 4,
        },
    )

    assert response.status_code == 200

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT service_code, developer_count, stripe_session_id FROM payments WHERE stripe_session_id = ?",
        ("cs_team_4",),
    ).fetchone()
    conn.close()

    assert row == ("origna_team", 4, "cs_team_4")


def test_payment_session_rejects_developer_count_for_non_team_service(client):
    test_client, _ = client

    response = test_client.post(
        "/api/payments/create-checkout-session",
        json={
            "service_code": "origna_code",
            "payment_provider": "stripe",
            "developer_count": 2,
        },
    )

    assert response.status_code == 400
    assert (
        response.json()["detail"] == "developer_count is only supported for OrignaTeam"
    )


def test_stripe_webhook_completed_payment_updates_status_and_sends_email(
    client, monkeypatch
):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    sent_emails = []
    monkeypatch.setattr(
        backend_app,
        "try_send_mailjet_email",
        lambda to_email, subject, html_body, text_body, attachments=None: (
            sent_emails.append(
                {
                    "to_email": to_email,
                    "subject": subject,
                    "html_body": html_body,
                    "text_body": text_body,
                    "attachments": attachments,
                }
            )
            or {"status": "sent"}
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
                "metadata": {
                    "service_code": "origna_team",
                    "client_email": "client@example.com",
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
    receipt_emails = [e for e in sent_emails if e["to_email"] == "client@example.com"]
    support_emails = [
        e for e in sent_emails if e["to_email"] == backend_app.settings.support_email
    ]
    assert len(receipt_emails) == 1
    assert "Subscription receipt" in receipt_emails[0]["subject"]
    assert receipt_emails[0]["attachments"]
    assert receipt_emails[0]["attachments"][0]["Filename"].endswith(".pdf")
    assert len(support_emails) == 1
    assert "Tier payment received" in support_emails[0]["subject"]
    assert support_emails[0]["attachments"] in (None, [])


def test_stripe_webhook_completed_payment_persists_tax_details(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_tax_1",
            "origna_launch",
            "finance@example.com",
            "cs_tax_done",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_checkout_completed_tax",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_tax_done",
                "mode": "payment",
                "customer": "cus_tax_123",
                "customer_email": "finance@example.com",
                "amount_subtotal": 300000,
                "amount_total": 339000,
                "total_details": {"amount_tax": 39000},
                "customer_details": {
                    "business_name": "Example Corp",
                    "tax_ids": [{"type": "ca_gst_hst", "value": "123456789RT0002"}],
                },
                "metadata": {
                    "service_code": "origna_launch",
                    "client_email": "finance@example.com",
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

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        """
        SELECT status, stripe_customer_id, customer_business_name, customer_tax_id_json,
               amount_subtotal_cents, amount_tax_cents, amount_total_cents
        FROM payments
        WHERE stripe_session_id = ?
        """,
        ("cs_tax_done",),
    ).fetchone()
    conn.close()

    assert row == (
        "paid",
        "cus_tax_123",
        "Example Corp",
        '[{"type": "ca_gst_hst", "value": "123456789RT0002"}]',
        300000,
        39000,
        339000,
    )


def test_stripe_webhook_completed_one_time_payment_keeps_subscription_null(
    client, monkeypatch
):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    sent_emails = []
    monkeypatch.setattr(
        backend_app,
        "try_send_mailjet_email",
        lambda to_email, subject, html_body, text_body, attachments=None: (
            sent_emails.append(
                {
                    "to_email": to_email,
                    "subject": subject,
                    "html_body": html_body,
                    "text_body": text_body,
                    "attachments": attachments,
                }
            )
            or {"status": "sent"}
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
    receipt_emails = [e for e in sent_emails if e["to_email"] == "launch@example.com"]
    support_emails = [
        e for e in sent_emails if e["to_email"] == backend_app.settings.support_email
    ]
    assert len(receipt_emails) == 1
    assert "Payment receipt" in receipt_emails[0]["subject"]
    assert receipt_emails[0]["attachments"]
    assert receipt_emails[0]["attachments"][0]["Filename"].endswith(".pdf")
    assert len(support_emails) == 1
    assert "Tier payment received" in support_emails[0]["subject"]
    assert support_emails[0]["attachments"] in (None, [])


def test_stripe_webhook_checkout_session_expired_marks_payment_expired(
    client, monkeypatch
):
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


def test_stripe_webhook_invoice_payment_failed_marks_subscription_past_due(
    client, monkeypatch
):
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


def test_stripe_webhook_duplicate_unknown_event_is_idempotent(client, monkeypatch):
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
    count = conn.execute(
        "SELECT COUNT(*) FROM webhook_events WHERE id = ?", ("evt_duplicate_case",)
    ).fetchone()[0]
    conn.close()
    assert count == 1


def test_stripe_webhook_invoice_payment_failed_sets_subscription_past_due(
    client, monkeypatch
):
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


def test_email_queue_persists_to_db_on_checkout_completed(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_eq_1",
            "origna_team",
            "queue@example.com",
            "cs_eq_test",
            "awaiting_payment",
            None,
            None,
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_eq_checkout",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_eq_test",
                "mode": "subscription",
                "customer_email": "queue@example.com",
                "subscription": "sub_eq_1",
                "metadata": {
                    "service_code": "origna_team",
                    "client_email": "queue@example.com",
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

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    queued = conn.execute(
        "SELECT * FROM email_queue WHERE to_email = ?", ("queue@example.com",)
    ).fetchall()
    support_queued = conn.execute(
        "SELECT * FROM email_queue WHERE to_email = ?",
        (backend_app.settings.support_email,),
    ).fetchall()
    conn.close()

    assert len(queued) >= 1
    assert queued[0]["status"] in ("sent", "skipped", "pending", "failed")
    assert len(support_queued) >= 1


def test_email_queue_retry_moves_to_dead_letter(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "mj_key")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "mj_secret")

    fail_count = {"n": 0}

    def fail_sender(*args, **kwargs):
        fail_count["n"] += 1
        return {"status": "failed", "reason": "simulated_failure"}

    monkeypatch.setattr(backend_app, "try_send_mailjet_email", fail_sender)

    email_ids = backend_app.enqueue_email_jobs(
        [
            {
                "to_email": "dead@example.com",
                "subject": "Will fail",
                "html_body": "<p>fail</p>",
                "text_body": "fail",
            }
        ]
    )
    assert len(email_ids) == 1

    for _ in range(backend_app._EMAIL_MAX_RETRIES):
        backend_app.retry_failed_emails()

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    row = conn.execute(
        "SELECT status, retry_count FROM email_queue WHERE id = ?", (email_ids[0],)
    ).fetchone()
    conn.close()

    assert row["status"] == backend_app._EMAIL_STATUS_DEAD
    assert row["retry_count"] >= backend_app._EMAIL_MAX_RETRIES


def test_webhook_price_mismatch_logs_warning(client, monkeypatch, caplog):
    import logging

    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (
            "pay_price_1",
            "origna_launch",
            "price@example.com",
            "cs_price_mismatch",
            "awaiting_payment",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    expected_cents = backend_app.SERVICE_CATALOG["origna_launch"]["price_cad"] * 100

    event = {
        "id": "evt_price_mismatch",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_price_mismatch",
                "mode": "payment",
                "customer_email": "price@example.com",
                "amount_subtotal": expected_cents + 9999,
                "amount_tax": None,
                "amount_total": None,
                "metadata": {"service_code": "origna_launch"},
            }
        },
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    with caplog.at_level(logging.WARNING, logger=backend_app.logger.name):
        response = test_client.post(
            "/api/stripe/webhook",
            content=raw,
            headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
        )

    assert response.status_code == 200
    assert any("price mismatch" in r.message.lower() for r in caplog.records)


def test_webhook_subscription_deleted_sends_lifecycle_email(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    sent_emails = []
    monkeypatch.setattr(
        backend_app,
        "try_send_mailjet_email",
        lambda to_email, subject, html_body, text_body, attachments=None: (
            sent_emails.append(
                {
                    "to_email": to_email,
                    "subject": subject,
                    "html_body": html_body,
                    "text_body": text_body,
                    "attachments": attachments,
                }
            )
            or {"status": "sent"}
        ),
    )
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "mj_key")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "mj_secret")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, locale, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_sub_del",
            "origna_team",
            "subdel@example.com",
            "cs_sub_del_session",
            "paid",
            "sub_del_1",
            "active",
            "en",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_sub_deleted",
        "type": "customer.subscription.deleted",
        "data": {"object": {"id": "sub_del_1", "status": "canceled"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )
    assert response.status_code == 200

    lifecycle_emails = [
        e
        for e in sent_emails
        if "canceled" in e["subject"].lower() or "annulé" in e["subject"]
    ]
    assert len(lifecycle_emails) >= 1
    assert "sub_del_1" in lifecycle_emails[0]["text_body"]


def test_webhook_invoice_payment_failed_sends_lifecycle_email(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")
    sent_emails = []
    monkeypatch.setattr(
        backend_app,
        "try_send_mailjet_email",
        lambda to_email, subject, html_body, text_body, attachments=None: (
            sent_emails.append(
                {
                    "to_email": to_email,
                    "subject": subject,
                    "html_body": html_body,
                    "text_body": text_body,
                    "attachments": attachments,
                }
            )
            or {"status": "sent"}
        ),
    )
    monkeypatch.setattr(backend_app.settings, "mailjet_api_key", "mj_key")
    monkeypatch.setattr(backend_app.settings, "mailjet_secret_key", "mj_secret")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, subscription_id, subscription_status, locale, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (
            "pay_inv_fail",
            "origna_team",
            "invfail@example.com",
            "cs_inv_fail_session",
            "paid",
            "sub_inv_fail",
            "active",
            "en",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_inv_fail_lifecycle",
        "type": "invoice.payment_failed",
        "data": {"object": {"subscription": "sub_inv_fail"}},
    }
    raw = json.dumps(event).encode("utf-8")
    signature = sign_stripe_payload("STRIPE_WEBHOOK_SECRET_REDACTED", raw)

    response = test_client.post(
        "/api/stripe/webhook",
        content=raw,
        headers={"Stripe-Signature": signature, "Content-Type": "application/json"},
    )
    assert response.status_code == 200

    lifecycle_emails = [
        e for e in sent_emails if e["to_email"] == "invfail@example.com"
    ]
    assert len(lifecycle_emails) >= 1
    assert (
        "failed" in lifecycle_emails[0]["subject"].lower()
        or "past due" in lifecycle_emails[0]["subject"].lower()
    )


def test_render_subscription_lifecycle_email_french():
    subject, html, text = backend_app.render_subscription_lifecycle_email(
        locale="fr",
        service_code="origna_team",
        subscription_id="sub_fr_1",
        new_status="canceled",
        event_type=backend_app._WEBHOOK_EVENT_SUBSCRIPTION_DELETED,
    )
    assert "annulé" in subject.lower()
    assert "sub_fr_1" in text
    assert "Origna Ventures" in subject


def test_render_subscription_lifecycle_email_spanish():
    subject, html, text = backend_app.render_subscription_lifecycle_email(
        locale="es",
        service_code="origna_team",
        subscription_id="sub_es_1",
        new_status=backend_app._SUBSCRIPTION_STATUS_PAST_DUE,
        event_type=backend_app._WEBHOOK_EVENT_INVOICE_PAYMENT_FAILED,
    )
    assert "Origna Ventures" in subject
    assert "sub_es_1" in text
    assert "Payment failed" in text or "past due" in text.lower()


def test_webhook_checkout_expired_updates_status(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(backend_app.settings, "stripe_webhook_secret", "STRIPE_WEBHOOK_SECRET_REDACTED")

    conn = sqlite3.connect(db_path)
    conn.execute(
        "INSERT INTO payments (id, service_code, payer_email, stripe_session_id, status, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (
            "pay_expired_1",
            "origna_code",
            "expired@example.com",
            "cs_expired_test",
            "awaiting_payment",
            backend_app.utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    event = {
        "id": "evt_expired_test",
        "type": "checkout.session.expired",
        "data": {"object": {"id": "cs_expired_test"}},
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
        "SELECT status FROM payments WHERE stripe_session_id = ?", ("cs_expired_test",)
    ).fetchone()
    conn.close()
    assert row == ("expired",)


def test_payment_session_operational_error_returns_503(client, monkeypatch):
    test_client, db_path = client
    monkeypatch.setattr(
        backend_app,
        "create_checkout_session_from_service",
        lambda service_code, service, payer_email=None, locale="en", developer_count=1, idempotency_key=None: {
            "id": "cs_flaky",
            "url": "https://checkout/flaky",
        },
    )

    def broken_db():
        raise backend_app.sqlite3.OperationalError("database is locked")

    monkeypatch.setattr(backend_app, "db", broken_db)

    response = test_client.post(
        "/api/payments/create-checkout-session",
        json={"service_code": "origna_code", "email": "flaky@example.com"},
    )
    assert response.status_code == 503
    assert "temporary" in response.json()["detail"].lower()


def _extract_pdf_text(pdf_bytes: bytes) -> str:
    reader = PdfReader(io.BytesIO(pdf_bytes))
    pages = []
    for page in reader.pages:
        text = page.extract_text()
        if text:
            pages.append(text)
    return "\n".join(pages)


def test_generate_receipt_pdf_contains_business_details():
    pdf_bytes = backend_app.generate_receipt_pdf(
        locale="en",
        service_code="origna_launch",
        subtotal_cents=300000,
        tax_cents=None,
        total_cents=None,
        is_subscription=False,
        stripe_session_id="cs_test_pdf_1",
    )
    text = _extract_pdf_text(pdf_bytes)
    assert backend_app.settings.company_legal_name in text
    assert backend_app.settings.company_bn in text
    assert "Invoice number" in text
    assert "CA$3,000.00" in text


def test_generate_receipt_pdf_french_labels():
    pdf_bytes = backend_app.generate_receipt_pdf(
        locale="fr",
        service_code="origna_team",
        subtotal_cents=100000,
        tax_cents=None,
        total_cents=None,
        is_subscription=True,
        stripe_session_id="cs_test_pdf_fr",
        developer_count=3,
    )
    text = _extract_pdf_text(pdf_bytes)
    assert "Recu" in text
    assert "Sous-total" in text
    assert "Numero de facture" in text


def test_generate_receipt_pdf_spanish_labels():
    pdf_bytes = backend_app.generate_receipt_pdf(
        locale="es",
        service_code="origna_code",
        subtotal_cents=50000,
        tax_cents=5000,
        total_cents=55000,
        is_subscription=False,
        stripe_session_id="cs_test_pdf_es",
    )
    text = _extract_pdf_text(pdf_bytes)
    assert "Recibo de pago" in text
    assert "Subtotal" in text
    assert "Impuesto" in text
    assert "Numero de factura" in text
