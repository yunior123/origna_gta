// coverage:ignore-file
// Migrated: delegates to OrignaBase stock notification provider.
// Screens continue using stockNotificationNotifierProvider.

export 'orignabase_stock_notification_provider.dart';

import 'orignabase_stock_notification_provider.dart';

/// Backward-compatible alias — screens use this name.
final stockNotificationNotifierProvider = obStockNotificationNotifierProvider;

/// Backward-compatible typedef.
typedef StockNotificationNotifier = OrignaBaseStockNotificationNotifier;
