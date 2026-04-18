import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the current [AppLifecycleState].
/// Initialized with [AppLifecycleState.resumed] as the app is active on launch.
final appLifecycleProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
  name: 'appLifecycleProvider',
);

/// Returns true only when the app has genuinely come back from background-ish
/// states into [AppLifecycleState.resumed].
bool isResumeTransition(
  AppLifecycleState? previous,
  AppLifecycleState next,
) {
  return next == AppLifecycleState.resumed &&
      previous != null &&
      previous != AppLifecycleState.resumed;
}

extension LifecycleRefX on Ref {
  /// Calls [callback] only when the app returns from background to resumed state.
  /// This helps providers refresh stale data after a meaningful background gap
  /// without needing their own [WidgetsBindingObserver].
  void onResume(void Function() callback) {
    listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (isResumeTransition(previous, next)) {
        callback();
      }
    });
  }
}

extension LifecycleWidgetRefX on WidgetRef {
  /// Calls [callback] only when the app returns from background to resumed state.
  /// Useful for screens that need to refresh UI or trigger actions on return.
  void onResume(void Function() callback) {
    listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (isResumeTransition(previous, next)) {
        callback();
      }
    });
  }
}
