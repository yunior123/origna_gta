import jwt
import time

secret = "REDACTED_SECRET"
now = int(time.time())

payload = {
    "sub": "admin-id-123",
    "iat": now,
    "exp": now + 3600,
    "roles": ["admin", "seller"],
    "typ": "access",
    "email_verified": True,
    "mfa_required": False
}

token = jwt.encode(payload, secret, algorithm="HS256")
print(f"Generated Admin Token: {token}")
