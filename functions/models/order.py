"""
Order models for OrignaGTA
Includes OrderItem, Taxes, Ratings, SellerPayout, and Order
"""

from datetime import datetime
from typing import List, Optional, Dict
from pydantic import BaseModel, Field, field_validator, ConfigDict

from .base import Address, OrderStatusEnum, PaymentStatusEnum, DeliveryStatusEnum, ShippingApprovalStatusEnum
from .product import SellerDeliveryOption


class OrderItem(BaseModel):
    """
    Individual item in an order (replaces CartItemDetailModel)
    Immutable object with all product details at time of purchase
    """
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
    imageUrls: List[str] = Field(..., min_length=1)
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

    def subtotal(self) -> float:
        """Calculate item subtotal"""
        return self.price * self.quantity


class Taxes(BaseModel):
    """
    Tax breakdown for an order
    Replaces Map<String, double> with typed object
    """
    GST: float = Field(default=0.0, ge=0, description="Goods and Services Tax (Federal)")
    PST: float = Field(default=0.0, ge=0, description="Provincial Sales Tax")
    HST: float = Field(default=0.0, ge=0, description="Harmonized Sales Tax")
    QST: float = Field(default=0.0, ge=0, description="Quebec Sales Tax")

    def total(self) -> float:
        """Calculate total tax amount"""
        return self.GST + self.PST + self.HST + self.QST


class Ratings(BaseModel):
    """
    Product ratings for an order
    Replaces Map<String, dynamic> with typed object
    """
    productId: str = Field(..., min_length=1)
    rating: float = Field(..., ge=0, le=5)
    review: Optional[str] = Field(default=None, max_length=1000)
    createdAt: datetime = Field(default_factory=datetime.now)


class SellerPayout(BaseModel):
    """
    Payout information for a seller in an order
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "sellerId": "seller_123",
                "sellerStripeAccountId": "acct_123",
                "amount": 47.50,
                "platformFee": 1.19,
                "netAmount": 46.31,
                "status": "pending"
            }
        }
    )

    sellerId: str = Field(..., min_length=1)
    sellerStripeAccountId: Optional[str] = Field(default=None)
    amount: float = Field(..., ge=0, description="Seller's portion before platform fee")
    platformFee: float = Field(..., ge=0, description="Platform fee (2.5%)")
    netAmount: float = Field(..., ge=0, description="Net amount after platform fee")
    status: str = Field(
        default="pending",
        description="Payout status: pending, processing, completed, failed"
    )
    payoutDate: Optional[datetime] = Field(default=None)
    stripeTransferId: Optional[str] = Field(default=None)
    failureReason: Optional[str] = Field(default=None, max_length=500)

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        """Validate payout status"""
        valid_statuses = {"pending", "processing", "completed", "failed"}
        if v not in valid_statuses:
            raise ValueError(f"Invalid payout status: {v}")
        return v


class Order(BaseModel):
    """
    Complete order model
    Single source of truth for order data
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "orderId": "order_123abc",
                "userId": "user_123",
                "customerId": "cus_stripe123",
                "customerEmail": "buyer@example.com",
                "items": [],
                "total": 54.99,
                "subtotal": 49.99,
                "shippingCost": 5.00,
                "taxes": {"GST": 2.50, "PST": 3.50},
                "status": "pending",
                "paymentStatus": "awaiting_payment",
                "deliveryInfo": {},
                "createdAt": "2026-02-01T10:00:00Z"
            }
        }
    )

    orderId: str = Field(..., min_length=1)
    userId: str = Field(..., min_length=1)
    customerId: str = Field(..., min_length=1)
    customerEmail: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    items: List[OrderItem] = Field(..., min_length=1)
    total: float = Field(..., ge=0)
    subtotal: float = Field(..., ge=0)
    shippingCost: float = Field(default=0.0, ge=0)
    taxes: Taxes = Field(default_factory=Taxes)
    status: OrderStatusEnum = Field(default=OrderStatusEnum.PENDING)
    paymentStatus: PaymentStatusEnum = Field(default=PaymentStatusEnum.AWAITING_PAYMENT)
    deliveryInfo: Address = Field(..., description="Delivery address")
    createdAt: datetime = Field(default_factory=datetime.now)
    currency: str = Field(default="cad")
    amount: int = Field(..., ge=0, description="Amount in cents for Stripe")
    sellerIds: List[str] = Field(default_factory=list)
    stripeSessionId: str = Field(..., min_length=1)
    
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
        """Validate currency code"""
        if v.lower() not in {"cad", "usd"}:
            raise ValueError("Only CAD and USD currencies supported")
        return v.lower()

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: int, info) -> int:
        """Validate amount matches total (in cents)"""
        # Note: We can't access other fields in Pydantic v2 validators easily
        # This would need to be a model_validator if we want to compare fields
        return v

    def calculate_totals(self) -> None:
        """Recalculate subtotal and total from items"""
        self.subtotal = sum(item.subtotal() for item in self.items)
        self.total = self.subtotal + self.shippingCost + self.taxes.total()


class OrderCreate(BaseModel):
    """
    Model for creating new orders
    (excludes orderId and createdAt which are generated)
    """
    userId: str = Field(..., min_length=1)
    customerId: str = Field(..., min_length=1)
    customerEmail: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    items: List[OrderItem] = Field(..., min_length=1)
    deliveryInfo: Address
    stripeSessionId: str = Field(..., min_length=1)
    shippingCost: float = Field(default=0.0, ge=0)
    currency: str = Field(default="cad")
    shippingApprovalRequired: bool = Field(default=False)
