"""
Pydantic models for OrignaGTA
Single source of truth for all shared data structures
"""

from .base import (
    Address,
    AddressDetails,
    OrderStatusEnum,
    PaymentStatusEnum,
    DeliveryStatusEnum,
    ShippingApprovalStatusEnum,
    UserRole,
)
from .product import (
    Product,
    ProductCreate,
    SellerDeliveryOption,
)
from .order import (
    OrderItem,
    Taxes,
    Ratings,
    SellerPayout,
    Order,
    OrderCreate,
)
from .user import (
    User,
    UserCreate,
)

__all__ = [
    # Base types
    "Address",
    "AddressDetails",
    "OrderStatusEnum",
    "PaymentStatusEnum",
    "DeliveryStatusEnum",
    "ShippingApprovalStatusEnum",
    "UserRole",
    # Product
    "Product",
    "ProductCreate",
    "SellerDeliveryOption",
    # Order
    "OrderItem",
    "Taxes",
    "Ratings",
    "SellerPayout",
    "Order",
    "OrderCreate",
    # User
    "User",
    "UserCreate",
]
