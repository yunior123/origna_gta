"""
Base models and enums for OrignaGTA
Includes Address, enumerations, and common types
"""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, field_validator, ConfigDict
import re


# ============================================================================
# ENUMERATIONS
# ============================================================================

class OrderStatusEnum(str, Enum):
    """Order status values"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    FAILED = "failed"
    EXPIRED = "expired"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"


class PaymentStatusEnum(str, Enum):
    """Payment status values"""
    AWAITING_PAYMENT = "awaiting_payment"
    PROCESSING = "processing"
    PAID = "paid"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    PAYMENT_FAILED = "payment_failed"
    REFUNDED = "refunded"
    SESSION_EXPIRED = "session_expired"


class DeliveryStatusEnum(str, Enum):
    """Delivery status for individual items"""
    PENDING = "pending"
    SHIPPED = "shipped"
    DELIVERED = "delivered"


class ShippingApprovalStatusEnum(str, Enum):
    """Shipping approval status"""
    NOT_REQUIRED = "not_required"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class UserRole(str, Enum):
    """User roles"""
    ADMIN = "admin"
    SELLER = "seller"
    BUYER = "buyer"


# ============================================================================
# ADDRESS MODELS
# ============================================================================

class Address(BaseModel):
    """
    Complete address model with validation
    Used for delivery, seller locations, and user addresses
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "street": "123 Main Street",
                "apartment": "Apt 4B",
                "city": "Toronto",
                "state": "ON",
                "postalCode": "M5V 3A8",
                "country": "Canada",
                "phoneNumber": "4165551234",
                "isDefault": True,
                "label": "Home"
            }
        }
    )

    street: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Street address"
    )
    apartment: str = Field(
        default="",
        max_length=20,
        description="Unit, Suite, Apt number"
    )
    city: str = Field(
        ...,
        min_length=2,
        max_length=50,
        description="City name"
    )
    state: str = Field(
        ...,
        min_length=2,
        max_length=2,
        description="Province/State code (e.g., ON, QC, BC)"
    )
    postalCode: str = Field(
        ...,
        description="Canadian postal code (e.g., M5V 3A8)"
    )
    country: str = Field(
        default="Canada",
        description="Country name"
    )
    phoneNumber: Optional[str] = Field(
        default=None,
        description="Contact phone number for delivery"
    )
    isDefault: bool = Field(
        default=False,
        description="Whether this is the default address"
    )
    label: Optional[str] = Field(
        default=None,
        max_length=20,
        description="Address label (Home, Work, Other)"
    )
    latitude: Optional[float] = Field(
        default=None,
        ge=-90,
        le=90,
        description="Latitude for mapping/delivery routing"
    )
    longitude: Optional[float] = Field(
        default=None,
        ge=-180,
        le=180,
        description="Longitude for mapping/delivery routing"
    )

    @field_validator("postalCode")
    @classmethod
    def validate_postal_code(cls, v: str) -> str:
        """Validate Canadian postal code format"""
        # Canadian postal code: A1A 1A1 or A1A1A1
        postal_pattern = re.compile(r"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$")
        if not postal_pattern.match(v):
            raise ValueError("Invalid Canadian postal code format (expected: A1A 1A1)")
        # Normalize: remove existing space/dash, then add space in middle
        v_clean = v.replace(" ", "").replace("-", "").upper()
        return f"{v_clean[:3]} {v_clean[3:]}"  # Format as A1A 1A1

    @field_validator("phoneNumber")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        """Validate phone number (10-15 digits)"""
        if v is None:
            return None
        # Remove all non-digit characters
        digits = re.sub(r"\D", "", v)
        if not 10 <= len(digits) <= 15:
            raise ValueError("Phone number must be 10-15 digits")
        return digits

    @field_validator("state")
    @classmethod
    def validate_state(cls, v: str) -> str:
        """Validate and normalize province code"""
        valid_provinces = {
            "AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"
        }
        v_upper = v.upper()
        if v_upper not in valid_provinces:
            raise ValueError(f"Invalid Canadian province code: {v}")
        return v_upper

    def formatted_address(self) -> str:
        """Get formatted address with line breaks"""
        lines = [
            self.street,
            self.apartment if self.apartment else None,
            f"{self.city}, {self.state} {self.postalCode}",
            self.country,
        ]
        return "\n".join(line for line in lines if line)

    def full_address(self) -> str:
        """Get single-line address"""
        parts = [
            self.street,
            self.apartment if self.apartment else None,
            self.city,
            self.state,
            self.postalCode,
            self.country,
        ]
        return ", ".join(part for part in parts if part)


class AddressDetails(BaseModel):
    """
    Simplified address for delivery info
    Includes geolocation coordinates
    """
    street: str = Field(..., min_length=1, max_length=100)
    city: str = Field(..., min_length=2, max_length=50)
    state: str = Field(..., min_length=2, max_length=2)
    postalCode: str = Field(...)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

    @field_validator("postalCode")
    @classmethod
    def validate_postal_code(cls, v: str) -> str:
        """Validate Canadian postal code"""
        postal_pattern = re.compile(r"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$")
        if not postal_pattern.match(v):
            raise ValueError("Invalid postal code format")
        return v.upper()

    @field_validator("state")
    @classmethod
    def validate_state(cls, v: str) -> str:
        """Validate province/state code"""
        valid_provinces = {
            "AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"
        }
        v_upper = v.upper()
        if v_upper not in valid_provinces:
            raise ValueError(f"Invalid province: {v}")
        return v_upper
