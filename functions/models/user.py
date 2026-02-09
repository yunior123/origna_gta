"""
User models for OrignaGTA
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from schema_constants import Fields

from .base import Address, UserRole


class User(BaseModel):
    """
    Complete user model
    Includes buyer, seller, and admin information
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.UID: "user_123abc",
                Fields.EMAIL: "user@example.com",
                Fields.NAME: "John Doe",
                Fields.ROLES: ["buyer"],
                Fields.CREATED_AT: "2026-02-01T10:00:00Z"
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
    roles: list[UserRole] = Field(
        ...,
        min_length=1,
        description="User roles (buyer, seller, admin)"
    )
    address: Address | None = Field(
        default=None,
        description="User's default address"
    )
    createdAt: datetime = Field(
        default_factory=datetime.now,
        description="Account creation timestamp"
    )

    # Stripe information
    customerId: str | None = Field(
        default=None,
        description="Stripe Customer ID for payments"
    )
    lastCheckoutSession: str | None = Field(
        default=None,
        description="Last Stripe Checkout Session ID"
    )
    lastOrderId: str | None = Field(
        default=None,
        description="Last created order ID"
    )
    lastCheckoutTimestamp: datetime | None = Field(
        default=None,
        description="Timestamp of last checkout"
    )

    # Seller information (Stripe Connect)
    stripeAccountId: str | None = Field(
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
    suspendedAt: datetime | None = Field(
        default=None,
        description="When account was suspended"
    )
    paymentProvider: str | None = Field(
        default="stripe",
        description="Payment provider for seller payouts (stripe or airwallex)"
    )
    airwallexAccountId: str | None = Field(
        default=None,
        description="Airwallex connected account ID"
    )
    airwallexCustomerId: str | None = Field(
        default=None,
        description="Airwallex customer ID"
    )
    airwallexStatus: str | None = Field(
        default=None,
        description="Airwallex account status"
    )
    mfaEnabled: bool = Field(
        default=False,
        description="Whether admin MFA is enabled"
    )
    mfaSecret: str | None = Field(
        default=None,
        description="Admin TOTP secret (server-only)"
    )
    lastMfaVerify: datetime | None = Field(
        default=None,
        description="Last successful admin MFA verification"
    )
    mfaBackupCodes: list[str] | None = Field(
        default=None,
        description="One-time admin MFA backup codes (hashed)"
    )
    updatedAt: datetime | None = Field(
        default=None,
        description="Last update timestamp"
    )
    
    # Tax exemption for businesses (GST/HST number)
    taxExemption: dict[str, str] | None = Field(
        default=None,
        description="Tax exemption details: {gstNumber: '123456789RT0001'}"
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
    def validate_roles(cls, v: list[UserRole]) -> list[UserRole]:
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
    roles: list[UserRole] = Field(default=[UserRole.BUYER])
    address: Address | None = None
