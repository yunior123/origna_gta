"""
User models for OrignaGTA
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, EmailStr, field_validator, ConfigDict

from .base import Address, UserRole


class User(BaseModel):
    """
    Complete user model
    Includes buyer, seller, and admin information
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "uid": "user_123abc",
                "email": "user@example.com",
                "name": "John Doe",
                "roles": ["buyer"],
                "createdAt": "2026-02-01T10:00:00Z"
            }
        }
    )

    uid: str = Field(
        ...,
        min_length=1,
        max_length=128,
        description="Firebase Auth User ID"
    )
    email: EmailStr = Field(
        ...,
        description="User email address"
    )
    name: str = Field(
        ...,
        min_length=2,
        max_length=60,
        description="User display name"
    )
    roles: List[UserRole] = Field(
        ...,
        min_length=1,
        description="User roles (buyer, seller, admin)"
    )
    address: Optional[Address] = Field(
        default=None,
        description="User's default address"
    )
    createdAt: datetime = Field(
        default_factory=datetime.now,
        description="Account creation timestamp"
    )
    
    # Stripe information
    customerId: Optional[str] = Field(
        default=None,
        description="Stripe Customer ID for payments"
    )
    lastCheckoutSession: Optional[str] = Field(
        default=None,
        description="Last Stripe Checkout Session ID"
    )
    lastOrderId: Optional[str] = Field(
        default=None,
        description="Last created order ID"
    )
    lastCheckoutTimestamp: Optional[datetime] = Field(
        default=None,
        description="Timestamp of last checkout"
    )
    
    # Seller information (Stripe Connect)
    stripeAccountId: Optional[str] = Field(
        default=None,
        description="Stripe Connect account ID (for sellers)"
    )
    payoutsEnabled: bool = Field(
        default=False,
        description="Whether seller can receive payouts"
    )
    chargesEnabled: bool = Field(
        default=False,
        description="Whether seller can accept charges"
    )
    onboardingCompleted: bool = Field(
        default=False,
        description="Whether Stripe Connect onboarding is complete"
    )
    
    # Account status
    suspended: bool = Field(
        default=False,
        description="Whether account is suspended"
    )
    suspendedAt: Optional[datetime] = Field(
        default=None,
        description="When account was suspended"
    )
    paymentProvider: Optional[str] = Field(
        default="stripe",
        description="Payment provider for seller payouts (stripe or airwallex)"
    )
    airwallexAccountId: Optional[str] = Field(
        default=None,
        description="Airwallex connected account ID"
    )
    airwallexCustomerId: Optional[str] = Field(
        default=None,
        description="Airwallex customer ID"
    )
    airwallexStatus: Optional[str] = Field(
        default=None,
        description="Airwallex account status"
    )
    adminMfaEnabled: bool = Field(
        default=False,
        description="Whether admin MFA is enabled"
    )
    adminMfaSecret: Optional[str] = Field(
        default=None,
        description="Admin TOTP secret (server-only)"
    )
    adminMfaVerifiedAt: Optional[datetime] = Field(
        default=None,
        description="Last successful admin MFA verification"
    )
    adminMfaBackupCodes: Optional[List[str]] = Field(
        default=None,
        description="One-time admin MFA backup codes"
    )
    updatedAt: Optional[datetime] = Field(
        default=None,
        description="Last update timestamp"
    )

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate name (letters, spaces, hyphens, apostrophes, periods)"""
        import re
        # Allow: O'Brien, Jr., María-José, etc.
        pattern = re.compile(r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ' .\-]*[A-Za-zÀ-ÖØ-öø-ÿ.]?$")
        if not pattern.match(v):
            raise ValueError("Name must contain only letters, spaces, hyphens, apostrophes, and periods")
        return v

    @field_validator("roles")
    @classmethod
    def validate_roles(cls, v: List[UserRole]) -> List[UserRole]:
        """Ensure at least one role is assigned"""
        if not v:
            raise ValueError("At least one role must be assigned")
        return v

    def is_seller(self) -> bool:
        """Check if user has seller role"""
        return UserRole.SELLER in self.roles

    def is_admin(self) -> bool:
        """Check if user has admin role"""
        return UserRole.ADMIN in self.roles

    def can_sell(self) -> bool:
        """Check if user can sell products (seller + onboarding complete)"""
        return self.is_seller() and self.onboardingCompleted and not self.suspended


class UserCreate(BaseModel):
    """
    Model for creating new users
    (excludes uid and createdAt which are generated by Firebase Auth)
    """
    email: EmailStr
    name: str = Field(..., min_length=2, max_length=60)
    roles: List[UserRole] = Field(default=[UserRole.BUYER])
    address: Optional[Address] = None
