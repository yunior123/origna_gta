import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/providers.dart' show userIdProvider;
import 'package:origna_gta/utils/env_config.dart';

/// EnvConfig provider local to this file.
/// Cannot use the one from providers.dart — that would create a circular import
/// (providers.dart imports orignabase_provider.dart, not the other way around).
final _envConfigProvider = Provider<EnvConfig>((ref) => EnvConfig());

/// Global OrignaBase client provider.
/// URL is determined by environment: dev/staging/prod.
final orignabaseProvider = Provider<OrignaBase>((ref) {
  final env = ref.watch(_envConfigProvider);
  final url = env.orignabaseUrl;
  return OrignaBase.initialize(url: url);
});

/// OrignaBase auth state as a stream provider.
final obAuthStateProvider = StreamProvider<AuthState>((ref) {
  final ob = ref.watch(orignabaseProvider);
  return ob.auth.authStateChanges;
});

/// Alias — canonical userId lives in providers.dart.
final obUserIdProvider = userIdProvider;
