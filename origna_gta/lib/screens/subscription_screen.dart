import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/mascot/shop_mascot.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/utils/safe_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:origna_gta/features/subscription/subscription_provider.dart';

part 'parts/subscription_hero_section.dart';
part 'parts/subscription_benefit_card.dart';
part 'parts/subscription_status_section.dart';

/// Premium subscription management: view plan, upgrade, cancel via Stripe.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  ProviderSubscription<String?>? _checkoutUrlSubscription;

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionStreamProvider);
    final vmState = ref.watch(subscriptionViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        appBar: AppBarFactory.simple(
          title: 'subscription.premium_membership'.tr(),
        ),
        body: subAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: DesignTokens.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'common.error_loading'.tr(),
                    style: TextStyle(color: DesignTokens.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (subInfo) =>
              _buildContent(context, ref, vmState, subInfo, isDark),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkoutUrlSubscription = ref.listenManual(
      subscriptionViewModelProvider.select((s) => s.checkoutUrl),
      (_, next) async {
        if (next != null && next.isNotEmpty) {
          await safeLaunchUrl(
            Uri.parse(next),
            mode: LaunchMode.externalApplication,
          );
          ref.read(subscriptionViewModelProvider.notifier).clearCheckoutUrl();
        }
      },
    );
  }

  @override
  void dispose() {
    _checkoutUrlSubscription?.close();
    super.dispose();
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState vmState,
    SubscriptionInfo? subInfo,
    bool isDark,
  ) {
    final vm = ref.read(subscriptionViewModelProvider.notifier);
    final isPremium = subInfo?.isPremium ?? false;
    final notifyNew =
        ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.notifyNewProducts),
        ) ??
        false;
    final notifyTrending =
        ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.notifyTrending),
        ) ??
        false;

    // Benefit icon colours — each gets its own semantic colour
    const benefitIcons = [
      (Icons.percent_rounded, DesignTokens.success),
      (Icons.chat_bubble_outline_rounded, DesignTokens.primary),
      (Icons.question_answer_outlined, DesignTokens.secondary),
      (Icons.notifications_active_outlined, DesignTokens.warning),
      (Icons.photo_camera_outlined, DesignTokens.tertiary),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveBreakpoints.contentMaxWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero section ──────────────────────────────────────────
              _SubscriptionHeroSection(isPremium: isPremium),

              // ── Benefits list ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BenefitCard(
                      icon: benefitIcons[0].$1,
                      iconColor: benefitIcons[0].$2,
                      title: 'subscription.no_platform_fee'.tr(),
                      subtitle: 'subscription.no_platform_fee_desc'.tr(),
                      semanticsLabel: 'benefit-no-platform-fee',
                      isDark: isDark,
                    ),
                    _BenefitCard(
                      icon: benefitIcons[1].$1,
                      iconColor: benefitIcons[1].$2,
                      title: 'subscription.chat_with_sellers'.tr(),
                      subtitle: 'subscription.chat_with_sellers_desc'.tr(),
                      semanticsLabel: 'benefit-chat-with-sellers',
                      isDark: isDark,
                    ),
                    _BenefitCard(
                      icon: benefitIcons[2].$1,
                      iconColor: benefitIcons[2].$2,
                      title: 'subscription.ask_questions'.tr(),
                      subtitle: 'subscription.ask_questions_desc'.tr(),
                      semanticsLabel: 'benefit-ask-questions',
                      isDark: isDark,
                    ),
                    _BenefitCard(
                      icon: benefitIcons[3].$1,
                      iconColor: benefitIcons[3].$2,
                      title: 'subscription.smart_notifications'.tr(),
                      subtitle: 'subscription.smart_notifications_desc'.tr(),
                      semanticsLabel: 'benefit-smart-notifications',
                      isDark: isDark,
                    ),
                    _BenefitCard(
                      icon: benefitIcons[4].$1,
                      iconColor: benefitIcons[4].$2,
                      title: 'subscription.photo_reviews'.tr(),
                      subtitle: 'subscription.photo_reviews_desc'.tr(),
                      semanticsLabel: 'benefit-photo-reviews',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    if (isPremium) ...[
                      _SubscriptionStatusCard(info: subInfo!, isDark: isDark),
                      const SizedBox(height: 24),
                      _NotificationPrefsCard(
                        vm: vm,
                        notifyNew: notifyNew,
                        notifyTrending: notifyTrending,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],

                    _SubscriptionActions(
                      subInfo: subInfo,
                      vmState: vmState,
                      vm: vm,
                      isPremium: isPremium,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // ConstrainedBox
    ); // Align
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────


// ═══ Widget Previews ═══

// Free user (no subscription)
Widget _subscriptionFreeUser() => previewScope(child: SubscriptionScreen());

// Premium user — already subscribed
Widget _subscriptionPremiumUser() => previewScope(
  extraOverrides: [
    subscriptionStreamProvider.overrideWith(
      (ref) => Stream.value(SubscriptionInfo(status: 'active', isPremium: true)),
    ),
  ],
  child: SubscriptionScreen(),
);

@Preview(name: 'Premium Subscription Plans — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionScreenMobile() => previewMobile(child: _subscriptionFreeUser());

@Preview(name: 'Premium Subscription Plans — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionScreenTablet() => previewTablet(child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionScreenDesktop() => previewDesktop(child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionScreenWeb() => previewWeb(child: previewScope(child: SubscriptionScreen()));

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Premium Subscription Plans Light — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionLightMobile() => previewMobile(theme: previewLightTheme, child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans Light — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionLightDesktop() => previewDesktop(theme: previewLightTheme, child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans Light — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionLightTablet() => previewTablet(theme: previewLightTheme, child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans Light — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionLightWeb() => previewWeb(theme: previewLightTheme, child: previewScope(child: SubscriptionScreen()));

// ── Premium User (already subscribed) ────────────────────────────────────────
@Preview(name: 'Premium Member View Dark — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionPremiumMobile() => previewMobile(child: _subscriptionPremiumUser());

@Preview(name: 'Premium Member View Dark — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionPremiumTablet() => previewTablet(child: _subscriptionPremiumUser());

@Preview(name: 'Premium Member View Dark — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionPremiumDesktop() => previewDesktop(child: _subscriptionPremiumUser());

@Preview(name: 'Premium Member View Dark — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionPremiumWeb() => previewWeb(child: _subscriptionPremiumUser());

@Preview(name: 'Premium Member View Light — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionPremiumLightMobile() => previewMobile(theme: previewLightTheme, child: _subscriptionPremiumUser());

@Preview(name: 'Premium Member View Light — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionPremiumLightDesktop() => previewDesktop(theme: previewLightTheme, child: _subscriptionPremiumUser());

