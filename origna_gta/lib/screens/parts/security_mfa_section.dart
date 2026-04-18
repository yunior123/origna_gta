part of '../security_settings_screen.dart';

/// MFA status card — shows current MFA state and enable/disable button.
Widget _buildMfaStatusCard(
  MfaState mfaState,
  bool isDark,
  VoidCallback onEnable,
  VoidCallback onDisable,
) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
    ),
    color: isDark ? DesignTokens.darkCard : null,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: DesignTokens.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'security.title'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'security.subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: mfaState.mfaEnabled
                      ? DesignTokens.success.withValues(alpha: 0.12)
                      : DesignTokens.outlineVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mfaState.mfaEnabled
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: mfaState.mfaEnabled
                          ? DesignTokens.success
                          : DesignTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        mfaState.mfaEnabled
                            ? 'security.mfa_enabled'.tr()
                            : 'security.mfa_disabled'.tr(),
                        style: TextStyle(
                          color: mfaState.mfaEnabled
                              ? DesignTokens.success
                              : DesignTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'security.description'.tr(),
            style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (!mfaState.mfaEnabled)
            Semantics(
              label: 'btn-enable-mfa',
              child: FilledButton.icon(
                onPressed: mfaState.isLoading ? null : onEnable,
                icon: const Icon(Icons.security_rounded),
                label: Text('security.enable_mfa'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                ),
              ),
            )
          else
            Semantics(
              label: 'btn-disable-mfa',
              child: FilledButton.icon(
                onPressed: mfaState.isLoading ? null : onDisable,
                icon: const Icon(Icons.close_rounded),
                label: Text('security.disable_mfa'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.error,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
