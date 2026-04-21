import 'package:origna_gta/core/schema/schema_constants.dart';

class CubaShippingValidator {
  static bool isValidCity(String city) =>
      city.trim().toLowerCase() == 'havana' ||
      ProvinceCodeValues.cubaProvinces.contains(city.trim().toUpperCase());

  static bool isValidProvinceForMaritime(String provinceCode) =>
      ProvinceCodeValues.cubaProvinces.contains(provinceCode);

  static bool isHavana(String city) => city.trim().toLowerCase() == 'havana';

  static double calculateMaritimeCost(double totalWeightKg) {
    final clampedWeight = totalWeightKg.clamp(
      MaritimeShippingConstants.minWeightKg,
      MaritimeShippingConstants.maxWeightKg,
    );
    double costCents = MaritimeShippingConstants.baseRateCents.toDouble();
    costCents += clampedWeight * MaritimeShippingConstants.perKgRateCents;
    if (clampedWeight > MaritimeShippingConstants.surchargeHeavyKg) {
      costCents += MaritimeShippingConstants.heavySurchargeCents.toDouble();
    }
    return costCents / 100.0;
  }

  static String estimatedDeliveryWindow() {
    return '${MaritimeShippingConstants.estimatedDaysMin}-${MaritimeShippingConstants.estimatedDaysMax} business days';
  }
}
