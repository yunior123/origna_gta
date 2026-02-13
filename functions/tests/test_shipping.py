# Self-contained testing of the logic in shipping_service.py


def _calculate_tiered_shipping(distance_km: float, seller_items: list[dict], speed: str) -> float:
    """Hyper-Competitive tiered calculation: Benchmarked against Instacart/DoorDash/PC Express"""
    base_cost = 26.99  # National Ceiling

    if distance_km <= 15:
        base_cost = 1.99  # Hyper-local Standard (Matches Instacart Scheduled)
    elif distance_km <= 50:
        base_cost = 4.99  # Local Standard
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
        qty = item.get("quantity", 1)
        total_items += qty

        # Volumetric: (L * W * H) / 5000
        actual_weight = item.get("weightKg", 0.5)
        vol_weight = (item.get("lengthCm", 10) * item.get("widthCm", 10) * item.get("heightCm", 10)) / 5000.0
        effective_weight = max(actual_weight, vol_weight)

        if effective_weight > 2.0:
            weight_surcharge += (effective_weight - 2.0) * 1.5 * qty

    subtotal = base_cost + weight_surcharge + ((max(0, total_items - 1)) * (base_cost * 0.15))

    # Speed multipliers (Benchmarked to hit $7.99 and $8.99 targets)
    multiplier = 1.0
    if speed == "express":
        if distance_km <= 15:
            multiplier = 4.0  # Result: $7.96 (~$7.99 "Rapid")
        elif distance_km <= 50:
            multiplier = 1.6  # Result: $7.98 (~$7.99 "Rapid")
        elif distance_km <= 150:
            multiplier = 1.5
        else:
            multiplier = 1.6
    elif speed == "same_day":
        if distance_km <= 15:
            multiplier = 4.5  # Result: $8.95 (~$8.99 "Really Fast")
        elif distance_km <= 50:
            multiplier = 1.8  # Result: $8.98 (~$8.99 "Really Fast")
        elif distance_km <= 150:
            multiplier = 1.8
        else:
            multiplier = 2.5

    return subtotal * multiplier


def run_test_scenario(
    name: str,
    distance_km: float,
    items: list[dict],
    speed: str = "standard",
    expected_min: float = None,
    expected_max: float = None,
):
    print(f"\n--- Scenario: {name} ---")
    print(f"Distance: {distance_km}km, Speed: {speed}")
    print(f"Items: {len(items)}")

    # We mock a simple buyer address with coordinates if needed,
    # but since we want to test the mathematical tiers directly:
    cost = _calculate_tiered_shipping(distance_km, items, speed)

    total_weight = sum(i.get("weightKg", 0.5) * i.get("quantity", 1) for i in items)
    print(f"Total Weight: {total_weight}kg")
    print(f"Calculated Cost: ${cost:.2f}")

    # CRITICAL FIX: Add assertions for automated validation
    if expected_min is not None:
        assert cost >= expected_min, f"Cost ${cost:.2f} below minimum ${expected_min:.2f}"
        print(f"✅ Cost meets minimum: ${expected_min:.2f}")

    if expected_max is not None:
        assert cost <= expected_max, f"Cost ${cost:.2f} exceeds maximum ${expected_max:.2f}"
        print(f"✅ Cost under maximum: ${expected_max:.2f}")

    # Sanity checks
    assert cost > 0, "Shipping cost must be positive"
    assert cost < 200, "Shipping cost unreasonably high (>${200:.2f})"


# Define some mock items
def create_item(weight=0.5, length=10, w=10, h=10, qty=1):
    return {"weightKg": weight, "lengthCm": length, "widthCm": w, "heightCm": h, "quantity": qty, "deliveryOptions": []}


if __name__ == "__main__":
    # Scenario 1: Local Small Item (Toronto to Toronto)
    run_test_scenario("Local Small Item", 10, [create_item()], expected_min=1.50, expected_max=3.00)

    # Scenario 2: Regional Medium Item (Toronto to Ottawa ~450km)
    run_test_scenario("Regional Small Item", 450, [create_item()], expected_min=13.00, expected_max=16.00)

    # Scenario 3: National Medium Item (Toronto to Vancouver ~3400km)
    # Note: Our tiers stop at 2500 currently (38.99 fallback for high distance)
    run_test_scenario("National Small Item", 3400, [create_item()], expected_min=25.00, expected_max=30.00)

    # Scenario 4: Heavy Local Item (10kg)
    run_test_scenario("Heavy Local (10kg)", 10, [create_item(weight=10.0)], expected_min=12.00, expected_max=18.00)

    # Scenario 5: Multiple Items Local
    run_test_scenario("3 Small Items Local", 10, [create_item(qty=3)], expected_min=2.00, expected_max=4.00)

    # Scenario 6: Express National
    run_test_scenario(
        "Express National Small", 3400, [create_item()], speed="express", expected_min=40.00, expected_max=50.00
    )

    # Scenario 7: Same Day Local
    run_test_scenario(
        "Same Day Local Small", 10, [create_item()], speed="same_day", expected_min=7.00, expected_max=10.00
    )

    # Scenario 9: Bulk Local (5 items)
    run_test_scenario("Bulk Local (5 items)", 10, [create_item(qty=5)], expected_min=2.50, expected_max=5.00)

    # Scenario 10: Heavy Cross-Country (20kg, 3400km)
    run_test_scenario("Heavy National (20kg)", 3400, [create_item(weight=20.0)], expected_min=50.00, expected_max=80.00)

    # Scenario 11: Middle Range Regional (250km)
    run_test_scenario("Mid Regional (250km)", 250, [create_item()], expected_min=13.00, expected_max=16.00)

    print("\n✅ All shipping cost tests passed!")
