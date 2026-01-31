// seller_registration_view_model.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:origna_gta/core/providers.dart';
import 'seller_registration_state.dart';

final sellerRegistrationViewModelProvider = StateNotifierProvider.autoDispose<SellerRegistrationViewModel, SellerRegistrationState>((ref) {
  return SellerRegistrationViewModel(ref);
});

class SellerRegistrationViewModel extends StateNotifier<SellerRegistrationState> {
  final Ref _ref;

  SellerRegistrationViewModel(this._ref) : super(SellerRegistrationState());

  /// Refreshes the user's stripe status from the backend
  Future<void> refreshAccountStatus() async {
    // We don't necessarily need to set loading here to avoid UI flickering on resume
    try {
      final functions = _ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('get_connect_account_status');
      await callable.call();
      // The cloud function usually updates the user document, which the UI observes via userProfileProvider
    } catch (e) {
      // Silently fail on background refresh, or log it
      state = state.copyWith(error: e.toString());
    }
  }

  /// Starts the registration process (Step 1)
  Future<void> startRegistration() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final functions = _ref.read(firebaseFunctionsProvider);
      final createAccount = functions.httpsCallable('create_connect_account');

      final result = await createAccount.call();
      final data = result.data as Map<String, dynamic>;
      debugPrint(data.toString());
      // Whether it's new or existing, we proceed to onboarding
      await _continueOnboarding();
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? 'Failed to create seller account');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred: $e');
    }
  }

  /// Generates the onboarding link and launches it (Step 2)
  Future<void> _continueOnboarding() async {
    // Note: Loading state is already true if called from startRegistration
    if (!state.isLoading) state = state.copyWith(isLoading: true, error: null);

    try {
      final functions = _ref.read(firebaseFunctionsProvider);
      final createLink = functions.httpsCallable('create_account_link');

      final result = await createLink.call({'refreshUrl': 'https://orignagta.ca/seller/refresh', 'returnUrl': 'https://orignagta.ca/seller/return'});

      final data = result.data as Map<String, dynamic>;
      final url = data['url'] as String?;

      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          state = state.copyWith(isLoading: false);
        } else {
          state = state.copyWith(isLoading: false, error: 'Could not open onboarding link');
        }
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to generate onboarding link');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Direct method to continue onboarding for users who already have an account ID but didn't finish
  Future<void> continueOnboarding() async {
    await _continueOnboarding();
  }

  /// Opens the Stripe Express Dashboard
  Future<void> openStripeDashboard() async {
    const url = 'https://dashboard.stripe.com/express';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      state = state.copyWith(error: 'Could not open Stripe Dashboard');
    }
  }
}
