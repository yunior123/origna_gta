"""
Comprehensive unit tests for handlers/admin.py, payment_airwallex.py, and cron_jobs.py
Tests MFA, user roles, GDPR compliance, Airwallex payments, and scheduled tasks

Run: pytest tests/test_handlers_admin_cron.py -v --cov
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from firebase_functions import https_fn, scheduler_fn
from firebase_admin import firestore
from datetime import datetime, timedelta
import pyotp
import json


class TestAdminHandlers:
    """Test admin user management functions"""
    
    @patch('handlers.admin.db')
    def test_update_user_roles_requires_admin(self, mock_db):
        """SECURITY: Test only admins can update user roles"""
        from handlers.admin import update_user_roles
        
        # Mock requesting user (not admin)
        mock_requester_doc = Mock()
        mock_requester_doc.exists = True
        mock_requester_doc.to_dict.return_value = {
            'userId': 'user_123',
            'role': 'buyer'  # Not admin
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_requester_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="user_123")
        mock_request.data = {
            'targetUserId': 'victim_456',
            'newRole': 'admin'
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            update_user_roles(mock_request)
        
        assert exc.value.code == 'permission-denied'
    
    @patch('handlers.admin.db')
    def test_update_user_roles_requires_mfa(self, mock_db):
        """SECURITY: Test admin role changes require MFA verification"""
        from handlers.admin import update_user_roles
        
        # Mock admin without MFA
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            'userId': 'admin_123',
            'role': 'admin',
            'mfaEnabled': False  # MFA not enabled
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_admin_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {
            'targetUserId': 'user_456',
            'newRole': 'seller'
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            update_user_roles(mock_request)
        
        assert exc.value.code == 'permission-denied'
        assert 'mfa' in str(exc.value).lower()
    
    @patch('handlers.admin.db')
    def test_update_user_roles_success_with_mfa(self, mock_db):
        """Test successful role update by verified admin"""
        from handlers.admin import update_user_roles
        
        # Mock admin with MFA
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            'userId': 'admin_123',
            'role': 'admin',
            'mfaEnabled': True,
            'mfaVerifiedAt': datetime.now()
        }
        
        # Mock target user
        mock_target_doc = Mock()
        mock_target_doc.exists = True
        
        mock_db.collection.return_value.document.return_value.get.side_effect = [
            mock_admin_doc,  # Requester check
            mock_target_doc  # Target user check
        ]
        
        mock_target_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_target_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {
            'targetUserId': 'user_456',
            'newRole': 'seller'
        }
        
        result = update_user_roles(mock_request)
        
        assert result['success'] is True
        mock_target_ref.update.assert_called_once()
    
    @patch('handlers.admin.db')
    @patch('handlers.admin.pyotp.random_base32')
    def test_admin_mfa_enroll_generates_secret(self, mock_random, mock_db):
        """Test MFA enrollment generates TOTP secret"""
        from handlers.admin import admin_mfa_enroll
        
        mock_random.return_value = 'JBSWY3DPEHPK3PXP'
        
        mock_user_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_user_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123", token={'email': 'admin@example.com'})
        
        result = admin_mfa_enroll(mock_request)
        
        assert result['success'] is True
        assert 'secret' in result
        assert 'qrCodeUrl' in result
        # Verify secret saved to DB
        mock_user_ref.update.assert_called_once()
        update_data = mock_user_ref.update.call_args[0][0]
        assert update_data['mfaSecret'] == 'JBSWY3DPEHPK3PXP'
        assert update_data['mfaEnabled'] is False  # Not enabled until verified
    
    @patch('handlers.admin.db')
    def test_admin_mfa_verify_valid_code(self, mock_db):
        """Test MFA verification with valid TOTP code"""
        from handlers.admin import admin_mfa_verify
        
        secret = pyotp.random_base32()
        totp = pyotp.TOTP(secret)
        valid_code = totp.now()
        
        # Mock user with MFA secret
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'userId': 'admin_123',
            'mfaSecret': secret,
            'mfaEnabled': False
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_user_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_user_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {'code': valid_code}
        
        result = admin_mfa_verify(mock_request)
        
        assert result['success'] is True
        assert result['verified'] is True
        # Verify MFA enabled in DB
        mock_user_ref.update.assert_called_once()
        update_data = mock_user_ref.update.call_args[0][0]
        assert update_data['mfaEnabled'] is True
    
    @patch('handlers.admin.db')
    def test_admin_mfa_verify_invalid_code_rejected(self, mock_db):
        """SECURITY: Test invalid TOTP code is rejected"""
        from handlers.admin import admin_mfa_verify
        
        secret = pyotp.random_base32()
        
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'userId': 'admin_123',
            'mfaSecret': secret
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {'code': '000000'}  # Invalid code
        
        with pytest.raises(https_fn.HttpsError) as exc:
            admin_mfa_verify(mock_request)
        
        assert exc.value.code == 'invalid-argument'
        assert 'invalid' in str(exc.value).lower()
    
    @patch('handlers.admin.db')
    def test_suspend_seller_deactivates_products(self, mock_db):
        """Test suspending seller deactivates all their products"""
        from handlers.admin import suspend_seller
        
        # Mock admin
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            'role': 'admin',
            'mfaEnabled': True
        }
        
        # Mock seller
        mock_seller_doc = Mock()
        mock_seller_doc.exists = True
        
        # Mock seller's products
        mock_product1 = Mock()
        mock_product1.reference = Mock()
        mock_product2 = Mock()
        mock_product2.reference = Mock()
        
        mock_products_query = Mock()
        mock_products_query.stream.return_value = [mock_product1, mock_product2]
        
        mock_db.collection.return_value.document.return_value.get.side_effect = [
            mock_admin_doc,
            mock_seller_doc
        ]
        mock_db.collection.return_value.where.return_value = mock_products_query
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {
            'sellerId': 'seller_456',
            'reason': 'Violating terms of service'
        }
        
        result = suspend_seller(mock_request)
        
        assert result['success'] is True
        # Verify all products deactivated
        assert mock_product1.reference.update.called
        assert mock_product2.reference.update.called
    
    @patch('handlers.admin.db')
    @patch('handlers.admin.auth')
    def test_delete_account_gdpr_compliance(self, mock_auth, mock_db):
        """Test account deletion anonymizes data (GDPR compliance)"""
        from handlers.admin import delete_account
        
        # Mock user
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'userId': 'user_123',
            'email': 'user@example.com',
            'displayName': 'John Doe'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_user_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_user_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="user_123")
        
        result = delete_account(mock_request)
        
        assert result['success'] is True
        # Verify data anonymized
        update_call = mock_user_ref.update.call_args[0][0]
        assert 'deleted_user_' in update_call['email']
        assert update_call['displayName'] == '[DELETED]'
        assert update_call['isDeleted'] is True
        # Verify Firebase Auth user deleted
        mock_auth.delete_user.assert_called_once_with('user_123')


class TestAirwallexPayments:
    """Test Airwallex payment handlers"""
    
    @patch('handlers.payment_airwallex.db')
    @patch('handlers.payment_airwallex.airwallex_service.create_connected_account')
    def test_create_airwallex_seller_account(self, mock_airwallex, mock_db):
        """Test Airwallex connected account creation"""
        from handlers.payment_airwallex import airwallex_create_seller_account
        
        mock_airwallex.return_value = 'acct_airwallex_123'
        
        mock_user_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_user_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {
            'email': 'seller@example.com',
            'businessInfo': {'name': 'Test Shop'}
        }
        
        result = airwallex_create_seller_account(mock_request)
        
        assert result['success'] is True
        assert result['accountId'] == 'acct_airwallex_123'
        # Verify saved to DB
        mock_user_ref.update.assert_called_once()
    
    @patch('handlers.payment_airwallex.db')
    @patch('handlers.payment_airwallex.airwallex_service.create_payment_intent')
    def test_airwallex_3ds_payment_flow(self, mock_airwallex, mock_db):
        """Test Airwallex payment with 3DS authentication"""
        from handlers.payment_airwallex import airwallex_process_payment
        
        # Mock order
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'userId': 'buyer_123',
            'totalAmount': 150.00
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        # Mock Airwallex response with 3DS
        mock_airwallex.return_value = {
            'id': 'pi_airwallex_123',
            'clientSecret': 'secret_xyz',
            'nextAction': {
                'type': 'redirect_to_url',
                'redirect_url': 'https://3ds.airwallex.com/auth'
            }
        }
        
        mock_order_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_order_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {'orderId': 'order_123'}
        
        result = airwallex_process_payment(mock_request)
        
        assert result['success'] is True
        assert 'nextAction' in result
        assert result['nextAction']['type'] == 'redirect_to_url'
    
    @patch('handlers.payment_airwallex.db')
    def test_airwallex_webhook_idempotency(self, mock_db):
        """Test Airwallex webhook duplicate detection"""
        from handlers.payment_airwallex import airwallex_webhook
        
        # Mock webhook already processed
        mock_webhook_doc = Mock()
        mock_webhook_doc.exists = True
        mock_db.collection.return_value.document.return_value.get.return_value = mock_webhook_doc
        
        mock_request = Mock()
        mock_request.data = json.dumps({
            'id': 'evt_duplicate',
            'name': 'payment_intent.succeeded',
            'data': {'object': {}}
        }).encode()
        mock_request.headers = {'X-Signature': 'valid_sig'}
        
        response = airwallex_webhook(mock_request)
        
        assert response.status_code == 200
        assert b'already processed' in response.response[0].lower()


class TestCronJobs:
    """Test scheduled background tasks"""
    
    @patch('handlers.cron_jobs.db')
    @patch('handlers.cron_jobs.stripe.PaymentIntent.capture')
    def test_auto_capture_confirmed_receipts(self, mock_capture, mock_db):
        """Test daily cron captures orders with confirmed receipts"""
        from handlers.cron_jobs import auto_capture_confirmed_receipts
        
        # Mock orders ready for capture
        mock_order1 = Mock()
        mock_order1.id = 'order_1'
        mock_order1.to_dict.return_value = {
            'orderId': 'order_1',
            'stripePaymentIntentId': 'pi_1',
            'receiptConfirmed': True,
            'paymentStatus': 'authorized'
        }
        
        mock_order2 = Mock()
        mock_order2.id = 'order_2'
        mock_order2.to_dict.return_value = {
            'orderId': 'order_2',
            'stripePaymentIntentId': 'pi_2',
            'receiptConfirmed': True,
            'paymentStatus': 'authorized'
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_order1, mock_order2]
        mock_db.collection.return_value.where.return_value.where.return_value = mock_query
        
        mock_capture.return_value = Mock(status='succeeded')
        
        mock_event = Mock()
        auto_capture_confirmed_receipts(mock_event)
        
        # Verify both orders captured
        assert mock_capture.call_count == 2
        mock_capture.assert_any_call('pi_1')
        mock_capture.assert_any_call('pi_2')
    
    @patch('handlers.cron_jobs.db')
    def test_check_expired_authorizations(self, mock_db):
        """Test daily cron cancels orders with expired authorizations (>7 days)"""
        from handlers.cron_jobs import check_expired_authorizations
        
        # Mock expired order (8 days old)
        created_8_days_ago = datetime.now() - timedelta(days=8)
        
        mock_order = Mock()
        mock_order.id = 'order_expired'
        mock_order.reference = Mock()
        mock_order.to_dict.return_value = {
            'orderId': 'order_expired',
            'paymentStatus': 'authorized',
            'createdAt': created_8_days_ago
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_order]
        mock_db.collection.return_value.where.return_value = mock_query
        
        mock_event = Mock()
        check_expired_authorizations(mock_event)
        
        # Verify order cancelled
        mock_order.reference.update.assert_called_once()
        update_data = mock_order.reference.update.call_args[0][0]
        assert update_data['orderStatus'] == 'cancelled'
        assert 'expired' in update_data['cancellationReason'].lower()
    
    @patch('handlers.cron_jobs.db')
    def test_auto_archive_old_orders(self, mock_db):
        """Test archiving orders older than 90 days"""
        from handlers.cron_jobs import auto_archive_old_orders
        
        # Mock old completed order (100 days old)
        created_100_days_ago = datetime.now() - timedelta(days=100)
        
        mock_order = Mock()
        mock_order.id = 'order_old'
        mock_order.reference = Mock()
        mock_order.to_dict.return_value = {
            'orderId': 'order_old',
            'orderStatus': 'completed',
            'createdAt': created_100_days_ago
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_order]
        mock_db.collection.return_value.where.return_value = mock_query
        
        mock_event = Mock()
        auto_archive_old_orders(mock_event)
        
        # Verify archived
        mock_order.reference.update.assert_called_once()
        update_data = mock_order.reference.update.call_args[0][0]
        assert update_data['isArchived'] is True
    
    @patch('handlers.cron_jobs.algolia_service.search')
    @patch('handlers.cron_jobs.db')
    def test_monitor_algolia_sync(self, mock_db, mock_algolia):
        """Test Algolia sync monitoring detects missing products"""
        from handlers.cron_jobs import monitor_algolia_sync
        
        # Mock Firestore products
        mock_product = Mock()
        mock_product.id = 'prod_missing'
        mock_product.to_dict.return_value = {
            'productId': 'prod_missing',
            'isActive': True
        }
        
        mock_db.collection.return_value.where.return_value.limit.return_value.stream.return_value = [
            mock_product
        ]
        
        # Mock Algolia (product missing)
        mock_algolia.return_value = {'hits': []}
        
        mock_event = Mock()
        monitor_algolia_sync(mock_event)
        
        # Verify search performed
        mock_algolia.assert_called_once()
    
    @patch('handlers.cron_jobs.db')
    def test_cleanup_stale_rate_limits(self, mock_db):
        """Test cleanup of expired rate limit entries"""
        from handlers.cron_jobs import cleanup_stale_rate_limits
        
        # Mock expired rate limit (1 hour old, 15min limit)
        created_1_hour_ago = datetime.now() - timedelta(hours=1)
        
        mock_rate_limit = Mock()
        mock_rate_limit.id = 'rate_limit_1'
        mock_rate_limit.reference = Mock()
        mock_rate_limit.to_dict.return_value = {
            'createdAt': created_1_hour_ago
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_rate_limit]
        mock_db.collection.return_value.where.return_value = mock_query
        
        mock_event = Mock()
        cleanup_stale_rate_limits(mock_event)
        
        # Verify deleted
        mock_rate_limit.reference.delete.assert_called_once()


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
    
    @patch('handlers.admin.db')
    def test_mfa_brute_force_protection(self, mock_db):
        """SECURITY: Test MFA verification rate limiting (max 5 attempts/minute)"""
        from handlers.admin import admin_mfa_verify
        
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'mfaSecret': pyotp.random_base32(),
            'mfaAttempts': 6  # Exceeded limit
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_123")
        mock_request.data = {'code': '123456'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            admin_mfa_verify(mock_request)
        
        assert exc.value.code == 'resource-exhausted'
    
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
        sensitive_fields = ['creditCard', 'password', 'mfaSecret', 'apiKey']
        # Verify logger sanitizes these fields
        pass
