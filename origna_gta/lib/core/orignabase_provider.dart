import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/providers.dart' show userIdProvider;
import 'package:origna_gta/utils/env_config.dart';

/// EnvConfig provider local to this file.
/// Cannot use the one from providers.dart — that would create a circular import
/// (providers.dart imports orignabase_provider.dart, not the other way around).
final _envConfigProvider = Provider<EnvConfig>((ref) => EnvConfig());

/// Provides the shared [OrignaBase] client configured for the active environment.
///
/// Returns:
/// - An initialized SDK client pointed at the URL from [EnvConfig.orignabaseUrl].
///
/// Gotchas:
/// - This provider must stay in this file to avoid the circular import noted above.
/// - Recreating the provider recreates the SDK client, so app code should read/watch
///   this provider instead of instantiating `OrignaBase` directly.
final orignabaseProvider = Provider<OrignaBase>((ref) {
  final env = ref.watch(_envConfigProvider);
  final url = env.orignabaseUrl;
  return OrignaBase.initialize(url: url);
});

/// Exposes the live OrignaBase auth stream as Riverpod state.
///
/// Returns:
/// - A stream of [AuthState] values emitted by the SDK whenever the local auth
///   session changes.
///
/// Gotchas:
/// - Consumers should expect an initial async loading state before the first
///   auth event arrives.
/// - This is a direct SDK stream; it does not normalize or debounce transitions.
final obAuthStateProvider = StreamProvider<AuthState>((ref) {
  final ob = ref.watch(orignabaseProvider);
  return ob.auth.authStateChanges;
});

/// Alias — canonical userId lives in providers.dart.
final obUserIdProvider = userIdProvider;
