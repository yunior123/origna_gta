// Profile viewmodel — re-exports OrignaBase profile viewmodel.

export 'profile_state.dart';
export 'orignabase_profile_viewmodel.dart';

import 'orignabase_profile_viewmodel.dart';

/// Backward-compatible typedef so older imports referencing [ProfileViewModel]
/// continue to resolve to [OrignaBaseProfileViewModel].
typedef ProfileViewModel = OrignaBaseProfileViewModel;
