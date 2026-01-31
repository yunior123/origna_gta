import requests
from typing import List, Dict
from config import GEOAPIFY_API_KEY

def get_tax_rate(province: str) -> float:
    """Get tax rate for a Canadian province"""
    tax_rates = {
        'AB': 0.05,
        'BC': 0.12,
        'MB': 0.12,
        'NB': 0.15,
        'NL': 0.15,
        'NT': 0.05,
        'NS': 0.15,
        'NU': 0.05,
        'ON': 0.13,
        'PE': 0.15,
        'QC': 0.14975,
        'SK': 0.11,
        'YT': 0.05,
    }
    return tax_rates.get(province, 0.13)

def _are_adjacent_provinces(p1: str, p2: str) -> bool:
    """Check if two provinces are adjacent"""
    adjacency = {
        'BC': ['AB', 'YT', 'NT'],
        'AB': ['BC', 'SK', 'NT'],
        'SK': ['AB', 'MB', 'NT', 'NU'],
        'MB': ['SK', 'ON', 'NU'],
        'ON': ['MB', 'QC'],
        'QC': ['ON', 'NB', 'NL'],
        'NB': ['QC', 'NS', 'PE'],
        'NS': ['NB', 'PE'],
        'PE': ['NB', 'NS'],
        'NL': ['QC'],
        'YT': ['BC', 'NT'],
        'NT': ['BC', 'AB', 'SK', 'YT', 'NU'],
        'NU': ['SK', 'MB', 'NT'],
    }
    return p2 in adjacency.get(p1, [])

def _are_same_region(p1: str, p2: str) -> bool:
    """Check if two provinces are in the same region"""
    regions = {
        'West': ['BC', 'AB'],
        'Prairies': ['SK', 'MB'],
        'Central': ['ON', 'QC'],
        'Atlantic': ['NB', 'NS', 'PE', 'NL'],
        'North': ['YT', 'NT', 'NU'],
    }
    for region_provinces in regions.values():
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
        vol_weight = (item.get('lengthCm', 10) * item.get('widthCm', 10) * item.get('heightCm', 10)) / 5000.0
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

def calculate_shipping_cost(items: List[Dict], buyer_address: Dict, speed: str = 'standard') -> float:
    """
    Server-side shipping calculation matching frontend logic.
    """
    if not buyer_address or not buyer_address.get('latitude') or not buyer_address.get('longitude'):
        print("⚠️ Buyer address missing coordinates")
        return 0.0

    total_shipping = 0.0
    items_by_seller = {}
    for item in items:
        seller_id = item.get('sellerId')
        if seller_id:
            items_by_seller.setdefault(seller_id, []).append(item)
    
    for seller_id, seller_items in items_by_seller.items():
        seller_address = seller_items[0].get('sellerAddress', {})
        seller_lat = seller_address.get('latitude')
        seller_lon = seller_address.get('longitude')
        seller_state = seller_address.get('state', 'ON')
        buyer_state = buyer_address.get('state', 'ON')

        chargeable_items = [i for i in seller_items if not i.get('freeShipping')]
        if not chargeable_items:
            continue
        
        # Check Local/Perishable restrictions early
        has_local_restriction = any(i.get('isLocalDeliveryOnly') or i.get('isPerishable') for i in seller_items)
        if has_local_restriction and seller_state != buyer_state:
            print(f"⚠️ Local-only item across province: {seller_state} -> {buyer_state}")
            total_shipping += 50.0 # High penalty

        # Try to find seller fixed price for this speed
        has_seller_fixed_price = False
        seller_fixed_total = 0
        for item in chargeable_items:
            options = item.get('deliveryOptions', [])
            matching_opt = next((o for o in options if o.get('speed') == speed and o.get('isEnabled')), None)
            if matching_opt and matching_opt.get('price', 0) > 0:
                seller_fixed_total += matching_opt['price'] * item.get('quantity', 1)
                has_seller_fixed_price = True
            else:
                has_seller_fixed_price = False # All items must have fixed price to use this mode
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
                    "targets": [{"location": [buyer_address['longitude'], buyer_address['latitude']]}]
                }
                response = requests.post(url, json=payload, timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    distance_km = data['sources_to_targets'][0][0]['distance'] / 1000.0
                    
                    if has_local_restriction and distance_km > 100:
                        total_shipping += 75.0
                        continue

                    total_shipping += _calculate_tiered_shipping(distance_km, chargeable_items, speed)
                    continue
            except Exception as e:
                print(f"⚠️ Geoapify error: {str(e)}")
        
        # Fallback
        item_count = sum(item.get('quantity', 1) for item in chargeable_items)
        total_shipping += _calculate_fallback_shipping(item_count, seller_state, buyer_state)
        
    return total_shipping
