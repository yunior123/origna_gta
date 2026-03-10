// coverage:ignore-file
// Migrated: delegates to OrignaBase profile viewmodel.
// Screens continue using profileViewModelProvider.

export 'profile_state.dart';
export 'orignabase_profile_viewmodel.dart';

import 'orignabase_profile_viewmodel.dart';

/// Backward-compatible alias — screens use this name.
final profileViewModelProvider = obProfileViewModelProvider;

/// Backward-compatible typedef.
typedef ProfileViewModel = OrignaBaseProfileViewModel;
