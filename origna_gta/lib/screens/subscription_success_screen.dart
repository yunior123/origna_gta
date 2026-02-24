import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../features/subscription/subscription_provider.dart';

class SubscriptionSuccessScreen extends ConsumerStatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  ConsumerState<SubscriptionSuccessScreen> createState() => _SubscriptionSuccessScreenState();
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _BenefitRow({required this.icon, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: DesignTokens.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : DesignTokens.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded, color: DesignTokens.success, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSuccessScreenState extends ConsumerState<SubscriptionSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  Timer? _activationTimeout;
  bool _timedOut = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subAsync = ref.watch(subscriptionStreamProvider);

    // Gate the success UI on actual isPremium=true from Firestore
    final isPremium = subAsync.valueOrNull?.isPremium ?? false;
    if (!isPremium && !_timedOut) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [DesignTokens.darkBackground, DesignTokens.darkSurface] : [const Color(0xFFF0F2FF), Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModernLoadingIndicator(),
                const SizedBox(height: 24),
                Text(
                  'subscription.activating_membership'.tr(),
                  style: const TextStyle(fontSize: 16, color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [DesignTokens.darkBackground, DesignTokens.darkSurface] : [const Color(0xFFF0F2FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated premium badge
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [DesignTokens.primary, DesignTokens.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primary.withValues(alpha: _glowAnimation.value),
                              blurRadius: 32,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.white, size: 50),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  'subscription.welcome_to_premium'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : DesignTokens.textPrimary, letterSpacing: -0.5),
                ),

                const SizedBox(height: 12),

                Text(
                  'subscription.subscription_active_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: DesignTokens.textSecondary, height: 1.5),
                ),

                const SizedBox(height: 40),

                _BenefitRow(
                  icon: Icons.percent_rounded,
                  title: 'subscription.no_platform_fee'.tr(),
                  subtitle: 'subscription.no_platform_fee_desc'.tr(),
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'subscription.chat_with_sellers'.tr(),
                  subtitle: 'subscription.chat_with_sellers_desc'.tr(),
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.question_answer_outlined,
                  title: 'subscription.ask_questions'.tr(),
                  subtitle: 'subscription.ask_questions_desc'.tr(),
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.photo_camera_outlined,
                  title: 'subscription.photo_reviews'.tr(),
                  subtitle: 'subscription.photo_reviews_desc'.tr(),
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'subscription.smart_notifications'.tr(),
                  subtitle: 'subscription.smart_notifications_desc'.tr(),
                  isDark: isDark,
                ),

                const Spacer(),

                Semantics(
                  button: true,
                  label: 'btn-start-shopping',
                  child: ModernButton(
                    label: 'subscription.start_shopping'.tr(),
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activationTimeout?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.55).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    // 30s timeout fallback — if webhook is delayed, show a manual refresh prompt
    _activationTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }
}
