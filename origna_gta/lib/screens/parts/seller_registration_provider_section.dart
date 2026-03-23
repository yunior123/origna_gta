part of '../seller_registration_screen.dart';

/// Payment provider selector with chips and info card.
class _ProviderSelector extends ConsumerWidget {
  final UserModel user;
  final SellerRegistrationState state;
  final SellerRegistrationViewModel viewModel;

  const _ProviderSelector({
    required this.user,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = user.paymentProvider.isNotEmpty
        ? user.paymentProvider
        : state.paymentProvider;
    final selectedConfig = availablePaymentProviders.firstWhere(
      (p) => p.id == provider,
      orElse: () => availablePaymentProviders.first,
    );

    // Watch backend provider status once — pass resolved value into the map to avoid double-watch
    final backendStatusMap =
        ref.watch(paymentProviderStatusProvider.select((a) => a.valueOrNull)) ??
        {};

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'seller.payment_provider'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: DesignTokens.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Dynamic provider chips from configuration
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePaymentProviders.map((config) {
              final isSelected = provider == config.id;

              // Check if provider is configured in backend (defaults to true if unknown)
              final providerStatus = backendStatusMap[config.id];
              final isConfiguredInBackend = providerStatus == null
                  ? true
                  : providerStatus[ApiKeys.configured] == true;

              // Provider is disabled if it's marked "comingSoon" OR not configured in backend
              final isDisabled = config.comingSoon || !isConfiguredInBackend;

              return Stack(
                children: [
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.icon,
                          size: 16,
                          color: isSelected
                              ? DesignTokens.white
                              : (isDisabled
                                    ? DesignTokens.textSecondary
                                    : config.primaryColor),
                        ),
                        const SizedBox(width: 6),
                        Text(config.name),
                        if (isDisabled) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.warning.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'seller.soon_badge'.tr(),
                              style: TextStyle(
                                fontSize: 9,
                                color: DesignTokens.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected && !isDisabled,
                    onSelected: isDisabled
                        ? null
                        : (selected) {
                            if (selected)
                              viewModel.setPaymentProvider(config.id);
                          },
                    selectedColor: config.primaryColor,
                    backgroundColor: isDisabled
                        ? DesignTokens.outlineVariant
                        : null,
                    labelStyle: TextStyle(
                      color: isSelected && !isDisabled
                          ? DesignTokens.white
                          : (isDisabled ? DesignTokens.textSecondary : null),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Dynamic payment timing info card based on selected provider
          _ProviderInfoCard(config: selectedConfig),
          const SizedBox(height: 8),
          Text(
            selectedConfig.recommendedFor,
            style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Detailed info card for the selected payment provider.
class _ProviderInfoCard extends ConsumerWidget {
  final PaymentProviderConfig config;

  const _ProviderInfoCard({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check backend configuration status
    final backendStatus = ref.watch(paymentProviderStatusProvider);
    final isConfiguredInBackend = backendStatus.when(
      data: (statusMap) {
        final providerStatus = statusMap[config.id];
        if (providerStatus == null) return true;
        return providerStatus[ApiKeys.configured] == true;
      },
      loading: () => true,
      error: (_, _) => true,
    );
    final isDisabled = config.comingSoon || !isConfiguredInBackend;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.primaryColor.withValues(alpha: 0.1),
            config.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, size: 18, color: config.primaryColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'seller.payout_timing'.tr(
                    namedArgs: {'timing': config.payoutTiming},
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: config.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            config.features.map((f) => '• $f').join('\n'),
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (isDisabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: DesignTokens.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: DesignTokens.warning),
                  const SizedBox(width: 4),
                  Text(
                    'seller.coming_soon'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: DesignTokens.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
