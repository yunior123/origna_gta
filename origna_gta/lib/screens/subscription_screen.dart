import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/subscription/subscription_provider.dart';
import '../features/subscription/subscription_state.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionStreamProvider);
    final vmState = ref.watch(subscriptionViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Launch Stripe checkout when URL appears — use ref.read inside callback to avoid stale capture
    ref.listen(subscriptionViewModelProvider.select((s) => s.checkoutUrl), (prev, next) async {
      if (next != null && next.isNotEmpty) {
        await launchUrl(Uri.parse(next), mode: LaunchMode.externalApplication);
        ref.read(subscriptionViewModelProvider.notifier).clearCheckoutUrl();
      }
    });

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'subscription.premium_membership'.tr()),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [isDark ? DesignTokens.darkSurface : DesignTokens.surface, isDark ? DesignTokens.darkSurfaceVariant : Colors.white],
          ),
        ),
        child: subAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (subInfo) => _buildContent(context, ref, vmState, subInfo, isDark),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle, bool isDark, {String? semanticsLabel}) {
    return Semantics(
      label: semanticsLabel,
      container: true,
      excludeSemantics: true,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SubscriptionState vmState, SubscriptionInfo? subInfo, bool isDark) {
    final vm = ref.read(subscriptionViewModelProvider.notifier);
    final isPremium = subInfo?.isPremium ?? false;
    final userAsync = ref.watch(userProfileProvider);
    final notifyNew = userAsync.valueOrNull?.notifyNewProducts ?? false;
    final notifyTrending = userAsync.valueOrNull?.notifyTrending ?? false;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Hero badge
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: isPremium ? 'lbl-premium-member' : 'lbl-upgrade-to-premium',
            container: true,
            excludeSemantics: true,
            child: Text(
              isPremium ? 'subscription.youre_premium_member'.tr() : 'subscription.upgrade_to_premium'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: isPremium ? 'lbl-enjoy-benefits' : 'lbl-price-monthly',
            container: true,
            excludeSemantics: true,
            child: Text(
              isPremium ? 'subscription.enjoy_benefits'.tr() : 'subscription.price_monthly'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: DesignTokens.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          // Benefits list
          _buildBenefit(Icons.percent_rounded, 'subscription.no_platform_fee'.tr(), 'subscription.no_platform_fee_desc'.tr(), isDark, semanticsLabel: 'benefit-no-platform-fee'),
          _buildBenefit(Icons.chat_bubble_outline_rounded, 'subscription.chat_with_sellers'.tr(), 'subscription.chat_with_sellers_desc'.tr(), isDark, semanticsLabel: 'benefit-chat-with-sellers'),
          _buildBenefit(Icons.question_answer_outlined, 'subscription.ask_questions'.tr(), 'subscription.ask_questions_desc'.tr(), isDark, semanticsLabel: 'benefit-ask-questions'),
          _buildBenefit(Icons.notifications_active_outlined, 'subscription.smart_notifications'.tr(), 'subscription.smart_notifications_desc'.tr(), isDark, semanticsLabel: 'benefit-smart-notifications'),
          _buildBenefit(Icons.photo_camera_outlined, 'subscription.photo_reviews'.tr(), 'subscription.photo_reviews_desc'.tr(), isDark, semanticsLabel: 'benefit-photo-reviews'),
          const SizedBox(height: 24),

          if (isPremium) ...[
            // Active subscription info
            _buildStatusCard(subInfo!, isDark),
            const SizedBox(height: 24),

            // Notification preferences
            _buildNotificationPrefs(ref, vm, notifyNew, notifyTrending, isDark),
            const SizedBox(height: 24),

            // Cancel button
            if (!subInfo.cancelAtPeriodEnd)
              Semantics(
                button: true,
                label: 'btn-cancel-subscription',
                child: OutlinedButton(
                  onPressed: vmState.isLoading ? null : () => _confirmCancel(context, vm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.error,
                    side: BorderSide(color: DesignTokens.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: vmState.isLoading
                      ? const ModernLoadingIndicator(size: 20)
                      : Text('subscription.cancel_subscription'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DesignTokens.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'subscription.subscription_ends_on'.tr(namedArgs: {'date': _formatDate(subInfo.currentPeriodEnd)}),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DesignTokens.warning, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: 'btn-reactivate-subscription',
                    child: OutlinedButton(
                      onPressed: vmState.isLoading ? null : () => vm.reactivateSubscription(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.primary,
                        side: BorderSide(color: DesignTokens.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: vmState.isLoading
                          ? const ModernLoadingIndicator(size: 20)
                          : Text('subscription.reactivate_subscription'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
          ] else ...[
            // Subscribe CTA
            if (vmState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  vmState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DesignTokens.error, fontSize: 14),
                ),
              ),
            Semantics(
              button: true,
              label: 'btn-subscribe-premium',
              child: ModernButton(
                key: const Key('subscribe_button'),
                label: 'subscription.subscribe_button'.tr(),
                onPressed: vmState.isLoading ? null : vm.createSubscription,
                isLoading: vmState.isLoading,
                icon: Icons.workspace_premium,
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildNotificationPrefs(WidgetRef ref, SubscriptionViewModel vm, bool notifyNew, bool notifyTrending, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'subscription.notification_preferences'.tr(),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => vm.updateNotificationPreferences(notifyNewProducts: !notifyNew),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('subscription.new_products'.tr(), style: const TextStyle(fontSize: 14)),
                        Text('subscription.new_products_desc'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'switch-notify-new-products',
                    child: SizedBox(
                      height: 28,
                      child: Switch.adaptive(
                        value: notifyNew,
                        onChanged: (val) => vm.updateNotificationPreferences(notifyNewProducts: val),
                        activeThumbColor: DesignTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => vm.updateNotificationPreferences(notifyTrending: !notifyTrending),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('subscription.trending_products'.tr(), style: const TextStyle(fontSize: 14)),
                        Text('subscription.trending_products_desc'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'switch-notify-trending',
                    child: SizedBox(
                      height: 28,
                      child: Switch.adaptive(
                        value: notifyTrending,
                        onChanged: (val) => vm.updateNotificationPreferences(notifyTrending: val),
                        activeThumbColor: DesignTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SubscriptionInfo info, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [DesignTokens.primary.withValues(alpha: 0.1), DesignTokens.secondary.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('subscription.status_label'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  info.status.toUpperCase(),
                  style: TextStyle(color: DesignTokens.success, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          if (info.currentPeriodEnd != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('subscription.renews_label'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
                Text(
                  _formatDate(info.currentPeriodEnd),
                  style: TextStyle(color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, SubscriptionViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('subscription.cancel_premium_title'.tr()),
        content: Text('subscription.cancel_premium_body'.tr()),
        actions: [
          Semantics(
            button: true,
            label: 'btn-keep-premium',
            child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('subscription.keep_premium'.tr())),
          ),
          Semantics(
            button: true,
            label: 'btn-confirm-cancel-subscription',
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                vm.cancelSubscription();
              },
              child: Text('subscription.cancel_subscription'.tr(), style: TextStyle(color: DesignTokens.error)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
