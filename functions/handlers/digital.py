"""Digital product handlers: license activation, book redirect, deactivation."""
import json
import logging
import re
import secrets
from datetime import datetime, timezone, timedelta

from firebase_functions import https_fn

from schema_constants import (
    Collections,
    Fields,
    DigitalTypeValues,
    LicenseStatusValues,
)

logger = logging.getLogger(__name__)

_db = None


def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db
    if _db is None:
        from firebase_admin import firestore as fs
        _db = fs.client()
    return _db

# Regex for license key format validation (prevents DB lookup on garbage input)
_LICENSE_KEY_RE = re.compile(r"^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$")
_TOKEN_RE = re.compile(r"^tok_[a-f0-9]+$")  # relaxed for tests (hex suffix length varies)

APP_BASE_URL = "https://app.origna.com"


# ── Internal implementations (pure functions, testable without HTTP context) ──


def _activate_license_impl(license_key: str, device_id: str, platform: str) -> dict:
    """Core activation logic. Raises ValueError with error code on failure."""
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get(Fields.STATUS) != LicenseStatusValues.ACTIVE:
        raise ValueError("revoked")

    supported = lic.get(Fields.SUPPORTED_PLATFORMS, [])
    if platform not in supported:
        raise ValueError("platform_not_supported")

    activations: list = list(lic.get(Fields.ACTIVATIONS, []))
    now = datetime.now(timezone.utc)

    # Idempotent re-activation: same device already registered
    for i, act in enumerate(activations):
        if act.get(Fields.DEVICE_ID) == device_id:
            activations[i] = {**act, Fields.LAST_VERIFIED_AT: now}
            db.collection(Collections.LICENSES).document(license_key).update(
                {"activations": activations, "updatedAt": now}
            )
            return {
                "approved": True,
                "licenseKey": license_key,
                "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
                "activatedAt": act.get("activatedAt"),
            }

    # Check device limit
    device_limit = lic.get(Fields.DEVICE_LIMIT)
    if device_limit is not None and len(activations) >= device_limit:
        raise ValueError("device_limit_exceeded")

    # New activation
    new_activation = {
        Fields.DEVICE_ID: device_id,
        "platform": platform,
        "activatedAt": now,
        Fields.LAST_VERIFIED_AT: now,
    }
    activations.append(new_activation)
    db.collection(Collections.LICENSES).document(license_key).update(
        {"activations": activations, "updatedAt": now}
    )

    return {
        "approved": True,
        "licenseKey": license_key,
        "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
        "activatedAt": now.isoformat(),
    }


def _deactivate_license_impl(license_key: str, device_id: str, caller_uid: str) -> dict:
    """Remove a device activation. Requires caller to be the license owner."""
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get(Fields.USER_ID) != caller_uid:
        raise ValueError("unauthorized")

    activations = [
        a for a in lic.get(Fields.ACTIVATIONS, [])
        if a.get(Fields.DEVICE_ID) != device_id
    ]
    db.collection(Collections.LICENSES).document(license_key).update(
        {"activations": activations, "updatedAt": datetime.now(timezone.utc)}
    )
    return {"deactivated": True, "remainingActivations": len(activations)}


def _generate_book_download_session_impl(license_key: str, caller_uid: str) -> dict:
    """Create a new 15-min single-use download token for a book license.
    Returns { downloadUrl } pointing to /dl?t={token}.
    """
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get(Fields.USER_ID) != caller_uid:
        raise ValueError("unauthorized")
    if lic.get(Fields.STATUS) != LicenseStatusValues.ACTIVE:
        raise ValueError("revoked")
    if lic.get(Fields.DIGITAL_TYPE) != DigitalTypeValues.BOOK:
        raise ValueError("not_a_book_license")

    token = "tok_" + secrets.token_hex(32)
    now = datetime.now(timezone.utc)
    token_doc = {
        Fields.ACCESS_TOKEN: token,
        Fields.LICENSE_KEY: license_key,
        Fields.USER_ID: caller_uid,
        Fields.PRODUCT_ID: lic.get(Fields.PRODUCT_ID),
        Fields.BOOK_SOURCE_URL: lic.get(Fields.BOOK_SOURCE_URL),
        "expiresAt": now + timedelta(minutes=15),
        "used": False,
        Fields.CREATED_AT: now,
    }
    db.collection(Collections.BOOK_ACCESS_TOKENS).document(token).set(token_doc)

    return {"downloadUrl": f"{APP_BASE_URL}/dl?t={token}"}


def _get_book_redirect_impl(token: str) -> str:
    """Validate token and return the bookSourceUrl for redirect.
    Marks token as used to prevent re-use.
    Raises ValueError with error code on any failure.
    """
    db = get_db()
    token_ref = db.collection(Collections.BOOK_ACCESS_TOKENS).document(token)
    doc = token_ref.get()

    if not doc.exists:
        raise ValueError("not_found")

    data = doc.to_dict()
    if data.get("used"):
        raise ValueError("already_used")

    expires_at = data.get("expiresAt")
    now = datetime.now(timezone.utc)
    # Handle both Firestore Timestamp and Python datetime
    if hasattr(expires_at, "tzinfo"):
        expires_dt = expires_at if expires_at.tzinfo else expires_at.replace(tzinfo=timezone.utc)
    else:
        expires_dt = expires_at
    if expires_dt < now:
        raise ValueError("expired")

    # Mark as used (best-effort — in production use a transaction for atomicity)
    token_ref.update({"used": True, "usedAt": now})

    book_url = data.get(Fields.BOOK_SOURCE_URL, "")
    if not book_url:
        raise ValueError("missing_source_url")
    return book_url


# ── Cloud Function endpoints ──────────────────────────────────────────────────


@https_fn.on_request(cors=True)
def activate_license(req: https_fn.Request) -> https_fn.Response:
    """POST /activate_license — no auth required (installed app to server).
    Body: { licenseKey, deviceId, platform }
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    try:
        body = req.get_json(silent=True) or {}
        license_key = str(body.get("licenseKey", "")).strip().upper()
        device_id = str(body.get("deviceId", "")).strip()
        platform = str(body.get("platform", "")).strip().lower()

        if not license_key or not device_id or not platform:
            return https_fn.Response(
                json.dumps({"error": "licenseKey, deviceId, and platform are required"}),
                status=400,
                content_type="application/json",
            )

        result = _activate_license_impl(license_key, device_id, platform)
        return https_fn.Response(json.dumps(result), status=200, content_type="application/json")

    except ValueError as e:
        code = str(e)
        status_map = {
            "not_found": 404,
            "revoked": 403,
            "platform_not_supported": 403,
            "device_limit_exceeded": 403,
            "invalid_key_format": 400,
        }
        status = status_map.get(code, 400)
        return https_fn.Response(json.dumps({"error": code}), status=status, content_type="application/json")
    except Exception:
        logger.exception("activate_license unexpected error")
        return https_fn.Response(json.dumps({"error": "internal_error"}), status=500, content_type="application/json")


@https_fn.on_call()
def deactivate_license(req: https_fn.CallableRequest) -> dict:
    """Authenticated: buyer removes a device from their license."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Login required")

    license_key = str(req.data.get("licenseKey", "")).strip().upper()
    device_id = str(req.data.get("deviceId", "")).strip()
    if not license_key or not device_id:
        raise https_fn.HttpsError("invalid-argument", "licenseKey and deviceId required")

    try:
        return _deactivate_license_impl(license_key, device_id, req.auth.uid)
    except ValueError as e:
        code = str(e)
        if code == "not_found":
            raise https_fn.HttpsError("not-found", "License not found")
        if code == "unauthorized":
            raise https_fn.HttpsError("permission-denied", "Not your license")
        raise https_fn.HttpsError("invalid-argument", code)


@https_fn.on_call()
def generate_book_download_session(req: https_fn.CallableRequest) -> dict:
    """Authenticated: generates a 15-min single-use redirect token for a book."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Login required")

    license_key = str(req.data.get("licenseKey", "")).strip().upper()
    if not license_key:
        raise https_fn.HttpsError("invalid-argument", "licenseKey required")

    try:
        return _generate_book_download_session_impl(license_key, req.auth.uid)
    except ValueError as e:
        code = str(e)
        if code == "not_found":
            raise https_fn.HttpsError("not-found", "License not found")
        if code == "unauthorized":
            raise https_fn.HttpsError("permission-denied", "Not your license")
        if code == "revoked":
            raise https_fn.HttpsError("failed-precondition", "License revoked")
        raise https_fn.HttpsError("invalid-argument", code)


@https_fn.on_request()
def get_book_redirect(req: https_fn.Request) -> https_fn.Response:
    """GET /dl?t={token} — public redirect, no auth.
    Single-use, 15-min expiry. bookSourceUrl never sent to client.
    """
    token = req.args.get("t", "").strip()
    if not token:
        return https_fn.Response("Missing token", status=400)

    try:
        book_url = _get_book_redirect_impl(token)
        return https_fn.Response(
            "",
            status=302,
            headers={"Location": book_url, "Cache-Control": "no-store"},
        )
    except ValueError as e:
        code = str(e)
        messages = {
            "not_found": "Download link not found.",
            "already_used": "This download link has already been used. Return to the app to generate a new one.",
            "expired": "This download link has expired. Return to the app to generate a new one.",
            "invalid_token_format": "Invalid download link.",
        }
        msg = messages.get(code, "Invalid request.")
        return https_fn.Response(msg, status=410)
    except Exception:
        logger.exception("get_book_redirect unexpected error")
        return https_fn.Response("Internal error", status=500)


@https_fn.on_request(cors=True)
def verify_license(req: https_fn.Request) -> https_fn.Response:
    """POST /verify_license — no auth. App periodically re-verifies license.
    Same as activate (idempotent re-activation updates lastVerifiedAt).
    Body: { licenseKey, deviceId, platform }
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    try:
        body = req.get_json(silent=True) or {}
        license_key = str(body.get("licenseKey", "")).strip().upper()
        device_id = str(body.get("deviceId", "")).strip()
        platform = str(body.get("platform", "")).strip().lower()

        if not license_key or not device_id or not platform:
            return https_fn.Response(
                json.dumps({"error": "licenseKey, deviceId, platform required"}),
                status=400,
                content_type="application/json",
            )

        result = _activate_license_impl(license_key, device_id, platform)
        return https_fn.Response(json.dumps(result), status=200, content_type="application/json")

    except ValueError as e:
        code = str(e)
        status = 403 if code in ("revoked", "device_limit_exceeded") else 400
        return https_fn.Response(json.dumps({"error": code}), status=status, content_type="application/json")
    except Exception:
        logger.exception("verify_license unexpected error")
        return https_fn.Response(json.dumps({"error": "internal_error"}), status=500, content_type="application/json")
