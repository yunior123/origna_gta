import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/terms/terms_provider.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

// Splash removal is handled entirely by index.html JS (flutter-first-frame + 5s fallback).

/// Auth gate: redirects to login if unauthenticated, shows main screen otherwise.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        // Require email verification except in emulator (emulator doesn't persist emailVerified reliably)
        if (user != null && !user.emailVerified && !EnvConfig().isEmulator) {
          return const EmailVerificationRequiredScreen();
        }
        // CASL/PIPEDA: gate on updated Terms version before allowing app access
        if (user != null) {
          final userProfileAsync = ref.watch(userProfileProvider);
          if (userProfileAsync.isLoading) {
            return const Scaffold(
              body: Center(child: ModernLoadingIndicator()),
            );
          }
          final needsTermsUpdate = ref.watch(needsTermsUpdateProvider);
          if (needsTermsUpdate) {
            return const _TermsUpdateGate();
          }
        }
        return const MainScreen();
      },
      loading: () => const MainScreen(), // HTML splash covers the gap
      error: (e, st) {
        // Log for GlitchTip observability — don't block the user
        AppError.log(e, stackTrace: st, context: 'auth_wrapper');
        return const MainScreen();
      },
    );
  }
}

// ─── Riverpod state for TermsUpdateGate ──────────────────────────────────────
final _termsAcceptingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _termsScrolledProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Un-bypassable full-screen gate shown when the user's accepted terms version
/// differs from the current required version. User must read and accept before
/// proceeding. No back button or skip action.
class _TermsUpdateGate extends ConsumerStatefulWidget {
  const _TermsUpdateGate();

  @override
  ConsumerState<_TermsUpdateGate> createState() => _TermsUpdateGateState();
}

class _TermsUpdateGateState extends ConsumerState<_TermsUpdateGate> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (ref.read(_termsScrolledProvider)) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      ref.read(_termsScrolledProvider.notifier).state = true;
    }
  }

  Future<void> _acceptTerms() async {
    if (ref.read(_termsAcceptingProvider)) return;
    ref.read(_termsAcceptingProvider.notifier).state = true;
    try {
      await ref.read(userRepositoryProvider).recordTermsAcceptance();
      // Provider will auto-update via database stream — no manual navigation needed.
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'terms_update_gate');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('legal.terms_accept_error'.tr()),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) ref.read(_termsAcceptingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(termsProvider);
    final accepting = ref.watch(_termsAcceptingProvider);
    final hasScrolledToBottom = ref.watch(_termsScrolledProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: true),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header — no close/back action
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    const Icon(
                      Icons.policy_outlined,
                      size: 36,
                      color: DesignTokens.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'legal.terms_updated_title'.tr(),
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'legal.terms_updated_subtitle'.tr(),
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Divider(
                color: DesignTokens.textSecondary.withValues(alpha: 0.3),
                height: 1,
              ),
              // Scrollable terms body
              Expanded(
                child: termsAsync.when(
                  data: (content) => ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: 1,
                    itemBuilder: (context, index) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  loading: () => const Center(child: ModernLoadingIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'legal.terms_load_error'.tr(),
                      style: const TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ),
                ),
              ),
              Divider(
                color: DesignTokens.textSecondary.withValues(alpha: 0.3),
                height: 1,
              ),
              // Accept button — enabled only after scrolling to bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasScrolledToBottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'legal.terms_scroll_to_accept'.tr(),
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ModernButton(
                      key: const Key('btn-terms-accept'),
                      semanticsLabel: 'btn-terms-accept',
                      label: accepting
                          ? 'common.loading'.tr()
                          : 'legal.terms_accept_button'.tr(),
                      onPressed: (accepting || !hasScrolledToBottom)
                          ? null
                          : _acceptTerms,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

final _previewAuthUser = AppAuthUser(
  uid: 'preview-auth-user',
  email: 'auth.preview@origna.ca',
  emailVerified: true,
);

final _previewAuthProfile = UserModel(
  uid: 'preview-auth-user',
  email: 'auth.preview@origna.ca',
  name: 'Jordan Lee',
  roles: const [UserRole.buyer],
  createdAt: DateTime(2026, 1, 5),
  verified: true,
);

Widget _authWrapperPreview({
  AppAuthUser? authUser,
  UserModel? profile,
  bool needsTermsUpdate = false,
  String? termsContent,
}) => previewScope(
  extraOverrides: [
    authStateProvider.overrideWith((ref) => Stream.value(authUser)),
    if (profile != null)
      userProfileProvider.overrideWith((ref) => Stream.value(profile)),
    needsTermsUpdateProvider.overrideWith((ref) => needsTermsUpdate),
    if (termsContent != null)
      termsProvider.overrideWith((ref) async => termsContent),
  ],
  child: const AuthWrapper(),
);

@Preview(
  name: 'Auth Wrapper — Mobile',
  group: 'Auth Screens',
  size: Size(390, 844),
)
Widget previewAuthWrapperScreenMobile() =>
    previewMobile(child: _authWrapperPreview());

@Preview(
  name: 'Auth Wrapper — Desktop',
  group: 'Auth Screens',
  size: Size(1280, 800),
)
Widget previewAuthWrapperScreenDesktop() => previewDesktop(
  child: _authWrapperPreview(
    authUser: _previewAuthUser,
    profile: _previewAuthProfile,
  ),
);

@Preview(
  name: 'Auth Wrapper Light — Desktop',
  group: 'Auth Screens',
  size: Size(1280, 800),
)
Widget previewAuthWrapperLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _authWrapperPreview(
    authUser: _previewAuthUser,
    profile: _previewAuthProfile,
    needsTermsUpdate: true,
    termsContent:
        'Updated marketplace terms.\n\n1. Orders are final after capture.\n\n2. Returns require seller approval.\n\n3. Premium subscription fees renew monthly unless cancelled.\n\n4. Payout delays may apply for new sellers.\n\n5. Use of the marketplace implies agreement with Canadian commerce law.\n\n6. Scroll to the bottom before accepting these updated terms.',
  ),
);

@Preview(
  name: 'Auth Wrapper Terms Gate — Desktop',
  group: 'Auth Screens',
  size: Size(1280, 800),
)
Widget previewAuthWrapperTermsGateDesktop() => previewDesktop(
  child: _authWrapperPreview(
    authUser: _previewAuthUser,
    profile: _previewAuthProfile,
    needsTermsUpdate: true,
    termsContent:
        'Updated marketplace terms.\n\n1. Orders are final after capture.\n\n2. Returns require seller approval.\n\n3. Premium subscription fees renew monthly unless cancelled.\n\n4. Payout delays may apply for new sellers.\n\n5. Use of the marketplace implies agreement with Canadian commerce law.\n\n6. Scroll to the bottom before accepting these updated terms.',
  ),
);
