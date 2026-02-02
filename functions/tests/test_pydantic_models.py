"""
Tests for Pydantic models
Validates schema consistency, validation rules, and serialization
"""

import pytest
from datetime import datetime
from pydantic import ValidationError

import sys
from pathlib import Path
functions_dir = Path(__file__).parent.parent
sys.path.insert(0, str(functions_dir))

from models import (
    Address,
    AddressDetails,
    OrderStatusEnum,
    PaymentStatusEnum,
    DeliveryStatusEnum,
    Product,
    ProductCreate,
    SellerDeliveryOption,
    OrderItem,
    Taxes,
    Ratings,
    SellerPayout,
    Order,
    OrderCreate,
    User,
    UserCreate,
    UserRole,
)


# ============================================================================
# ADDRESS TESTS
# ============================================================================

def test_address_valid():
    """Test creating a valid address"""
    address = Address(
        street="123 Main Street",
        apartment="Apt 4B",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
        phoneNumber="4165551234",
        isDefault=True,
        label="Home",
        latitude=43.6532,
        longitude=-79.3832,
    )
    assert address.street == "123 Main Street"
    assert address.city == "Toronto"
    assert address.state == "ON"
    assert address.formatted_address().count("\n") == 3


def test_address_postal_code_validation():
    """Test postal code validation"""
    # Valid postal codes
    address1 = Address(
        street="123 Main St",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    assert address1.postalCode == "M5V 3A8"
    
    address2 = Address(
        street="123 Main St",
        city="Toronto",
        state="ON",
        postalCode="M5V3A8",  # No space
        country="Canada",
    )
    assert " " in address2.postalCode  # Should normalize with space
    
    # Invalid postal code
    with pytest.raises(ValidationError):
        Address(
            street="123 Main St",
            city="Toronto",
            state="ON",
            postalCode="12345",  # Invalid format
            country="Canada",
        )


def test_address_province_validation():
    """Test province code validation"""
    # Valid province
    address = Address(
        street="123 Main St",
        city="Montreal",
        state="qc",  # Lowercase should be normalized
        postalCode="H3A 1A1",
        country="Canada",
    )
    assert address.state == "QC"  # Should be uppercase
    
    # Invalid province
    with pytest.raises(ValidationError):
        Address(
            street="123 Main St",
            city="Toronto",
            state="XX",  # Invalid province
            postalCode="M5V 3A8",
            country="Canada",
        )


def test_address_phone_validation():
    """Test phone number validation"""
    # Valid phone
    address = Address(
        street="123 Main St",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
        phoneNumber="(416) 555-1234",  # Formatted phone
    )
    assert address.phoneNumber == "4165551234"  # Should be digits only
    
    # Invalid phone (too short)
    with pytest.raises(ValidationError):
        Address(
            street="123 Main St",
            city="Toronto",
            state="ON",
            postalCode="M5V 3A8",
            country="Canada",
            phoneNumber="12345",  # Too short
        )


# ============================================================================
# PRODUCT TESTS
# ============================================================================

def test_product_valid():
    """Test creating a valid product"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    product = Product(
        productId="prod_123",
        name="Organic Apples",
        price=4.99,
        description="Fresh organic apples from local farm",
        imageUrls=["https://example.com/image1.jpg"],
        sellerId="seller_123",
        sellerAddress=address,
        categoryId=1,
        stockQuantity=100,
        rating=4.5,
        dateCreated=datetime.now(),
        isActive=True,
    )
    
    assert product.name == "Organic Apples"
    assert product.price == 4.99
    assert product.categoryId == 1


def test_product_price_validation():
    """Test price validation (must be positive)"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    # Invalid: negative price
    with pytest.raises(ValidationError):
        Product(
            productId="prod_123",
            name="Organic Apples",
            price=-4.99,  # Negative price
            description="Fresh organic apples",
            imageUrls=["https://example.com/image1.jpg"],
            sellerId="seller_123",
            sellerAddress=address,
            categoryId=1,
            stockQuantity=100,
            dateCreated=datetime.now(),
        )
    
    # Invalid: zero price
    with pytest.raises(ValidationError):
        Product(
            productId="prod_123",
            name="Organic Apples",
            price=0.0,  # Zero price
            description="Fresh organic apples",
            imageUrls=["https://example.com/image1.jpg"],
            sellerId="seller_123",
            sellerAddress=address,
            categoryId=1,
            stockQuantity=100,
            dateCreated=datetime.now(),
        )


def test_product_category_validation():
    """Test category ID validation (1-21)"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    # Invalid: category 0
    with pytest.raises(ValidationError):
        Product(
            productId="prod_123",
            name="Organic Apples",
            price=4.99,
            description="Fresh organic apples",
            imageUrls=["https://example.com/image1.jpg"],
            sellerId="seller_123",
            sellerAddress=address,
            categoryId=0,  # Invalid
            stockQuantity=100,
            dateCreated=datetime.now(),
        )
    
    # Invalid: category 22
    with pytest.raises(ValidationError):
        Product(
            productId="prod_123",
            name="Organic Apples",
            price=4.99,
            description="Fresh organic apples",
            imageUrls=["https://example.com/image1.jpg"],
            sellerId="seller_123",
            sellerAddress=address,
            categoryId=22,  # Invalid
            stockQuantity=100,
            dateCreated=datetime.now(),
        )


def test_product_image_urls_validation():
    """Test image URLs validation"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    # Invalid: invalid URL
    with pytest.raises(ValidationError):
        Product(
            productId="prod_123",
            name="Organic Apples",
            price=4.99,
            description="Fresh organic apples",
            imageUrls=["not-a-url"],  # Invalid URL
            sellerId="seller_123",
            sellerAddress=address,
            categoryId=1,
            stockQuantity=100,
            dateCreated=datetime.now(),
        )


# ============================================================================
# TAXES TESTS
# ============================================================================

def test_taxes_total_calculation():
    """Test taxes total calculation"""
    taxes = Taxes(GST=2.5, PST=3.5, HST=0.0, QST=0.0)
    assert taxes.total() == 6.0
    
    taxes2 = Taxes(GST=0.0, PST=0.0, HST=13.0, QST=0.0)
    assert taxes2.total() == 13.0


def test_taxes_default_values():
    """Test taxes default values are all zero"""
    taxes = Taxes()
    assert taxes.GST == 0.0
    assert taxes.PST == 0.0
    assert taxes.HST == 0.0
    assert taxes.QST == 0.0
    assert taxes.total() == 0.0


# ============================================================================
# ORDER ITEM TESTS
# ============================================================================

def test_order_item_subtotal_calculation():
    """Test order item subtotal calculation"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    item = OrderItem(
        productId="prod_123",
        name="Organic Apples",
        description="Fresh organic apples",
        price=4.99,
        quantity=3,
        imageUrls=["https://example.com/image1.jpg"],
        sellerId="seller_123",
        sellerAddress=address,
    )
    
    assert item.subtotal() == 14.97  # 4.99 * 3


# ============================================================================
# SELLER PAYOUT TESTS
# ============================================================================

def test_seller_payout_status_validation():
    """Test seller payout status validation"""
    # Valid statuses
    payout1 = SellerPayout(
        sellerId="seller_123",
        amount=100.0,
        platformFee=2.5,
        netAmount=97.5,
        status="pending",
    )
    assert payout1.status == "pending"
    
    payout2 = SellerPayout(
        sellerId="seller_123",
        amount=100.0,
        platformFee=2.5,
        netAmount=97.5,
        status="completed",
    )
    assert payout2.status == "completed"
    
    # Invalid status
    with pytest.raises(ValidationError):
        SellerPayout(
            sellerId="seller_123",
            amount=100.0,
            platformFee=2.5,
            netAmount=97.5,
            status="invalid_status",  # Invalid
        )


# ============================================================================
# USER TESTS
# ============================================================================

def test_user_valid():
    """Test creating a valid user"""
    user = User(
        uid="user_123",
        email="user@example.com",
        name="John Doe",
        roles=[UserRole.BUYER],
        createdAt=datetime.now(),
    )
    
    assert user.uid == "user_123"
    assert user.email == "user@example.com"
    assert UserRole.BUYER in user.roles


def test_user_name_validation():
    """Test user name validation (letters, spaces, hyphens only)"""
    # Valid name
    user1 = User(
        uid="user_123",
        email="user@example.com",
        name="John Doe",
        roles=[UserRole.BUYER],
        createdAt=datetime.now(),
    )
    assert user1.name == "John Doe"
    
    user2 = User(
        uid="user_123",
        email="user@example.com",
        name="Jean-Pierre",
        roles=[UserRole.BUYER],
        createdAt=datetime.now(),
    )
    assert user2.name == "Jean-Pierre"
    
    # Invalid: contains numbers
    with pytest.raises(ValidationError):
        User(
            uid="user_123",
            email="user@example.com",
            name="John123",  # Invalid: contains numbers
            roles=[UserRole.BUYER],
            createdAt=datetime.now(),
        )


def test_user_roles_validation():
    """Test at least one role is required"""
    # Valid: has roles
    user = User(
        uid="user_123",
        email="user@example.com",
        name="John Doe",
        roles=[UserRole.BUYER, UserRole.SELLER],
        createdAt=datetime.now(),
    )
    assert len(user.roles) == 2
    
    # Invalid: empty roles
    with pytest.raises(ValidationError):
        User(
            uid="user_123",
            email="user@example.com",
            name="John Doe",
            roles=[],  # Empty roles list
            createdAt=datetime.now(),
        )


def test_user_helper_methods():
    """Test user helper methods"""
    # Buyer only
    buyer = User(
        uid="user_123",
        email="buyer@example.com",
        name="Jane Buyer",
        roles=[UserRole.BUYER],
        createdAt=datetime.now(),
    )
    assert not buyer.is_seller()
    assert not buyer.is_admin()
    assert not buyer.can_sell()
    
    # Seller (onboarding incomplete)
    seller_incomplete = User(
        uid="user_123",
        email="seller@example.com",
        name="John Seller",
        roles=[UserRole.SELLER],
        createdAt=datetime.now(),
        onboardingCompleted=False,
    )
    assert seller_incomplete.is_seller()
    assert not seller_incomplete.can_sell()  # Onboarding not complete
    
    # Seller (onboarding complete)
    seller_complete = User(
        uid="user_123",
        email="seller@example.com",
        name="John Seller",
        roles=[UserRole.SELLER],
        createdAt=datetime.now(),
        onboardingCompleted=True,
    )
    assert seller_complete.is_seller()
    assert seller_complete.can_sell()
    
    # Admin
    admin = User(
        uid="user_123",
        email="admin@example.com",
        name="Admin User",
        roles=[UserRole.ADMIN, UserRole.BUYER],
        createdAt=datetime.now(),
    )
    assert admin.is_admin()


# ============================================================================
# SERIALIZATION TESTS
# ============================================================================

def test_address_json_serialization():
    """Test Address JSON serialization/deserialization"""
    address = Address(
        street="123 Main Street",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    # Serialize to JSON
    json_data = address.model_dump()
    assert json_data["street"] == "123 Main Street"
    assert json_data["city"] == "Toronto"
    
    # Deserialize from JSON
    address2 = Address(**json_data)
    assert address2.street == address.street
    assert address2.city == address.city


def test_product_json_serialization():
    """Test Product JSON serialization/deserialization"""
    address = Address(
        street="123 Farm Road",
        city="Toronto",
        state="ON",
        postalCode="M5V 3A8",
        country="Canada",
    )
    
    product = Product(
        productId="prod_123",
        name="Organic Apples",
        price=4.99,
        description="Fresh organic apples",
        imageUrls=["https://example.com/image1.jpg"],
        sellerId="seller_123",
        sellerAddress=address,
        categoryId=1,
        stockQuantity=100,
        dateCreated=datetime.now(),
    )
    
    # Serialize to JSON
    json_data = product.model_dump()
    assert json_data["name"] == "Organic Apples"
    assert json_data["price"] == 4.99
    
    # Deserialize from JSON
    product2 = Product(**json_data)
    assert product2.name == product.name
    assert product2.price == product.price


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
