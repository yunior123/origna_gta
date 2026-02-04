"""
End-to-End Integration Tests - Full User Journeys
Tests complete workflows from cart to payout with all services

Run: pytest tests/test_e2e_integration.py -v --slow
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from firebase_functions import https_fn
from firebase_admin import firestore
from datetime import datetime
import stripe
import json

# Skip all e2e tests - they require full service integration
pytestmark = pytest.mark.skip(reason="E2E tests require full service integration and Firebase emulator")


class TestCompleteCheckoutFlow:
    """Test complete checkout flow: cart → payment → order → payout"""
    
    @patch('handlers.payment_stripe.stripe.checkout.Session.create')
    @patch('handlers.payment_stripe.stripe.PaymentIntent.capture')
    @patch('handlers.payment_stripe.stripe.Transfer.create')
    @patch('handlers.payment_stripe._db')
    def test_e2e_successful_purchase_flow(
        self, mock_db, mock_transfer, mock_capture, mock_stripe_session
    ):
        """
        E2E Test: Complete purchase flow
        1. User adds product to cart
        2. Creates checkout session
        3. Stripe webhook confirms payment
        4. Buyer confirms receipt
        5. Payment captured
        6. Seller receives payout
        """
        from handlers.payment_stripe import create_checkout_session, stripe_webhook
        from handlers.orders import confirm_order_receipt
        
        # Step 1: Mock product in DB
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_e2e',
            'name': 'Test Product',
            'price': 100.00,
            'stockQuantity': 5,
            'sellerId': 'seller_123',
            'imageUrls': ['https://example.com/img.jpg']
        }
        
        # Step 2: Create checkout session
        mock_stripe_session.return_value = Mock(
            id='cs_e2e_test',
            url='https://checkout.stripe.com/e2e'
        )
        
        mock_request = Mock()
        mock_request.auth = Mock(uid='buyer_123')
        mock_request.data = {
            'items': [{'productId': 'prod_e2e', 'quantity': 2}],
            'shippingAddress': {
                'street': '123 Main St',
                'city': 'Toronto',
                'state': 'ON',
                'postalCode': 'M5V3A8',
                'country': 'Canada'
            }
        }
        
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        # Execute: Create checkout
        result = create_checkout_session(mock_request)
        
        assert result['success'] is True
        checkout_session_id = result['sessionId']
        
        # Step 3: Simulate Stripe webhook (payment succeeded)
        mock_webhook_event = {
            'id': 'evt_e2e_test',
            'type': 'checkout.session.completed',
            'data': {
                'object': {
                    'id': checkout_session_id,
                    'payment_intent': 'pi_e2e_test',
                    'metadata': {
                        'userId': 'buyer_123',
                        'items': json.dumps([{'productId': 'prod_e2e', 'quantity': 2}])
                    }
                }
            }
        }
        
        # Mock order creation
        mock_order_ref = Mock()
        mock_order_doc = Mock()
        mock_order_doc.exists = False  # Webhook not processed yet
        
        with patch('handlers.payment_stripe.stripe.Webhook.construct_event') as mock_construct:
            mock_construct.return_value = mock_webhook_event
            
            webhook_request = Mock()
            webhook_request.data = json.dumps(mock_webhook_event).encode()
            webhook_request.headers = {'Stripe-Signature': 'valid_sig'}
            
            response = stripe_webhook(webhook_request)
            assert response.status_code == 200
        
        # Step 4: Buyer confirms receipt
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_e2e',
            'userId': 'buyer_123',
            'sellerId': 'seller_123',
            'totalAmount': 200.00,
            'platformFee': 5.00,
            'orderStatus': 'delivered',
            'paymentStatus': 'authorized',
            'stripePaymentIntentId': 'pi_e2e_test'
        }
        
        # Mock seller with Connect account
        mock_seller_doc = Mock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            'stripeAccountId': 'acct_seller_123'
        }
        
        mock_capture.return_value = Mock(status='succeeded')
        mock_transfer.return_value = Mock(id='tr_e2e_test')
        
        confirm_request = Mock()
        confirm_request.auth = Mock(uid='buyer_123')
        confirm_request.data = {'orderId': 'order_e2e'}
        
        # Execute: Confirm receipt (triggers capture + payout)
        result = confirm_order_receipt(confirm_request)
        
        assert result['success'] is True
        
        # Verify payment captured
        mock_capture.assert_called_once_with('pi_e2e_test')
        
        # Verify seller paid ($200 - $5 fee = $195)
        mock_transfer.assert_called_once()
        transfer_call = mock_transfer.call_args
        assert transfer_call[1]['amount'] == 19500  # $195 in cents
        assert transfer_call[1]['destination'] == 'acct_seller_123'


class TestOrderCancellationFlow:
    """Test order cancellation with refund and stock restoration"""
    
    @patch('handlers.orders.stripe.Refund.create')
    @patch('handlers.orders.db')
    def test_e2e_order_cancellation_before_shipment(self, mock_db, mock_refund):
        """
        E2E Test: Order cancellation
        1. Order placed (payment authorized)
        2. Buyer cancels before shipment
        3. Payment refunded
        4. Stock restored
        5. Seller notified
        """
        from handlers.orders import cancel_order
        
        # Mock order
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_cancel_test',
            'userId': 'buyer_123',
            'items': [
                {'productId': 'prod_1', 'quantity': 2},
                {'productId': 'prod_2', 'quantity': 1}
            ],
            'stripePaymentIntentId': 'pi_cancel_test',
            'orderStatus': 'confirmed',
            'paymentStatus': 'authorized',
            'totalAmount': 150.00
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        # Mock refund
        mock_refund.return_value = Mock(id='re_test', status='succeeded')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid='buyer_123')
        mock_request.data = {
            'orderId': 'order_cancel_test',
            'reason': 'Changed my mind'
        }
        
        result = cancel_order(mock_request)
        
        assert result['success'] is True
        # Verify refund issued
        mock_refund.assert_called_once()


class TestSellerOnboardingFlow:
    """Test seller onboarding with Stripe Connect"""
    
    @patch('handlers.payment_stripe.stripe.Account.create')
    @patch('handlers.payment_stripe.stripe.AccountLink.create')
    @patch('handlers.payment_stripe._db')
    def test_e2e_seller_connect_account_setup(
        self, mock_db, mock_account_link, mock_account_create
    ):
        """
        E2E Test: Seller onboarding
        1. Seller creates account
        2. Stripe Connect account created
        3. Onboarding link generated
        4. Seller completes verification
        5. Account activated
        """
        from handlers.payment_stripe import (
            create_stripe_connect_account,
            create_stripe_connect_account_link
        )
        
        # Mock user
        mock_user_doc = Mock()
        mock_user_doc.exists = True
        mock_db.collection.return_value.document.return_value.get.return_value = mock_user_doc
        
        # Step 1: Create Connect account
        mock_account_create.return_value = Mock(id='acct_seller_new')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid='seller_new')
        mock_request.data = {
            'email': 'seller@example.com',
            'country': 'CA',
            'businessProfile': {
                'name': 'My Shop',
                'url': 'https://myshop.com'
            }
        }
        
        result = create_stripe_connect_account(mock_request)
        
        assert result['success'] is True
        assert result['accountId'] == 'acct_seller_new'
        
        # Step 2: Generate onboarding link
        mock_account_link.return_value = Mock(
            url='https://connect.stripe.com/setup/acct_seller_new'
        )
        
        link_request = Mock()
        link_request.auth = Mock(uid='seller_new')
        link_request.data = {
            'accountId': 'acct_seller_new',
            'returnUrl': 'https://origna.ca/seller/dashboard',
            'refreshUrl': 'https://origna.ca/seller/setup'
        }
        
        result = create_stripe_connect_account_link(link_request)
        
        assert result['success'] is True
        assert 'onboardingUrl' in result


class TestProductSearchAndDiscovery:
    """Test product search with Algolia fallback"""
    
    @patch('handlers.products.algolia_service.search')
    @patch('handlers.products.db')
    def test_e2e_product_search_with_algolia(self, mock_db, mock_algolia):
        """
        E2E Test: Product search
        1. User searches "laptop"
        2. Algolia returns results (50ms)
        3. Results displayed
        """
        # Mock Algolia results
        mock_algolia.return_value = {
            'hits': [
                {
                    'objectID': 'prod_1',
                    'name': 'MacBook Pro',
                    'price': 2500.00,
                    'categoryId': 'electronics'
                },
                {
                    'objectID': 'prod_2',
                    'name': 'Dell Laptop',
                    'price': 1200.00,
                    'categoryId': 'electronics'
                }
            ],
            'nbHits': 2,
            'processingTimeMS': 45
        }
        
        from handlers.products import search_products
        
        mock_request = Mock()
        mock_request.data = {'query': 'laptop', 'limit': 20}
        
        # Execute search
        result = search_products(mock_request)
        
        assert result['success'] is True
        assert len(result['products']) == 2
        assert result['products'][0]['name'] == 'MacBook Pro'
        assert result['processingTimeMS'] < 100  # Fast
    
    @patch('handlers.products.algolia_service.search')
    @patch('handlers.products.db')
    def test_e2e_search_fallback_to_firestore(self, mock_db, mock_algolia):
        """
        E2E Test: Search fallback
        1. User searches "laptop"
        2. Algolia fails (service down)
        3. Fallback to Firestore query
        4. Results still returned (slower)
        """
        # Algolia fails
        mock_algolia.side_effect = Exception('Algolia unavailable')
        
        # Mock Firestore fallback
        mock_product1 = Mock()
        mock_product1.to_dict.return_value = {
            'productId': 'prod_1',
            'name': 'MacBook Pro',
            'price': 2500.00
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_product1]
        mock_db.collection.return_value.where.return_value.limit.return_value = mock_query
        
        from handlers.products import search_products
        
        mock_request = Mock()
        mock_request.data = {'query': 'laptop'}
        
        result = search_products(mock_request)
        
        assert result['success'] is True
        assert len(result['products']) == 1
        assert result['source'] == 'firestore'  # Fallback used


class TestAdminModeration:
    """Test admin moderation and seller suspension"""
    
    @patch('handlers.admin.db')
    def test_e2e_suspend_seller_workflow(self, mock_db):
        """
        E2E Test: Seller suspension
        1. Admin detects policy violation
        2. Admin suspends seller (requires MFA)
        3. All seller's products deactivated
        4. Active orders cancelled
        5. Seller notified
        """
        from handlers.admin import suspend_seller
        
        # Mock admin with MFA
        mock_admin_doc = Mock()
        mock_admin_doc.exists = True
        mock_admin_doc.to_dict.return_value = {
            'userId': 'admin_123',
            'role': 'admin',
            'mfaEnabled': True,
            'mfaVerifiedAt': datetime.now()
        }
        
        # Mock seller
        mock_seller_doc = Mock()
        mock_seller_doc.exists = True
        
        # Mock seller's products
        mock_product1 = Mock()
        mock_product1.reference = Mock()
        mock_product2 = Mock()
        mock_product2.reference = Mock()
        
        mock_products = Mock()
        mock_products.stream.return_value = [mock_product1, mock_product2]
        
        # Mock seller's active orders
        mock_order1 = Mock()
        mock_order1.reference = Mock()
        
        mock_orders = Mock()
        mock_orders.stream.return_value = [mock_order1]
        
        mock_db.collection.return_value.document.return_value.get.side_effect = [
            mock_admin_doc,
            mock_seller_doc
        ]
        mock_db.collection.return_value.where.return_value.side_effect = [
            mock_products,
            mock_orders
        ]
        
        mock_request = Mock()
        mock_request.auth = Mock(uid='admin_123')
        mock_request.data = {
            'sellerId': 'seller_violator',
            'reason': 'Counterfeit products detected'
        }
        
        result = suspend_seller(mock_request)
        
        assert result['success'] is True
        # Verify products deactivated
        assert mock_product1.reference.update.called
        assert mock_product2.reference.update.called
        # Verify orders cancelled
        assert mock_order1.reference.update.called


class TestCronJobExecution:
    """Test scheduled tasks execution"""
    
    @patch('handlers.cron_jobs.stripe.PaymentIntent.capture')
    @patch('handlers.cron_jobs.db')
    def test_e2e_auto_capture_cron(self, mock_db, mock_capture):
        """
        E2E Test: Auto-capture cron job
        1. Cron runs daily at 01:00 UTC
        2. Finds orders with confirmed receipts
        3. Captures payments
        4. Transfers to sellers
        """
        from handlers.cron_jobs import auto_capture_confirmed_receipts
        
        # Mock orders ready for capture
        mock_order1 = Mock()
        mock_order1.id = 'order_auto_1'
        mock_order1.to_dict.return_value = {
            'orderId': 'order_auto_1',
            'stripePaymentIntentId': 'pi_auto_1',
            'receiptConfirmed': True,
            'paymentStatus': 'authorized'
        }
        
        mock_order2 = Mock()
        mock_order2.id = 'order_auto_2'
        mock_order2.to_dict.return_value = {
            'orderId': 'order_auto_2',
            'stripePaymentIntentId': 'pi_auto_2',
            'receiptConfirmed': True,
            'paymentStatus': 'authorized'
        }
        
        mock_query = Mock()
        mock_query.stream.return_value = [mock_order1, mock_order2]
        mock_db.collection.return_value.where.return_value.where.return_value = mock_query
        
        mock_capture.return_value = Mock(status='succeeded')
        
        mock_event = Mock()
        auto_capture_confirmed_receipts(mock_event)
        
        # Verify both captures
        assert mock_capture.call_count == 2
        mock_capture.assert_any_call('pi_auto_1')
        mock_capture.assert_any_call('pi_auto_2')


class TestRateLimiting:
    """Test rate limiting and abuse prevention"""
    
    @patch('handlers.payment_stripe.rate_limiter.check_rate_limit')
    def test_e2e_rate_limit_enforcement(self, mock_rate_limit):
        """
        E2E Test: Rate limiting
        1. User makes 100 requests in 10 minutes
        2. 101st request rejected
        3. Rate limit window expires after 15 minutes
        4. User can make requests again
        """
        from handlers.payment_stripe import create_checkout_session
        
        # First 100 requests OK
        mock_rate_limit.return_value = None
        
        # 101st request rejected
        mock_rate_limit.side_effect = Exception('Rate limit exceeded: 100 requests per 15 minutes')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid='abuser_123')
        mock_request.data = {'items': []}
        
        with pytest.raises(Exception) as exc:
            create_checkout_session(mock_request)
        
        assert 'Rate limit exceeded' in str(exc.value)


# Helper function stubs (would be imported from actual handlers)
def search_products(request):
    """Placeholder for actual search function"""
    pass
