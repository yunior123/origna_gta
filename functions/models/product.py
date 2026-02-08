"""
Product models for OrignaGTA
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .base import Address
from schema_constants import Fields

# ============================================================================
# SHIPPING QUANTITY DISCOUNT - Volume-based shipping discounts
# ============================================================================

class ShippingQuantityDiscount(BaseModel):
    """Volume-based shipping discount thresholds"""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "minQuantity": 5,
                "discountType": "percent",
                "discountValue": 10.0,
                Fields.LABEL: "10% off shipping for 5+ items"
            }
        }
    )

    minQuantity: int = Field(
        ...,
        ge=2,
        description="Minimum quantity to qualify for this discount"
    )
    discountType: str = Field(
        default="percent",
        description="Discount type: percent, fixed, flat_rate"
    )
    discountValue: float = Field(
        ...,
        ge=0,
        description="Discount value (interpretation depends on discountType)"
    )
    label: str | None = Field(
        default=None,
        max_length=100,
        description="Optional label for display"
    )

    @field_validator("discountType")
    @classmethod
    def validate_discount_type(cls, v: str) -> str:
        valid_types = {"percent", "fixed", "flat_rate"}
        if v not in valid_types:
            raise ValueError(f"Invalid discount type: {v}. Must be one of: {valid_types}")
        return v


class SellerDeliveryOption(BaseModel):
    """Seller-specific delivery options with quantity-based pricing"""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.TYPE: "standard",
                Fields.DESCRIPTION: "Standard shipping",
                "cost": 5.99,
                "estimatedDays": 5,
                "quantityDiscounts": [],
                "maxItemsPerShipment": 10,
                "additionalItemCost": 1.50,
                "availableInternational": True
            }
        }
    )

    type: str = Field(
        ...,
        description="Delivery type: pickup, standard, express, same_day"
    )
    description: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Description of delivery option"
    )
    cost: float = Field(
        ...,
        ge=0,
        description="Base cost in CAD"
    )
    estimatedDays: int = Field(
        ...,
        ge=0,
        le=90,
        description="Estimated delivery days"
    )
    quantityDiscounts: list[ShippingQuantityDiscount] = Field(
        default_factory=list,
        description="Quantity-based shipping discounts"
    )
    maxItemsPerShipment: int = Field(
        default=0,
        ge=0,
        description="Max items before cost increases (0 = no limit)"
    )
    additionalItemCost: float = Field(
        default=0.0,
        ge=0,
        description="Additional cost per item after maxItemsPerShipment"
    )
    availableInternational: bool = Field(
        default=True,
        description="Whether option is available for international suppliers"
    )

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        """Validate delivery type"""
        valid_types = {"pickup", "standard", "express", "same_day", "custom"}
        if v not in valid_types:
            raise ValueError(f"Invalid delivery type: {v}")
        return v


# ============================================================================
# SUPPLIER INFO - For dropshipping/marketplace products
# NOTE: The 'currency' field is for SUPPLIER COST tracking only.
#       All SELLING prices on the platform are in CAD (Canadian Dollars).
# ============================================================================

class SupplierInfo(BaseModel):
    """
    Supplier information for dropshipping/international products.
    IMPORTANT: The currency field is for tracking what you PAY the supplier.
    All selling prices to customers are in CAD only.
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.TYPE: "aliexpress",
                "supplierSku": "ABC123456",
                "supplierUrl": "https://aliexpress.com/item/123.html",
                "cost": 15.99,
                Fields.CURRENCY: "USD",  # What you pay supplier (selling price is always CAD)
                "shippingDays": "15-30",
                "hasTracking": True,
                "notes": "Good quality supplier"
            }
        }
    )

    type: str = Field(
        ...,
        description="Supplier platform: aliexpress, alibaba, 1688, dhgate, temu, amazon_usa, custom, etc."
    )
    supplierSku: str | None = Field(
        default=None,
        max_length=100,
        description="Supplier's product SKU"
    )
    supplierUrl: str | None = Field(
        default=None,
        max_length=500,
        description="Direct URL to supplier product"
    )
    cost: float | None = Field(
        default=None,
        ge=0,
        le=100000,
        description="Cost price from supplier (what seller pays)"
    )
    currency: str = Field(
        default="USD",
        description="Currency of SUPPLIER cost (for tracking). Selling price is always CAD."
    )
    shippingDays: str | None = Field(
        default=None,
        max_length=20,
        description="Estimated shipping days range (e.g., '7-15')"
    )
    hasTracking: bool = Field(
        default=False,
        description="Whether supplier provides tracking"
    )
    notes: str | None = Field(
        default=None,
        max_length=500,
        description="Internal notes about supplier"
    )

    @field_validator("currency")
    @classmethod
    def validate_supplier_currency(cls, v: str) -> str:
        """Validate supplier cost currency (these are for cost tracking, not selling)"""
        valid_currencies = {
            "CAD", "USD", "EUR", "GBP", "CNY", "JPY", "KRW",
            "INR", "AUD", "MXN", "BRL", "HKD", "SGD", "TWD"
        }
        if v.upper() not in valid_currencies:
            raise ValueError(f"Invalid currency: {v}. Must be one of: {valid_currencies}")
        return v.upper()


# ============================================================================
# INVENTORY CONFIG - For flexible inventory management
# ============================================================================

class InventoryConfig(BaseModel):
    """Inventory management configuration"""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "managed": True,
                "trackQuantity": True,
                "allowBackorder": False,
                "lowStockThreshold": 5,
                "reservationHoldMinutes": 30
            }
        }
    )

    managed: bool = Field(
        default=True,
        description="Whether inventory is actively managed"
    )
    trackQuantity: bool = Field(
        default=True,
        description="Track stock quantity (false = unlimited)"
    )
    allowBackorder: bool = Field(
        default=False,
        description="Allow orders when out of stock"
    )
    lowStockThreshold: int = Field(
        default=5,
        ge=0,
        le=1000,
        description="Alert threshold for low stock"
    )
    reservationHoldMinutes: int = Field(
        default=30,
        ge=5,
        le=120,
        description="How long to hold inventory during checkout"
    )


class Product(BaseModel):
    """
    Complete product model
    Single source of truth for product data
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                Fields.PRODUCT_ID: "prod_123abc",
                Fields.NAME: "Organic Apples",
                Fields.PRICE: 4.99,
                Fields.DESCRIPTION: "Fresh organic apples from local farm",
                Fields.IMAGE_URLS: ["https://example.com/image1.jpg"],
                Fields.SELLER_ID: "seller_123",
                Fields.SELLER_ADDRESS: {
                    Fields.STREET: "123 Farm Road",
                    Fields.CITY: "Toronto",
                    Fields.STATE: "ON",
                    Fields.POSTAL_CODE: "M5V 3A8",
                    Fields.COUNTRY: "Canada"
                },
                Fields.CATEGORY_ID: 1,
                Fields.STOCK_QUANTITY: 100,
                Fields.RATING: 4.5,
                Fields.DATE_CREATED: "2026-02-01T10:00:00Z",
                Fields.IS_ACTIVE: True
            }
        }
    )

    productId: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Unique product identifier"
    )
    name: str = Field(
        ...,
        min_length=1,
        max_length=120,
        description="Product name"
    )
    price: float = Field(
        ...,
        gt=0,
        le=100000,
        description="Price in CAD"
    )
    description: str = Field(
        ...,
        min_length=10,
        max_length=4000,
        description="Product description"
    )
    imageUrls: list[str] = Field(
        ...,
        min_length=1,
        max_length=5,
        description="Product image URLs (1-5 images)"
    )
    sellerId: str = Field(
        ...,
        min_length=1,
        description="Seller user ID"
    )
    sellerAddress: Address = Field(
        ...,
        description="Seller's address for shipping calculations"
    )
    categoryId: int = Field(
        ...,
        ge=1,
        le=21,
        description="Product category ID (1-21)"
    )
    stockQuantity: int = Field(
        ...,
        ge=0,
        description="Available stock quantity"
    )
    rating: float = Field(
        default=0.0,
        ge=0,
        le=5,
        description="Average product rating (0-5)"
    )
    dateCreated: datetime = Field(
        default_factory=datetime.now,
        description="Product creation timestamp"
    )
    isActive: bool = Field(
        default=True,
        description="Whether product is active and visible"
    )

    # Optional shipping metadata
    weightKg: float | None = Field(
        default=None,
        gt=0,
        le=1000,
        description="Product weight in kilograms"
    )
    lengthCm: float | None = Field(
        default=None,
        gt=0,
        le=1000,
        description="Package length in centimeters"
    )
    widthCm: float | None = Field(
        default=None,
        gt=0,
        le=1000,
        description="Package width in centimeters"
    )
    heightCm: float | None = Field(
        default=None,
        gt=0,
        le=1000,
        description="Package height in centimeters"
    )

    # Delivery options
    isLocalDeliveryOnly: bool = Field(
        default=False,
        description="Only available for local delivery"
    )
    isPerishable: bool = Field(
        default=False,
        description="Product is perishable (affects shipping)"
    )
    estimatedShipDays: int = Field(
        default=3,
        ge=0,
        le=90,
        description="Estimated days to ship"
    )
    deliveryOptions: list[SellerDeliveryOption] = Field(
        default_factory=list,
        description="Seller-specific delivery options"
    )
    minimumOrderQuantity: int = Field(
        default=1,
        ge=1,
        le=100,
        description="Minimum order quantity"
    )
    freeShipping: bool = Field(
        default=False,
        description="Free shipping offered by seller"
    )

    # Digital product flag
    isDigital: bool = Field(
        default=False,
        description="Whether this is a digital product (no shipping required)"
    )

    # Tax and metadata
    taxCode: str | None = Field(
        default=None,
        description="Tax code override for specific products"
    )
    keywords: list[str] = Field(
        default_factory=list,
        description="Search keywords for Algolia"
    )

    # NEW: Structured objects for scalability
    supplier: SupplierInfo | None = Field(
        default=None,
        description="Supplier information for dropshipping/marketplace products"
    )
    inventory: InventoryConfig | None = Field(
        default=None,
        description="Inventory management configuration"
    )
    status: str = Field(
        default="active",
        description="Product status: draft, active, paused, archived, out_of_stock"
    )

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        valid_statuses = {"draft", "active", "paused", "archived", "out_of_stock"}
        if v not in valid_statuses:
            raise ValueError(f"Invalid status: {v}. Must be one of: {valid_statuses}")
        return v

    @field_validator("imageUrls")
    @classmethod
    def validate_image_urls(cls, v: list[str]) -> list[str]:
        """Validate image URLs"""
        for url in v:
            if not url.startswith(("http://", "https://")):
                raise ValueError(f"Invalid image URL: {url}")
        return v

    @field_validator("description")
    @classmethod
    def validate_description(cls, v: str) -> str:
        """Validate description doesn't contain disallowed characters"""
        disallowed = ["<script>", "<iframe>", "javascript:"]
        v_lower = v.lower()
        for pattern in disallowed:
            if pattern in v_lower:
                raise ValueError("Description contains disallowed content")
        return v


class ProductCreate(BaseModel):
    """
    Model for creating new products
    (excludes productId and dateCreated which are generated)
    IMPORTANT: sellerAddress.country MUST be 'Canada' - enforced by validation
    """
    name: str = Field(..., min_length=1, max_length=120)
    price: float = Field(..., gt=0, le=100000)
    description: str = Field(..., min_length=10, max_length=4000)
    imageUrls: list[str] = Field(..., min_length=1, max_length=5)
    sellerId: str = Field(..., min_length=1)
    sellerAddress: Address
    categoryId: int = Field(..., ge=1, le=21)
    stockQuantity: int = Field(..., ge=0)
    rating: float = Field(default=0.0, ge=0, le=5)
    isActive: bool = Field(default=True)
    weightKg: float | None = Field(default=None, gt=0, le=1000)
    lengthCm: float | None = Field(default=None, gt=0, le=1000)
    widthCm: float | None = Field(default=None, gt=0, le=1000)
    heightCm: float | None = Field(default=None, gt=0, le=1000)
    isLocalDeliveryOnly: bool = Field(default=False)
    isPerishable: bool = Field(default=False)
    estimatedShipDays: int = Field(default=3, ge=0, le=90)
    deliveryOptions: list[SellerDeliveryOption] = Field(default_factory=list)
    minimumOrderQuantity: int = Field(default=1, ge=1, le=100)
    freeShipping: bool = Field(default=False)
    isDigital: bool = Field(default=False)
    taxCode: str | None = None
    keywords: list[str] = Field(default_factory=list)
    # NEW: Structured objects
    supplier: SupplierInfo | None = Field(default=None)
    inventory: InventoryConfig | None = Field(default=None)
    status: str = Field(default="active")

    @field_validator("sellerAddress")
    @classmethod
    def validate_canada_only(cls, v: Address) -> Address:
        """CRITICAL: Only Canadian sellers can list products"""
        if v.country.lower() not in ['canada', 'ca']:
            raise ValueError(f"Only Canadian sellers can list products. Received country: {v.country}")
        return v
