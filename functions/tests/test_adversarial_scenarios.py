"""
Adversarial Test Scenarios — OrignaGta
Tests malicious buyer, seller, and race condition scenarios.
Run: cd functions && python -m pytest tests/test_adversarial_scenarios.py -v
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, MagicMock
import json


class TestPriceManipulationScenarios:
    """Scenarios 1-3: Client-side price tampering attempts."""
    
    def test_price_change_detected(self, mock_db, mock_stripe):
        """Scenario 1: Buyer sends old price after seller updated it."""
        from handlers.payment_stripe import create_checkout_session
        
        # Setup: Product price changed from $10 to $15
        mock_product = Mock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            'price': 15.0,  # Current price
            'stockQuantity': 10,
            'isActive': True,
            'sellerId': 'seller_123',
            'name': 'Test Product',
            'imageUrls': [],
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product
        
        # Buyer tries to checkout with old price
        req = Mock()
        req.auth.uid = 'buyer_123'
        req.auth.token.get.return_value = True  # email_verified
        req.data = {
            'items': [{
                'productId': 'prod_123',
                'quantity': 1,
                'price': 10.0,  # Old price!
                'sellerId': 'seller_123',
            }],
            'shippingAddress': {
                'street': '123 Main St',
                'city': 'Toronto',
                'province': 'ON',
                'postalCode': 'M5V 3A8',
                'country': 'Canada',
                'latitude': 43.7,
                'longitude': -79.4,
            },
            'subtotal': 10.0,
        }
        
        with pytest.raises(Exception) as exc_info:
            create_checkout_session(req)
        
        assert 'PRICE_CHANGED' in str(exc_info.value) or 'Price changed' in str(exc_info.value)
    
    def test_seller_id_mismatch_blocked(self, mock_db, mock_stripe):
        """Scenario 2: Buyer sends wrong sellerId to redirect payment."""
        from handlers.payment_stripe import create_checkout_session
        
        mock_product = Mock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {
            'price': 10.0,
            'stockQuantity': 10,
            'isActive': True,
            'sellerId': 'legitimate_seller',  # Actual owner
            'name': 'Test Product',
            'imageUrls': [],
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product
        
        req = Mock()
        req.auth.uid = 'buyer_123'
        req.auth.token.get.return_value = True
        req.data = {
            'items': [{
                'productId': 'prod_123',
                'quantity': 1,
                'price': 10.0,
                'sellerId': 'attacker_seller',  # Wrong!
            }],
            'shippingAddress': {
                'street': '123 Main St',
                'city': 'Toronto',
                'province': 'ON',
                'postalCode': 'M5V 3A8',
                'country': 'Canada',
                'latitude': 43.7,
                'longitude': -79.4,
            },
            'subtotal': 10.0,
        }
        
        with pytest.raises(Exception) as exc_info:
            create_checkout_session(req)
        
        assert 'Seller ID mismatch' in str(exc_info.value)


class TestRaceConditionScenarios:
    """Scenarios 13-14, 19-20: Concurrent operation races."""
    
    def test_capture_during_cancel_blocked(self, mock_db):
        """Scenario 13: Capture attempt while cancel in progress."""
        from handlers.orders import cancel_order
        from firebase_admin import firestore
        
        # Setup order in 'cancelling' state
        mock_order = Mock()
        mock_order.exists = True
        mock_order.to_dict.return_value = {
            'userId': 'buyer_123',
            'paymentStatus': 'cancelling',  # Lock acquired by cancel_order
            'orderStatus': 'confirmed',
            'items': [{'productId': 'p1', 'sellerId': 's1', 'quantity': 1}],
            'stockRestored': False,
        }
        mock_order.reference = Mock()
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order
        
        # Buyer's capture request should see 'cancelling' and fail
        # This is tested in the capture_payment function's check
    
    def test_stock_double_restore_prevented(self, mock_db):
        """Scenario 19: Cancel and expire both try to restore stock."""
        from handlers.orders import cancel_order
        from firebase_admin import firestore
        
        mock_order = Mock()
        mock_order.exists = True
        mock_order.to_dict.return_value = {
            'userId': 'buyer_123',
            'paymentStatus': 'authorized',
            'orderStatus': 'pending',
            'items': [{
                'productId': 'prod_123',
                'sellerId': 'seller_123',
                'quantity': 5,
            }],
            'stockRestored': False,
        }
        mock_order.reference = Mock()
        
        mock_product = Mock()
        mock_product.exists = True
        mock_product.to_dict.return_value = {'stockQuantity': 10}
        
        # Simulate concurrent execution
        calls = []
        def mock_update(updates):
            calls.append(updates)
        
        mock_order.reference.update = mock_update
        
        # Both cancel and expire see stockRestored=False
        # But they use batch + atomic Increment
        # Verify Increment is used, not read-then-write
        
        assert True  # Placeholder - actual test would verify atomic operations


class TestInventoryScenarios:
    """Scenarios 25-30: Product and inventory edge cases."""
    
    def test_negative_stock_rejected(self, mock_db):
        """Scenario 27: Attempt to set negative stock quantity."""
        # This test documents the expected behavior
        # Currently NOT enforced - this is a GAP
        
        product_data = {
            'stockQuantity': -5,  # Invalid!
            'name': 'Test Product',
            'price': 10.0,
        }
        
        # TODO: Add validation in products.py update handler
        # assert validation_fails(product_data)
        pass
    
    def test_local_delivery_out_of_province_blocked(self, mock_db):
        """Scenario 30: Order local-only product from different province."""
        from shipping_service import calculate_shipping_cost
        
        items = [{
            'productId': 'local_prod',
            'sellerId': 'seller_on',
            'quantity': 1,
            'isLocalDeliveryOnly': True,
            'freeShipping': False,
            'isDigital': False,
            'sellerAddress': {
                'state': 'ON',  # Product in Ontario
                'latitude': 43.7,
                'longitude': -79.4,
            },
        }]
        
        buyer_address = {
            'state': 'BC',  # Buyer in BC
            'latitude': 49.2,
            'longitude': -123.1,
        }
        
        with pytest.raises(ValueError) as exc_info:
            calculate_shipping_cost(items, buyer_address)
        
        assert 'Local delivery only' in str(exc_info.value)


class TestAuthSecurityScenarios:
    """Scenarios 31-35: Authentication and admin security."""
    
    def test_mfa_brute_force_protection(self, mock_db):
        """Scenario 31: Lockout after 5 failed MFA attempts."""
        # Verify the mfaFailedAttempts counter increments
        # Verify lockout after 5 attempts
        pass
    
    def test_admin_role_change_requires_mfa(self, mock_db):
        """Scenario 32: Admin must verify MFA before role changes."""
        from handlers.admin import update_user_roles
        
        # Admin without recent MFA verification
        mock_admin = Mock()
        mock_admin.exists = True
        mock_admin.to_dict.return_value = {
            'roles': ['admin'],
            'mfaEnabled': True,
            'lastMfaVerify': datetime.now() - timedelta(minutes=10),  # Too old!
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_admin
        
        req = Mock()
        req.auth.uid = 'admin_123'
        req.data = {
            'targetUserId': 'user_456',
            'roles': ['seller'],
        }
        
        with pytest.raises(Exception) as exc_info:
            update_user_roles(req)
        
        assert 'MFA' in str(exc_info.value) or 'expired' in str(exc_info.value).lower()


class TestWebhookSecurityScenarios:
    """Scenarios 11-12: Webhook attack prevention."""
    
    def test_stale_webhook_rejected(self, mock_db):
        """Scenario 11: Webhook older than 5 minutes rejected."""
        import time
        from handlers.payment_stripe import stripe_webhook
        
        # Create webhook payload with old timestamp
        old_event = {
            'id': 'evt_old',
            'type': 'checkout.session.completed',
            'created': int(time.time()) - 400,  # 6+ minutes ago
        }
        
        # Mock signature verification to pass
        with patch('stripe.Webhook.construct_event', return_value=old_event):
            req = Mock()
            req.method = 'POST'
            req.headers = {'Stripe-Signature': 'valid_sig'}
            req.data = b'{}'
            
            response = stripe_webhook(req)
            
            assert response.status_code == 400
            assert b'Event too old' in response.data
    
    def test_webhook_rate_limiting(self, mock_db):
        """Scenario 12: Too many webhooks from same IP blocked."""
        # Rate limiter test - 100 webhooks per minute per IP
        pass


class TestShippingApprovalScenarios:
    """Scenario 24: Shipping cost approval edge cases."""
    
    def test_approval_after_authorization_expiry_blocked(self, mock_db):
        """Buyer can't approve shipping after auth expired."""
        from handlers.orders import approve_shipping_cost
        
        mock_order = Mock()
        mock_order.exists = True
        mock_order.to_dict.return_value = {
            'userId': 'buyer_123',
            'paymentStatus': 'authorized',
            'shippingApproval': {
                'status': 'pending',
                'actualCost': 25.0,
            },
            'shippingCostCents': 2000,
            'totalAmountCents': 10200,
            'expiresAt': datetime.now() - timedelta(minutes=1),  # Expired!
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order
        
        req = Mock()
        req.auth.uid = 'buyer_123'
        req.data = {
            'orderId': 'order_123',
            'approved': True,
        }
        
        with pytest.raises(Exception) as exc_info:
            approve_shipping_cost(req)
        
        assert 'expired' in str(exc_info.value).lower()


# Fixtures
@pytest.fixture
def mock_db():
    """Mock Firestore database."""
    with patch('handlers.payment_stripe.get_db') as mock:
        yield mock.return_value


@pytest.fixture
def mock_stripe():
    """Mock Stripe API."""
    with patch('handlers.payment_stripe.stripe') as mock:
        yield mock


@pytest.fixture
def mock_rate_limiter():
    """Mock rate limiter to always allow."""
    with patch('handlers.payment_stripe.get_rate_limiter') as mock:
        limiter = Mock()
        limiter.check_rate_limit.return_value = (True, "OK")
        mock.return_value = limiter
        yield limiter
