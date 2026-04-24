import 'package:easy_localization/easy_localization.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

enum DeliveryRegion {
  canada,
  cuba,
  international;

  static DeliveryRegion fromCountry(String? country) {
    if (country == null || country.trim().isEmpty) {
      return DeliveryRegion.canada;
    }
    final lower = country.toLowerCase().trim();
    if (lower == CountryValues.canada.toLowerCase() ||
        lower == CountryValues.canadaCode.toLowerCase()) {
      return DeliveryRegion.canada;
    }
    if (lower == CountryValues.cuba.toLowerCase() ||
        lower == CountryValues.cubaCode.toLowerCase()) {
      return DeliveryRegion.cuba;
    }
    return DeliveryRegion.international;
  }

  bool get isDomestic =>
      this == DeliveryRegion.canada || this == DeliveryRegion.cuba;

  bool get isInternational => this == DeliveryRegion.international;

  String get flagEmoji {
    switch (this) {
      case DeliveryRegion.canada:
        return '🇨🇦';
      case DeliveryRegion.cuba:
        return '🇨🇺';
      case DeliveryRegion.international:
        return '🌍';
    }
  }

  String localizedLabel() {
    if (isDomestic) {
      return 'product.delivery_to_canada_cuba'.tr();
    }
    return 'orders.ships_international'.tr();
  }

  String localizedDeliveryEstimate({int? estimatedShipDays}) {
    final days = estimatedShipDays ?? 0;
    if (isInternational || days >= 28) {
      return 'orders.estimated_delivery_international'.tr();
    }
    return '';
  }
}
