import requests
from typing import List, Dict, Optional
from config import GEOAPIFY_API_KEY
from schema_constants import Fields

# PERFORMANCE FIX: Cache province data in memory to avoid repeated dict construction
_TAX_RATES_CACHE = {
    'AB': 0.05, 'BC': 0.12, 'MB': 0.12, 'NB': 0.15, 'NL': 0.15,
    'NT': 0.05, 'NS': 0.15, 'NU': 0.05, 'ON': 0.13, 'PE': 0.15,
    'QC': 0.14975, 'SK': 0.11, 'YT': 0.05,
}

_ADJACENCY_CACHE = {
    'BC': {'AB', 'YT', 'NT'},
    'AB': {'BC', 'SK', 'NT'},
    'SK': {'AB', 'MB', 'NT', 'NU'},
    'MB': {'SK', 'ON', 'NU'},
    'ON': {'MB', 'QC'},
    'QC': {'ON', 'NB', 'NL'},
    'NB': {'QC', 'NS', 'PE'},
    'NS': {'NB', 'PE'},
    'PE': {'NB', 'NS'},
    'NL': {'QC'},
    'YT': {'BC', 'NT'},
    'NT': {'BC', 'AB', 'SK', 'YT', 'NU'},
    'NU': {'SK', 'MB', 'NT'},
}

_REGIONS_CACHE = {
    'West': {'BC', 'AB'},
    'Prairies': {'SK', 'MB'},
    'Central': {'ON', 'QC'},
    'Atlantic': {'NB', 'NS', 'PE', 'NL'},
    'North': {'YT', 'NT', 'NU'},
}

# ============================================================================
# INTERNATIONAL SUPPLIER SHIPPING CONFIGURATION
# For dropshipping from China, Korea, and other international suppliers
# ============================================================================

_INTERNATIONAL_SHIPPING_CONFIG = {
    # Supplier type -> default shipping days and base cost
    'aliexpress': {
        'standard': {'days': '15-30', 'base_cost': 0.0},  # ePacket/AliExpress Standard
        'express': {'days': '7-15', 'base_cost': 15.99},   # DHL/UPS Express
    },
    'dhgate': {
        'standard': {'days': '20-40', 'base_cost': 0.0},
        'express': {'days': '10-20', 'base_cost': 19.99},
    },
    'alibaba': {
        'standard': {'days': '25-45', 'base_cost': 0.0},   # Sea freight typical
        'express': {'days': '7-15', 'base_cost': 25.99},   # Air freight
    },
    '1688': {
        'standard': {'days': '30-50', 'base_cost': 0.0},   # Requires agent
        'express': {'days': '10-20', 'base_cost': 29.99},
    },
    'temu': {
        'standard': {'days': '7-15', 'base_cost': 0.0},    # Temu has fast shipping
        'express': {'days': '5-10', 'base_cost': 9.99},
    },
    'cjdropshipping': {
        'standard': {'days': '10-20', 'base_cost': 0.0},   # CJ has warehouses
        'express': {'days': '5-10', 'base_cost': 12.99},
    },
    'other': {
        'standard': {'days': '20-35', 'base_cost': 5.99},
        'express': {'days': '10-20', 'base_cost': 19.99},
    },
}

# Country to region mapping for international shipping estimates
_COUNTRY_REGIONS = {
    'CN': 'asia',      # China
    'KR': 'asia',      # Korea
    'JP': 'asia',      # Japan
    'TW': 'asia',      # Taiwan
    'HK': 'asia',      # Hong Kong
    'SG': 'asia',      # Singapore
    'US': 'north_america',
    'MX': 'north_america',
    'UK': 'europe',
    'GB': 'europe',
    'DE': 'europe',
    'FR': 'europe',
    'IT': 'europe',
    'ES': 'europe',
    'AU': 'oceania',
    'NZ': 'oceania',
}

def get_tax_rate(state_code: str) -> float:
    """Get tax rate for a Canadian province by state code (cached)"""
    return _TAX_RATES_CACHE.get(state_code, 0.13)


def get_international_shipping_estimate(
    supplier_type: str, 
    speed: str = 'standard',
    weight_kg: float = 0.5
) -> Dict:
    """
    Get estimated shipping info for international suppliers.
    
    Args:
        supplier_type: One of aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
        speed: 'standard' or 'express'
        weight_kg: Product weight for cost calculation
        
    Returns:
        Dict with 'days' (str range), 'cost' (float), 'tracking' (bool)
    """
    config = _INTERNATIONAL_SHIPPING_CONFIG.get(supplier_type, _INTERNATIONAL_SHIPPING_CONFIG['other'])
    speed_config = config.get(speed, config['standard'])
    
    base_cost = speed_config['base_cost']
    
    # Weight surcharge for heavier items
    weight_surcharge = 0.0
    if weight_kg > 1.0:
        weight_surcharge = (weight_kg - 1.0) * 3.0  # $3 per kg over 1kg
    
    return {
        'days': speed_config['days'],
        'cost': base_cost + weight_surcharge,
        'tracking': supplier_type in ['temu', 'cjdropshipping'] or speed == 'express',
        'supplier_type': supplier_type,
    }


def estimate_delivery_date_range(
    supplier_info: Optional[Dict] = None,
    seller_estimated_days: int = 3,
    is_international: bool = False
) -> Dict:
    """
    Calculate estimated delivery date range for buyer display.
    
    Args:
        supplier_info: Product's supplier object (if dropshipping)
        seller_estimated_days: Seller's stated shipping days
        is_international: Whether seller ships from outside Canada
        
    Returns:
        Dict with 'min_days', 'max_days', 'display_text'
    """
    if supplier_info and supplier_info.get('type'):
        # Dropshipping product with supplier info
        supplier_type = supplier_info.get('type', 'other')
        shipping_days = supplier_info.get('shippingDays', '')
        
        if shipping_days and '-' in shipping_days:
            try:
                parts = shipping_days.replace(' ', '').split('-')
                min_days = int(parts[0])
                max_days = int(parts[1])
            except (ValueError, IndexError):
                # Fall back to supplier type defaults
                estimate = get_international_shipping_estimate(supplier_type)
                days_str = estimate['days']
                parts = days_str.split('-')
                min_days = int(parts[0])
                max_days = int(parts[1])
        else:
            estimate = get_international_shipping_estimate(supplier_type)
            days_str = estimate['days']
            parts = days_str.split('-')
            min_days = int(parts[0])
            max_days = int(parts[1])
        
        return {
            'min_days': min_days,
            'max_days': max_days,
            'display_text': f'{min_days}-{max_days} business days',
            'source': 'international_supplier',
            'has_tracking': supplier_info.get('hasTracking', False),
        }
    
    if is_international:
        # Generic international (non-dropship)
        return {
            'min_days': 14,
            'max_days': 30,
            'display_text': '14-30 business days',
            'source': 'international_generic',
            'has_tracking': True,
        }
    
    # Domestic Canadian shipping
    return {
        'min_days': seller_estimated_days,
        'max_days': seller_estimated_days + 3,
        'display_text': f'{seller_estimated_days}-{seller_estimated_days + 3} business days',
        'source': 'domestic',
        'has_tracking': True,
    }

def _are_adjacent_provinces(p1: str, p2: str) -> bool:
    """Check if two provinces are adjacent (cached)"""
    return p2 in _ADJACENCY_CACHE.get(p1, set())

def _are_same_region(p1: str, p2: str) -> bool:
    """Check if two provinces are in the same region (cached)"""
    for region_provinces in _REGIONS_CACHE.values():
        if p1 in region_provinces and p2 in region_provinces:
            return True
    return False

def _calculate_tiered_shipping(distance_km: float, seller_items: List[Dict], speed: str) -> float:
    """Hyper-Competitive tiered calculation: Benchmarked against Instacart/DoorDash/PC Express"""
    base_cost = 26.99  # National Ceiling

    if distance_km <= 15:
        base_cost = 1.99   # Hyper-local Standard (Matches Instacart Scheduled)
    elif distance_km <= 50:
        base_cost = 4.99   # Local Standard
    elif distance_km <= 150:
        base_cost = 9.99
    elif distance_km <= 500:
        base_cost = 14.99  # Captures Toronto-Ottawa/Montreal corridors
    elif distance_km <= 1200:
        base_cost = 18.99
    elif distance_km <= 2500:
        base_cost = 22.99
    
    # Weight & Volumetric surcharges
    weight_surcharge = 0
    total_items = 0
    for item in seller_items:
        qty = item.get('quantity', 1)
        total_items += qty
        
        # Volumetric: (L * W * H) / 5000
        actual_weight = item.get('weightKg', 0.5)
        length = max(item.get('lengthCm', 10), 1)  # Prevent zero dimensions
        width = max(item.get('widthCm', 10), 1)
        height = max(item.get('heightCm', 10), 1)
        vol_weight = (length * width * height) / 5000.0
        effective_weight = max(actual_weight, vol_weight)
        
        if effective_weight > 2.0:
            weight_surcharge += (effective_weight - 2.0) * 1.5 * qty

    subtotal = base_cost + weight_surcharge + ((max(0, total_items - 1)) * (base_cost * 0.15))
    
    # Speed multipliers (Benchmarked to hit $7.99 and $8.99 targets)
    multiplier = 1.0
    if speed == 'express':
        if distance_km <= 15:
            multiplier = 4.0  # Result: $7.96 (~$7.99 "Rapid")
        elif distance_km <= 50:
            multiplier = 1.6  # Result: $7.98 (~$7.99 "Rapid")
        elif distance_km <= 150:
            multiplier = 1.5
        else:
            multiplier = 1.6
    elif speed == 'same_day':
        if distance_km <= 15:
            multiplier = 4.5  # Result: $8.95 (~$8.99 "Really Fast")
        elif distance_km <= 50:
            multiplier = 1.8  # Result: $8.98 (~$8.99 "Really Fast")
        elif distance_km <= 150:
            multiplier = 1.8
        else:
            multiplier = 2.5
    
    return subtotal * multiplier

def _calculate_fallback_shipping(item_count: int, seller_province: str, buyer_province: str) -> float:
    """Fallback shipping calculation using province matrix (Matches new $26.99 ceiling)"""
    base_cost = 26.99  # Default Cross-country National

    if seller_province == buyer_province:
        base_cost = 12.99 # Safe fallback for same province (Avg of local/regional)
    elif _are_adjacent_provinces(seller_province, buyer_province):
        base_cost = 18.99
    elif _are_same_region(seller_province, buyer_province):
        base_cost = 22.99
    
    additional_cost = max(0, item_count - 1) * (base_cost * 0.15)
    
    return base_cost + additional_cost

def _best_quantity_discount(discounts: List[Dict], quantity: int) -> Optional[Dict]:
    """Return the best (highest minQuantity) discount applicable to quantity."""
    best = None
    for d in discounts or []:
        try:
            min_qty = int(d.get('minQuantity', 0) or 0)
        except (TypeError, ValueError):
            continue
        if quantity >= min_qty and (best is None or min_qty > int(best.get('minQuantity', 0) or 0)):
            best = d
    return best

def _calculate_delivery_option_cost(option: Dict, quantity: int) -> float:
    """
    Calculate shipping cost for a delivery option.

    Supports:
    - Canonical schema: {type, cost, quantityDiscounts, maxItemsPerShipment, additionalItemCost}
    - Legacy schema: {speed, isEnabled, price}
    """
    qty = max(1, int(quantity or 1))

    # Canonical schema
    if 'cost' in option or 'type' in option:
        try:
            base_cost = float(option.get('cost', 0) or 0)
        except (TypeError, ValueError):
            base_cost = 0.0

        try:
            max_items = int(option.get('maxItemsPerShipment', 0) or 0)
        except (TypeError, ValueError):
            max_items = 0

        try:
            additional_item_cost = float(option.get('additionalItemCost', 0) or 0)
        except (TypeError, ValueError):
            additional_item_cost = 0.0

        if max_items > 0 and qty > max_items:
            base_cost += (qty - max_items) * additional_item_cost

        discounts = option.get('quantityDiscounts', []) or []
        best = _best_quantity_discount(discounts, qty)
        if not best:
            return base_cost

        discount_type = best.get('discountType', 'percent')
        try:
            discount_value = float(best.get('discountValue', 0) or 0)
        except (TypeError, ValueError):
            discount_value = 0.0

        if discount_type == 'percent':
            return base_cost * (1 - discount_value / 100.0)
        if discount_type == 'fixed':
            return max(0.0, base_cost - discount_value)
        if discount_type == 'flat_rate':
            return max(0.0, discount_value)
        return base_cost

    # Legacy schema
    try:
        price = float(option.get('price', 0) or 0)
    except (TypeError, ValueError):
        price = 0.0
    return price * qty

def _find_matching_delivery_option(options: List[Dict], speed: str) -> Optional[Dict]:
    """
    Find delivery option matching requested speed.

    - Canonical schema matches on `type`
    - Legacy schema matches on `speed` and requires `isEnabled`
    """
    for o in options or []:
        if not isinstance(o, dict):
            continue

        if o.get('type') == speed:
            return o

        if o.get('speed') == speed and o.get('isEnabled'):
            return o

    return None

def calculate_shipping_cost(items: List[Dict], buyer_address: Dict, speed: str = 'standard') -> float:
    """
    Server-side shipping calculation matching frontend logic.
    """
    if not buyer_address or buyer_address.get(Fields.LATITUDE) is None or buyer_address.get(Fields.LONGITUDE) is None:
        print("⚠️ Buyer address missing coordinates")
        return 0.0

    total_shipping = 0.0
    items_by_seller = {}
    for item in items:
        seller_id = item.get(Fields.SELLER_ID)
        if seller_id:
            items_by_seller.setdefault(seller_id, []).append(item)
    
    for seller_id, seller_items in items_by_seller.items():
        # CRITICAL FIX: Defensive checks to prevent crashes on corrupted data
        if not seller_items:
            print(f"⚠️ Skipping seller {seller_id}: Empty items list")
            continue
        
        seller_address = seller_items[0].get(Fields.SELLER_ADDRESS)
        if not seller_address or not isinstance(seller_address, dict):
            print(f"⚠️ Skipping seller {seller_id}: Missing or invalid seller address")
            continue
        
        seller_lat = seller_address.get(Fields.LATITUDE)
        seller_lon = seller_address.get(Fields.LONGITUDE)
        seller_state = seller_address.get(Fields.STATE, 'ON')
        buyer_state = buyer_address.get(Fields.STATE, 'ON')

        chargeable_items = [i for i in seller_items if not i.get(Fields.FREE_SHIPPING)]
        if not chargeable_items:
            continue
        
        # Check Local/Perishable restrictions early
        has_local_restriction = any(i.get(Fields.IS_LOCAL_DELIVERY_ONLY) or i.get(Fields.IS_PERISHABLE) for i in seller_items)
        if has_local_restriction and seller_state != buyer_state:
            print(f"⚠️ Local-only item across province: {seller_state} -> {buyer_state}")
            total_shipping += 50.0 # High penalty

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

        should_call_geoapify = speed in ['express', 'same_day'] or has_local_restriction

        if should_call_geoapify and seller_lat and seller_lon and GEOAPIFY_API_KEY:
            try:
                url = f"https://api.geoapify.com/v1/routematrix?apiKey={GEOAPIFY_API_KEY}"
                payload = {
                    "mode": "drive",
                    "sources": [{"location": [seller_lon, seller_lat]}],
                    "targets": [{"location": [buyer_address[Fields.LONGITUDE], buyer_address[Fields.LATITUDE]]}]
                }
                response = requests.post(url, json=payload, timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    distance_km = max(0, data['sources_to_targets'][0][0]['distance'] / 1000.0)

                    if has_local_restriction and distance_km > 100:
                        total_shipping += 75.0
                        continue

                    total_shipping += _calculate_tiered_shipping(distance_km, chargeable_items, speed)
                    continue
            except Exception as e:
                print(f"⚠️ Geoapify error: {str(e)}")
        
        # Fallback
        item_count = sum(item.get(Fields.QUANTITY, 1) for item in chargeable_items)
        total_shipping += _calculate_fallback_shipping(item_count, seller_state, buyer_state)
        
    return total_shipping
