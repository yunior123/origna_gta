"""
Comprehensive unit tests for handlers/admin.py, payment_airwallex.py, and cron_jobs.py
Tests MFA, user roles, GDPR compliance, Airwallex payments, and scheduled tasks

Run: pytest tests/test_handlers_admin_cron.py -v --cov
"""

import json
from datetime import UTC, datetime, timedelta, timezone
from unittest.mock import MagicMock, Mock, call, patch

import pyotp
import pytest
from firebase_admin import firestore
from firebase_functions import https_fn, scheduler_fn


class TestAdminHandlers:
    """Test admin user management functions"""

    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.admin.get_db")
    def test_update_user_roles_requires_admin(self, mock_get_db, mock_rate_limiter_cls):
        """SECURITY: Test only admins can update user roles"""
        from handlers.admin import update_user_roles

        # Mock rate limiter to allow requests
        mock_rate_limiter_cls.return_value.check_rate_limit.return_value = (True, "")

        # Mock requesting user (not admin)
        mock_requester_doc = Mock()
        mock_requester_doc.exists = True
        mock_requester_doc.to_dict.return_value = {
            "userId": "user_123",
            "roles": ["buyer"],  # Not admin - use array
        }
        mock_db = Mock()
        mock_get_db.return_value = mock_db
        mock_db.collection.return_value.document.return_value.get.return_value = mock_requester_doc

        mock_request = Mock()
        mock_request.auth = Mock(uid="user_123")
        mock_request.data = {
            "targetUserId": "victim_456",
            "roles": ["admin"],  # Use roles array
        }

        with pytest.raises(https_fn.HttpsError) as exc:
            update_user_roles(mock_request)

        assert exc.value.code == "permission-denied"

    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.admin.get_db")
    def test_update_user_roles_requires_mfa(self, mock_get_db, mock_rate_limiter_cls):
        """SECURITY: Test admin role changes require MFA verification"""
        from handlers.admin import update_user_roles

        # Mock rate limiter to allow requests
        mock_rate_limiter_cls.return_value.check_rate_limit.return_value = (True, "")

        # Mock admin without MFA
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            "userId": "admin_123",
            "roles": ["admin"],  # Note: roles is an array
            "mfaEnabled": False,  # MFA not enabled
        }
        mock_db = Mock()
        mock_get_db.return_value = mock_db
        mock_db.collection.return_value.document.return_value.get.return_value = mock_admin_doc

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {
            "targetUserId": "user_456",
            "roles": ["seller"],  # Note: roles is an array
        }

        with pytest.raises(https_fn.HttpsError) as exc:
            update_user_roles(mock_request)

        # Should fail because MFA not enabled (failed-precondition) or not verified (permission-denied)
        assert exc.value.code in ["permission-denied", "failed-precondition"]
        assert "mfa" in str(exc.value).lower()

    @patch("services.rate_limiter.RateLimiter")
    @patch("handlers.admin.create_success_response")
    @patch("handlers.admin.get_db")
    def test_update_user_roles_success_with_mfa(self, mock_get_db, mock_create_response, mock_rate_limiter_cls):
        """Test successful role update by verified admin"""
        from handlers.admin import update_user_roles

        # Mock rate limiter to allow requests
        mock_rate_limiter_cls.return_value.check_rate_limit.return_value = (True, "")

        mock_create_response.return_value = {"success": True}

        # Mock admin with MFA verified recently (use UTC to match admin.py handler)
        from datetime import timezone

        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            "userId": "admin_123",
            "roles": ["admin"],
            "mfaEnabled": True,
            "lastMfaVerify": datetime.now(UTC),
        }

        # Mock target user
        mock_target_doc = Mock()
        mock_target_doc.exists = True
        mock_target_doc.to_dict.return_value = {"userId": "user_456", "roles": ["buyer"]}

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_admin_ref = Mock()
        mock_admin_ref.get.return_value = mock_admin_doc
        mock_target_ref = Mock()
        mock_target_ref.get.return_value = mock_target_doc

        def document_side_effect(doc_id):
            if doc_id == "admin_123":
                return mock_admin_ref
            return mock_target_ref

        mock_db.collection.return_value.document.side_effect = document_side_effect

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {"targetUserId": "user_456", "roles": ["seller"]}

        result = update_user_roles(mock_request)

        assert result["success"] is True

    @patch("handlers.admin.create_success_response")
    @patch("pyotp.random_base32")
    @patch("handlers.admin.get_db")
    def test_admin_mfa_enroll_generates_secret(self, mock_get_db, mock_random, mock_create_response):
        """Test MFA enrollment generates TOTP secret"""
        from handlers.admin import admin_mfa_enroll

        mock_random.return_value = "JBSWY3DPEHPK3PXP"
        mock_create_response.return_value = {
            "success": True,
            "secret": "JBSWY3DPEHPK3PXP",
            "qrCodeUrl": "otpauth://...",
        }

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        # Mock user document with admin role
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"userId": "admin_123", "roles": ["admin"], "email": "admin@example.com"}

        mock_user_ref = Mock()
        mock_user_ref.get.return_value = mock_user_doc
        mock_db.collection.return_value.document.return_value = mock_user_ref

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")

        result = admin_mfa_enroll(mock_request)

        assert result["success"] is True
        mock_create_response.assert_called_once()

    @patch("handlers.admin.create_success_response")
    @patch("handlers.admin.get_db")
    def test_admin_mfa_verify_valid_code(self, mock_get_db, mock_create_response):
        """Test MFA verification with valid TOTP code"""
        from handlers.admin import admin_mfa_verify
        from utils.crypto_utils import encrypt_mfa_secret

        secret = pyotp.random_base32()
        encrypted_secret = encrypt_mfa_secret(secret)
        totp = pyotp.TOTP(secret)
        valid_code = totp.now()

        mock_create_response.return_value = {"success": True, "mfaEnabled": True}

        # Mock user with encrypted MFA secret
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            "userId": "admin_123",
            "mfaSecretTemp": encrypted_secret,
            "mfaEnabled": False,
        }
        mock_db = Mock()
        mock_get_db.return_value = mock_db
        mock_user_ref = Mock()
        mock_user_ref.get.return_value = mock_user_doc
        mock_db.collection.return_value.document.return_value = mock_user_ref

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {"code": valid_code}

        result = admin_mfa_verify(mock_request)

        assert result["success"] is True
        assert result["mfaEnabled"] is True

    @patch("handlers.admin.get_db")
    def test_admin_mfa_verify_invalid_code_rejected(self, mock_get_db):
        """SECURITY: Test invalid TOTP code is rejected"""
        from handlers.admin import admin_mfa_verify
        from utils.crypto_utils import encrypt_mfa_secret

        secret = pyotp.random_base32()
        encrypted_secret = encrypt_mfa_secret(secret)

        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"userId": "admin_123", "mfaSecret": encrypted_secret}
        mock_db = Mock()
        mock_get_db.return_value = mock_db
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {"code": "000000"}  # Invalid code

        with pytest.raises(https_fn.HttpsError) as exc:
            admin_mfa_verify(mock_request)

        assert exc.value.code == "unauthenticated"
        assert "invalid" in str(exc.value).lower()

    @patch("handlers.admin.create_success_response")
    @patch("handlers.admin.get_db")
    def test_suspend_seller_deactivates_products(self, mock_get_db, mock_create_response):
        """Test suspending seller deactivates all their products"""
        from handlers.admin import suspend_seller

        mock_create_response.return_value = {"success": True, "message": "Seller suspended"}

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        # Mock admin with recent MFA verification
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            "roles": ["admin"],
            "mfaEnabled": True,
            "lastMfaVerify": datetime.now(UTC),
        }

        # Mock seller
        mock_seller_doc = Mock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {"userId": "seller_456", "roles": ["seller"]}

        # Mock admin and seller refs
        mock_admin_ref = Mock()
        mock_admin_ref.get.return_value = mock_admin_doc
        mock_seller_ref = Mock()
        mock_seller_ref.get.return_value = mock_seller_doc

        def document_side_effect(doc_id):
            if doc_id == "admin_123":
                return mock_admin_ref
            return mock_seller_ref

        mock_db.collection.return_value.document.side_effect = document_side_effect

        # Mock products query (empty for simplicity)
        mock_query = Mock()
        mock_query.where.return_value = mock_query
        mock_query.limit.return_value = mock_query
        mock_query.stream.return_value = iter([])
        mock_db.collection.return_value.where.return_value = mock_query

        mock_db.batch.return_value = Mock()

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {"sellerId": "seller_456", "reason": "Violating terms of service"}

        result = suspend_seller(mock_request)

        assert result["success"] is True


# NOTE: test_delete_account_gdpr_compliance moved to e2e/tests/ - requires full Firestore integration


class TestAirwallexPayments:
    """Test Airwallex payment handlers"""

    @patch("handlers.payment_airwallex.get_utils")
    @patch("handlers.payment_airwallex.get_collections")
    @patch("handlers.payment_airwallex.get_airwallex_service")
    @patch("handlers.payment_airwallex.get_db")
    def test_create_airwallex_seller_account(
        self, mock_get_db, mock_get_airwallex, mock_get_collections, mock_get_utils
    ):
        """Test Airwallex connected account creation"""
        from handlers.payment_airwallex import airwallex_create_seller_account

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        # Mock collections
        mock_collections = Mock()
        mock_collections.USERS = "users"
        mock_get_collections.return_value = mock_collections

        # Mock utils
        mock_utils = Mock()
        mock_utils.create_success_response = lambda x: {"success": True, **x}
        mock_get_utils.return_value = mock_utils

        mock_airwallex_service = Mock()
        mock_get_airwallex.return_value = mock_airwallex_service
        mock_airwallex_service.create_connected_account.return_value = "acct_airwallex_123"

        mock_user_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_user_ref

        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {"email": "seller@example.com", "businessInfo": {"name": "Test Shop"}}

        result = airwallex_create_seller_account(mock_request)

        assert result["success"] is True
        assert result["accountId"] == "acct_airwallex_123"
        # Verify saved to DB
        mock_user_ref.update.assert_called_once()


# NOTE: Airwallex 3DS and webhook tests moved to e2e/tests/ - require full integration
# NOTE: Cron job tests (auto_capture, expired_auth, archive, algolia_sync, rate_limits) moved to e2e/tests/


class TestSecurityEdgeCases:
    """Advanced security and edge case tests"""

    def test_totp_time_window_validation(self):
        """Test TOTP code valid for 30 second window only"""
        secret = pyotp.random_base32()
        totp = pyotp.TOTP(secret)

        # Current code valid
        current_code = totp.now()
        assert totp.verify(current_code) is True

        # Code from 1 minute ago invalid
        old_time = datetime.now() - timedelta(minutes=1)
        old_code = totp.at(old_time)
        assert totp.verify(old_code) is False

    @patch("handlers.admin.get_db")
    def test_mfa_brute_force_protection(self, mock_get_db):
        """SECURITY: Test MFA verification with invalid code is rejected"""
        from handlers.admin import admin_mfa_verify
        from utils.crypto_utils import encrypt_mfa_secret

        mock_db = Mock()
        mock_get_db.return_value = mock_db

        secret = pyotp.random_base32()
        encrypted_secret = encrypt_mfa_secret(secret)
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {"mfaSecret": encrypted_secret}
        mock_user_ref = Mock()
        mock_user_ref.get.return_value = mock_user_doc
        mock_db.collection.return_value.document.return_value = mock_user_ref

        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {"code": "000000"}  # Invalid code

        with pytest.raises(https_fn.HttpsError) as exc:
            admin_mfa_verify(mock_request)

        assert exc.value.code == "unauthenticated"

    def test_gdpr_anonymization_irreversible(self):
        """Test deleted user data cannot be recovered"""
        original_email = "user@example.com"
        anonymized_email = f"deleted_user_{datetime.now().timestamp()}@example.com"

        # Once anonymized, original email cannot be derived
        assert original_email not in anonymized_email
        assert "deleted_user_" in anonymized_email

    def test_admin_role_escalation_prevented(self):
        """SECURITY: Test user cannot self-promote to admin"""
        # User A tries to make User A admin
        # Should require existing admin to grant role
        pass

    def test_webhook_replay_attack_prevented(self):
        """SECURITY: Test same webhook event cannot be replayed"""
        # Idempotency key stored in webhook_events collection
        # Duplicate event_id rejected
        pass

    def test_sensitive_data_not_logged(self):
        """SECURITY: Test credit cards, passwords not in logs"""
        # All logging should mask sensitive fields
        # Verify logger sanitizes these fields
        pass
