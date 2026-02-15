#!/usr/bin/env python3
"""Set up test users in orignagta-dev Firestore."""
import json
import subprocess
import urllib.request
import urllib.error
import ssl
import certifi

PROJECT = "orignagta-dev"

def get_token():
    return subprocess.check_output(["gcloud", "auth", "print-access-token"]).decode().strip()

def create_user(uid, email, name, roles, extra_fields=None):
    token = get_token()
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/users/{uid}"
    fields = {
        "uid": {"stringValue": uid},
        "email": {"stringValue": email},
        "name": {"stringValue": name},
        "roles": {"arrayValue": {"values": [{"stringValue": r} for r in roles]}},
        "suspended": {"booleanValue": False},
        "consentTimestamp": {"timestampValue": "2025-01-01T00:00:00Z"},
        "termsAcceptedAt": {"timestampValue": "2025-01-01T00:00:00Z"},
        "privacyAcceptedAt": {"timestampValue": "2025-01-01T00:00:00Z"},
        "consentMethod": {"stringValue": "signup"},
        "dataProcessingConsent": {"booleanValue": True},
        "emailConsent": {"booleanValue": True},
        "marketingOptIn": {"booleanValue": False},
        "privacyPolicyVersion": {"stringValue": "1.0"},
        "termsVersion": {"stringValue": "1.0"},
        "preferredLanguage": {"stringValue": "en"},
        "createdAt": {"timestampValue": "2025-01-01T00:00:00Z"},
    }
    if extra_fields:
        fields.update(extra_fields)

    body = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(url, data=body, method="PATCH")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    ctx = ssl.create_default_context(cafile=certifi.where())
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            doc = json.loads(resp.read())
            r = [v["stringValue"] for v in doc["fields"]["roles"]["arrayValue"]["values"]]
            print(f"SUCCESS {email} - roles: {r}")
    except urllib.error.HTTPError as e:
        print(f"ERROR {e.code}: {e.read().decode()}")

# Seller/Admin user
create_user(
    uid="RU9MI8vYFkQCakMrJfG8iGTuc012",
    email="yr62813@gmail.com",
    name="Test Seller Admin",
    roles=["buyer", "seller", "admin"],
    extra_fields={
        "chargesEnabled": {"booleanValue": True},
        "payoutsEnabled": {"booleanValue": True},
        "onboardingCompleted": {"booleanValue": True},
    }
)

# Buyer user
create_user(
    uid="eVxwL5SfEATPnw1zhWYaUdGx8MD2",
    email="yuniorrodriguezo4601@yahoo.com",
    name="Test Buyer",
    roles=["buyer"],
)
