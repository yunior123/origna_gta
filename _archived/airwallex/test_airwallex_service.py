"""
Comprehensive unit tests for services/airwallex_service.py
Tests all Airwallex payment service methods with mocked HTTP responses.

Note: Airwallex is DEAD CODE FOR LAUNCH — Stripe-only at launch.
These tests are kept to ensure the Airwallex code remains functional
for potential post-launch activation.

Run: pytest tests/test_airwallex_service.py -v --cov=services.airwallex_service
"""

import base64
import hashlib
import hmac
import json
from datetime import datetime, timedelta
from unittest.mock import MagicMock, Mock, patch

import pytest

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
from services.airwallex_service import AirwallexService, get_airwallex_service

# =============================================================================
# Fixtures
# =============================================================================


@pytest.fixture
def service():
    """Create AirwallexService with test credentials."""
    svc = AirwallexService()
    svc.api_key = "test_api_key"
    svc.client_id = "test_client_id"
    svc.webhook_secret = "test_webhook_secret"
    svc.base_url = "https://api.airwallex.com/api/v1"
    # Pre-set a cached token to skip auth for most tests
    svc.token = "cached_test_token"
    svc.token_expiry = datetime.now() + timedelta(minutes=30)
    return svc


@pytest.fixture
def mock_response_ok():
    """Factory for successful HTTP responses."""

    def _make(json_data=None, status_code=200):
        resp = Mock()
        resp.status_code = status_code
        resp.json.return_value = json_data or {}
        resp.raise_for_status.return_value = None
        return resp

    return _make


@pytest.fixture
def sample_seller_data():
    """Sample seller data for account creation."""
    return {
        Fields.FULL_NAME: "John Doe",
        Fields.BUSINESS_NAME: "Doe Trading Co.",
        Fields.EMAIL: "john@doe.ca",
        Fields.COUNTRY: "CA",
        Fields.IS_CORPORATE: True,
        Fields.BANK_DETAILS: {"account_number": "123456789"},
    }


# =============================================================================
# Authentication Tests
# =============================================================================


class TestAuthentication:
    """Tests for _authenticate method."""

    def test_returns_cached_token_when_valid(self, service):
        """Should return cached token without API call when not expired."""
        token = service._authenticate()
        assert token == "cached_test_token"

    @patch("services.airwallex_service.requests.post")
    def test_fetches_new_token_when_expired(self, mock_post, service):
        """Should request new token when cached one is expired."""
        service.token_expiry = datetime.now() - timedelta(minutes=1)
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"token": "new_token"}),
            raise_for_status=Mock(),
        )

        token = service._authenticate()
        assert token == "new_token"
        mock_post.assert_called_once()
        call_kwargs = mock_post.call_args
        assert "x-api-key" in call_kwargs[1]["headers"]
        assert "x-client-id" in call_kwargs[1]["headers"]

    @patch("services.airwallex_service.requests.post")
    def test_fetches_new_token_when_none(self, mock_post, service):
        """Should request new token when no cached token exists."""
        service.token = None
        service.token_expiry = None
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"token": "fresh_token"}),
            raise_for_status=Mock(),
        )

        token = service._authenticate()
        assert token == "fresh_token"
        assert service.token_expiry > datetime.now()

    def test_raises_when_no_credentials(self, service):
        """Should raise ValueError when API credentials are missing."""
        service.api_key = ""
        service.client_id = ""
        service.token = None
        service.token_expiry = None

        with pytest.raises(ValueError, match="credentials not configured"):
            service._authenticate()

    def test_headers_include_bearer_token(self, service):
        headers = service._headers()
        assert headers["Authorization"] == "Bearer cached_test_token"
        assert headers["Content-Type"] == "application/json"


# =============================================================================
# Customer & Account Creation Tests
# =============================================================================


class TestAccountCreation:
    """Tests for create_customer and create_connected_account."""

    @patch("services.airwallex_service.requests.post")
    def test_create_customer_corporate(self, mock_post, service, sample_seller_data):
        """Should create corporate customer with correct payload."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "cust_123"}),
            raise_for_status=Mock(),
        )

        result = service.create_customer("seller_001", sample_seller_data)

        assert result["id"] == "cust_123"
        call_kwargs = mock_post.call_args
        payload = call_kwargs[1]["json"]
        assert payload["customer_name"] == "Doe Trading Co."
        assert payload["customer_type"] == "corporate"
        assert payload[Fields.COUNTRY] == "CA"
        assert payload["metadata"]["seller_id"] == "seller_001"

    @patch("services.airwallex_service.requests.post")
    def test_create_customer_individual(self, mock_post, service):
        """Should create individual customer when not corporate."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "cust_456"}),
            raise_for_status=Mock(),
        )
        seller_data = {
            Fields.FULL_NAME: "Jane Smith",
            Fields.EMAIL: "jane@smith.ca",
            Fields.IS_CORPORATE: False,
        }

        service.create_customer("seller_002", seller_data)
        payload = mock_post.call_args[1]["json"]
        assert payload["customer_type"] == "individual"

    @patch("services.airwallex_service.requests.post")
    def test_create_connected_account(self, mock_post, service, sample_seller_data):
        """Should create customer then connected account."""
        # First call returns customer, second returns account
        mock_post.side_effect = [
            Mock(status_code=200, json=Mock(return_value={"id": "cust_123"}), raise_for_status=Mock()),
            Mock(status_code=200, json=Mock(return_value={"id": "acct_123"}), raise_for_status=Mock()),
        ]

        result = service.create_connected_account("seller_001", sample_seller_data)

        assert result["id"] == "acct_123"
        assert mock_post.call_count == 2
        # Verify the connected account payload uses correct currency
        acct_payload = mock_post.call_args_list[1][1]["json"]
        assert acct_payload[Fields.CURRENCY] == BusinessRules.DEFAULT_CURRENCY.upper()
        assert acct_payload["customer_id"] == "cust_123"

    @patch("services.airwallex_service.requests.post")
    def test_connected_account_currency_is_uppercase(self, mock_post, service, sample_seller_data):
        """Currency sent to Airwallex must be uppercase 'CAD', not lowercase 'cad'."""
        mock_post.side_effect = [
            Mock(status_code=200, json=Mock(return_value={"id": "cust_1"}), raise_for_status=Mock()),
            Mock(status_code=200, json=Mock(return_value={"id": "acct_1"}), raise_for_status=Mock()),
        ]

        service.create_connected_account("s1", sample_seller_data)

        acct_payload = mock_post.call_args_list[1][1]["json"]
        assert acct_payload[Fields.CURRENCY] == "CAD"
        assert acct_payload[Fields.CURRENCY] != "cad"


# =============================================================================
# Payment Intent Tests
# =============================================================================


class TestPaymentIntents:
    """Tests for payment intent creation."""

    @patch("services.airwallex_service.requests.post")
    def test_create_payment_intent_for_checkout(self, mock_post, service):
        """Should create payment intent with uppercased currency."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "pi_123", "status": "INITIAL"}),
            raise_for_status=Mock(),
        )

        result = service.create_payment_intent_for_checkout(
            amount_cents=5000,
            currency="cad",
            order_id="order_001",
            return_url="https://origna.ca/return",
        )

        assert result["id"] == "pi_123"
        payload = mock_post.call_args[1]["json"]
        assert payload[Fields.CURRENCY] == "CAD"  # Uppercased
        assert payload[Fields.AMOUNT] == 5000
        assert payload["merchant_order_id"] == "order_001"
        assert payload["capture"] is False

    @patch("services.airwallex_service.requests.post")
    def test_create_payment_intent_for_checkout_with_metadata(self, mock_post, service):
        """Should merge custom metadata."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "pi_456"}),
            raise_for_status=Mock(),
        )

        service.create_payment_intent_for_checkout(
            amount_cents=1000,
            currency="cad",
            order_id="order_002",
            return_url="https://origna.ca/return",
            metadata={"custom_key": "custom_value"},
        )

        payload = mock_post.call_args[1]["json"]
        assert payload["metadata"]["custom_key"] == "custom_value"
        assert payload["metadata"]["platform"] == AppConfig.PLATFORM_NAME

    def test_create_payment_intent_negative_amount_raises(self, service):
        """Should reject negative amounts."""
        with pytest.raises(ValueError, match="positive"):
            service.create_payment_intent_for_checkout(
                amount_cents=-100,
                currency="cad",
                order_id="order_neg",
                return_url="https://origna.ca/return",
            )

    def test_create_payment_intent_zero_amount_raises(self, service):
        """Should reject zero amounts — no $0 payments allowed."""
        with pytest.raises(ValueError, match="positive"):
            service.create_payment_intent_for_checkout(
                amount_cents=0,
                currency="cad",
                order_id="order_zero",
                return_url="https://origna.ca/return",
            )

    @patch("services.airwallex_service.requests.post")
    def test_create_payment_intent_default_currency(self, mock_post, service):
        """create_payment_intent should default to uppercase CAD from BusinessRules."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "pi_789"}),
            raise_for_status=Mock(),
        )

        service.create_payment_intent("seller_1", "order_1", 3000)

        payload = mock_post.call_args[1]["json"]
        assert payload[Fields.CURRENCY] == "CAD"

    @patch("services.airwallex_service.requests.post")
    def test_create_payment_intent_with_capture(self, mock_post, service):
        """Should set capture=True and auto_capture=True."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "pi_cap"}),
            raise_for_status=Mock(),
        )

        service.create_payment_intent("seller_1", "order_1", 3000, capture=True)

        payload = mock_post.call_args[1]["json"]
        assert payload["capture"] is True
        assert payload["payment_method_options"]["card"]["auto_capture"] is True


# =============================================================================
# Capture, Refund, Cancel Tests
# =============================================================================


class TestPaymentOperations:
    """Tests for capture_payment, refund_payment, cancel_payment."""

    @patch("services.airwallex_service.requests.post")
    def test_capture_payment_full(self, mock_post, service):
        """Should capture without amount for full capture."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"status": "SUCCEEDED"}),
            raise_for_status=Mock(),
        )

        result = service.capture_payment("pi_123")
        assert result["status"] == "SUCCEEDED"
        payload = mock_post.call_args[1]["json"]
        assert Fields.AMOUNT not in payload

    @patch("services.airwallex_service.requests.post")
    def test_capture_payment_partial(self, mock_post, service):
        """Should include amount for partial capture."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"status": "SUCCEEDED"}),
            raise_for_status=Mock(),
        )

        service.capture_payment("pi_123", amount_cents=2500)
        payload = mock_post.call_args[1]["json"]
        assert payload[Fields.AMOUNT] == 2500

    @patch("services.airwallex_service.requests.post")
    def test_refund_payment(self, mock_post, service):
        """Should send correct refund payload."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "ref_123"}),
            raise_for_status=Mock(),
        )

        result = service.refund_payment("pi_123", 1000, reason="Customer request")
        assert result["id"] == "ref_123"
        payload = mock_post.call_args[1]["json"]
        assert payload[Fields.AMOUNT] == 1000
        assert payload[Fields.REASON] == "Customer request"

    @patch("services.airwallex_service.requests.post")
    def test_cancel_payment(self, mock_post, service):
        """Should cancel authorized payment."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"status": "CANCELLED"}),
            raise_for_status=Mock(),
        )

        result = service.cancel_payment("pi_123")
        assert result["status"] == "CANCELLED"
        assert "/pi_123/cancel" in mock_post.call_args[0][0]


# =============================================================================
# Payout Tests
# =============================================================================


class TestPayouts:
    """Tests for payout operations."""

    @patch("services.airwallex_service.requests.post")
    def test_create_payout(self, mock_post, service):
        """Should create payout with uppercase CAD."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "po_123"}),
            raise_for_status=Mock(),
        )

        result = service.create_payout("seller_1", 5000, "acct_1", reference="Order payout")
        assert result["id"] == "po_123"
        payload = mock_post.call_args[1]["json"]
        assert payload[Fields.CURRENCY] == "CAD"
        assert payload[Fields.AMOUNT] == 5000
        assert payload["reference"] == "Order payout"

    @patch("services.airwallex_service.requests.post")
    def test_create_payout_default_reference(self, mock_post, service):
        """Should generate default reference when none provided."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "po_456"}),
            raise_for_status=Mock(),
        )

        service.create_payout("seller_42", 3000, "acct_42")
        payload = mock_post.call_args[1]["json"]
        assert "seller_42" in payload["reference"]

    @patch("services.airwallex_service.requests.get")
    def test_get_payout_status(self, mock_get, service):
        """Should retrieve payout status."""
        mock_get.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "po_123", "status": "SUCCESS"}),
            raise_for_status=Mock(),
        )

        result = service.get_payout_status("po_123")
        assert result["status"] == "SUCCESS"


# =============================================================================
# Webhook Signature Verification Tests
# =============================================================================


class TestWebhookVerification:
    """Tests for verify_webhook_signature."""

    def test_valid_hex_signature(self, service):
        """Should verify valid HMAC-SHA256 hex signature."""
        body = '{"event_type":"payment_intent.succeeded"}'
        timestamp = "1234567890"

        # Compute expected signature
        signed_payload = timestamp.encode() + body.encode()
        expected = hmac.new(service.webhook_secret.encode(), signed_payload, hashlib.sha256).hexdigest()

        result = service.verify_webhook_signature(body, expected, timestamp=timestamp)
        assert result is True

    def test_valid_base64_signature(self, service):
        """Should verify valid base64-encoded signature."""
        body = '{"event_type":"payout.failed"}'
        timestamp = "9876543210"

        signed_payload = timestamp.encode() + body.encode()
        raw_digest = hmac.new(service.webhook_secret.encode(), signed_payload, hashlib.sha256).digest()
        sig_b64 = base64.b64encode(raw_digest).decode()

        result = service.verify_webhook_signature(body, sig_b64, timestamp=timestamp)
        assert result is True

    def test_invalid_signature_returns_false(self, service):
        """Should return False for incorrect signature."""
        result = service.verify_webhook_signature('{"data":"test"}', "invalid_hex_signature", timestamp="123")
        assert result is False

    def test_missing_timestamp_returns_false(self, service):
        """Should return False when timestamp is missing."""
        result = service.verify_webhook_signature('{"data":"test"}', "abcdef123456")
        assert result is False

    def test_missing_signature_returns_false(self, service):
        """Should return False when signature is empty."""
        result = service.verify_webhook_signature('{"data":"test"}', "", timestamp="123")
        assert result is False

    def test_no_webhook_secret_raises(self, service):
        """Should raise ValueError when webhook secret is not configured."""
        service.webhook_secret = ""
        with pytest.raises(ValueError, match="AIRWALLEX_WEBHOOK_SECRET not configured"):
            service.verify_webhook_signature("body", "sig", timestamp="123")

    def test_bytes_body(self, service):
        """Should handle bytes body input."""
        body = b'{"event_type":"test"}'
        timestamp = "123"
        signed_payload = timestamp.encode() + body
        expected = hmac.new(service.webhook_secret.encode(), signed_payload, hashlib.sha256).hexdigest()

        result = service.verify_webhook_signature(body, expected, timestamp=timestamp)
        assert result is True

    def test_sha256_prefix_stripped(self, service):
        """Should strip 'sha256=' prefix from signature."""
        body = '{"test": true}'
        timestamp = "111"
        signed_payload = timestamp.encode() + body.encode()
        expected = hmac.new(service.webhook_secret.encode(), signed_payload, hashlib.sha256).hexdigest()

        result = service.verify_webhook_signature(body, f"sha256={expected}", timestamp=timestamp)
        assert result is True


# =============================================================================
# Webhook Event Handling Tests
# =============================================================================


class TestWebhookHandling:
    """Tests for handle_webhook_event and individual handlers."""

    def test_unknown_event_type_ignored(self, service):
        """Should return 'ignored' for unrecognized event types."""
        result = service.handle_webhook_event("unknown.event", {})
        assert result[Fields.STATUS] == WebhookResponseStatus.IGNORED

    @patch("google.cloud.firestore.Client")
    def test_handle_payment_success(self, mock_firestore_client, service):
        """Should update order payment status to CAPTURED."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "pi_123",
            "metadata": {"order_id": "order_001"},
        }

        result = service.handle_webhook_event("payment_intent.succeeded", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result["order_id"] == "order_001"
        mock_db.collection.assert_called_with(Collections.ORDERS)

    @patch("google.cloud.firestore.Client")
    def test_handle_payment_failure(self, mock_firestore_client, service):
        """Should update order payment status to PAYMENT_FAILED."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "pi_fail",
            "metadata": {"order_id": "order_002"},
            Fields.ERROR: {"message": "Insufficient funds"},
        }

        result = service.handle_webhook_event("payment_intent.failed", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result[Fields.ERROR] == "Insufficient funds"

    @patch("google.cloud.firestore.Client")
    def test_handle_payment_canceled(self, mock_firestore_client, service):
        """Should update order payment status to CANCELLED."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "pi_cancel",
            "metadata": {"order_id": "order_003"},
        }

        result = service.handle_webhook_event("payment_intent.canceled", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED

    @patch("google.cloud.firestore.Client")
    def test_handle_payout_success(self, mock_firestore_client, service):
        """Should log payout success to payouts collection."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "po_succ",
            "metadata": {"seller_id": "seller_1"},
            Fields.AMOUNT: 5000,
        }

        result = service.handle_webhook_event("payout.succeeded", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result["payout_id"] == "po_succ"
        mock_db.collection.assert_called_with(Collections.PAYOUTS)

    @patch("google.cloud.firestore.Client")
    def test_handle_payout_failure(self, mock_firestore_client, service):
        """Should log payout failure with error."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "po_fail",
            "metadata": {"seller_id": "seller_2"},
            Fields.ERROR: {"message": "Bank rejected"},
        }

        result = service.handle_webhook_event("payout.failed", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result[Fields.ERROR] == "Bank rejected"

    @patch("google.cloud.firestore.Client")
    def test_handle_refund_success(self, mock_firestore_client, service):
        """Should log refund success."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "ref_succ",
            "payment_intent_id": "pi_123",
            Fields.AMOUNT: 2000,
        }

        result = service.handle_webhook_event("refund.succeeded", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result["refund_id"] == "ref_succ"

    @patch("google.cloud.firestore.Client")
    def test_handle_refund_failure(self, mock_firestore_client, service):
        """Should log refund failure."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "ref_fail",
            Fields.ERROR: {"message": "Refund rejected by provider"},
        }

        result = service.handle_webhook_event("refund.failed", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result[Fields.ERROR] == "Refund rejected by provider"

    @patch("services.email_service.send_3ds_authentication_email")
    @patch("google.cloud.firestore.Client")
    def test_handle_requires_action_3ds(self, mock_firestore_client, mock_send_email, service):
        """Should update order for 3DS authentication."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        # Mock order document for email sending
        mock_order_doc = MagicMock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            Fields.CUSTOMER_EMAIL: "buyer@test.ca",
            Fields.CUSTOMER_NAME: "Test Buyer",
            Fields.TOTAL_AMOUNT_CENTS: 5000,
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc

        event_data = {
            "id": "pi_3ds",
            "metadata": {"order_id": "order_3ds"},
            "next_action": {
                Fields.TYPE: "redirect_to_url",
                "url": "https://bank.com/3ds",
            },
        }

        result = service.handle_webhook_event("payment_intent.requires_action", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result["action_required"] == "redirect_to_url"
        assert result["url"] == "https://bank.com/3ds"

    @patch("google.cloud.firestore.Client")
    def test_handle_requires_action_missing_next_action(self, mock_firestore_client, service):
        """Should return error when next_action is missing from event data."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "pi_broken",
            "metadata": {"order_id": "order_broken"},
        }

        result = service.handle_webhook_event("payment_intent.requires_action", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.ERROR

    @patch("google.cloud.firestore.Client")
    def test_handle_verification_failed(self, mock_firestore_client, service):
        """Should disable payouts and log security alert for KYC failure."""
        mock_db = MagicMock()
        mock_firestore_client.return_value = mock_db

        event_data = {
            "id": "acct_fail",
            "metadata": {"seller_id": "seller_kyc"},
            "failure_reason": "Document verification failed",
        }

        result = service.handle_webhook_event("connected_account.verification_failed", event_data)

        assert result[Fields.STATUS] == WebhookResponseStatus.PROCESSED
        assert result[Fields.ERROR] == "Document verification failed"
        # Should have called collection for both users update and security_alerts add
        calls = [c[0][0] for c in mock_db.collection.call_args_list]
        assert Collections.USERS in calls
        assert Collections.SECURITY_ALERTS in calls


# =============================================================================
# Currency Consistency Tests
# =============================================================================


class TestCurrencyConsistency:
    """Ensure currency casing is correct across all methods."""

    def test_business_rules_currency_is_lowercase(self):
        """BusinessRules.DEFAULT_CURRENCY should be lowercase for Stripe compatibility."""
        assert BusinessRules.DEFAULT_CURRENCY == "cad"

    def test_uppercase_conversion(self):
        """Uppercasing DEFAULT_CURRENCY should produce 'CAD' for Airwallex."""
        assert BusinessRules.DEFAULT_CURRENCY.upper() == "CAD"

    @patch("services.airwallex_service.requests.post")
    def test_all_airwallex_payloads_use_uppercase_currency(self, mock_post, service):
        """All Airwallex API calls should send uppercase currency."""
        mock_post.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"id": "test"}),
            raise_for_status=Mock(),
        )

        # create_payment_intent (no explicit currency)
        service.create_payment_intent("s1", "o1", 1000)
        pi_payload = mock_post.call_args[1]["json"]
        assert pi_payload[Fields.CURRENCY] == pi_payload[Fields.CURRENCY].upper()

        # create_payment_intent_for_checkout (lowercase input)
        service.create_payment_intent_for_checkout(
            amount_cents=1000, currency="cad", order_id="o2", return_url="https://test.ca"
        )
        checkout_payload = mock_post.call_args[1]["json"]
        assert checkout_payload[Fields.CURRENCY] == "CAD"


# =============================================================================
# Singleton Tests
# =============================================================================


class TestSingleton:
    """Tests for get_airwallex_service singleton."""

    def test_singleton_returns_service_instance(self):
        """Should return an AirwallexService instance."""
        import services.airwallex_service as mod

        # Reset singleton
        mod._airwallex_service = None
        svc = get_airwallex_service()
        assert isinstance(svc, AirwallexService)

    def test_singleton_returns_same_instance(self):
        """Should return the same instance on repeated calls."""
        import services.airwallex_service as mod

        mod._airwallex_service = None
        svc1 = get_airwallex_service()
        svc2 = get_airwallex_service()
        assert svc1 is svc2
