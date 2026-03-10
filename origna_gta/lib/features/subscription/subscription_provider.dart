// coverage:ignore-file
// Migrated: delegates to OrignaBase subscription provider.
// Screens continue using subscriptionViewModelProvider, subscriptionStreamProvider, SubscriptionViewModel.

export 'subscription_state.dart';
export 'orignabase_subscription_provider.dart';

import 'orignabase_subscription_provider.dart';

/// Backward-compatible aliases — screens use these names.
final subscriptionViewModelProvider = obSubscriptionViewModelProvider;
final subscriptionStreamProvider = obSubscriptionStreamProvider;

/// Backward-compatible typedef.
typedef SubscriptionViewModel = OrignaBaseSubscriptionViewModel;
