"""
Generate JSON Schema from Pydantic models
Run: python generate_schema.py
"""

import json
import sys
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "functions"
sys.path.insert(0, str(functions_dir))

from models import (
    Address,
    AddressDetails,
    OrderStatusEnum,
    PaymentStatusEnum,
    DeliveryStatusEnum,
    ShippingApprovalStatusEnum,
    UserRole,
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
)


def generate_schemas():
    """Generate JSON Schema for all models"""
    
    schemas = {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "title": "OrignaGTA Data Models",
        "description": "JSON Schema for all shared data models between Python backend and Flutter frontend",
        "version": "2.0.0",
        "generated": "2026-02-02",
        "definitions": {
            # Base types
            "Address": Address.model_json_schema(),
            "AddressDetails": AddressDetails.model_json_schema(),
            
            # Enums
            "OrderStatusEnum": {
                "type": "string",
                "enum": [s.value for s in OrderStatusEnum],
                "description": "Order status values"
            },
            "PaymentStatusEnum": {
                "type": "string",
                "enum": [s.value for s in PaymentStatusEnum],
                "description": "Payment status values"
            },
            "DeliveryStatusEnum": {
                "type": "string",
                "enum": [s.value for s in DeliveryStatusEnum],
                "description": "Delivery status values"
            },
            "ShippingApprovalStatusEnum": {
                "type": "string",
                "enum": [s.value for s in ShippingApprovalStatusEnum],
                "description": "Shipping approval status values"
            },
            "UserRole": {
                "type": "string",
                "enum": [r.value for r in UserRole],
                "description": "User role values"
            },
            
            # Product
            "SellerDeliveryOption": SellerDeliveryOption.model_json_schema(),
            "Product": Product.model_json_schema(),
            "ProductCreate": ProductCreate.model_json_schema(),
            
            # Order
            "OrderItem": OrderItem.model_json_schema(),
            "Taxes": Taxes.model_json_schema(),
            "Ratings": Ratings.model_json_schema(),
            "SellerPayout": SellerPayout.model_json_schema(),
            "Order": Order.model_json_schema(),
            "OrderCreate": OrderCreate.model_json_schema(),
            
            # User
            "User": User.model_json_schema(),
            "UserCreate": UserCreate.model_json_schema(),
        }
    }
    
    # Write to file
    output_file = Path(__file__).parent / "json_schemas" / "models.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w") as f:
        json.dump(schemas, f, indent=2)
    
    print(f"✅ JSON Schema generated: {output_file}")
    print(f"📊 Generated {len(schemas['definitions'])} schema definitions")
    
    # Also generate individual schemas for Quicktype
    individual_dir = output_file.parent / "individual"
    individual_dir.mkdir(exist_ok=True)
    
    for name, schema in schemas["definitions"].items():
        if isinstance(schema, dict) and "$ref" not in schema:
            individual_file = individual_dir / f"{name}.json"
            with open(individual_file, "w") as f:
                json.dump(schema, f, indent=2)
            print(f"  - {name}.json")
    
    print(f"\n✅ Individual schemas saved to: {individual_dir}")
    return output_file


if __name__ == "__main__":
    output = generate_schemas()
    print(f"\n🎉 Schema generation complete!")
    print(f"\nNext steps:")
    print(f"1. Install Quicktype: npm install -g quicktype")
    print(f"2. Run: ./scripts/generate_dart_models.sh")
