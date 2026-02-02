"""
Product models for OrignaGTA
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator, ConfigDict

from .base import Address


class SellerDeliveryOption(BaseModel):
    """Seller-specific delivery options"""
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "type": "pickup",
                "description": "Free local pickup",
                "cost": 0.0,
                "estimatedDays": 0
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
        description="Cost in CAD"
    )
    estimatedDays: int = Field(
        ...,
        ge=0,
        le=90,
        description="Estimated delivery days"
    )

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        """Validate delivery type"""
        valid_types = {"pickup", "standard", "express", "same_day", "custom"}
        if v not in valid_types:
            raise ValueError(f"Invalid delivery type: {v}")
        return v


class Product(BaseModel):
    """
    Complete product model
    Single source of truth for product data
    """
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "productId": "prod_123abc",
                "name": "Organic Apples",
                "price": 4.99,
                "description": "Fresh organic apples from local farm",
                "imageUrls": ["https://example.com/image1.jpg"],
                "sellerId": "seller_123",
                "sellerAddress": {
                    "street": "123 Farm Road",
                    "city": "Toronto",
                    "state": "ON",
                    "postalCode": "M5V 3A8",
                    "country": "Canada"
                },
                "categoryId": 1,
                "stockQuantity": 100,
                "rating": 4.5,
                "dateCreated": "2026-02-01T10:00:00Z",
                "isActive": True
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
    imageUrls: List[str] = Field(
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
    weightKg: Optional[float] = Field(
        default=None,
        gt=0,
        le=1000,
        description="Product weight in kilograms"
    )
    lengthCm: Optional[float] = Field(
        default=None,
        gt=0,
        le=1000,
        description="Package length in centimeters"
    )
    widthCm: Optional[float] = Field(
        default=None,
        gt=0,
        le=1000,
        description="Package width in centimeters"
    )
    heightCm: Optional[float] = Field(
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
    deliveryOptions: List[SellerDeliveryOption] = Field(
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
    taxCode: Optional[str] = Field(
        default=None,
        description="Tax code override for specific products"
    )
    keywords: List[str] = Field(
        default_factory=list,
        description="Search keywords for Algolia"
    )

    @field_validator("imageUrls")
    @classmethod
    def validate_image_urls(cls, v: List[str]) -> List[str]:
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
    """
    name: str = Field(..., min_length=1, max_length=120)
    price: float = Field(..., gt=0, le=100000)
    description: str = Field(..., min_length=10, max_length=4000)
    imageUrls: List[str] = Field(..., min_length=1, max_length=5)
    sellerId: str = Field(..., min_length=1)
    sellerAddress: Address
    categoryId: int = Field(..., ge=1, le=21)
    stockQuantity: int = Field(..., ge=0)
    rating: float = Field(default=0.0, ge=0, le=5)
    isActive: bool = Field(default=True)
    weightKg: Optional[float] = Field(default=None, gt=0, le=1000)
    lengthCm: Optional[float] = Field(default=None, gt=0, le=1000)
    widthCm: Optional[float] = Field(default=None, gt=0, le=1000)
    heightCm: Optional[float] = Field(default=None, gt=0, le=1000)
    isLocalDeliveryOnly: bool = Field(default=False)
    isPerishable: bool = Field(default=False)
    estimatedShipDays: int = Field(default=3, ge=0, le=90)
    deliveryOptions: List[SellerDeliveryOption] = Field(default_factory=list)
    minimumOrderQuantity: int = Field(default=1, ge=1, le=100)
    freeShipping: bool = Field(default=False)
    isDigital: bool = Field(default=False)
    taxCode: Optional[str] = None
    keywords: List[str] = Field(default_factory=list)
