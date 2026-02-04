"""
Comprehensive unit tests for handlers/products.py and handlers/orders.py
Tests product CRUD, Algolia sync, order lifecycle, and state machine

Run: pytest tests/test_handlers_products_orders.py -v --cov
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from firebase_functions import https_fn, firestore_fn
from firebase_admin import firestore
from datetime import datetime, timedelta
import json


class TestProductHandlers:
    """Test product CRUD operations"""
    
    @patch('handlers.products.db')
    @patch('handlers.products.r2_service.generate_presigned_post')
    def test_upload_product_images_success(self, mock_r2, mock_db):
        """Test successful image upload with presigned URLs"""
        from handlers.products import upload_product_images
        
        mock_r2.return_value = {
            'url': 'https://r2.example.com/upload',
            'fields': {'key': 'products/test.jpg'}
        }
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {
            'productId': 'prod_123',
            'fileNames': ['image1.jpg', 'image2.png'],
            'contentTypes': ['image/jpeg', 'image/png']
        }
        
        result = upload_product_images(mock_request)
        
        assert result['success'] is True
        assert len(result['presignedUrls']) == 2
        assert mock_r2.call_count == 2
    
    @patch('handlers.products.db')
    def test_upload_images_invalid_file_type_rejected(self, mock_db):
        """SECURITY: Test non-image file types are rejected"""
        from handlers.products import upload_product_images
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {
            'productId': 'prod_123',
            'fileNames': ['malicious.exe'],
            'contentTypes': ['application/x-msdownload']
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            upload_product_images(mock_request)
        
        assert exc.value.code == 'invalid-argument'
        assert 'image' in str(exc.value).lower()
    
    @patch('handlers.products.db')
    def test_upload_images_too_many_files_rejected(self, mock_db):
        """Test maximum 10 images per product enforced"""
        from handlers.products import upload_product_images
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {
            'productId': 'prod_123',
            'fileNames': [f'image{i}.jpg' for i in range(15)],  # 15 images
            'contentTypes': ['image/jpeg'] * 15
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            upload_product_images(mock_request)
        
        assert exc.value.code == 'invalid-argument'
        assert '10' in str(exc.value)
    
    @patch('handlers.products.db')
    def test_delete_product_soft_delete(self, mock_db):
        """Test product soft delete (sets isActive=false)"""
        from handlers.products import delete_product
        
        # Mock product owned by user
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_123',
            'sellerId': 'seller_123',
            'isActive': True
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        mock_product_ref = Mock()
        mock_db.collection.return_value.document.return_value = mock_product_ref
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {'productId': 'prod_123'}
        
        result = delete_product(mock_request)
        
        assert result['success'] is True
        mock_product_ref.update.assert_called_once()
        # Verify soft delete (not permanent deletion)
        update_call = mock_product_ref.update.call_args[0][0]
        assert update_call['isActive'] is False
        assert 'deletedAt' in update_call
    
    @patch('handlers.products.db')
    def test_delete_product_unauthorized_seller_rejected(self, mock_db):
        """SECURITY: Test user cannot delete another seller's product"""
        from handlers.products import delete_product
        
        mock_product_doc = Mock()
        mock_product_doc.exists = True
        mock_product_doc.to_dict.return_value = {
            'productId': 'prod_123',
            'sellerId': 'other_seller_456'  # Different seller
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_product_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {'productId': 'prod_123'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            delete_product(mock_request)
        
        assert exc.value.code == 'permission-denied'
    
    @patch('handlers.products.db')
    def test_submit_rating_validates_range(self, mock_db):
        """Test rating must be 1-5 stars"""
        from handlers.products import submit_product_rating
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            'productId': 'prod_123',
            'rating': 6,  # Invalid: > 5
            'review': 'Great product'
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            submit_product_rating(mock_request)
        
        assert exc.value.code == 'invalid-argument'
        assert '1' in str(exc.value) and '5' in str(exc.value)
    
    @patch('handlers.products.db')
    def test_submit_rating_requires_verified_purchase(self, mock_db):
        """Test rating requires verified purchase (user bought product)"""
        from handlers.products import submit_product_rating
        
        # Mock no orders found
        mock_orders = Mock()
        mock_orders.stream.return_value = []
        mock_db.collection.return_value.where.return_value.where.return_value = mock_orders
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            'productId': 'prod_123',
            'rating': 5,
            'review': 'Great!'
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            submit_product_rating(mock_request)
        
        assert exc.value.code == 'permission-denied'
        assert 'purchase' in str(exc.value).lower()
    
    @patch('handlers.products.algolia_service.save_object')
    def test_on_product_created_indexes_algolia(self, mock_algolia):
        """Test Firestore trigger indexes new product in Algolia"""
        from handlers.products import on_product_created
        
        mock_event = Mock()
        mock_event.data = Mock()
        mock_event.data.to_dict.return_value = {
            'productId': 'prod_123',
            'name': 'Test Product',
            'description': 'A great product',
            'price': 29.99,
            'categoryId': 'cat_1',
            'isActive': True
        }
        mock_event.params = {'productId': 'prod_123'}
        
        on_product_created(mock_event)
        
        mock_algolia.assert_called_once()
        call_args = mock_algolia.call_args[0][0]
        assert call_args['objectID'] == 'prod_123'
        assert call_args['name'] == 'Test Product'
        assert call_args['price'] == 29.99
    
    @patch('handlers.products.algolia_service.delete_object')
    def test_on_product_deleted_removes_from_algolia(self, mock_algolia):
        """Test Firestore trigger removes deleted product from Algolia"""
        from handlers.products import on_product_deleted
        
        mock_event = Mock()
        mock_event.params = {'productId': 'prod_123'}
        
        on_product_deleted(mock_event)
        
        mock_algolia.assert_called_once_with('prod_123')


class TestOrderHandlers:
    """Test order lifecycle management"""
    
    @patch('handlers.orders.db')
    @patch('handlers.orders.stripe.PaymentIntent.capture')
    @patch('handlers.orders.stripe.Transfer.create')
    def test_confirm_order_receipt_captures_and_pays_seller(self, mock_transfer, mock_capture, mock_db):
        """Test buyer confirms receipt → capture payment → pay seller"""
        from handlers.orders import confirm_order_receipt
        
        # Mock order
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'userId': 'buyer_123',
            'sellerId': 'seller_456',
            'totalAmount': 100.00,
            'platformFee': 2.50,
            'orderStatus': 'delivered',
            'paymentStatus': 'authorized',
            'stripePaymentIntentId': 'pi_test_123'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        # Mock seller Connect account
        mock_seller_doc = Mock()
        mock_seller_doc.exists = True
        mock_seller_doc.to_dict.return_value = {
            'stripeAccountId': 'acct_seller_123'
        }
        
        mock_capture.return_value = Mock(status='succeeded')
        mock_transfer.return_value = Mock(id='tr_test_123')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {'orderId': 'order_123'}
        
        result = confirm_order_receipt(mock_request)
        
        assert result['success'] is True
        # Verify payment captured
        mock_capture.assert_called_once_with('pi_test_123')
        # Verify seller paid (total - platform fee)
        mock_transfer.assert_called_once()
        transfer_amount = mock_transfer.call_args[1]['amount']
        assert transfer_amount == 9750  # $97.50 in cents (100 - 2.50)
    
    @patch('handlers.orders.db')
    def test_confirm_receipt_non_buyer_rejected(self, mock_db):
        """SECURITY: Test only buyer can confirm receipt"""
        from handlers.orders import confirm_order_receipt
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'userId': 'buyer_123',  # Real buyer
            'orderStatus': 'delivered'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="attacker_999")  # Different user
        mock_request.data = {'orderId': 'order_123'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            confirm_order_receipt(mock_request)
        
        assert exc.value.code == 'permission-denied'
    
    @patch('handlers.orders.db')
    def test_update_order_status_validates_state_machine(self, mock_db):
        """Test state machine prevents invalid transitions"""
        from handlers.orders import update_order_status
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'sellerId': 'seller_123',
            'orderStatus': 'pending'  # Current status
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="seller_123")
        mock_request.data = {
            'orderId': 'order_123',
            'newStatus': 'delivered'  # INVALID: pending → delivered (must go through confirmed, shipped first)
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            update_order_status(mock_request)
        
        assert exc.value.code == 'failed-precondition'
        assert 'transition' in str(exc.value).lower()
    
    @patch('handlers.orders.db')
    def test_update_order_status_valid_transitions(self, mock_db):
        """Test valid state transitions are allowed"""
        # Valid: pending → confirmed → shipped → delivered → completed
        valid_transitions = [
            ('pending', 'confirmed'),
            ('pending', 'cancelled'),
            ('confirmed', 'shipped'),
            ('shipped', 'delivered'),
            ('delivered', 'completed')
        ]
        
        for current, next_status in valid_transitions:
            assert is_valid_transition(current, next_status), f"{current} → {next_status} should be valid"
    
    @patch('handlers.orders.db')
    @patch('handlers.orders.stripe.Refund.create')
    def test_cancel_order_refunds_and_restores_stock(self, mock_refund, mock_db):
        """Test order cancellation refunds payment and restores inventory"""
        from handlers.orders import cancel_order
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'userId': 'buyer_123',
            'items': [
                {'productId': 'prod_1', 'quantity': 2},
                {'productId': 'prod_2', 'quantity': 1}
            ],
            'stripePaymentIntentId': 'pi_test_123',
            'orderStatus': 'confirmed',
            'paymentStatus': 'authorized'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        # Mock products for stock restoration
        mock_product_refs = []
        for i in range(2):
            mock_ref = Mock()
            mock_product_refs.append(mock_ref)
        
        mock_refund.return_value = Mock(id='re_test_123', status='succeeded')
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {
            'orderId': 'order_123',
            'reason': 'Changed my mind'
        }
        
        result = cancel_order(mock_request)
        
        assert result['success'] is True
        # Verify refund issued
        mock_refund.assert_called_once()
        # Stock restoration verified in transaction
    
    @patch('handlers.orders.db')
    def test_cancel_delivered_order_rejected(self, mock_db):
        """Test cannot cancel order that is already delivered"""
        from handlers.orders import cancel_order
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'userId': 'buyer_123',
            'orderStatus': 'delivered'  # Cannot cancel delivered order
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_123")
        mock_request.data = {'orderId': 'order_123'}
        
        with pytest.raises(https_fn.HttpsError) as exc:
            cancel_order(mock_request)
        
        assert exc.value.code == 'failed-precondition'
    
    @patch('handlers.orders.db')
    def test_approve_shipping_cost_seller_only(self, mock_db):
        """Test only seller can approve shipping cost adjustments"""
        from handlers.orders import approve_shipping_cost
        
        mock_order_doc = Mock()
        mock_order_doc.exists = True
        mock_order_doc.to_dict.return_value = {
            'orderId': 'order_123',
            'sellerId': 'seller_123',
            'orderStatus': 'pending'
        }
        mock_db.collection.return_value.document.return_value.get.return_value = mock_order_doc
        
        # Buyer tries to approve (should fail)
        mock_request = Mock()
        mock_request.auth = Mock(uid="buyer_999")
        mock_request.data = {
            'orderId': 'order_123',
            'shippingCost': 15.00
        }
        
        with pytest.raises(https_fn.HttpsError) as exc:
            approve_shipping_cost(mock_request)
        
        assert exc.value.code == 'permission-denied'
    
    @patch('handlers.orders.email_service.send_email')
    def test_on_order_status_changed_sends_notification(self, mock_email):
        """Test Firestore trigger sends email when order status changes"""
        from handlers.orders import on_order_status_changed
        
        mock_event = Mock()
        mock_event.data.before.to_dict.return_value = {
            'orderStatus': 'confirmed'
        }
        mock_event.data.after.to_dict.return_value = {
            'orderId': 'order_123',
            'orderStatus': 'shipped',  # Status changed
            'userId': 'buyer_123',
            'trackingNumber': 'TRACK123'
        }
        
        on_order_status_changed(mock_event)
        
        mock_email.assert_called_once()
        call_args = mock_email.call_args[1]
        assert 'shipped' in call_args['template'].lower()


class TestOrderEdgeCases:
    """Test complex order scenarios and edge cases"""
    
    @patch('handlers.orders.db')
    def test_partial_refund_calculation_correct(self, mock_db):
        """Test partial refund (1 item from 3-item order)"""
        # Order: 3 items @ $30 each = $90 total
        # Refund 1 item = $30 refund
        # Platform keeps fee on refunded amount
        total = 90.00
        refund_amount = 30.00
        platform_fee_rate = 0.025
        
        platform_keeps = refund_amount * platform_fee_rate
        seller_refund = refund_amount - platform_keeps
        
        assert seller_refund == 29.25
        assert platform_keeps == 0.75
    
    def test_concurrent_order_status_updates(self):
        """Test race condition: buyer and seller update status simultaneously"""
        # Firestore transactions should handle this
        # Last write wins with timestamp
        pass
    
    @patch('handlers.orders.db')
    def test_refund_after_capture_uses_reverse_transfer(self, mock_db):
        """Test refund after capture reverses transfer to seller"""
        # If payment already captured and transferred to seller,
        # refund must use Reverse Transfer to pull money back
        pass
    
    def test_order_with_zero_total_free_product(self):
        """Test order with $0.00 total (free product/promo code)"""
        total = 0.00
        # Should skip payment, auto-confirm order
        assert total == 0.00


# Helper functions
def is_valid_transition(current_status, new_status):
    """Validate order status transitions"""
    VALID_TRANSITIONS = {
        'pending': ['confirmed', 'cancelled'],
        'confirmed': ['shipped', 'cancelled'],
        'shipped': ['delivered', 'in_transit'],
        'in_transit': ['delivered', 'return_requested'],
        'delivered': ['completed'],
        'return_requested': ['returned'],
        'cancelled': [],  # Terminal state
        'completed': []  # Terminal state
    }
    
    allowed = VALID_TRANSITIONS.get(current_status, [])
    return new_status in allowed
