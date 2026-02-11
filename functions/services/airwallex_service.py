"""
Airwallex Payment Service - Complete Implementation
P2.1-P2.5: Account, Backend, Payment, Payout, Webhooks
"""
import logging
logger = logging.getLogger(__name__)
import base64
import hashlib
import hmac
import uuid
from datetime import datetime, timedelta
from typing import Any, Union

import requests

from config import (
    AIRWALLEX_API_KEY,
    AIRWALLEX_BASE_URL,
    AIRWALLEX_CLIENT_ID,
    AIRWALLEX_WEBHOOK_SECRET,
)
from schema_constants import (
    AppConfig,
    BusinessRules,
    Collections,
    Fields,
    PaymentProviderValues,
    PaymentStatusValues,
    PayoutStatusValues,
    SecurityAlertTypes,
    WebhookResponseStatus,
)


class AirwallexService:
    """Airwallex API Integration for international sellers"""

    def __init__(self):
        self.api_key = AIRWALLEX_API_KEY
        self.client_id = AIRWALLEX_CLIENT_ID
        self.webhook_secret = AIRWALLEX_WEBHOOK_SECRET
        self.base_url = AIRWALLEX_BASE_URL
        self.token = None
        self.token_expiry = None

    def _authenticate(self) -> str:
        """Get OAuth bearer token"""
        if not self.client_id or not self.api_key:
            raise ValueError("Airwallex API credentials not configured")
        if self.token and self.token_expiry and datetime.now() < self.token_expiry:
            return self.token

        # Airwallex auth uses API key + client id headers (scoped API key flow).
        # Token lifetime is typically 30 minutes; cache with a safety buffer.
        resp = requests.post(
            f"{self.base_url}/authentication/login",
            headers={
                "x-api-key": self.api_key,
                "x-client-id": self.client_id,
            },
            timeout=AppConfig.API_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        data = resp.json()
        self.token = data['token']
        self.token_expiry = datetime.now() + timedelta(minutes=AppConfig.TOKEN_CACHE_MINUTES)
        return self.token

    def _headers(self) -> dict[str, str]:
        """Get auth headers"""
        return {
            "Authorization": f"Bearer {self._authenticate()}",
            "Content-Type": "application/json"
        }

    # ===== P2.1: Account Creation =====
    def create_customer(self, seller_id: str, seller_data: dict[str, Any]) -> dict[str, Any]:
        """Create Airwallex customer for seller"""
        payload = {
            "customer_name": seller_data.get(Fields.BUSINESS_NAME, seller_data[Fields.FULL_NAME]),
            Fields.EMAIL: seller_data[Fields.EMAIL],
            "customer_type": "corporate" if seller_data.get(Fields.IS_CORPORATE) else "individual",
            Fields.COUNTRY: seller_data.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_CODE),
            "metadata": {"seller_id": seller_id}
        }

        resp = requests.post(
            f"{self.base_url}/customers",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    def create_connected_account(self, seller_id: str, seller_data: dict[str, Any]) -> dict[str, Any]:
        """Create connected account for seller payouts"""
        customer = self.create_customer(seller_id, seller_data)

        payload = {
            "customer_id": customer['id'],
            "account_type": "payout",
            Fields.COUNTRY: seller_data.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_CODE),
            Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY.upper(),
            "bank_details": seller_data.get(Fields.BANK_DETAILS, {})
        }

        resp = requests.post(
            f"{self.base_url}/connected_accounts",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    # ===== P2.2 & P2.3: Payment Flow =====
    def create_payment_intent_for_checkout(
        self,
        *,
        amount_cents: int,
        currency: str,
        order_id: str,
        return_url: str,
        capture: bool = False,
        metadata: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """
        Create Airwallex payment intent for checkout.

        NOTE: Airwallex APIs evolve; keep payload minimal and rely on `merchant_order_id`
        + metadata to correlate to Firestore orders.
        """
        if amount_cents < 0:
            raise ValueError("amount_cents must be non-negative")

        payload = {
            # Idempotency-style request id
            "request_id": f"order_{order_id}_{uuid.uuid4().hex[:10]}",
            Fields.AMOUNT: int(amount_cents),
            Fields.CURRENCY: str(currency).upper(),
            "merchant_order_id": str(order_id),
            "return_url": str(return_url),
            "capture": bool(capture),
            "metadata": {
                "order_id": str(order_id),
                "platform": AppConfig.PLATFORM_NAME,
                **(metadata or {}),
            },
        }

        resp = requests.post(
            f"{self.base_url}/pa/payment_intents/create",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        return resp.json()

    def create_payment_intent(self,
                            seller_id: str,
                            order_id: str,
                            amount_cents: int,
                            currency: str = '',
                            capture: bool = False) -> dict[str, Any]:
        """Create payment intent (authorize or capture)"""
        resolved_currency = (currency or BusinessRules.DEFAULT_CURRENCY).upper()
        payload = {
            Fields.AMOUNT: amount_cents,
            Fields.CURRENCY: resolved_currency,
            "merchant_id": seller_id,
            "order_id": order_id,
            "capture": capture,  # False = authorize only
            "metadata": {
                "order_id": order_id,
                "seller_id": seller_id,
                "platform": AppConfig.PLATFORM_NAME
            },
            "return_url": f"{AppConfig.PROD_WEB_URL}/order/{order_id}",
            "payment_method_options": {
                "card": {
                    "auto_capture": capture
                }
            }
        }

        resp = requests.post(
            f"{self.base_url}/payments/create",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    def capture_payment(self, payment_id: str, amount_cents: int | None = None) -> dict[str, Any]:
        """Capture previously authorized payment"""
        payload = {}
        if amount_cents:
            payload[Fields.AMOUNT] = amount_cents

        resp = requests.post(
            f"{self.base_url}/payments/{payment_id}/capture",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    def refund_payment(self, payment_id: str, amount_cents: int, reason: str = "") -> dict[str, Any]:
        """Refund payment (partial or full)"""
        payload = {
            Fields.AMOUNT: amount_cents,
            Fields.REASON: reason
        }

        resp = requests.post(
            f"{self.base_url}/payments/{payment_id}/refunds",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    def cancel_payment(self, payment_id: str) -> dict[str, Any]:
        """Cancel authorized payment before capture"""
        resp = requests.post(
            f"{self.base_url}/payments/{payment_id}/cancel",
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    # ===== P2.4: Payouts =====
    def create_payout(self,
                     seller_id: str,
                     amount_cents: int,
                     connected_account_id: str,
                     reference: str = "") -> dict[str, Any]:
        """Schedule payout to seller bank account"""
        payload = {
            "connected_account_id": connected_account_id,
            Fields.AMOUNT: amount_cents,
            Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY.upper(),
            "reference": reference or f"Payout to {seller_id}",
            "metadata": {"seller_id": seller_id}
        }

        resp = requests.post(
            f"{self.base_url}/payouts",
            json=payload,
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    def get_payout_status(self, payout_id: str) -> dict[str, Any]:
        """Check payout status"""
        resp = requests.get(
            f"{self.base_url}/payouts/{payout_id}",
            headers=self._headers(),
            timeout=AppConfig.API_TIMEOUT_SECONDS
        )
        resp.raise_for_status()
        return resp.json()

    # ===== P2.5: Webhooks & Error Handling =====
    def verify_webhook_signature(
        self,
        body: Union[str, bytes, bytearray],
        signature: str,
        *,
        timestamp: str | None = None,
    ) -> bool:
        """Verify webhook came from Airwallex.

        Per Airwallex docs, the signature is an HMAC-SHA256 digest (hex) of:
          `<timestamp><raw_body>`

        Notes:
        - Prefer verifying on raw bytes to avoid encoding ambiguity.
        - Supports common signature encodings (hex digest, or base64 of raw digest).
        """
        if not self.webhook_secret:
            raise ValueError("AIRWALLEX_WEBHOOK_SECRET not configured")

        if not signature or not timestamp:
            return False

        normalized_sig = str(signature).strip()
        if normalized_sig.lower().startswith('sha256='):
            normalized_sig = normalized_sig.split('=', 1)[1].strip()

        body_bytes = bytes(body) if isinstance(body, (bytes, bytearray)) else str(body).encode('utf-8')

        ts = str(timestamp).strip().encode('utf-8')
        signed_payload = ts + body_bytes

        computed_digest = hmac.new(
            self.webhook_secret.encode('utf-8'),
            signed_payload,
            hashlib.sha256
        ).digest()

        # Hex signature (64 hex chars)
        sig_candidate = normalized_sig.strip().lower()
        is_hex = len(sig_candidate) == 64
        if is_hex:
            try:
                int(sig_candidate, 16)
                return hmac.compare_digest(computed_digest.hex(), sig_candidate)
            except Exception:
                pass

        # Base64 signature (raw digest)
        try:
            decoded = base64.b64decode(normalized_sig, validate=True)
            return hmac.compare_digest(computed_digest, decoded)
        except Exception:
            return False

    def handle_webhook_event(self, event_type: str, event_data: dict[str, Any]) -> dict[str, Any]:
        """Process webhook events"""
        handlers = {
            'payment_intent.succeeded': self._handle_payment_success,
            'payment_intent.failed': self._handle_payment_failure,
            'payment_intent.canceled': self._handle_payment_canceled,
            'payment_intent.requires_action': self._handle_requires_action,  # P2 FIX #6: 3DS handling
            'payout.succeeded': self._handle_payout_success,
            'payout.failed': self._handle_payout_failure,
            'refund.succeeded': self._handle_refund_success,
            'refund.failed': self._handle_refund_failure,
            'connected_account.verification_failed': self._handle_verification_failed,  # P2 FIX #6: KYC rejection
        }

        handler = handlers.get(event_type)
        if not handler:
            return {Fields.STATUS: WebhookResponseStatus.IGNORED, 'event_type': event_type}

        return handler(event_data)

    def _handle_payment_success(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle successful payment"""
        payment_id = data['id']
        order_id = data.get('metadata', {}).get('order_id')

        # Update Firestore order status
        from google.cloud import firestore
        db = firestore.Client()

        if order_id:
            db.collection(Collections.ORDERS).document(order_id).update({
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.AIRWALLEX_PAYMENT_ID: payment_id,
                Fields.PAYMENT_COMPLETED_AT: firestore.SERVER_TIMESTAMP
            })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'order_id': order_id}

    def _handle_payment_failure(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle failed payment"""
        payment_id = data['id']
        order_id = data.get('metadata', {}).get('order_id')
        error_message = data.get(Fields.ERROR, {}).get('message', 'Payment failed')

        from google.cloud import firestore
        db = firestore.Client()

        if order_id:
            db.collection(Collections.ORDERS).document(order_id).update({
                Fields.PAYMENT_STATUS: PaymentStatusValues.PAYMENT_FAILED,
                Fields.PAYMENT_ERROR: error_message,
                Fields.AIRWALLEX_PAYMENT_ID: payment_id
            })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'order_id': order_id, Fields.ERROR: error_message}

    def _handle_payment_canceled(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle canceled payment"""
        payment_id = data['id']
        order_id = data.get('metadata', {}).get('order_id')

        from google.cloud import firestore
        db = firestore.Client()

        if order_id:
            db.collection(Collections.ORDERS).document(order_id).update({
                Fields.PAYMENT_STATUS: PaymentStatusValues.CANCELLED,
                Fields.AIRWALLEX_PAYMENT_ID: payment_id
            })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'order_id': order_id}

    def _handle_payout_success(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle successful payout"""
        payout_id = data['id']
        seller_id = data.get('metadata', {}).get('seller_id')

        from google.cloud import firestore
        db = firestore.Client()

        # Log payout success
        db.collection(Collections.PAYOUTS).document(payout_id).set({
            Fields.SELLER_ID: seller_id,
            Fields.STATUS: PayoutStatusValues.COMPLETED,
            Fields.AMOUNT: data[Fields.AMOUNT],
            Fields.COMPLETED_AT: firestore.SERVER_TIMESTAMP,
            Fields.PROVIDER: PaymentProviderValues.AIRWALLEX
        })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'payout_id': payout_id}

    def _handle_payout_failure(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle failed payout"""
        payout_id = data['id']
        seller_id = data.get('metadata', {}).get('seller_id')
        error_message = data.get(Fields.ERROR, {}).get('message', 'Payout failed')

        from google.cloud import firestore
        db = firestore.Client()

        # Log payout failure
        db.collection(Collections.PAYOUTS).document(payout_id).set({
            Fields.SELLER_ID: seller_id,
            Fields.STATUS: PayoutStatusValues.FAILED,
            Fields.ERROR: error_message,
            Fields.FAILED_AT: firestore.SERVER_TIMESTAMP,
            Fields.PROVIDER: PaymentProviderValues.AIRWALLEX
        })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'payout_id': payout_id, Fields.ERROR: error_message}

    def _handle_refund_success(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle successful refund"""
        refund_id = data['id']
        payment_id = data.get('payment_intent_id')

        from google.cloud import firestore
        db = firestore.Client()

        # Log refund
        db.collection(Collections.REFUNDS).document(refund_id).set({
            Fields.PAYMENT_ID: payment_id,
            Fields.STATUS: PayoutStatusValues.COMPLETED,
            Fields.AMOUNT: data[Fields.AMOUNT],
            Fields.COMPLETED_AT: firestore.SERVER_TIMESTAMP,
            Fields.PROVIDER: PaymentProviderValues.AIRWALLEX
        })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'refund_id': refund_id}

    def _handle_refund_failure(self, data: dict[str, Any]) -> dict[str, Any]:
        """Handle failed refund"""
        refund_id = data['id']
        error_message = data.get(Fields.ERROR, {}).get('message', 'Refund failed')

        from google.cloud import firestore
        db = firestore.Client()

        db.collection(Collections.REFUNDS).document(refund_id).set({
            Fields.STATUS: PayoutStatusValues.FAILED,
            Fields.ERROR: error_message,
            Fields.FAILED_AT: firestore.SERVER_TIMESTAMP,
            Fields.PROVIDER: PaymentProviderValues.AIRWALLEX
        })

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'refund_id': refund_id, Fields.ERROR: error_message}

    def _handle_requires_action(self, data: dict[str, Any]) -> dict[str, Any]:
        """P2 FIX #6: Handle payment requiring 3DS authentication"""
        payment_id = data['id']
        order_id = data.get('metadata', {}).get('order_id')
        next_action = data.get('next_action')

        # CRITICAL FIX: Validate next_action exists to prevent crash on malformed events
        if not next_action or not isinstance(next_action, dict):
            logger.warning(f"⚠️  Payment {payment_id} requires action but next_action missing")
            return {Fields.STATUS: WebhookResponseStatus.ERROR, 'message': 'Missing next_action in event data'}

        action_type = next_action.get(Fields.TYPE)  # Usually 'redirect_to_url' for 3DS
        action_url = next_action.get('url')

        from google.cloud import firestore
        db = firestore.Client()

        logger.warning(f"⚠️  Payment {payment_id} requires action: {action_type}")

        if order_id:
            db.collection(Collections.ORDERS).document(order_id).update({
                Fields.PAYMENT_STATUS: PaymentStatusValues.PROCESSING,
                Fields.AIRWALLEX_PAYMENT_ID: payment_id,
                Fields.REQUIRES_3DS: True,
                Fields.AUTHENTICATION_URL: action_url,
                Fields.UPDATED_AT: firestore.SERVER_TIMESTAMP
            })

            # ✅ COMPLETED TODO: Send email to buyer with 3DS authentication link
            try:
                order_doc = db.collection(Collections.ORDERS).document(order_id).get()
                if order_doc.exists:
                    order_data = order_doc.to_dict()
                    from services.email_service import send_3ds_authentication_email
                    send_3ds_authentication_email(
                        order_id=order_id,
                        customer_email=order_data.get(Fields.CUSTOMER_EMAIL),
                        customer_name=order_data.get(Fields.CUSTOMER_NAME, 'Customer'),
                        authentication_url=action_url,
                        amount=order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0)
                    )
                    logger.info("  ✅ 3DS authentication email sent")
            except Exception as email_error:
                logger.warning(f"  ⚠️  Failed to send 3DS email: {str(email_error)}")

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'order_id': order_id, 'action_required': action_type, 'url': action_url}

    def _handle_verification_failed(self, data: dict[str, Any]) -> dict[str, Any]:
        """P2 FIX #6: Handle connected account verification failure (KYC rejection)"""
        account_id = data['id']
        seller_id = data.get('metadata', {}).get('seller_id')
        failure_reason = data.get('failure_reason', 'Verification failed')

        from google.cloud import firestore
        db = firestore.Client()

        logger.error(f"❌ Seller account verification failed: {account_id}")

        if seller_id:
            # Update seller status
            db.collection(Collections.USERS).document(seller_id).update({
                Fields.AIRWALLEX_ACCOUNT_VERIFIED: False,
                Fields.AIRWALLEX_VERIFICATION_STATUS: 'failed',
                Fields.AIRWALLEX_VERIFICATION_ERROR: failure_reason,
                Fields.PAYOUTS_ENABLED: False,  # Disable payouts
                Fields.UPDATED_AT: firestore.SERVER_TIMESTAMP
            })

            # Log security event
            db.collection(Collections.SECURITY_ALERTS).add({
                Fields.TYPE: SecurityAlertTypes.SELLER_KYC_FAILED,
                Fields.SELLER_ID: seller_id,
                Fields.ACCOUNT_ID: account_id,
                Fields.REASON: failure_reason,
                Fields.PROVIDER: PaymentProviderValues.AIRWALLEX,
                Fields.TIMESTAMP: firestore.SERVER_TIMESTAMP
            })

            logger.error(f"  🔒 Seller {seller_id} payouts disabled due to failed verification")

        return {Fields.STATUS: WebhookResponseStatus.PROCESSED, 'seller_id': seller_id, Fields.ERROR: failure_reason}


# Singleton instance
_airwallex_service = None

def get_airwallex_service() -> AirwallexService:
    """Get Airwallex service singleton"""
    global _airwallex_service
    if _airwallex_service is None:
        _airwallex_service = AirwallexService()
    return _airwallex_service
