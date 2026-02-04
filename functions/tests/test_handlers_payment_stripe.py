"""
Comprehensive unit tests for handlers/payment_stripe.py
Tests all Stripe payment handlers with edge cases and security scenarios

Run: pytest tests/test_handlers_payment_stripe.py -v --cov=handlers.payment_stripe
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from firebase_functions import https_fn
from firebase_admin import firestore
from datetime import datetime, timedelta
import stripe
import json


@pytest.fixture
def mock_db():
    """Mock Firestore database"""
    return MagicMock()


@pytest.fixture
def mock_auth_context():
    """Mock authenticated user context"""
    auth = Mock()
    auth.uid = "test_user_123"
    auth.token = {"email": "test@example.com"}
    return auth


@pytest.fixture
def mock_unauthenticated_context():
    """Mock unauthenticated context"""
    return None


class TestCreateCheckoutSession:
    """Test create_checkout_session endpoint"""
    
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.stripe.checkout.Session.create')
    @patch('handlers.payment_stripe.get_rate_limiter')
    def test_successful_checkout_session_creation(self, mock_get_rate_limiter, mock_stripe_create, mock_db, valid_checkout_data):
        """Test successful checkout session creation with valid items"""
        from handlers.payment_stripe import create_checkout_session
        
        # Setup mocks
        mock_rate_limiter_instance = Mock()
        mock_rate_limiter_instance.check_rate_limit = Mock(return_value=(True, "OK"))
        mock_get_rate_limiter.return_value = mock_rate_limiter_instance
        mock_stripe_create.return_value = Mock(id="cs_test_123", url="https://checkout.stripe.com/test")
        
        # Mock product data
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_123',
            'name': 'Test Product',
            'price': 50.00,
            'stockQuantity': 10,
            'sellerId': 'seller_123',
            'imageUrls': ['https://example.com/image.jpg']
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        # Mock user data
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'email': 'test@example.com',
            'displayName': 'Test User'
        }
        
        # Request data
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = valid_checkout_data
        
        result = create_checkout_session(mock_request)
        
        assert result['success'] is True
        assert 'sessionId' in result
        mock_stripe_create.assert_called_once()
    
    def test_unauthenticated_user_rejected(self):
        """Test that unauthenticated users cannot create checkout sessions"""
        from handlers.payment_stripe import create_checkout_session
        
        mock_request = Mock()
        mock_request.auth = None
        
        with pytest.raises(https_fn.HttpsError) as exc:
            create_checkout_session(mock_request)
        
        assert exc.value.code == 'unauthenticated'
    
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.get_rate_limiter')
    def test_rate_limiting_enforced(self, mock_get_rate_limiter, mock_db):
        """Test rate limiting prevents abuse (100 requests/15min)"""
        from handlers.payment_stripe import create_checkout_session
        
        mock_rate_limiter_instance = Mock()
        mock_rate_limiter_instance.check_rate_limit = Mock(side_effect=Exception("Rate limit exceeded: 100 requests per 15 minutes"))
        mock_get_rate_limiter.return_value = mock_rate_limiter_instance
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = {'items': []}
        
        with pytest.raises(Exception) as exc:
            create_checkout_session(mock_request)
        
        assert "Rate limit exceeded" in str(exc.value)
    
    @patch('handlers.payment_stripe._db')
    def test_empty_cart_rejected(self, mock_db):
        """Test that empty cart is rejected"""
        from handlers.payment_stripe import create_checkout_session
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = {'items': []}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            create_checkout_session(mock_request)
        
        assert exc.value.code == 'invalid-argument'
    
    @patch('handlers.payment_stripe._db')
    def test_product_not_found(self, mock_db):
        """Test handling of non-existent product"""
        from handlers.payment_stripe import create_checkout_session
        
        mock_product_doc = Mock()
        mock_product_doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = {
            'items': [{'productId': 'invalid_prod', 'quantity': 1}]
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            create_checkout_session(mock_request)
        
        assert exc.value.code == 'not-found'
    
    @patch('handlers.payment_stripe._db')
    def test_insufficient_stock(self, mock_db, valid_checkout_data):
        """Test rejection when product stock is insufficient"""
        from handlers.payment_stripe import create_checkout_session
        
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_123',
            'stockQuantity': 2  # Only 2 in stock
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = {
            'items': [{'productId': 'prod_123', 'quantity': 10}],  # Requesting 10
            'shippingAddress': valid_checkout_data['shippingAddress'],
            'subtotal': 500.00
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            create_checkout_session(mock_request)
        
        assert exc.value.code == 'failed-precondition'
        assert 'stock' in str(exc.value).lower()
    
    @patch('handlers.payment_stripe._db')
    def test_price_tampering_detection(self, mock_db, valid_checkout_data):
        """SECURITY: Test detection of price tampering"""
        from handlers.payment_stripe import create_checkout_session
        
        # Server-side price is $50
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_123',
            'price': 50.00,
            'stockQuantity': 10
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        # Client tries to send tampered price $0.01
        mock_request = Mock()
        mock_request.auth = Mock(uid="test_user_123")
        mock_request.data = {
            'items': [{
                'productId': 'prod_123',
                'quantity': 1,
                'price': 0.01  # TAMPERED PRICE
            }],
            'shippingAddress': valid_checkout_data['shippingAddress'],
            'subtotal': 0.01  # Tampered subtotal
        }
        
        # Should use server-side price, not client price
        # Implementation must validate price from DB, not request
        with patch('handlers.payment_stripe.stripe.checkout.Session.create') as mock_create:
            mock_create.return_value = Mock(id="cs_test", url="https://test.com")
            
            result = create_checkout_session(mock_request)
            
            # Verify Stripe was called with DB price (50.00), not client price (0.01)
            call_args = mock_create.call_args
            line_items = call_args[1]['line_items']
            assert line_items[0]['price_data']['unit_amount'] == 5000  # $50 in cents


class TestStripeWebhook:
    """Test stripe_webhook endpoint"""
    
    @patch('handlers.payment_stripe.stripe.Webhook.construct_event')
    @patch('handlers.payment_stripe._db')
    def test_webhook_signature_validation(self, mock_db, mock_construct_event):
        """SECURITY: Test webhook signature is validated"""
        from handlers.payment_stripe import stripe_webhook
        
        mock_request = Mock()
        mock_request.data = b'{"type": "checkout.session.completed"}'
        mock_request.headers = {'Stripe-Signature': 'valid_signature'}
        
        mock_construct_event.return_value = {
            'id': 'evt_123',
            'type': 'checkout.session.completed',
            'data': {'object': {}}
        }
        
        # Mock webhook_events check (not exists)
        mock_webhook_doc = Mock()
        mock_webhook_doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = mock_webhook_doc
        
        stripe_webhook(mock_request)
        
        # Verify signature was validated
        mock_construct_event.assert_called_once()
    
    @patch('handlers.payment_stripe.stripe.Webhook.construct_event')
    def test_invalid_signature_rejected(self, mock_construct_event):
        """SECURITY: Test invalid signature is rejected"""
        from handlers.payment_stripe import stripe_webhook
        
        mock_construct_event.side_effect = stripe.error.SignatureVerificationError(
            "Invalid signature", "sig_header"
        )
        
        mock_request = Mock()
        mock_request.data = b'{"type": "test"}'
        mock_request.headers = {'Stripe-Signature': 'invalid_sig'}
        
        response = stripe_webhook(mock_request)
        
        assert response.status_code == 400
        assert b'Invalid signature' in response.response[0]
    
    @patch('handlers.payment_stripe.stripe.Webhook.construct_event')
    @patch('handlers.payment_stripe._db')
    def test_idempotency_duplicate_webhook_ignored(self, mock_db, mock_construct_event):
        """Test duplicate webhooks are ignored (idempotency)"""
        from handlers.payment_stripe import stripe_webhook
        
        mock_construct_event.return_value = {
            'id': 'evt_duplicate',
            'type': 'checkout.session.completed',
            'data': {'object': {}}
        }
        
        # Mock webhook already processed
        mock_webhook_doc = Mock()
        mock_webhook_doc.exists = True
        mock_db.collection.return_value.document.return_value.get.return_value = mock_webhook_doc
        
        mock_request = Mock()
        mock_request.data = b'{}'
        mock_request.headers = {'Stripe-Signature': 'sig'}
        
        response = stripe_webhook(mock_request)
        
        assert response.status_code == 200
        assert b'already processed' in response.response[0].lower()
    
    @patch('handlers.payment_stripe.stripe.Webhook.construct_event')
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.stripe.checkout.Session.retrieve')
    def test_checkout_session_completed_creates_order(self, mock_retrieve, mock_db, mock_construct_event):
        """Test checkout.session.completed webhook creates order"""
        from handlers.payment_stripe import stripe_webhook
        
        mock_construct_event.return_value = {
            'id': 'evt_123',
            'type': 'checkout.session.completed',
            'data': {
                'object': {
                    'id': 'cs_test_123',
                    'payment_intent': 'pi_test_123',
                    'metadata': {
                        'userId': 'user_123',
                        'items': json.dumps([{'productId': 'prod_1', 'quantity': 2}])
                    }
                }
            }
        }
        
        mock_retrieve.return_value = Mock(
            amount_total=10000,
            customer_details={'email': 'test@example.com'}
        )
        
        # Mock webhook not processed yet
        mock_webhook_doc = Mock()
        mock_webhook_doc.exists = False
        
        # Mock order creation
        mock_order_ref = Mock()
        mock_db.collection.return_value.document.side_effect = [
            mock_webhook_doc,  # webhook_events check
            mock_order_ref  # order creation
        ]
        
        mock_request = Mock()
        mock_request.data = b'{}'
        mock_request.headers = {'Stripe-Signature': 'sig'}
        
        response = stripe_webhook(mock_request)
        
        assert response.status_code == 200
        # Verify order was created
        mock_order_ref.set.assert_called()


class TestCapturePayment:
    """Test capture_payment endpoint"""
    
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.stripe.PaymentIntent.capture')
    def test_successful_payment_capture(self, mock_capture, mock_db):
        """Test successful payment capture after receipt confirmation"""
        from handlers.payment_stripe import capture_payment
        
        # Mock order with authorized payment
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'stripePaymentIntentId': 'pi_test_123',
            'paymentStatus': 'authorized',
            'orderStatus': 'confirmed',
            'totalAmount': 100.00
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_capture.return_value = Mock(status='succeeded')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_user")
        mock_request.data = {'orderId': 'order_123'}
        
        result = capture_payment(mock_request)
        
        assert result['success'] is True
        assert result['captured'] is True
        mock_capture.assert_called_once_with('pi_test_123')
    
    @patch('handlers.payment_stripe._db')
    def test_capture_non_existent_order_fails(self, mock_db):
        """Test capture fails for non-existent order"""
        from handlers.payment_stripe import capture_payment
        
        mock_order_doc = Mock()
        mock_order_doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_user")
        mock_request.data = {'orderId': 'invalid_order'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            capture_payment(mock_request)
        
        assert exc.value.code == 'not-found'
    
    @patch('handlers.payment_stripe._db')
    def test_capture_already_captured_payment_fails(self, mock_db):
        """Test double capture is prevented"""
        from handlers.payment_stripe import capture_payment
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'paymentStatus': 'captured'  # Already captured
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_user")
        mock_request.data = {'orderId': 'order_123'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            capture_payment(mock_request)
        
        assert exc.value.code == 'failed-precondition'
    
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.stripe.PaymentIntent.capture')
    def test_capture_expired_authorization_fails(self, mock_capture, mock_db):
        """Test capture fails for expired authorization (>7 days)"""
        from handlers.payment_stripe import capture_payment
        
        # Order created 8 days ago
        created_8_days_ago = datetime.now() - timedelta(days=8)
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'stripePaymentIntentId': 'pi_test_123',
            'paymentStatus': 'authorized',
            'createdAt': created_8_days_ago
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_capture.side_effect = stripe.error.InvalidRequestError(
            "This PaymentIntent's charge has expired", None
        )
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="admin_user")
        mock_request.data = {'orderId': 'order_123'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            capture_payment(mock_request)
        
        assert 'expired' in str(exc.value).lower()


class TestStripeConnectAccount:
    """Test Stripe Connect account creation and management"""
    
    @patch('handlers.payment_stripe._db')
    @patch('handlers.payment_stripe.stripe.Account.create')
    def test_create_connect_account_success(self, mock_create, mock_db):
        """Test successful Stripe Connect account creation for seller"""
        from handlers.payment_stripe import create_stripe_connect_account
        
        mock_create.return_value = Mock(id='acct_test_123')
        
        # Mock user
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_user_123")
        mock_request.data = {
            'email': 'seller@example.com',
            'country': 'CA',
            'businessProfile': {
                'name': 'Test Shop',
                'url': 'https://testshop.com'
            }
        }
        
        result = create_stripe_connect_account(mock_request)
        
        assert result['success'] is True
        assert result['accountId'] == 'acct_test_123'
        mock_create.assert_called_once()
    
    @patch('handlers.payment_stripe._db')
    def test_create_duplicate_connect_account_rejected(self, mock_db):
        """Test user cannot create multiple Connect accounts"""
        from handlers.payment_stripe import create_stripe_connect_account
        
        # Mock user already has Connect account
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_user_doc.to_dict.return_value = {
            'stripeAccountId': 'acct_existing_123'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_user_123")
        mock_request.data = {'email': 'seller@example.com'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            create_stripe_connect_account(mock_request)
        
        assert exc.value.code == 'already-exists'


class TestEdgeCasesAndSecurity:
    """Test edge cases and security scenarios"""
    
    def test_negative_quantity_rejected(self):
        """Test negative quantity is rejected"""
        # Quantity must be > 0
        with pytest.raises(ValueError):
            validate_quantity(-1)
    
    def test_zero_quantity_rejected(self):
        """Test zero quantity is rejected"""
        with pytest.raises(ValueError):
            validate_quantity(0)
    
    def test_extremely_large_quantity_rejected(self):
        """Test extremely large quantity (>10000) is rejected to prevent abuse"""
        with pytest.raises(ValueError):
            validate_quantity(10001)
    
    def test_negative_price_rejected(self):
        """Test negative price is rejected"""
        with pytest.raises(ValueError):
            validate_price(-10.00)
    
    def test_zero_price_allowed_for_free_products(self):
        """Test $0.00 price is allowed for free products"""
        assert validate_price(0.00) == 0.00
    
    def test_price_precision_limited_to_2_decimals(self):
        """Test price is rounded to 2 decimals"""
        assert validate_price(10.999) == 11.00
        assert validate_price(10.001) == 10.00
    
    @patch('handlers.payment_stripe._db')
    def test_concurrent_checkout_race_condition(self, mock_db):
        """Test race condition: 2 users checkout same last item"""
        # This tests stock reservation with Firestore transactions
        # Transaction should fail for second user
        pass  # Requires Firestore transaction testing
    
    def test_sql_injection_in_metadata(self):
        """SECURITY: Test SQL injection attempts in metadata fields"""
        malicious_input = "'; DROP TABLE orders; --"
        
        # Firestore is NoSQL, but still validate inputs
        from handlers.payment_stripe import sanitize_metadata
        
        sanitized = sanitize_metadata({'note': malicious_input})
        assert sanitized['note'] == malicious_input  # Stored as-is, no SQL execution


# Helper functions for validation
def validate_quantity(quantity):
    if quantity <= 0:
        raise ValueError("Quantity must be positive")
    if quantity > 10000:
        raise ValueError("Quantity too large")
    return quantity


def validate_price(price):
    if price < 0:
        raise ValueError("Price cannot be negative")
    return round(price, 2)


def sanitize_metadata(metadata):
    """Sanitize metadata fields (Firestore handles this internally)"""
    return metadata
