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
    "HAB", "MAT", "VC", "SC", "HOL", "CMG", "CAV", "SSP", "CFG", "PR", "GRA", "LT", "GU", "IJ", "ART", "MAY",
];

pub fn is_cuba_province(province: &str) -> bool {
    CUBA_PROVINCES.contains(&province.trim().to_uppercase().as_str())
}

/// Helper to parse weight from a JSON value, defaulting to 1.0 kg if missing or invalid.
pub fn parse_weight_kg(item: &Value) -> f64 {
    item.get("weightKg")
        .and_then(|v| v.as_f64())
        .unwrap_or(MARITIME_MIN_WEIGHT_KG)
}

/// Calculate total maritime shipping cost based on the total weight of items.
pub fn calculate_cuba_maritime_total_cents(total_weight_kg: f64) -> i64 {
    let clamped_weight = total_weight_kg.clamp(MARITIME_MIN_WEIGHT_KG, MARITIME_MAX_WEIGHT_KG);
    
    let mut cost_cents = MARITIME_BASE_RATE_CENTS;
    cost_cents += (clamped_weight * MARITIME_PER_KG_RATE_CENTS as f64).round() as i64;
    
    if clamped_weight > MARITIME_SURCHARGE_HEAVY_KG {
        cost_cents += MARITIME_HEAVY_SURCHARGE_CENTS;
    }
    cost_cents
}

/// Calculate total maritime shipping cost and provide itemized breakdown
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
    
    let weight_to_distribute = if total_weight > 0.0 { total_weight } else { 1.0 };
    
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

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug, Clone)]
    struct MockItem {
        id: String,
        weight: f64,
        qty: f64,
    }

    #[test]
    fn test_is_cuba_province() {
        assert!(is_cuba_province("HAB"));
        assert!(is_cuba_province("hab"));
        assert!(is_cuba_province(" SC "));
        assert!(!is_cuba_province("ON"));
        assert!(!is_cuba_province(""));
    }

    #[test]
    fn test_calculate_cuba_maritime_total_cents() {
        // Under 1 kg -> base $25 + 1kg * $5 = $30
        assert_eq!(calculate_cuba_maritime_total_cents(0.5), 3000);
        assert_eq!(calculate_cuba_maritime_total_cents(1.0), 3000);
        
        // 5 kg -> base $25 + 5kg * $5 = $50
        assert_eq!(calculate_cuba_maritime_total_cents(5.0), 5000);
        
        // 25 kg -> base $25 + 25kg * $5 + $15 heavy = $165
        assert_eq!(calculate_cuba_maritime_total_cents(25.0), 16500);
        
        // 40 kg (clamped to 30kg) -> base $25 + 30kg * $5 + $15 heavy = $190
        assert_eq!(calculate_cuba_maritime_total_cents(40.0), 19000);
    }

    #[test]
    fn test_calculate_cuba_maritime_itemized() {
        let items = vec![
            MockItem { id: "item1".to_string(), weight: 2.0, qty: 1.0 }, // 2kg
            MockItem { id: "item2".to_string(), weight: 0.5, qty: 2.0 }, // 1kg
        ];
        
        // Total weight = 3kg
        // Total cost = $25 + 3kg * $5 = $40 (4000 cents)
        let (total, breakdown) = calculate_cuba_maritime_itemized(
            &items,
            |it| it.id.clone(),
            |it| it.weight,
            |it| it.qty,
        );
        
        assert_eq!(total, 4000);
        assert_eq!(breakdown.len(), 2);
        
        // item1 share = 2/3 of 4000 = 2667
        // item2 share = 1/3 of 4000 = 1333
        assert_eq!(*breakdown.get("item1").unwrap(), 2667);
        assert_eq!(*breakdown.get("item2").unwrap(), 1333);
        assert_eq!(2667 + 1333, 4000);
    }
}
