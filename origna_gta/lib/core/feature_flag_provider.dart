import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

final featureFlagSellerOnboardingProvider = Provider<bool>(
  (ref) => FeatureFlags.kSellerOnboardingEnabled,
);
