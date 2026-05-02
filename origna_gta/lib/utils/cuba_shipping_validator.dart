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
