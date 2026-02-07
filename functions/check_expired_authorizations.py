"""
Cloud Function to check and cancel expired payment authorizations.
Runs via Cloud Scheduler daily to ensure authorizations don't expire.

Stripe authorizations are valid for 7 days. After this period:
- Funds are automatically released back to customer
- Order cannot be captured
- Must create new payment

This function:
1. Finds orders with paymentStatus='authorized' and authorizationExpiresAt < now
2. Updates status to CANCELLED with reason 'authorization_expired'
3. Restores stock to prevent overselling
4. Sends notification emails to buyer and seller
"""

from datetime import datetime
from firebase_functions import https_fn, scheduler_fn
from firebase_admin import firestore
from config import Collections
from schema_constants import OrderStatusValues as OrderStatus
from email_service import send_authorization_expired_email
import traceback

db = firestore.client()


@scheduler_fn.on_schedule(schedule="0 2 * * *")  # Run daily at 2 AM UTC
def check_expired_authorizations_scheduled(event: scheduler_fn.ScheduledEvent):
    """Scheduled job to check expired authorizations"""
    print("=" * 80)
    print("🕐 SCHEDULED JOB: Checking expired authorizations")
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    result = _process_expired_authorizations()
    
    print(f"✅ Job completed: {result['cancelled_count']} orders cancelled")
    print("=" * 80)
    return result


@https_fn.on_request()
def check_expired_authorizations_http(req: https_fn.Request) -> https_fn.Response:
    """HTTP endpoint to manually trigger check (for testing)"""
    print("=" * 80)
    print("🔧 MANUAL TRIGGER: Checking expired authorizations")
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    try:
        result = _process_expired_authorizations()
        
        print(f"✅ Manual check completed: {result['cancelled_count']} orders cancelled")
        print("=" * 80)
        
        return https_fn.Response(
            status=200,
            headers={"Content-Type": "application/json"},
            response=str(result)
        )
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        print(traceback.format_exc())
        return https_fn.Response(
            status=500,
            headers={"Content-Type": "application/json"},
            response=str({"error": str(e)})
        )


def _process_expired_authorizations() -> dict:
    """Core logic to process expired authorizations"""
    now = datetime.utcnow()
    cancelled_count = 0
    error_count = 0
    
    try:
        # Query orders with expired authorizations
        expired_orders = db.collection(Collections.ORDERS).where(
            'paymentStatus', '==', 'authorized'
        ).where(
            'authorizationExpiresAt', '<', now
        ).stream()
        
        for order_doc in expired_orders:
            order_id = order_doc.id
            order_data = order_doc.to_dict()
            
            print(f"\n⏰ Processing expired authorization: {order_id}")
            print(f"  Authorized at: {order_data.get('authorizedAt')}")
            print(f"  Expired at: {order_data.get('authorizationExpiresAt')}")
            
            try:
                # CRITICAL FIX: Use transaction to prevent race condition
                # Without this, seller could accept order while cron cancels it
                @firestore.transactional
                def cancel_if_still_authorized(transaction, ref):
                    snapshot = ref.get(transaction=transaction)
                    current_status = snapshot.get('paymentStatus')
                    
                    # Only cancel if STILL authorized (not confirmed/captured)
                    if current_status == 'authorized':
                        transaction.update(ref, {
                            'status': OrderStatus.CANCELLED,
                            'paymentStatus': 'authorization_expired',
                            'cancelledAt': firestore.SERVER_TIMESTAMP,
                            'cancelReason': 'Payment authorization expired after 7 days',
                            'updatedAt': firestore.SERVER_TIMESTAMP,
                        })
                        return True
                    else:
                        print(f"  ⏭️ Skipping: Status changed to {current_status}")
                        return False
                
                transaction = db.transaction()
                was_cancelled = cancel_if_still_authorized(transaction, order_doc.reference)
                
                if was_cancelled:
                    # Restore stock for all items
                    _restore_stock_for_order(order_data)
                    
                    # Send notification emails
                    try:
                        send_authorization_expired_email(order_id, order_data)
                    except Exception as email_error:
                        print(f"  ⚠️ Email notification failed: {str(email_error)}")
                    
                    cancelled_count += 1
                    print(f"  ✅ Order cancelled and stock restored")
                
            except Exception as e:
                error_count += 1
                print(f"  ❌ Failed to process order {order_id}: {str(e)}")
                print(traceback.format_exc())
        
        return {
            "success": True,
            "cancelled_count": cancelled_count,
            "error_count": error_count,
            "checked_at": now.isoformat()
        }
        
    except Exception as e:
        print(f"❌ Query failed: {str(e)}")
        print(traceback.format_exc())
        return {
            "success": False,
            "cancelled_count": cancelled_count,
            "error_count": error_count + 1,
            "error": str(e)
        }


def _restore_stock_for_order(order_data: dict) -> None:
    """Restore stock for all items in an order"""
    print("  📦 Restoring stock...")
    try:
        items = order_data.get('items', [])
        for item in items:
            product_id = item.get('productId')
            quantity = item.get('quantity', 1)
            
            if product_id:
                product_ref = db.collection(Collections.PRODUCTS).document(product_id)
                product_ref.update({
                    'stockQuantity': firestore.Increment(quantity)
                })
                print(f"    ✓ Restored {quantity} units for product {product_id}")
    except Exception as e:
        print(f"  ⚠️ Failed to restore stock: {str(e)}")
        # Don't raise - log and continue
