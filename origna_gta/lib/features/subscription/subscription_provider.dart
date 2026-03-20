// Subscription provider — re-exports OrignaBase subscription provider.

export 'subscription_state.dart';
export 'orignabase_subscription_provider.dart';

import 'orignabase_subscription_provider.dart';

/// Backward-compatible typedef.
typedef SubscriptionViewModel = OrignaBaseSubscriptionViewModel;
