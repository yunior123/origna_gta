# Cuba Integration Backup

Archived before removing active Cuba support on 2026-05-03.

Base commit before removal: `3c1a1ed4`.

Full pre-removal files can be recovered with:

```bash
git show 3c1a1ed4:origna_gta/lib/utils/cuba_shipping_validator.dart
git show 3c1a1ed4:orignabase/crates/ob-handlers/src/shipping_calc/cuba.rs
git show 3c1a1ed4:origna_gta/lib/core/schema/schema_constants.dart
git show 3c1a1ed4:origna_gta/lib/screens/editaddress_screen.dart
git show 3c1a1ed4:orignabase/crates/ob-handlers/src/payments/checkout.rs
git show 3c1a1ed4:orignabase/crates/ob-handlers/src/shipping_calc/mod.rs
```

## Flutter Validator

```dart
import 'package:origna_gta/core/schema/schema_constants.dart';

class CubaShippingValidator {
  static bool isValidCity(String city) =>
      city.trim().toLowerCase() == 'havana' ||
      ProvinceCodeValues.cubaProvinces.contains(city.trim().toUpperCase());

  static bool isValidProvinceForMaritime(String provinceCode) =>
      ProvinceCodeValues.cubaProvinces.contains(provinceCode);

  static bool isHavana(String city) => city.trim().toLowerCase() == 'havana';

  static int calculateMaritimeCost(double totalWeightKg) {
    final clampedWeight = totalWeightKg.clamp(
      MaritimeShippingConstants.minWeightKg,
      MaritimeShippingConstants.maxWeightKg,
    );
    int costCents = MaritimeShippingConstants.baseRateCents;
    costCents += (clampedWeight * MaritimeShippingConstants.perKgRateCents)
        .round();
    if (clampedWeight > MaritimeShippingConstants.surchargeHeavyKg) {
      costCents += MaritimeShippingConstants.heavySurchargeCents;
    }
    return costCents;
  }

  static String estimatedDeliveryWindow() {
    return '${MaritimeShippingConstants.estimatedDaysMin}-${MaritimeShippingConstants.estimatedDaysMax} business days';
  }
}
```

## Rust Maritime Module

```rust
//! Cuba maritime shipping logic.
//! Reused across `checkout.rs` and `shipping_calc/mod.rs`.

use serde_json::Value;
use std::collections::HashMap;

pub const MARITIME_BASE_RATE_CENTS: i64 = 2500;
pub const MARITIME_PER_KG_RATE_CENTS: i64 = 500;
pub const MARITIME_MIN_WEIGHT_KG: f64 = 1.0;
pub const MARITIME_MAX_WEIGHT_KG: f64 = 30.0;
pub const MARITIME_SURCHARGE_HEAVY_KG: f64 = 20.0;
pub const MARITIME_HEAVY_SURCHARGE_CENTS: i64 = 1500;

const CUBA_PROVINCES: &[&str] = &[
    "HAB", "MAT", "VC", "SC", "HOL", "CMG", "CAV", "SSP", "CFG", "PR", "GRA", "LT", "GU", "IJ",
    "ART", "MAY",
];

pub fn is_cuba_province(province: &str) -> bool {
    CUBA_PROVINCES.contains(&province.trim().to_uppercase().as_str())
}

pub fn parse_weight_kg(item: &Value) -> f64 {
    item.get("weightKg")
        .and_then(|v| v.as_f64())
        .unwrap_or(MARITIME_MIN_WEIGHT_KG)
}

pub fn calculate_cuba_maritime_total_cents(total_weight_kg: f64) -> i64 {
    let clamped_weight = total_weight_kg.clamp(MARITIME_MIN_WEIGHT_KG, MARITIME_MAX_WEIGHT_KG);

    let mut cost_cents = MARITIME_BASE_RATE_CENTS;
    cost_cents += (clamped_weight * MARITIME_PER_KG_RATE_CENTS as f64).round() as i64;

    if clamped_weight > MARITIME_SURCHARGE_HEAVY_KG {
        cost_cents += MARITIME_HEAVY_SURCHARGE_CENTS;
    }
    cost_cents
}

pub fn calculate_cuba_maritime_itemized<T>(
    items: &[T],
    get_id: impl Fn(&T) -> String,
    get_weight: impl Fn(&T) -> f64,
    get_qty: impl Fn(&T) -> f64,
) -> (i64, HashMap<String, i64>) {
    let mut total_weight = 0.0;
    for item in items {
        total_weight += get_weight(item) * get_qty(item);
    }

    let total_cents = calculate_cuba_maritime_total_cents(total_weight);

    let mut breakdown = HashMap::new();
    let mut remaining_cents = total_cents;

    let weight_to_distribute = if total_weight > 0.0 {
        total_weight
    } else {
        1.0
    };

    for (i, item) in items.iter().enumerate() {
        let id = get_id(item);
        if i == items.len() - 1 {
            breakdown.insert(id, remaining_cents);
        } else {
            let ew = get_weight(item) * get_qty(item);
            let share = ew / weight_to_distribute;
            let item_cost = (total_cents as f64 * share).round() as i64;
            breakdown.insert(id, item_cost);
            remaining_cents -= item_cost;
        }
    }

    (total_cents, breakdown)
}
```
