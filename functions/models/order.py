"""
Order models for OrignaGTA
Includes OrderItem, Taxes, Ratings, SellerPayout, and Order
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .base import Address, DeliveryStatusEnum, OrderStatusEnum, PaymentStatusEnum, ShippingApprovalStatusEnum
from .product import SellerDeliveryOption
from schema_constants import Fields


class OrderItem(BaseModel):
    """Individual item in an order — immutable snapshot at time of purchase."""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.PRODUCT_ID: "prod_123",
                Fields.NAME: "Organic Apples",
                Fields.DESCRIPTION: "Fresh organic apples",
                Fields.PRICE: 4.99,
                Fields.QUANTITY: 2,
                Fields.IMAGE_URLS: ["https://example.com/image.jpg"],
                Fields.SELLER_ID: "seller_123",
                Fields.SELLER_ADDRESS: {
                    Fields.STREET: "123 Farm Road",
                    Fields.CITY: "Toronto",
                    Fields.STATE: "ON",
                    Fields.POSTAL_CODE: "M5V 3A8",
                    Fields.COUNTRY: "Canada"
                },
                Fields.DELIVERY_STATUS: "pending"
            }
        }
    )

    productId: str = Field(..., min_length=1)
    name: str = Field(..., min_length=1, max_length=120)
    description: str = Field(..., max_length=4000)
    price: float = Field(..., gt=0)
    quantity: int = Field(..., gt=0, le=1000)
    imageUrls: list[str] = Field(..., min_length=1, description="Product image URLs")
    sellerId: str = Field(..., min_length=1)
    sellerAddress: Address
    deliveryStatus: DeliveryStatusEnum = Field(default=DeliveryStatusEnum.PENDING)
    trackingNumber: str | None = Field(default=None, max_length=100)
    confirmedByBuyer: bool = Field(default=False)

    # Shipping metadata (captured at purchase time)
    weightKg: float | None = Field(default=None, gt=0)
    lengthCm: float | None = Field(default=None, gt=0)
    widthCm: float | None = Field(default=None, gt=0)
    heightCm: float | None = Field(default=None, gt=0)
    isLocalDeliveryOnly: bool = Field(default=False)
    isPerishable: bool = Field(default=False)
    estimatedShipDays: int = Field(default=3, ge=0)
    deliveryOptions: list[SellerDeliveryOption] = Field(default_factory=list)
    minimumOrderQuantity: int = Field(default=1, ge=1)
    freeShipping: bool = Field(default=False)
    isDigital: bool = Field(default=False, description="Whether this item is a digital product")

    def subtotal(self) -> float:
        """Calculate item subtotal"""
        return self.price * self.quantity


class Taxes(BaseModel):
    """Tax breakdown for an order (Canadian taxes)."""
    GST: float = Field(default=0.0, ge=0, description="Goods and Services Tax (Federal)")
    PST: float = Field(default=0.0, ge=0, description="Provincial Sales Tax")
    HST: float = Field(default=0.0, ge=0, description="Harmonized Sales Tax")
    QST: float = Field(default=0.0, ge=0, description="Quebec Sales Tax")

    def total(self) -> float:
        """Calculate total tax amount"""
        return self.GST + self.PST + self.HST + self.QST


class Ratings(BaseModel):
    """Product rating within an order."""
    productId: str = Field(..., min_length=1)
    rating: float = Field(..., ge=0, le=5)
    review: str | None = Field(default=None, max_length=1000)
    createdAt: datetime = Field(default_factory=datetime.now)


class SellerPayout(BaseModel):
    """Payout information for a seller in an order. All money in cents."""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.SELLER_ID: "seller_123",
                Fields.STRIPE_ACCOUNT_ID: "acct_123",
                Fields.AMOUNT_CENTS: 4750,
                Fields.PLATFORM_FEE_CENTS: 119,
                Fields.NET_AMOUNT_CENTS: 4631,
                Fields.STATUS: "pending"
            }
        }
    )

    sellerId: str = Field(..., min_length=1)
    stripeAccountId: str | None = Field(default=None)
    amountCents: int = Field(..., ge=0, description="Gross amount in cents")
    platformFeeCents: int = Field(..., ge=0, description="Platform fee in cents")
    netAmountCents: int = Field(..., ge=0, description="Net amount in cents")
    status: str = Field(default="pending", description="Payout status: pending, processing, completed, failed")
    payoutDate: datetime | None = Field(default=None)
    stripeTransferId: str | None = Field(default=None)
    failureReason: str | None = Field(default=None, max_length=500)

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        valid_statuses = {"pending", "processing", "completed", "failed"}
        if v not in valid_statuses:
            raise ValueError(f"Invalid payout status: {v}")
        return v


class Order(BaseModel):
    """Complete order model. All money in integer cents."""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.ORDER_ID: "order_123abc",
                Fields.USER_ID: "user_123",
                Fields.CUSTOMER_ID: "cus_stripe123",
                "customerEmail": "buyer@example.com",
                Fields.ITEMS: [],
                Fields.SUBTOTAL_CENTS: 4999,
                Fields.SHIPPING_COST_CENTS: 500,
                Fields.TAX_AMOUNT_CENTS: 650,
                Fields.TOTAL_AMOUNT_CENTS: 6149,
                Fields.TAXES: {"GST": 2.50, "PST": 3.50},
                Fields.ORDER_STATUS: "pending",
                Fields.PAYMENT_STATUS: "awaiting_payment",
                Fields.SHIPPING_ADDRESS: {},
                Fields.CREATED_AT: "2026-02-01T10:00:00Z"
            }
        }
    )

    orderId: str = Field(..., min_length=1)
    userId: str = Field(..., min_length=1)

    # Optional identity fields (can be fetched from user doc)
    customerId: str | None = Field(default=None, min_length=1)
    customerEmail: str | None = Field(default=None, pattern=r"^[^@]+@[^@]+\.[^@]+$")

    items: list[OrderItem] = Field(..., min_length=1)
    sellerIds: list[str] = Field(default_factory=list)

    # Money — all in integer cents
    subtotalCents: int = Field(..., ge=0)
    shippingCostCents: int = Field(default=0, ge=0)
    taxAmountCents: int = Field(default=0, ge=0)
    totalAmountCents: int = Field(..., ge=0)

    taxes: Taxes = Field(default_factory=Taxes)

    # Status
    orderStatus: OrderStatusEnum = Field(default=OrderStatusEnum.PENDING)
    paymentStatus: PaymentStatusEnum = Field(default=PaymentStatusEnum.AWAITING_PAYMENT)

    # Address
    shippingAddress: Address | None = Field(default=None)

    # Timestamps
    createdAt: datetime = Field(default_factory=datetime.now)
    updatedAt: datetime | None = Field(default=None)

    # Payment provider IDs
    stripeSessionId: str | None = Field(default=None, min_length=1)
    stripePaymentIntentId: str | None = Field(default=None, min_length=1)

    currency: str = Field(default="cad")

    # Shipping approval
    shippingApprovalStatus: ShippingApprovalStatusEnum = Field(
        default=ShippingApprovalStatusEnum.NOT_REQUIRED
    )
    shippingApprovalRequired: bool = Field(default=False)
    actualShipping: float = Field(default=0.0, ge=0)
    pendingTotal: float = Field(default=0.0, ge=0)

    # Payout tracking
    sellerPayouts: list[SellerPayout] = Field(default_factory=list)
    confirmedByClient: bool = Field(default=False)
    confirmedAt: datetime | None = None
    platformFeeTotal: float = Field(default=0.0, ge=0)
    payoutStatus: str = Field(
        default="pending",
        description="Overall payout status: pending, processing, completed, partial"
    )

    # Ratings
    ratings: list[Ratings] = Field(default_factory=list)

    @field_validator("currency")
    @classmethod
    def validate_currency(cls, v: str) -> str:
        if v.lower() not in {"cad", "usd"}:
            raise ValueError("Only CAD and USD currencies supported")
        return v.lower()


class OrderCreate(BaseModel):
    """Model for creating new orders (excludes orderId and createdAt which are generated)."""
    userId: str = Field(..., min_length=1)
    customerId: str = Field(..., min_length=1)
    customerEmail: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    items: list[OrderItem] = Field(..., min_length=1)
    shippingAddress: Address
    shippingCost: float = Field(default=0.0, ge=0)
    currency: str = Field(default="cad")
    shippingApprovalRequired: bool = Field(default=False)
