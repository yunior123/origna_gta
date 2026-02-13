import logging

import requests

from config import GEOAPIFY_API_KEY
from schema_constants import (
    AppConfig,
    DeliveryTypeValues,
    DiscountTypeValues,
    Fields,
    ShippingSourceValues,
    ShippingTiers,
)

logger = logging.getLogger(__name__)

# PERFORMANCE FIX: Cache province data in memory to avoid repeated dict construction
# NOTE: NS changed from 0.15 to 0.14 on April 1, 2025 (CRA)
_TAX_RATES_CACHE = {
    "AB": 0.05,
    "BC": 0.12,
    "MB": 0.12,
    "NB": 0.15,
    "NL": 0.15,
    "NT": 0.05,
    "NS": 0.14,
    "NU": 0.05,
    "ON": 0.13,
    "PE": 0.15,
    "QC": 0.14975,
    "SK": 0.11,
    "YT": 0.05,
}

_ADJACENCY_CACHE = {
    "BC": {"AB", "YT", "NT"},
    "AB": {"BC", "SK", "NT"},
    "SK": {"AB", "MB", "NT", "NU"},
    "MB": {"SK", "ON", "NU"},
    "ON": {"MB", "QC"},
    "QC": {"ON", "NB", "NL"},
    "NB": {"QC", "NS", "PE"},
    "NS": {"NB", "PE"},
    "PE": {"NB", "NS"},
    "NL": {"QC"},
    "YT": {"BC", "NT"},
    "NT": {"BC", "AB", "SK", "YT", "NU"},
    "NU": {"SK", "MB", "NT"},
}

_REGIONS_CACHE = {
    "West": {"BC", "AB"},
    "Prairies": {"SK", "MB"},
    "Central": {"ON", "QC"},
    "Atlantic": {"NB", "NS", "PE", "NL"},
    "North": {"YT", "NT", "NU"},
}

# ============================================================================
# INTERNATIONAL SUPPLIER SHIPPING CONFIGURATION
# For dropshipping from China, Korea, and other international suppliers
# ============================================================================

_INTERNATIONAL_SHIPPING_CONFIG = {
    # Supplier type -> default shipping days and base cost
    "aliexpress": {
        "standard": {"days": "15-30", "base_cost": 0.0},  # ePacket/AliExpress Standard
        "express": {"days": "7-15", "base_cost": 15.99},  # DHL/UPS Express
    },
    "dhgate": {
        "standard": {"days": "20-40", "base_cost": 0.0},
        "express": {"days": "10-20", "base_cost": 19.99},
    },
    "alibaba": {
        "standard": {"days": "25-45", "base_cost": 0.0},  # Sea freight typical
        "express": {"days": "7-15", "base_cost": 25.99},  # Air freight
    },
    "1688": {
        "standard": {"days": "30-50", "base_cost": 0.0},  # Requires agent
        "express": {"days": "10-20", "base_cost": 29.99},
    },
    "temu": {
        "standard": {"days": "7-15", "base_cost": 0.0},  # Temu has fast shipping
        "express": {"days": "5-10", "base_cost": 9.99},
    },
    "cjdropshipping": {
        "standard": {"days": "10-20", "base_cost": 0.0},  # CJ has warehouses
        "express": {"days": "5-10", "base_cost": 12.99},
    },
    "other": {
        "standard": {"days": "20-35", "base_cost": 5.99},
        "express": {"days": "10-20", "base_cost": 19.99},
    },
}

# Country to region mapping for international shipping estimates
_COUNTRY_REGIONS = {
    "CN": "asia",  # China
    "KR": "asia",  # Korea
    "JP": "asia",  # Japan
    "TW": "asia",  # Taiwan
    "HK": "asia",  # Hong Kong
    "SG": "asia",  # Singapore
    "US": "north_america",
    "MX": "north_america",
    "UK": "europe",
    "GB": "europe",
    "DE": "europe",
    "FR": "europe",
    "IT": "europe",
    "ES": "europe",
    "AU": "oceania",
    "NZ": "oceania",
}


def get_tax_rate(state_code: str) -> float:
    """Get tax rate for a Canadian province by state code (cached)"""
    return _TAX_RATES_CACHE.get(state_code, 0.13)


def get_international_shipping_estimate(
    supplier_type: str, speed: str = DeliveryTypeValues.STANDARD, weight_kg: float = ShippingTiers.DEFAULT_WEIGHT_KG
) -> dict:
    """
    Get estimated shipping info for international suppliers.

    Args:
        supplier_type: One of aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
        speed: 'standard' or 'express'
        weight_kg: Product weight for cost calculation

    Returns:
        Dict with 'days' (str range), 'cost' (float), 'tracking' (bool)
    """
    config = _INTERNATIONAL_SHIPPING_CONFIG.get(supplier_type, _INTERNATIONAL_SHIPPING_CONFIG["other"])
    speed_config = config.get(speed, config[DeliveryTypeValues.STANDARD])

    base_cost = speed_config["base_cost"]

    # Weight surcharge for heavier items
    weight_surcharge = 0.0
    if weight_kg > ShippingTiers.INTL_WEIGHT_THRESHOLD_KG:
        weight_surcharge = (
            weight_kg - ShippingTiers.INTL_WEIGHT_THRESHOLD_KG
        ) * ShippingTiers.INTL_WEIGHT_SURCHARGE_PER_KG

    return {
        "days": speed_config["days"],
        "cost": base_cost + weight_surcharge,
        "tracking": supplier_type in ["temu", "cjdropshipping"] or speed == DeliveryTypeValues.EXPRESS,
        "supplier_type": supplier_type,
    }


def estimate_delivery_date_range(
    supplier_info: dict | None = None,
    seller_estimated_days: int = ShippingTiers.DEFAULT_SELLER_SHIP_DAYS,
    is_international: bool = False,
) -> dict:
    """
    Calculate estimated delivery date range for buyer display.

    Args:
        supplier_info: Product's supplier object (if dropshipping)
        seller_estimated_days: Seller's stated shipping days
        is_international: Whether seller ships from outside Canada

    Returns:
        Dict with 'min_days', 'max_days', 'display_text'
    """
    if supplier_info and supplier_info.get(Fields.TYPE):
        # Dropshipping product with supplier info
        supplier_type = supplier_info.get(Fields.TYPE, "other")
        shipping_days = supplier_info.get(Fields.SHIPPING_DAYS, "")

        if shipping_days and "-" in shipping_days:
            try:
                parts = shipping_days.replace(" ", "").split("-")
                min_days = int(parts[0])
                max_days = int(parts[1])
            except (ValueError, IndexError):
                # Fall back to supplier type defaults
                estimate = get_international_shipping_estimate(supplier_type)
                days_str = estimate["days"]
                parts = days_str.split("-")
                min_days = int(parts[0])
                max_days = int(parts[1])
        else:
            estimate = get_international_shipping_estimate(supplier_type)
            days_str = estimate["days"]
            parts = days_str.split("-")
            min_days = int(parts[0])
            max_days = int(parts[1])

        return {
            "min_days": min_days,
            "max_days": max_days,
            "display_text": f"{min_days}-{max_days} business days",
            "source": ShippingSourceValues.INTERNATIONAL_SUPPLIER,
            "has_tracking": supplier_info.get(Fields.HAS_TRACKING, False),
        }

    if is_international:
        # Generic international (non-dropship)
        return {
            "min_days": ShippingTiers.INTL_GENERIC_MIN_DAYS,
            "max_days": ShippingTiers.INTL_GENERIC_MAX_DAYS,
            "display_text": f"{ShippingTiers.INTL_GENERIC_MIN_DAYS}-{ShippingTiers.INTL_GENERIC_MAX_DAYS} business days",
            "source": ShippingSourceValues.INTERNATIONAL_GENERIC,
            "has_tracking": True,
        }

    # Domestic Canadian shipping
    return {
        "min_days": seller_estimated_days,
        "max_days": seller_estimated_days + ShippingTiers.DOMESTIC_BUFFER_DAYS,
        "display_text": f"{seller_estimated_days}-{seller_estimated_days + ShippingTiers.DOMESTIC_BUFFER_DAYS} business days",
        "source": ShippingSourceValues.DOMESTIC,
        "has_tracking": True,
    }


def _are_adjacent_provinces(p1: str, p2: str) -> bool:
    """Check if two provinces are adjacent (cached)"""
    return p2 in _ADJACENCY_CACHE.get(p1, set())


def _are_same_region(p1: str, p2: str) -> bool:
    """Check if two provinces are in the same region (cached)"""
    return any(p1 in region_provinces and p2 in region_provinces for region_provinces in _REGIONS_CACHE.values())


def _calculate_tiered_shipping(distance_km: float, seller_items: list[dict], speed: str) -> float:
    """Hyper-Competitive tiered calculation: Benchmarked against Instacart/DoorDash/PC Express"""
    base_cost = ShippingTiers.NATIONAL_CEILING

    for threshold, cost in ShippingTiers.TIERS:
        if distance_km <= threshold:
            base_cost = cost
            break

    # Weight & Volumetric surcharges
    weight_surcharge = 0
    total_items = 0
    for item in seller_items:
        qty = item.get(Fields.QUANTITY, 1)
        total_items += qty

        # Volumetric: (L * W * H) / 5000
        actual_weight = max(item.get(Fields.WEIGHT_KG, ShippingTiers.DEFAULT_WEIGHT_KG), 0)
        length = max(item.get(Fields.LENGTH_CM, ShippingTiers.DEFAULT_DIMENSION_CM), 1)
        width = max(item.get(Fields.WIDTH_CM, ShippingTiers.DEFAULT_DIMENSION_CM), 1)
        height = max(item.get(Fields.HEIGHT_CM, ShippingTiers.DEFAULT_DIMENSION_CM), 1)
        vol_weight = (length * width * height) / ShippingTiers.VOLUMETRIC_DIVISOR
        effective_weight = max(actual_weight, vol_weight)

        if effective_weight > ShippingTiers.WEIGHT_SURCHARGE_THRESHOLD_KG:
            weight_surcharge += (
                (effective_weight - ShippingTiers.WEIGHT_SURCHARGE_THRESHOLD_KG)
                * ShippingTiers.WEIGHT_SURCHARGE_PER_KG
                * qty
            )

    subtotal = (
        base_cost + weight_surcharge + ((max(0, total_items - 1)) * (base_cost * ShippingTiers.ADDITIONAL_ITEM_RATE))
    )

    # Speed multipliers
    multiplier = 1.0
    if speed == DeliveryTypeValues.EXPRESS:
        if distance_km <= 15:
            multiplier = ShippingTiers.EXPRESS_MULTIPLIERS["hyper_local"]
        elif distance_km <= 50:
            multiplier = ShippingTiers.EXPRESS_MULTIPLIERS["local"]
        elif distance_km <= 150:
            multiplier = ShippingTiers.EXPRESS_MULTIPLIERS["regional"]
        else:
            multiplier = ShippingTiers.EXPRESS_MULTIPLIERS["default"]
    elif speed == DeliveryTypeValues.SAME_DAY:
        if distance_km <= 15:
            multiplier = ShippingTiers.SAME_DAY_MULTIPLIERS["hyper_local"]
        elif distance_km <= 50:
            multiplier = ShippingTiers.SAME_DAY_MULTIPLIERS["local"]
        elif distance_km <= 150:
            multiplier = ShippingTiers.SAME_DAY_MULTIPLIERS["regional"]
        else:
            multiplier = ShippingTiers.SAME_DAY_MULTIPLIERS["default"]

    return subtotal * multiplier


def _calculate_fallback_shipping(item_count: int, seller_province: str, buyer_province: str) -> float:
    """Fallback shipping calculation using province matrix"""
    base_cost = ShippingTiers.NATIONAL_CEILING

    if seller_province == buyer_province:
        base_cost = ShippingTiers.FALLBACK_SAME_PROVINCE
    elif _are_adjacent_provinces(seller_province, buyer_province):
        base_cost = ShippingTiers.FALLBACK_ADJACENT
    elif _are_same_region(seller_province, buyer_province):
        base_cost = ShippingTiers.FALLBACK_SAME_REGION

    additional_cost = max(0, item_count - 1) * (base_cost * ShippingTiers.ADDITIONAL_ITEM_RATE)

    return base_cost + additional_cost


def _best_quantity_discount(discounts: list[dict], quantity: int) -> dict | None:
    """Return the best (highest minQuantity) discount applicable to quantity."""
    best = None
    for d in discounts or []:
        try:
            min_qty = int(d.get(Fields.MIN_QUANTITY, 0) or 0)
        except (TypeError, ValueError):
            continue
        if quantity >= min_qty and (best is None or min_qty > int(best.get(Fields.MIN_QUANTITY, 0) or 0)):
            best = d
    return best


def _calculate_delivery_option_cost(option: dict, quantity: int) -> float:
    """
    Calculate shipping cost for a delivery option.

    Supports:
    - Canonical schema: {type, cost, quantityDiscounts, maxItemsPerShipment, additionalItemCost}
    - Alternate schema: {speed, isEnabled, price}
    """
    qty = max(1, int(quantity or 1))

    # Canonical schema
    if Fields.COST in option or Fields.TYPE in option:
        try:
            base_cost = float(option.get(Fields.COST, 0) or 0)
        except (TypeError, ValueError):
            base_cost = 0.0

        try:
            max_items = int(option.get(Fields.MAX_ITEMS_PER_SHIPMENT, 0) or 0)
        except (TypeError, ValueError):
            max_items = 0

        try:
            additional_item_cost = float(option.get(Fields.ADDITIONAL_ITEM_COST, 0) or 0)
        except (TypeError, ValueError):
            additional_item_cost = 0.0

        if max_items > 0 and qty > max_items:
            base_cost += (qty - max_items) * additional_item_cost

        discounts = option.get(Fields.QUANTITY_DISCOUNTS, []) or []
        best = _best_quantity_discount(discounts, qty)
        if not best:
            return base_cost

        discount_type = best.get(Fields.DISCOUNT_TYPE, DiscountTypeValues.PERCENT)
        try:
            discount_value = float(best.get(Fields.DISCOUNT_VALUE, 0) or 0)
        except (TypeError, ValueError):
            discount_value = 0.0

        if discount_type == DiscountTypeValues.PERCENT:
            # Clamp discount to 0-100% to prevent negative shipping costs
            clamped_discount = max(0.0, min(100.0, discount_value))
            return max(0.0, base_cost * (1 - clamped_discount / 100.0))
        if discount_type == DiscountTypeValues.FIXED:
            return max(0.0, base_cost - discount_value)
        if discount_type == DiscountTypeValues.FLAT_RATE:
            return max(0.0, discount_value)
        return base_cost

    # Alternate schema
    try:
        price = float(option.get(Fields.PRICE, 0) or 0)
    except (TypeError, ValueError):
        price = 0.0
    return price * qty


def _find_matching_delivery_option(options: list[dict], speed: str) -> dict | None:
    """
    Find delivery option matching requested speed.

    - Canonical schema matches on `type`
    - Alternate schema matches on `speed` and requires `isEnabled`
    """
    for o in options or []:
        if not isinstance(o, dict):
            continue

        if o.get(Fields.TYPE) == speed:
            return o

        if o.get(Fields.DELIVERY_SPEED) == speed and o.get("isEnabled"):
            return o

    return None


def calculate_shipping_cost(items: list[dict], buyer_address: dict, speed: str = DeliveryTypeValues.STANDARD) -> float:
    """
    Server-side shipping calculation matching frontend logic.
    """
    if not buyer_address or buyer_address.get(Fields.LATITUDE) is None or buyer_address.get(Fields.LONGITUDE) is None:
        logger.warning("⚠️ Buyer address missing coordinates — using province-based fallback")
        # Use province-based fallback instead of free shipping
        if not buyer_address:
            return ShippingTiers.DEFAULT_MIN_COST
        buyer_state = buyer_address.get(Fields.STATE, "ON")
        total_fallback = 0.0
        items_by_seller = {}
        for item in items:
            seller_id = item.get(Fields.SELLER_ID)
            if seller_id:
                items_by_seller.setdefault(seller_id, []).append(item)
        for _sid, seller_items in items_by_seller.items():
            chargeable = [i for i in seller_items if not i.get(Fields.FREE_SHIPPING) and not i.get(Fields.IS_DIGITAL)]
            if chargeable:
                seller_state = (
                    chargeable[0].get(Fields.SELLER_ADDRESS, {}).get(Fields.STATE, "ON")
                    if chargeable[0].get(Fields.SELLER_ADDRESS)
                    else "ON"
                )
                item_count = sum(i.get(Fields.QUANTITY, 1) for i in chargeable)
                total_fallback += _calculate_fallback_shipping(item_count, seller_state, buyer_state)
        return total_fallback

    total_shipping = 0.0
    items_by_seller = {}
    for item in items:
        seller_id = item.get(Fields.SELLER_ID)
        if seller_id:
            items_by_seller.setdefault(seller_id, []).append(item)

    for seller_id, seller_items in items_by_seller.items():
        # CRITICAL FIX: Defensive checks to prevent crashes on corrupted data
        if not seller_items:
            logger.warning(f"⚠️ Skipping seller {seller_id}: Empty items list")
            continue

        seller_address = seller_items[0].get(Fields.SELLER_ADDRESS)
        if not seller_address or not isinstance(seller_address, dict):
            logger.warning(f"⚠️ Skipping seller {seller_id}: Missing or invalid seller address")
            continue

        seller_lat = seller_address.get(Fields.LATITUDE)
        seller_lon = seller_address.get(Fields.LONGITUDE)
        seller_state = seller_address.get(Fields.STATE, "ON")
        buyer_state = buyer_address.get(Fields.STATE, "ON")

        chargeable_items = [i for i in seller_items if not i.get(Fields.FREE_SHIPPING) and not i.get(Fields.IS_DIGITAL)]
        if not chargeable_items:
            continue

        # Check Local/Perishable restrictions early
        has_local_restriction = any(i.get(Fields.IS_LOCAL_DELIVERY_ONLY) for i in seller_items)
        has_perishable = any(i.get(Fields.IS_PERISHABLE) for i in seller_items)
        if has_local_restriction and seller_state != buyer_state:
            # SECURITY FIX: Block local-only products entirely for out-of-province buyers
            local_names = [i.get(Fields.NAME, "Unknown") for i in seller_items if i.get(Fields.IS_LOCAL_DELIVERY_ONLY)]
            raise ValueError(
                f"Local delivery only: {', '.join(local_names)} cannot be shipped from {seller_state} to {buyer_state}. "
                f"These products are only available for local delivery within {seller_state}."
            )
        if has_perishable and seller_state != buyer_state:
            logger.warning(f"⚠️ Perishable item across province: {seller_state} -> {buyer_state}")
            total_shipping += ShippingTiers.PERISHABLE_CROSS_PROVINCE

        # Try to find seller fixed price for this speed
        has_seller_fixed_price = False
        seller_fixed_total = 0
        for item in chargeable_items:
            options = item.get(Fields.DELIVERY_OPTIONS, [])
            matching_opt = _find_matching_delivery_option(options, speed)
            if not matching_opt:
                has_seller_fixed_price = False  # All items must have fixed price to use this mode
                break

            option_cost = _calculate_delivery_option_cost(matching_opt, item.get(Fields.QUANTITY, 1))
            if option_cost > 0:
                seller_fixed_total += option_cost
                has_seller_fixed_price = True
            else:
                has_seller_fixed_price = False  # Cost must be positive to qualify as fixed price
                break

        if has_seller_fixed_price:
            total_shipping += seller_fixed_total
            continue

        should_call_geoapify = speed in [DeliveryTypeValues.EXPRESS, DeliveryTypeValues.SAME_DAY] or has_perishable

        if should_call_geoapify and seller_lat and seller_lon and GEOAPIFY_API_KEY:
            try:
                url = f"https://api.geoapify.com/v1/routematrix?apiKey={GEOAPIFY_API_KEY}"
                payload = {
                    "mode": "drive",
                    "sources": [{"location": [seller_lon, seller_lat]}],
                    "targets": [{"location": [buyer_address[Fields.LONGITUDE], buyer_address[Fields.LATITUDE]]}],
                }
                response = requests.post(url, json=payload, timeout=AppConfig.GEOAPIFY_TIMEOUT_SECONDS)
                if response.status_code == 200:
                    data = response.json()
                    distance_km = max(0, data["sources_to_targets"][0][0]["distance"] / 1000.0)

                    if has_perishable and distance_km > ShippingTiers.PERISHABLE_DISTANCE_THRESHOLD_KM:
                        total_shipping += ShippingTiers.PERISHABLE_LONG_DISTANCE
                        continue

                    total_shipping += _calculate_tiered_shipping(distance_km, chargeable_items, speed)
                    continue
            except Exception as e:
                logger.warning(f"⚠️ Geoapify error: {str(e)}")

        # Fallback
        item_count = sum(item.get(Fields.QUANTITY, 1) for item in chargeable_items)
        total_shipping += _calculate_fallback_shipping(item_count, seller_state, buyer_state)

    return total_shipping
