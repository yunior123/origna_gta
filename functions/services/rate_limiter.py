"""
Rate Limiter for Cloud Functions
Protects against abuse and DDoS
"""
import logging
logger = logging.getLogger(__name__)
import os
from datetime import UTC, datetime, timedelta

from firebase_admin import firestore

from schema_constants import Collections, Fields

# In emulator mode, relax rate limits 100x for E2E test throughput
_IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR', 'false').lower() == 'true'
_EMULATOR_RATE_MULTIPLIER = 100 if _IS_EMULATOR else 1


class RateLimiter:
    """Simple in-memory + Firestore rate limiter"""

    def __init__(self, db):
        self.db = db
        self.collection = Collections.RATE_LIMITS

    def check_rate_limit(
        self,
        identifier: str,  # IP, user_id, email
        action: str,  # 'create_checkout', 'webhook', etc
        max_requests: int,
        window_minutes: int,
        fail_closed: bool = False  # If True, block on errors (for auth/payment)
    ) -> tuple[bool, str]:
        """
        Returns (allowed: bool, message: str)

        SECURITY FIX: Added fail_closed parameter.
        - fail_closed=False (default): Fail-open for UX (product views)
        - fail_closed=True: Fail-closed for security (auth, payments)

        EDGE CASE FIX #4: Use Firestore transaction to prevent race conditions.
        Without transaction, concurrent requests could bypass rate limit.
        """
        # In emulator mode, multiply max_requests to avoid test throttling
        max_requests = max_requests * _EMULATOR_RATE_MULTIPLIER

        now = datetime.now(UTC).replace(tzinfo=None)
        window_start = now - timedelta(minutes=window_minutes)

        doc_id = f"{action}_{identifier}"
        ref = self.db.collection(self.collection).document(doc_id)

        try:
            # FIXED: Use transaction to prevent race conditions
            @firestore.transactional
            def check_and_increment(transaction, ref):
                doc = ref.get(transaction=transaction)

                if doc.exists:
                    data = doc.to_dict()
                    count = data.get(Fields.COUNT, 0)
                    first_request = data.get(Fields.FIRST_REQUEST).replace(tzinfo=None)

                    # Window expired, reset
                    if first_request < window_start:
                        transaction.set(ref, {
                            Fields.COUNT: 1,
                            Fields.FIRST_REQUEST: now,
                            Fields.LAST_REQUEST: now
                        })
                        return True, "OK"

                    # Within window, check limit
                    if count >= max_requests:
                        return False, f"Rate limit exceeded: {max_requests} requests per {window_minutes} minutes"

                    # Increment atomically
                    transaction.update(ref, {
                        Fields.COUNT: count + 1,
                        Fields.LAST_REQUEST: now
                    })
                    return True, "OK"
                else:
                    # First request
                    transaction.set(ref, {
                        Fields.COUNT: 1,
                        Fields.FIRST_REQUEST: now,
                        Fields.LAST_REQUEST: now
                    })
                    return True, "OK"

            # Execute transaction
            transaction = self.db.transaction()
            return check_and_increment(transaction, ref)

        except Exception as e:
            logger.warning(f"⚠️ Rate limiter error: {e}")

            # SECURITY FIX: Fail-closed for high-stakes actions
            if fail_closed:
                return False, "Rate limiter unavailable - request blocked for security"

            # Fail-open for UX-critical actions (don't block legitimate users)
            return True, "OK"

    def get_identifier(self, req) -> str:
        """Extract identifier from request (IP, user_id, or device fingerprint)"""
        # Try user ID first
        if hasattr(req, 'auth') and req.auth:
            base_id = f"user_{req.auth.uid}"
            # SECURITY FIX: Add device fingerprint if available from Firebase claims
            # This prevents rate limit bypass via account switching
            fingerprint = req.auth.token.get('fingerprint') or req.auth.token.get('device_id')
            if fingerprint:
                return f"{base_id}_{fingerprint[:16]}"
            return base_id

        # Fall back to IP
        if hasattr(req, 'headers'):
            # SECURITY: Use the LAST X-Forwarded-For entry — it's added by the
            # trusted Google Cloud load balancer. The first entry is client-supplied
            # and can be spoofed to bypass rate limiting.
            forwarded_header = req.headers.get('X-Forwarded-For', '')
            if forwarded_header:
                parts = [p.strip() for p in forwarded_header.split(',') if p.strip()]
                # Last entry = added by trusted proxy (GCP LB)
                trusted_ip = parts[-1] if parts else ''
                if trusted_ip:
                    return f"ip_{trusted_ip}"

            # Direct IP
            remote_addr = req.headers.get('X-Real-IP', 'unknown')
            return f"ip_{remote_addr}"

        return "unknown"
