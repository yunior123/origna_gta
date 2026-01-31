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

RFC_5322_EMAIL = re.compile(
    r"^(?:[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*)@"
    r"(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
)

NAME_REGEX = re.compile(r"^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:[ -][A-Za-zÀ-ÖØ-öø-ÿ]+)*$")
POSTAL_CODE_CA_REGEX = re.compile(r"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$")

DISALLOWED_CHARS = re.compile(r"[<>\"{}\[\]\\|^`]")
CONTROL_CHARS = re.compile(r"[\x00-\x1F\x7F]")

MAX_EMAIL_LENGTH = 254
MAX_NAME_LENGTH = 60
MAX_STREET_LENGTH = 100
MAX_CITY_LENGTH = 50
MAX_MESSAGE_LENGTH = 1000
MIN_MESSAGE_LENGTH = 10


def sanitize_text(value: str, max_length: int, field_name: str = "input", min_length: int = 1) -> str:
    """Sanitize text input and enforce length constraints."""
    if value is None:
        raise ValueError(f"{field_name} is required")
    text = str(value).strip()
    text = CONTROL_CHARS.sub("", text)
    text = DISALLOWED_CHARS.sub("", text)
    text = re.sub(r"\s+", " ", text)
    if len(text) < min_length:
        raise ValueError(f"{field_name} is too short")
    if len(text) > max_length:
        raise ValueError(f"{field_name} exceeds max length")
    return text


def sanitize_email(email: str) -> str:
    """Sanitize and validate email address (RFC 5322 compliant)"""
    if email is None:
        raise ValueError("Email is required")
    email = str(email).strip().lower()
    if len(email) > MAX_EMAIL_LENGTH:
        raise ValueError("Email exceeds max length")
    if not RFC_5322_EMAIL.match(email):
        raise ValueError("Invalid email format")
    return email


def validate_name(name: str) -> str:
    """Validate person name (letters, spaces, hyphens only)."""
    cleaned = sanitize_text(name, MAX_NAME_LENGTH, field_name="name", min_length=2)
    if not NAME_REGEX.match(cleaned):
        raise ValueError("Invalid name format")
    return cleaned


def validate_phone(phone: str) -> str:
    """Validate phone number (10-15 digits only)."""
    if phone is None:
        raise ValueError("Phone is required")
    value = str(phone).strip()
    if not re.fullmatch(r"\d{10,15}", value):
        raise ValueError("Invalid phone format")
    return value


def validate_message(message: str) -> str:
    """Validate message length (10-1000) and sanitize."""
    cleaned = sanitize_text(message, MAX_MESSAGE_LENGTH, field_name="message", min_length=MIN_MESSAGE_LENGTH)
    return cleaned


def validate_postal_code(postal_code: str) -> str:
    """Validate Canadian postal code format."""
    cleaned = sanitize_text(postal_code, 7, field_name="postalCode", min_length=6).upper()
    if not POSTAL_CODE_CA_REGEX.match(cleaned):
        raise ValueError("Invalid postal code format")
    return cleaned


def validate_address_map(address: Dict[str, Any]) -> Dict[str, Any]:
    """Validate and sanitize delivery address."""
    if not isinstance(address, dict):
        raise ValueError("Invalid address payload")

    required_fields = ['street', 'city', 'state', 'postalCode', 'country']
    missing = [f for f in required_fields if not str(address.get(f, '')).strip()]
    if missing:
        raise ValueError(f"Missing address fields: {', '.join(missing)}")

    street = sanitize_text(address.get('street'), MAX_STREET_LENGTH, field_name="street", min_length=3)
    city = sanitize_text(address.get('city'), MAX_CITY_LENGTH, field_name="city", min_length=2)
    state = sanitize_text(address.get('state'), 2, field_name="state", min_length=2).upper()
    country = sanitize_text(address.get('country'), 20, field_name="country", min_length=2)
    postal_code = validate_postal_code(address.get('postalCode'))

    sanitized = {
        "street": street,
        "city": city,
        "state": state,
        "postalCode": postal_code,
        "country": country
    }

    apartment = address.get('apartment')
    if apartment is not None and str(apartment).strip() != "":
        sanitized["apartment"] = sanitize_text(apartment, 20, field_name="apartment", min_length=1)

    phone_number = address.get('phoneNumber')
    if phone_number is not None and str(phone_number).strip() != "":
        sanitized["phoneNumber"] = validate_phone(phone_number)

    label = address.get('label')
    if label is not None and str(label).strip() != "":
        sanitized["label"] = sanitize_text(label, 30, field_name="label", min_length=1)

    is_default = address.get('isDefault')
    if is_default is not None:
        if not isinstance(is_default, bool):
            raise ValueError("Invalid isDefault flag")
        sanitized["isDefault"] = is_default

    latitude = address.get('latitude')
    longitude = address.get('longitude')
    if latitude is not None:
        if not isinstance(latitude, (int, float)) or latitude < -90 or latitude > 90:
            raise ValueError("Invalid latitude")
        sanitized["latitude"] = float(latitude)
    if longitude is not None:
        if not isinstance(longitude, (int, float)) or longitude < -180 or longitude > 180:
            raise ValueError("Invalid longitude")
        sanitized["longitude"] = float(longitude)

    return sanitized

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
    try:
        sanitize_text(item.get('name'), 120, field_name="item name", min_length=1)
    except ValueError as e:
        return False, str(e)
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

    try:
        validate_address_map(data['deliveryInfo'])
    except ValueError as e:
        return False, str(e)
    
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
