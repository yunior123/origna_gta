import json
import re
from datetime import datetime
from typing import Any, Dict, Optional
from firebase_functions import https_fn
from firebase_admin import firestore
from config import IS_EMULATOR

def create_success_response(data: Dict[str, Any], status_code: int = 200) -> https_fn.Response:
    """Create standardized success response"""
    response_data = {"success": True, **data}
    return https_fn.Response(
        json.dumps(response_data),
        status=status_code,
        headers={"Content-Type": "application/json"}
    )

def create_error_response(error: str, status_code: int = 400, details: Optional[str] = None) -> https_fn.Response:
    """Create standardized error response"""
    response_data = {
        "success": False,
        "error": error,
        "details": details,
        "timestamp": datetime.now().isoformat()
    }
    return https_fn.Response(
        json.dumps(response_data),
        status=status_code,
        headers={"Content-Type": "application/json"}
    )

def sanitize_email(email: str) -> str:
    """Sanitize and validate email address"""
    email = email.strip().lower()
    if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email):
        raise ValueError("Invalid email format")
    return email

def validate_item(item: Dict) -> tuple[bool, str]:
    """Validate individual item data"""
    if not item.get('sellerId'):
        return False, "sellerId required for all items"
    if not item.get('productId'):
        return False, "productId required for all items"
    quantity = item.get('quantity', 0)
    if not isinstance(quantity, int):
        return False, "quantity must be integer"
    if quantity <= 0:
        return False, "quantity must be positive"
    if quantity > 100:
        return False, "quantity exceeds maximum"
    if item.get('price', 0) < 0:
        return False, "price cannot be negative"
    if not item.get('name'):
        return False, "name required for all items"
    return True, ""

def validate_order_data(data: Dict[str, Any]) -> tuple[bool, Optional[str]]:
    """Validate order data structure"""
    required_fields = ['userId', 'customerEmail', 'amount', 'items', 'deliveryInfo']
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
    
    if not isinstance(data['amount'], (int, float)) or data['amount'] <= 0:
        return False, "Invalid amount: must be positive number"
    if not isinstance(data['items'], list) or len(data['items']) == 0:
        return False, "Invalid items: must be non-empty array"
    
    try:
        sanitize_email(data['customerEmail'])
    except ValueError:
        return False, "Invalid email address format"
    
    for idx, item in enumerate(data['items']):
        is_valid, error_msg = validate_item(item)
        if not is_valid:
            return False, f"Item {idx}: {error_msg}"
    return True, None

def log_webhook_to_database(db, event_id: str, event_type: str, payload_size: int, signature_verified: bool, 
                           processing_status: str, order_id: Optional[str] = None, 
                           error_message: Optional[str] = None, raw_event_data: Optional[Dict] = None) -> None:
    """Log all webhook calls to database for audit trail and debugging"""
    try:
        log_data = {
            "eventId": event_id,
            "eventType": event_type,
            "payloadSize": payload_size,
            "signatureVerified": signature_verified,
            "processingStatus": processing_status,
            "orderId": order_id,
            "errorMessage": error_message,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "environment": "emulator" if IS_EMULATOR else "production",
        }
        if raw_event_data:
            log_data["eventData"] = {
                "id": raw_event_data.get("id"),
                "type": raw_event_data.get("type"),
                "created": raw_event_data.get("created"),
                "livemode": raw_event_data.get("livemode"),
                "object_id": raw_event_data.get("data", {}).get("object", {}).get("id"),
            }
        db.collection('webhook_logs').document(event_id).set(log_data)
        print(f"✅ Logged webhook {event_id} to database")
    except Exception as e:
        print(f"⚠️ Failed to log webhook to database: {str(e)}")
