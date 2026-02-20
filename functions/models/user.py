"""
User models for OrignaGTA
"""

from datetime import UTC, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from schema_constants import Fields, PaymentProviderValues

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
                Fields.CREATED_AT: "2026-02-01T10:00:00Z",
            }
        }
    )

    uid: str = Field(..., min_length=1, max_length=128, description="Firebase Auth User ID")
    email: EmailStr = Field(..., description="User email address")
    name: str = Field(..., min_length=2, max_length=60, description="User display name")
    roles: list[UserRole] = Field(..., min_length=1, description="User roles (buyer, seller, admin)")
    address: Address | None = Field(default=None, description="User's default address")
    createdAt: datetime = Field(default_factory=lambda: datetime.now(UTC), description="Account creation timestamp")

    # Stripe information
    customerId: str | None = Field(default=None, description="Stripe Customer ID for payments")
    lastCheckoutSession: str | None = Field(default=None, description="Last Stripe Checkout Session ID")
    lastOrderId: str | None = Field(default=None, description="Last created order ID")
    lastCheckoutTimestamp: datetime | None = Field(default=None, description="Timestamp of last checkout")

    # Seller information (Stripe Connect)
    stripeAccountId: str | None = Field(default=None, description="Stripe Connect account ID (for sellers)")
    payoutsEnabled: bool = Field(default=False, description="Whether seller can receive payouts")
    chargesEnabled: bool = Field(default=False, description="Whether seller can accept charges")
    onboardingCompleted: bool = Field(default=False, description="Whether Stripe Connect onboarding is complete")

    # Account status
    suspended: bool = Field(default=False, description="Whether account is suspended")
    suspendedAt: datetime | None = Field(default=None, description="When account was suspended")
    paymentProvider: str | None = Field(
        default=PaymentProviderValues.STRIPE, description="Payment provider for seller payouts (stripe or airwallex)"
    )
    airwallexAccountId: str | None = Field(default=None, description="Airwallex connected account ID")
    airwallexCustomerId: str | None = Field(default=None, description="Airwallex customer ID")
    airwallexStatus: str | None = Field(default=None, description="Airwallex account status")
    mfaEnabled: bool = Field(default=False, description="Whether admin MFA is enabled")
    mfaSecret: str | None = Field(default=None, description="Admin TOTP secret (server-only)")
    lastMfaVerify: datetime | None = Field(default=None, description="Last successful admin MFA verification")
    mfaBackupCodes: list[str] | None = Field(default=None, description="One-time admin MFA backup codes (hashed)")
    updatedAt: datetime | None = Field(default=None, description="Last update timestamp")

    # Tax exemption for businesses (GST/HST number)
    taxExemption: dict[str, str] | None = Field(
        default=None, description="Tax exemption details: {gstNumber: '123456789RT0001'}"
    )

    # === CONSENT & COMPLIANCE (CASL + PIPEDA + Quebec Law 25) ===
    emailConsent: bool = Field(default=True, description="User consented to receive transactional emails")
    marketingOptIn: bool = Field(default=False, description="Explicit opt-in for marketing/promotional emails (CASL)")
    consentTimestamp: datetime | None = Field(default=None, description="When consent was given (ISO 8601)")
    consentMethod: str | None = Field(
        default=None, description="How consent was obtained: signup, checkbox, double_opt_in, implied"
    )
    privacyAcceptedAt: datetime | None = Field(default=None, description="When user accepted the privacy policy")
    termsAcceptedAt: datetime | None = Field(default=None, description="When user accepted the Terms of Service")
    privacyPolicyVersion: str | None = Field(default=None, description="Version of privacy policy the user accepted")
    termsVersion: str | None = Field(default=None, description="Version of Terms of Service the user accepted")
    preferredLanguage: str = Field(
        default="en", description="User preferred language: 'en' or 'fr' (for Quebec Bill 96 compliance)"
    )
    unsubscribedAt: datetime | None = Field(default=None, description="When user unsubscribed from marketing emails")
    dataProcessingConsent: bool = Field(
        default=False, description="Explicit consent for personal data processing (PIPEDA / Law 25)"
    )

    # === PREMIUM SUBSCRIPTION ===
    isPremium: bool = Field(default=False, description="Cached premium status — authoritative source: subscriptions/{uid}")
    premiumSince: datetime | None = Field(default=None, description="When premium subscription started")
    premiumExpiresAt: datetime | None = Field(default=None, description="Current billing period end (premium expires after this)")
    stripeSubscriptionId: str | None = Field(default=None, description="Stripe Subscription ID")
    notifyNewProducts: bool = Field(default=False, description="Opt-in: receive FCM notification when new products are added (premium only)")
    notifyTrending: bool = Field(default=False, description="Opt-in: receive FCM notification for trending products (premium only)")
    fcmToken: str | None = Field(default=None, description="Firebase Cloud Messaging device token for push notifications")
    fcmTokenUpdatedAt: datetime | None = Field(default=None, description="Last FCM token update timestamp")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate name: allow Unicode letters but reject digits, HTML, and dangerous characters.
        Canada is multicultural — support Chinese, Arabic, Korean, Cyrillic, etc."""
        import re
        import unicodedata

        # Reject HTML tags and dangerous characters
        if re.search(r"[<>]", v):
            raise ValueError("Name contains disallowed characters")
        # Reject digits
        if re.search(r"\d", v):
            raise ValueError("Name must not contain digits")
        # Allow only: Unicode letters, spaces, hyphens, apostrophes, periods
        for char in v:
            cat = unicodedata.category(char)
            if cat.startswith("L"):  # Any letter (Latin, CJK, Arabic, Cyrillic, etc.)
                continue
            if char in " '-.\u00b7":  # Space, apostrophe, hyphen, period, middle dot
                continue
            raise ValueError(f"Name contains disallowed character: {char!r}")
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
