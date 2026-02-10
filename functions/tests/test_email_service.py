"""
Comprehensive unit tests for services/email_service.py
Tests all email generation and sending functions with mocked Mailjet.

Run: pytest tests/test_email_service.py -v --cov=services.email_service
"""

import os
from unittest.mock import MagicMock, Mock, patch

import pytest

from schema_constants import AppConfig, EmailConfig, Fields

# Force emulator mode for deterministic tests
os.environ['FUNCTIONS_EMULATOR'] = 'true'


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def sample_order_data():
    """Sample order data for email generation tests."""
    return {
        Fields.ORDER_ID: "abc12345-6789-defg",
        Fields.ITEMS: [
            {
                Fields.NAME: "Vintage Headphones",
                Fields.QUANTITY: 2,
                Fields.PRICE: 49.99,
                Fields.SELLER_ID: "seller_001",
                Fields.IMAGE_URLS: ["https://cdn.test/img.jpg"],
            },
            {
                Fields.NAME: "USB-C Cable <script>alert(1)</script>",
                Fields.QUANTITY: 1,
                Fields.PRICE: 12.50,
                Fields.SELLER_ID: "seller_002",
                Fields.IMAGE_URLS: [],
            },
        ],
        Fields.SUBTOTAL_CENTS: 11248,  # $112.48
        Fields.SHIPPING_COST_CENTS: 999,  # $9.99
        Fields.TAXES: {"GST": 5.62, "PST": 7.87},
        Fields.TOTAL_AMOUNT_CENTS: 13596,  # $135.96
        Fields.SHIPPING_ADDRESS: {
            Fields.STREET: "123 Main St",
            Fields.APARTMENT: "Suite 4B",
            Fields.CITY: "Toronto",
            Fields.STATE: "ON",
            Fields.POSTAL_CODE: "M5V 3A8",
            Fields.COUNTRY: "Canada",
            Fields.PHONE_NUMBER: "+14165551234",
        },
        Fields.CUSTOMER_EMAIL: "buyer@test.ca",
        Fields.CUSTOMER_NAME: "Jean Tremblay",
    }


@pytest.fixture
def mock_mailjet():
    """Mock the Mailjet Client."""
    with patch("services.email_service.Client") as mock_client_cls:
        mock_client = MagicMock()
        mock_client_cls.return_value = mock_client
        mock_send = MagicMock()
        mock_send.create.return_value = MagicMock(status_code=200, json=lambda: {"Messages": [{"Status": "success"}]})
        mock_client.send = mock_send
        yield mock_client


# =============================================================================
# Order Confirmation Email Tests
# =============================================================================

class TestOrderConfirmationEmail:
    """Tests for get_order_confirmation_email."""

    def test_returns_html_string(self, sample_order_data):
        """Should return a non-empty HTML string."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        assert isinstance(html, str)
        assert len(html) > 100
        assert "<!DOCTYPE html>" in html

    def test_contains_order_id(self, sample_order_data):
        """Should include the (shortened) order ID."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        # Order ID is truncated to first 8 chars
        assert "abc12345" in html

    def test_contains_item_names(self, sample_order_data):
        """Should include product names in the email."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        assert "Vintage Headphones" in html

    def test_xss_protection_escapes_html_in_item_names(self, sample_order_data):
        """Item names should be HTML-escaped to prevent XSS."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        # The malicious <script> tag should be escaped
        assert "<script>" not in html
        assert "&lt;script&gt;" in html

    def test_contains_address(self, sample_order_data):
        """Should include shipping address details."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        assert "123 Main St" in html
        assert "Toronto" in html
        assert "M5V 3A8" in html

    def test_contains_phone_number(self, sample_order_data):
        """Should include phone number when provided."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        assert "+14165551234" in html

    def test_no_phone_number_when_missing(self, sample_order_data):
        """Should handle missing phone number gracefully."""
        from services.email_service import get_order_confirmation_email
        del sample_order_data[Fields.SHIPPING_ADDRESS][Fields.PHONE_NUMBER]
        html = get_order_confirmation_email(sample_order_data)
        assert isinstance(html, str)
        assert "📱" not in html

    def test_order_id_from_parameter(self, sample_order_data):
        """Should accept order_id as parameter when not in order_data."""
        from services.email_service import get_order_confirmation_email
        del sample_order_data[Fields.ORDER_ID]
        html = get_order_confirmation_email(sample_order_data, order_id="custom_order_999")
        assert "custom_o" in html  # First 8 chars

    def test_empty_items_list(self, sample_order_data):
        """Should handle empty items gracefully."""
        from services.email_service import get_order_confirmation_email
        sample_order_data[Fields.ITEMS] = []
        html = get_order_confirmation_email(sample_order_data)
        assert isinstance(html, str)

    def test_total_formatting(self, sample_order_data):
        """Should format monetary amounts correctly."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        # $135.96 total
        assert "135.96" in html

    def test_contains_origna_branding(self, sample_order_data):
        """Should include Origna branding."""
        from services.email_service import get_order_confirmation_email
        html = get_order_confirmation_email(sample_order_data)
        assert "O R I G N A" in html
        assert "Order Confirmed" in html


# =============================================================================
# Seller Notification Email Tests
# =============================================================================

class TestSellerNotificationEmail:
    """Tests for get_seller_notification_email."""

    def test_returns_html_string(self, sample_order_data):
        """Should return a non-empty HTML string."""
        from services.email_service import get_seller_notification_email
        html = get_seller_notification_email(sample_order_data, order_id="ord_test", seller_id="seller_001")
        assert isinstance(html, str)
        assert len(html) > 100

    def test_contains_seller_relevant_info(self, sample_order_data):
        """Should include order details relevant to seller."""
        from services.email_service import get_seller_notification_email
        html = get_seller_notification_email(sample_order_data, order_id="ord_seller_test")
        # Order ID from sample_order_data takes priority (abc12345...)
        assert "abc12345" in html

    def test_contains_origna_branding(self, sample_order_data):
        """Should include Origna branding for seller emails too."""
        from services.email_service import get_seller_notification_email
        html = get_seller_notification_email(sample_order_data, order_id="ord_brand")
        assert "O R I G N A" in html


# =============================================================================
# send_email Tests
# =============================================================================

class TestSendEmail:
    """Tests for the send_email function."""

    def test_emulator_mode_skips_mailjet(self):
        """In emulator mode (without FORCE_REAL_EMAIL), should skip Mailjet and return True."""
        from services.email_service import send_email
        # FUNCTIONS_EMULATOR is 'true' and FORCE_REAL_EMAIL is not set
        with patch.dict(os.environ, {"FORCE_REAL_EMAIL": "false", "FUNCTIONS_EMULATOR": "true"}):
            # Re-import to pick up env changes (module-level constants)
            import importlib

            import services.email_service as mod
            original_force = mod.FORCE_REAL_EMAIL
            mod.FORCE_REAL_EMAIL = False
            try:
                result = mod.send_email("test@test.ca", "Test Subject", "<p>Hello</p>")
                assert result is True
            finally:
                mod.FORCE_REAL_EMAIL = original_force

    @patch("services.email_service.Client")
    def test_send_email_success(self, mock_client_cls):
        """Should successfully send email via Mailjet."""
        import services.email_service as mod
        from services.email_service import send_email

        mock_client = MagicMock()
        mock_send_result = MagicMock()
        mock_send_result.status_code = 200
        mock_client.send.create.return_value = mock_send_result
        mock_client_cls.return_value = mock_client

        # Temporarily enable real email for test
        original_emulator = mod.IS_EMULATOR
        original_force = mod.FORCE_REAL_EMAIL
        original_key = mod.MAILJET_API_KEY
        mod.IS_EMULATOR = False
        mod.FORCE_REAL_EMAIL = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            result = send_email("dest@test.ca", "Subject", "<p>Body</p>")
            assert result is True
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.FORCE_REAL_EMAIL = original_force
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED

    @patch("services.email_service.Client")
    def test_send_email_failure(self, mock_client_cls):
        """Should return False when Mailjet returns non-200."""
        import services.email_service as mod
        from services.email_service import send_email

        mock_client = MagicMock()
        mock_send_result = MagicMock()
        mock_send_result.status_code = 400
        mock_send_result.json.return_value = {"ErrorMessage": "Bad request"}
        mock_client.send.create.return_value = mock_send_result
        mock_client_cls.return_value = mock_client

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            result = send_email("dest@test.ca", "Subject", "<p>Body</p>")
            assert result is False
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED

    @patch("services.email_service.Client")
    def test_send_email_exception_returns_false(self, mock_client_cls):
        """Should return False when Mailjet raises an exception."""
        import services.email_service as mod
        from services.email_service import send_email

        mock_client_cls.side_effect = Exception("Connection refused")

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            result = send_email("dest@test.ca", "Subject", "<p>Body</p>")
            assert result is False
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED

    def test_send_email_custom_from(self):
        """Should accept custom from_email."""
        import services.email_service as mod
        from services.email_service import send_email

        # In emulator mode, just verify it doesn't crash
        original_force = mod.FORCE_REAL_EMAIL
        mod.FORCE_REAL_EMAIL = False
        try:
            result = send_email("to@test.ca", "Sub", "<p>Hi</p>", from_email="noreply@origna.ca")
            assert result is True
        finally:
            mod.FORCE_REAL_EMAIL = original_force


# =============================================================================
# Authorization Expired Email Tests
# =============================================================================

class TestAuthorizationExpiredEmail:
    """Tests for send_authorization_expired_email."""

    def test_emulator_mode_skips(self):
        """Should skip sending in emulator mode."""
        import services.email_service as mod
        from services.email_service import send_authorization_expired_email

        original_force = mod.FORCE_REAL_EMAIL
        mod.FORCE_REAL_EMAIL = False
        try:
            # Should not raise
            send_authorization_expired_email("order_exp", {
                Fields.CUSTOMER_EMAIL: "buyer@test.ca",
                Fields.TOTAL_AMOUNT_CENTS: 5000,
                Fields.ITEMS: [{Fields.NAME: "Widget", Fields.QUANTITY: 1}],
            })
        finally:
            mod.FORCE_REAL_EMAIL = original_force

    @patch("services.email_service.Client")
    def test_sends_email_in_production(self, mock_client_cls):
        """Should send email via Mailjet in production mode."""
        import services.email_service as mod
        from services.email_service import send_authorization_expired_email

        mock_client = MagicMock()
        mock_client_cls.return_value = mock_client
        mock_client.send.create.return_value = MagicMock(status_code=200)

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        original_secret = mod.MAILJET_SECRET_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"
        mod.MAILJET_SECRET_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            send_authorization_expired_email("order_prod", {
                Fields.CUSTOMER_EMAIL: "buyer@prod.ca",
                Fields.TOTAL_AMOUNT_CENTS: 10000,
                Fields.ITEMS: [{Fields.NAME: "Laptop", Fields.QUANTITY: 1}],
            })
            mock_client.send.create.assert_called_once()
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED
            mod.MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED

    def test_no_crash_on_missing_mailjet_credentials(self):
        """Should handle missing Mailjet credentials gracefully."""
        import services.email_service as mod
        from services.email_service import send_authorization_expired_email

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = ""

        try:
            # Should not raise, just print warning
            send_authorization_expired_email("order_no_creds", {
                Fields.CUSTOMER_EMAIL: "buyer@test.ca",
                Fields.TOTAL_AMOUNT_CENTS: 1000,
                Fields.ITEMS: [],
            })
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED


# =============================================================================
# Payment Capture Failed Email Tests
# =============================================================================

class TestPaymentCaptureFailedEmail:
    """Tests for send_payment_capture_failed_email."""

    def test_emulator_mode_skips(self):
        """Should skip in emulator mode."""
        import services.email_service as mod
        from services.email_service import send_payment_capture_failed_email

        original_force = mod.FORCE_REAL_EMAIL
        mod.FORCE_REAL_EMAIL = False
        try:
            # Should not raise
            send_payment_capture_failed_email(
                "order_cap_fail",
                "buyer@test.ca",
                "Test Buyer",
                99.99,
                "Insufficient funds"
            )
        finally:
            mod.FORCE_REAL_EMAIL = original_force

    def test_missing_email_skips(self):
        """Should skip when customer_email is missing."""
        from services.email_service import send_payment_capture_failed_email
        # Should not raise
        send_payment_capture_failed_email("order_1", "", "Buyer", 50.0, "Error")

    @patch("services.email_service.Client")
    def test_sends_email_in_production(self, mock_client_cls):
        """Should send capture failure email via Mailjet."""
        import services.email_service as mod
        from services.email_service import send_payment_capture_failed_email

        mock_client = MagicMock()
        mock_client_cls.return_value = mock_client
        mock_client.send.create.return_value = MagicMock(status_code=200)

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        original_secret = mod.MAILJET_SECRET_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"
        mod.MAILJET_SECRET_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            send_payment_capture_failed_email(
                "order_cap",
                "buyer@prod.ca",
                "Jean Tremblay",
                149.99,
                "Card expired"
            )
            mock_client.send.create.assert_called_once()
            call_data = mock_client.send.create.call_args[1]["data"]
            assert call_data["Messages"][0]["To"][0]["Email"] == "buyer@prod.ca"
            assert "Payment Issue" in call_data["Messages"][0]["Subject"]
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED
            mod.MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED


# =============================================================================
# 3DS Authentication Email Tests
# =============================================================================

class TestThreeDSAuthenticationEmail:
    """Tests for send_3ds_authentication_email."""

    def test_emulator_mode_skips(self):
        """Should skip in emulator mode."""
        import services.email_service as mod
        from services.email_service import send_3ds_authentication_email

        original_force = mod.FORCE_REAL_EMAIL
        mod.FORCE_REAL_EMAIL = False
        try:
            send_3ds_authentication_email(
                "order_3ds",
                "buyer@test.ca",
                "Test Buyer",
                "https://bank.com/3ds/verify",
                75.50,
            )
        finally:
            mod.FORCE_REAL_EMAIL = original_force

    def test_missing_email_skips(self):
        """Should skip when customer_email is missing."""
        from services.email_service import send_3ds_authentication_email
        # Should not raise
        send_3ds_authentication_email("order_1", "", "Buyer", "https://bank.com/3ds", 50.0)

    def test_missing_authentication_url_skips(self):
        """Should skip when authentication_url is missing."""
        from services.email_service import send_3ds_authentication_email
        # Should not raise
        send_3ds_authentication_email("order_1", "buyer@test.ca", "Buyer", "", 50.0)

    @patch("services.email_service.Client")
    def test_sends_3ds_email_in_production(self, mock_client_cls):
        """Should send 3DS authentication email via Mailjet."""
        import services.email_service as mod
        from services.email_service import send_3ds_authentication_email

        mock_client = MagicMock()
        mock_client_cls.return_value = mock_client
        mock_client.send.create.return_value = MagicMock(status_code=200)

        original_emulator = mod.IS_EMULATOR
        original_key = mod.MAILJET_API_KEY
        original_secret = mod.MAILJET_SECRET_KEY
        mod.IS_EMULATOR = False
        mod.MAILJET_API_KEY = "MAILJET_CREDENTIAL_REDACTED"
        mod.MAILJET_SECRET_KEY = "MAILJET_CREDENTIAL_REDACTED"

        try:
            send_3ds_authentication_email(
                "order_3ds_prod",
                "buyer@prod.ca",
                "Marie Dupont",
                "https://secure.bank.com/3ds/xyz",
                199.99,
            )
            mock_client.send.create.assert_called_once()
            call_data = mock_client.send.create.call_args[1]["data"]
            msg = call_data["Messages"][0]
            assert msg["To"][0]["Email"] == "buyer@prod.ca"
            assert "Verify Your Payment" in msg["Subject"]
            assert "https://secure.bank.com/3ds/xyz" in msg["HTMLPart"]
            assert msg["From"]["Name"] == EmailConfig.SENDER_NAME_SECURITY
        finally:
            mod.IS_EMULATOR = original_emulator
            mod.MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED
            mod.MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED


# =============================================================================
# Configuration & Module Constants Tests
# =============================================================================

class TestModuleConstants:
    """Tests for module-level constants and configuration."""

    def test_email_config_support_email(self):
        """EmailConfig should have a valid support email."""
        assert "@" in EmailConfig.SUPPORT_EMAIL
        assert EmailConfig.SUPPORT_EMAIL == "support@orignaventures.ca"

    def test_email_config_sender_name(self):
        """EmailConfig should have platform sender name."""
        assert "Origna" in EmailConfig.SENDER_NAME

    def test_email_config_copyright(self):
        """EmailConfig should contain copyright text."""
        assert "2026" in EmailConfig.COPYRIGHT_TEXT

    def test_app_base_url_emulator(self):
        """In emulator mode, APP_BASE_URL should point to localhost."""
        from services.email_service import APP_BASE_URL
        # We set FUNCTIONS_EMULATOR=true at module level
        assert "localhost" in APP_BASE_URL or "127.0.0.1" in APP_BASE_URL

    def test_email_config_mailjet_version(self):
        """Mailjet API version should be v3.1."""
        assert EmailConfig.MAILJET_API_VERSION == "v3.1"
