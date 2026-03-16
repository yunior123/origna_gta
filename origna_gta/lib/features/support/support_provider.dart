/// Customer Support Agent — Riverpod Providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/support/support_state.dart';
import 'package:origna_gta/features/support/support_viewmodel.dart';

/// Provides [SupportViewModel] and its [SupportState].
/// autoDispose so the conversation is reset when the screen is closed.
final supportViewModelProvider =
    StateNotifierProvider.autoDispose<SupportViewModel, SupportState>((ref) {
  return SupportViewModel(ref);
});
