"""
Order models for OrignaGTA
Includes OrderItem, Taxes, Ratings, SellerPayout, and Order
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator, ConfigDict

from .base import Address, OrderStatusEnum, PaymentStatusEnum, DeliveryStatusEnum, ShippingApprovalStatusEnum
from .product import SellerDeliveryOption


class OrderItem(BaseModel):
    """Individual item in an order — immutable snapshot at time of purchase."""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "productId": "prod_123",
                "name": "Organic Apples",
                "description": "Fresh organic apples",
                "price": 4.99,
                "quantity": 2,
                "imageUrls": ["https://example.com/image.jpg"],
                "sellerId": "seller_123",
                "sellerAddress": {
                    "street": "123 Farm Road",
                    "city": "Toronto",
                    "state": "ON",
                    "postalCode": "M5V 3A8",
                    "country": "Canada"
                },
                "deliveryStatus": "pending"
            }
        }
    )

    productId: str = Field(..., min_length=1)
    name: str = Field(..., min_length=1, max_length=120)
    description: str = Field(..., max_length=4000)
    price: float = Field(..., gt=0)
    quantity: int = Field(..., gt=0, le=1000)
    imageUrls: List[str] = Field(..., min_length=1, description="Product image URLs")
    sellerId: str = Field(..., min_length=1)
    sellerAddress: Address
    deliveryStatus: DeliveryStatusEnum = Field(default=DeliveryStatusEnum.PENDING)
    trackingNumber: Optional[str] = Field(default=None, max_length=100)
    confirmedByBuyer: bool = Field(default=False)

    # Shipping metadata (captured at purchase time)
    weightKg: Optional[float] = Field(default=None, gt=0)
    lengthCm: Optional[float] = Field(default=None, gt=0)
    widthCm: Optional[float] = Field(default=None, gt=0)
    heightCm: Optional[float] = Field(default=None, gt=0)
    isLocalDeliveryOnly: bool = Field(default=False)
    isPerishable: bool = Field(default=False)
    estimatedShipDays: int = Field(default=3, ge=0)
    deliveryOptions: List[SellerDeliveryOption] = Field(default_factory=list)
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
    review: Optional[str] = Field(default=None, max_length=1000)
    createdAt: datetime = Field(default_factory=datetime.now)


class SellerPayout(BaseModel):
    """Payout information for a seller in an order. All money in cents."""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "sellerId": "seller_123",
                "stripeAccountId": "acct_123",
                "amountCents": 4750,
                "platformFeeCents": 119,
                "netAmountCents": 4631,
                "status": "pending"
            }
        }
    )

    sellerId: str = Field(..., min_length=1)
    stripeAccountId: Optional[str] = Field(default=None)
    amountCents: int = Field(..., ge=0, description="Gross amount in cents")
    platformFeeCents: int = Field(..., ge=0, description="Platform fee in cents")
    netAmountCents: int = Field(..., ge=0, description="Net amount in cents")
    status: str = Field(default="pending", description="Payout status: pending, processing, completed, failed")
    payoutDate: Optional[datetime] = Field(default=None)
    stripeTransferId: Optional[str] = Field(default=None)
    failureReason: Optional[str] = Field(default=None, max_length=500)

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
                "orderId": "order_123abc",
                "userId": "user_123",
                "customerId": "cus_stripe123",
                "customerEmail": "buyer@example.com",
                "items": [],
                "subtotalCents": 4999,
                "shippingCostCents": 500,
                "taxAmountCents": 650,
                "totalAmountCents": 6149,
                "taxes": {"GST": 2.50, "PST": 3.50},
                "orderStatus": "pending",
                "paymentStatus": "awaiting_payment",
                "shippingAddress": {},
                "createdAt": "2026-02-01T10:00:00Z"
            }
        }
    )

    orderId: str = Field(..., min_length=1)
    userId: str = Field(..., min_length=1)

    # Optional identity fields (can be fetched from user doc)
    customerId: Optional[str] = Field(default=None, min_length=1)
    customerEmail: Optional[str] = Field(default=None, pattern=r"^[^@]+@[^@]+\.[^@]+$")

    items: List[OrderItem] = Field(..., min_length=1)
    sellerIds: List[str] = Field(default_factory=list)

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
    shippingAddress: Optional[Address] = Field(default=None)

    # Timestamps
    createdAt: datetime = Field(default_factory=datetime.now)
    updatedAt: Optional[datetime] = Field(default=None)

    # Payment provider IDs
    stripeSessionId: Optional[str] = Field(default=None, min_length=1)
    stripePaymentIntentId: Optional[str] = Field(default=None, min_length=1)

    currency: str = Field(default="cad")

    # Shipping approval
    shippingApprovalStatus: ShippingApprovalStatusEnum = Field(
        default=ShippingApprovalStatusEnum.NOT_REQUIRED
    )
    shippingApprovalRequired: bool = Field(default=False)
    actualShipping: float = Field(default=0.0, ge=0)
    pendingTotal: float = Field(default=0.0, ge=0)

    # Payout tracking
    sellerPayouts: List[SellerPayout] = Field(default_factory=list)
    confirmedByClient: bool = Field(default=False)
    confirmedAt: Optional[datetime] = None
    platformFeeTotal: float = Field(default=0.0, ge=0)
    payoutStatus: str = Field(
        default="pending",
        description="Overall payout status: pending, processing, completed, partial"
    )

    # Ratings
    ratings: List[Ratings] = Field(default_factory=list)

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
    items: List[OrderItem] = Field(..., min_length=1)
    shippingAddress: Address
    shippingCost: float = Field(default=0.0, ge=0)
    currency: str = Field(default="cad")
    shippingApprovalRequired: bool = Field(default=False)
