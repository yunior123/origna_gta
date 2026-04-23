part of '../subscription_screen.dart';

/// Subscription status card showing active status and renewal date.
class _SubscriptionStatusCard extends StatelessWidget {
  final SubscriptionInfo info;
  final bool isDark;

  const _SubscriptionStatusCard({required this.info, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.1),
            DesignTokens.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'subscription.status_label'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.status.toUpperCase(),
                  style: TextStyle(
                    color: DesignTokens.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (info.currentPeriodEnd != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'subscription.renews_label'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(info.currentPeriodEnd),
                  style: TextStyle(
                    color: isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Notification preferences toggles for premium members.
class _NotificationPrefsCard extends StatelessWidget {
  final SubscriptionViewModel vm;
  final bool notifyNew;
  final bool notifyTrending;
  final bool isDark;

  const _NotificationPrefsCard({
    required this.vm,
    required this.notifyNew,
    required this.notifyTrending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? DesignTokens.darkOutline : DesignTokens.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'subscription.notification_preferences'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark
                    ? DesignTokens.textOnDark
                    : DesignTokens.textPrimary,
              ),
            ),
          ),
          _buildToggleRow(
            semanticsLabel: 'btn-toggle-notify-new-products',
            switchLabel: 'switch-notify-new-products',
            title: 'subscription.new_products'.tr(),
            subtitle: 'subscription.new_products_desc'.tr(),
            value: notifyNew,
            onChanged: (val) =>
                vm.updateNotificationPreferences(notifyNewProducts: val),
            onTap: () =>
                vm.updateNotificationPreferences(notifyNewProducts: !notifyNew),
          ),
          _buildToggleRow(
            semanticsLabel: 'btn-toggle-notify-trending',
            switchLabel: 'switch-notify-trending',
            title: 'subscription.trending_products'.tr(),
            subtitle: 'subscription.trending_products_desc'.tr(),
            value: notifyTrending,
            onChanged: (val) =>
                vm.updateNotificationPreferences(notifyTrending: val),
            onTap: () => vm.updateNotificationPreferences(
              notifyTrending: !notifyTrending,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String semanticsLabel,
    required String switchLabel,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14)),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: switchLabel,
                child: SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: DesignTokens.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action buttons: cancel, reactivate, or subscribe CTA.
class _SubscriptionActions extends StatelessWidget {
  final SubscriptionInfo? subInfo;
  final SubscriptionState vmState;
  final SubscriptionViewModel vm;
  final bool isPremium;

  const _SubscriptionActions({
    required this.subInfo,
    required this.vmState,
    required this.vm,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _buildPremiumActions(context);
    }
    return _buildSubscribeCta(context);
  }

  Widget _buildPremiumActions(BuildContext context) {
    final info = subInfo!;
    if (!info.cancelAtPeriodEnd) {
      return Semantics(
        button: true,
        label: 'btn-cancel-subscription',
        child: OutlinedButton(
          onPressed: vmState.isLoading ? null : () => _confirmCancel(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.error,
            side: BorderSide(color: DesignTokens.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: vmState.isLoading
              ? const ModernLoadingIndicator(size: 20)
              : Text(
                  'subscription.cancel_subscription'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'subscription.subscription_ends_on'.tr(
              namedArgs: {'date': _formatDate(info.currentPeriodEnd)},
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'btn-reactivate-subscription',
          child: OutlinedButton(
            onPressed: vmState.isLoading
                ? null
                : () => vm.reactivateSubscription(),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.primary,
              side: BorderSide(color: DesignTokens.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: vmState.isLoading
                ? const ModernLoadingIndicator(size: 20)
                : Text(
                    'subscription.reactivate_subscription'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeCta(BuildContext context) {
    return Column(
      children: [
        if (vmState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              vmState.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.error, fontSize: 14),
            ),
          ),
        // Premium CTA with golden gradient
        Semantics(
          button: true,
          label: 'btn-subscribe-premium',
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  DesignTokens.tertiary,
                  DesignTokens.warning,
                  DesignTokens.tertiary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.warning.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: vmState.isLoading
                ? const Center(
                    child: ModernLoadingIndicator(
                      size: 24,
                      color: DesignTokens.white,
                    ),
                  )
                : Material(
                    color: DesignTokens.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: vmState.isLoading ? null : vm.createSubscription,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: DesignTokens.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'subscription.subscribe_button'.tr(),
                              style: const TextStyle(
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('subscription.cancel_premium_title'.tr()),
        content: Text('subscription.cancel_premium_body'.tr()),
        actions: [
          Semantics(
            button: true,
            label: 'btn-keep-premium',
            child: TextButton(
              onPressed: () => appPop(ctx),
              child: Text('subscription.keep_premium'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-confirm-cancel-subscription',
            child: TextButton(
              onPressed: () {
                appPop(ctx);
                vm.cancelSubscription();
              },
              child: Text(
                'subscription.cancel_subscription'.tr(),
                style: TextStyle(color: DesignTokens.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '\u2014';
  return DateFormat('MMM d, yyyy').format(date);
}
