// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/safe_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import 'seller_registration_state.dart';

/// OrignaBase provider to fetch backend payment provider configuration status.
final obPaymentProviderStatusProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return const {
    PaymentProviderValues.stripe: {
      ApiKeys.enabled: true,
      ApiKeys.configured: true,
      ApiKeys.missingKeys: <String>[],
    },
  };
});

final obSellerRegistrationViewModelProvider =
    StateNotifierProvider.autoDispose<
      OrignaBaseSellerRegistrationViewModel,
      SellerRegistrationState
    >((ref) {
      return OrignaBaseSellerRegistrationViewModel(ref);
    });

/// OrignaBase seller registration viewmodel.
class OrignaBaseSellerRegistrationViewModel
    extends StateNotifier<SellerRegistrationState> {
  final Ref _ref;

  bool _isOperationInProgress = false;
  DateTime? _lastOperationTime;
  static const _minOperationInterval = Duration(seconds: 3);

  OrignaBaseSellerRegistrationViewModel(this._ref)
    : super(SellerRegistrationState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);
  String? get _userId => _ref.read(obUserIdProvider);

  bool _canProceed() {
    if (_isOperationInProgress || state.isLoading) return false;
    if (_lastOperationTime != null) {
      final elapsed = DateTime.now().difference(_lastOperationTime!);
      if (elapsed < _minOperationInterval) return false;
    }
    return true;
  }

  String _cleanErrorMessage(dynamic error, String fallback) {
    if (error is OrignaBaseException) {
      return error.message;
    }
    return fallback;
  }

  Future<void> continueOnboarding() async {
    if (!_canProceed()) return;
    await _continueOnboarding();
  }

  /// Opens the Stripe Express Dashboard via a server-side login link.
  Future<void> openStripeDashboard() async {
    if (!_canProceed()) return;

    _isOperationInProgress = true;
    _lastOperationTime = DateTime.now();

    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      final result = await _ob.request(
        'POST',
        ApiEndpoints.adminStripeLoginLink,
        body: {Fields.userId: userId},
      );
      final data = Map<String, dynamic>.from(result as Map);
      final url = data[ApiKeys.url] as String?;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await safeLaunchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        state = state.copyWith(error: 'Could not open Stripe Dashboard');
      }
    } on OrignaBaseException catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e, 'Failed to open Stripe Dashboard'),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Could not open Stripe Dashboard. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Refreshes the user's stripe status from the backend.
  Future<void> refreshAccountStatus() async {
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      await _ob.request('POST', ApiEndpoints.connectStatus, body: {});
    } on OrignaBaseException catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e, 'Failed to refresh account status'),
      );
    } catch (_) {
      // Silently fail on background refresh
    }
  }

  Future<void> setPaymentProvider(String provider) async {
    if (state.isLoading) return;
    if (provider != PaymentProviderValues.stripe) {
      state = state.copyWith(
        error: 'This payment provider is not available yet.',
        successMessage: null,
      );
      return;
    }
    state = state.copyWith(
      paymentProvider: provider,
      error: null,
      successMessage: null,
    );
  }

  /// Starts the registration process (Step 1).
  Future<void> startRegistration() async {
    if (!_canProceed()) return;

    _isOperationInProgress = true;
    _lastOperationTime = DateTime.now();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      await _ob.request('POST', ApiEndpoints.connectCreateAccount, body: {});
      await _continueOnboarding();
    } on OrignaBaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanErrorMessage(e, 'Failed to create seller account'),
      );
      _isOperationInProgress = false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      _isOperationInProgress = false;
    }
  }

  /// Generates the onboarding link and launches it (Step 2).
  Future<void> _continueOnboarding() async {
    if (!_isOperationInProgress && !_canProceed()) return;

    if (!_isOperationInProgress) {
      _isOperationInProgress = true;
      _lastOperationTime = DateTime.now();
    }

    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      final result = await _ob.request(
        'POST',
        ApiEndpoints.connectAccountLink,
        body: {},
      );
      final data = Map<String, dynamic>.from(result as Map);
      final url = data[ApiKeys.url] as String?;

      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await safeLaunchUrl(
            uri,
            mode: kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
          );
          state = state.copyWith(isLoading: false);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Could not open onboarding link',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate onboarding link',
        );
      }
    } on OrignaBaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanErrorMessage(e, 'Failed to generate onboarding link'),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not complete onboarding. Please try again.',
      );
    } finally {
      _isOperationInProgress = false;
    }
  }
}
