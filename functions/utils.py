import json
import re
from datetime import datetime
from typing import Any

from firebase_admin import firestore
from firebase_functions import https_fn
from pydantic import ValidationError

from config import IS_EMULATOR

# Import Pydantic models
from models.base import Address
from models.order import OrderItem
from schema_constants import Collections, Fields


def create_success_response(data: dict[str, Any], status_code: int = 200) -> dict[str, Any]:
    """Create standardized success response dict for on_call functions"""
    return {"success": True, **data}

def create_error_response(error: str, status_code: int = 400, details: str | None = None) -> https_fn.Response:
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

# Allow letters, spaces, hyphens, apostrophes, periods (O'Brien, Jr., María-José)
NAME_REGEX = re.compile(r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ' .\-]*[A-Za-zÀ-ÖØ-öø-ÿ.]?$")
POSTAL_CODE_CA_REGEX = re.compile(r"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$")

DISALLOWED_CHARS = re.compile(r"[<>\"{}\[\]\\|^`]")
CONTROL_CHARS = re.compile(r"[\x00-\x1F\x7F]")

MAX_EMAIL_LENGTH = 254
MAX_NAME_LENGTH = 60
MAX_STREET_LENGTH = 100
MAX_CITY_LENGTH = 50
MAX_MESSAGE_LENGTH = 1000
MIN_MESSAGE_LENGTH = 10


def sanitized_text(value: str) -> str:
    """
    Sanitize text to prevent XSS attacks.
    Removes dangerous HTML tags and script injections.
    """
    if value is None:
        return ""

    text = str(value)

    # Remove script tags and their content
    text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.IGNORECASE | re.DOTALL)

    # Remove iframe tags
    text = re.sub(r'<iframe[^>]*>.*?</iframe>', '', text, flags=re.IGNORECASE | re.DOTALL)

    # Remove javascript: protocol
    text = re.sub(r'javascript:', '', text, flags=re.IGNORECASE)

    # Remove onerror and other event handlers
    text = re.sub(r'\son\w+\s*=', '', text, flags=re.IGNORECASE)

    # Remove any remaining script tags (self-closing or malformed)
    text = re.sub(r'</?script[^>]*>', '', text, flags=re.IGNORECASE)

    # Remove other dangerous tags
    text = re.sub(r'</?iframe[^>]*>', '', text, flags=re.IGNORECASE)
    text = re.sub(r'</?object[^>]*>', '', text, flags=re.IGNORECASE)
    text = re.sub(r'</?embed[^>]*>', '', text, flags=re.IGNORECASE)

    return text


def sanitize_path(path: str) -> str:
    """
    Sanitize file paths to prevent path traversal attacks.
    Removes dangerous path components like '..' and absolute paths.
    """
    if path is None:
        return ""

    import os

    path_str = str(path)

    # Remove all occurrences of '..' (both forward and backslash)
    path_str = path_str.replace('..', '')

    # Get only the basename (filename) - removes all directory traversal
    path_str = os.path.basename(path_str)

    # Remove any remaining path separators
    path_str = path_str.replace('/', '').replace('\\', '')

    return path_str


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
    """Validate person name (letters, spaces, hyphens, apostrophes, periods)."""
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


def validate_address_map(address: dict[str, Any]) -> Address:
    """
    Validate and sanitize delivery address using Pydantic Address model.
    Returns validated Address object.
    Raises ValidationError for consistency with other validation functions.
    """
    # CONSISTENCY FIX: Let ValidationError propagate (don't convert to ValueError)
    # This standardizes error handling - callers use try/except ValidationError
    validated_address = Address(**address)
    return validated_address

def validate_item(item: dict) -> tuple[bool, str]:
    """
    Validate individual item data using OrderItem model.
    Returns (True, "") on success or (False, error_message) on failure.
    """
    try:
        # Create OrderItem to validate structure
        validated_item = OrderItem(**item)

        # Additional business rules
        if validated_item.quantity > 100:
            return False, "quantity exceeds maximum (100)"

        return True, ""
    except ValidationError as e:
        errors = e.errors()
        if errors:
            field = errors[0].get('loc', ['unknown'])[0]
            msg = errors[0].get('msg', 'Invalid value')
            return False, f"{field}: {msg}"
        return False, "Invalid item data"
    except Exception as e:
        return False, str(e)

def validate_order_data(data: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate order data structure using Pydantic models.
    This is a lightweight check before creating full Order object.
    Returns (True, None) on success or (False, error_message) on failure.
    """
    for field in [Fields.USER_ID, Fields.ITEMS]:
        if field not in data:
            return False, f"Missing required field: {field}"

    if not isinstance(data[Fields.ITEMS], list) or len(data[Fields.ITEMS]) == 0:
        return False, "Invalid items: must be non-empty array"

    # totalAmountCents is required (integer cents)
    amount_cents = data.get(Fields.TOTAL_AMOUNT_CENTS)
    if amount_cents is None or not isinstance(amount_cents, (int, float)) or isinstance(amount_cents, bool) or amount_cents < 0:
        return False, "Invalid totalAmountCents: must be non-negative integer"

    # customerEmail is optional (can be fetched from user doc)
    customer_email = data.get(Fields.CUSTOMER_EMAIL)
    if customer_email:
        try:
            from pydantic import EmailStr
            EmailStr._validate(customer_email)
        except Exception:
            return False, "Invalid email address format"

    # Validate address (only for physical items)
    has_physical_items = any(not item.get(Fields.IS_DIGITAL, False) for item in data[Fields.ITEMS])
    if has_physical_items:
        shipping_address = data.get(Fields.SHIPPING_ADDRESS)
        if not shipping_address:
            return False, "Missing required field: shippingAddress"

        try:
            validate_address_map(shipping_address)
        except Exception as e:
            return False, str(e)

    # Validate each item
    for idx, item in enumerate(data[Fields.ITEMS]):
        is_valid, error_msg = validate_item(item)
        if not is_valid:
            return False, f"Item {idx}: {error_msg}"

    return True, None

def log_webhook_to_database(db, event_id: str, event_type: str, payload_size: int, signature_verified: bool,
                           processing_status: str, order_id: str | None = None,
                           error_message: str | None = None, raw_event_data: dict | None = None) -> None:
    """Log all webhook calls to database for audit trail and debugging"""
    try:
        log_data = {
            Fields.EVENT_ID: event_id,
            Fields.EVENT_TYPE: event_type,
            Fields.PAYLOAD_SIZE: payload_size,
            Fields.SIGNATURE_VERIFIED: signature_verified,
            Fields.PROCESSING_STATUS: processing_status,
            Fields.ORDER_ID: order_id,
            Fields.ERROR_MESSAGE: error_message,
            Fields.TIMESTAMP: firestore.SERVER_TIMESTAMP,
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
        db.collection(Collections.WEBHOOK_LOGS).document(event_id).set(log_data)
        print(f"✅ Logged webhook {event_id} to database")
    except Exception as e:
        print(f"⚠️ Failed to log webhook to database: {str(e)}")

# ============================================================================
# ORDER STATE MACHINE VALIDATION - CRITICAL BUSINESS LOGIC
# ============================================================================

def is_valid_order_status_transition(current_status: str, new_status: str) -> bool:
    """
    CRITICAL BUSINESS LOGIC: Validate order status transitions

    Prevents data corruption from invalid state changes.
    This mirrors the Firestore rules validation.

    Valid transitions:
    - pending -> [confirmed, cancelled, failed, expired]
    - confirmed -> [processing, cancelled, expired]
    - processing -> [shipped, cancelled]
    - shipped -> [delivered, cancelled]
    - delivered -> [refunded, partially_refunded]
    - cancelled -> [] (terminal)
    - failed -> [pending] (retry)
    - expired -> [pending] (retry)
    - refunded -> [] (terminal)
    - partially_refunded -> [refunded]
    """
    valid_transitions = {
        'pending': ['confirmed', 'cancelled', 'failed', 'expired'],
        'confirmed': ['processing', 'cancelled', 'expired'],
        'processing': ['shipped', 'cancelled'],
        'shipped': ['in_transit', 'delivered'],
        'in_transit': ['delivered', 'cancelled'],
        'delivered': ['refunded', 'partially_refunded'],
        'cancelled': [],
        'failed': ['pending'],
        'expired': ['pending'],
        'refunded': [],
        'partially_refunded': ['refunded'],
    }

    allowed_next_states = valid_transitions.get(current_status, [])
    is_valid = new_status in allowed_next_states

    if not is_valid:
        print(f"❌ INVALID STATE TRANSITION: {current_status} → {new_status}")
    else:
        print(f"✅ Valid state transition: {current_status} → {new_status}")

    return is_valid
