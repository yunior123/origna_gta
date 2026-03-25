import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

part 'subscription_state.freezed.dart';

@freezed
abstract class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool isLoading,
    String? errorMessage,
    String? checkoutUrl,
    SubscriptionInfo? subscription,
  }) = _SubscriptionState;
}

/// Premium subscription details: plan name, price, billing period, expiration.
class SubscriptionInfo {
  final String status;
  final bool isPremium;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  const SubscriptionInfo({
    required this.status,
    required this.isPremium,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  factory SubscriptionInfo.fromMap(Map<String, dynamic> data) {
    final periodEnd = parseDateTime(data[Fields.currentPeriodEnd]);

    final status =
        data[Fields.status] as String? ?? SubscriptionStatusValues.inactive;
    final isPremium = SubscriptionStatusValues.premiumActive.contains(status);

    return SubscriptionInfo(
      status: status,
      isPremium: isPremium,
      currentPeriodEnd: periodEnd,
      cancelAtPeriodEnd: data[Fields.cancelAtPeriodEnd] as bool? ?? false,
    );
  }
}
