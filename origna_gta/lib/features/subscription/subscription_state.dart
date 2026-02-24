import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

class SubscriptionState {
  final bool isLoading;
  final String? errorMessage;
  final String? checkoutUrl;
  final SubscriptionInfo? subscription;

  const SubscriptionState({
    this.isLoading = false,
    this.errorMessage,
    this.checkoutUrl,
    this.subscription,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? checkoutUrl,
    SubscriptionInfo? subscription,
    bool clearError = false,
    bool clearCheckoutUrl = false,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      checkoutUrl: clearCheckoutUrl ? null : checkoutUrl ?? this.checkoutUrl,
      subscription: subscription ?? this.subscription,
    );
  }
}

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
    DateTime? periodEnd;
    final periodEndRaw = data['currentPeriodEnd'];
    if (periodEndRaw is Timestamp) {
      periodEnd = periodEndRaw.toDate();
    } else if (periodEndRaw is int) {
      periodEnd = DateTime.fromMillisecondsSinceEpoch(periodEndRaw * 1000);
    }

    final status = data['status'] as String? ?? 'inactive';
    final isPremium = status == SubscriptionStatusValues.active ||
        status == SubscriptionStatusValues.trialing;

    return SubscriptionInfo(
      status: status,
      isPremium: isPremium,
      currentPeriodEnd: periodEnd,
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] as bool? ?? false,
    );
  }
}
