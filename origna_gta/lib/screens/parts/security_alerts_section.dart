part of '../security_settings_screen.dart';

/// Security alerts card — shows unacknowledged security alerts with
/// "Was this you?" action buttons.
Widget _buildSecurityAlerts(
  List<Map<String, dynamic>> securityAlerts,
  bool isDark,
  void Function(String alertId) onAcknowledge,
) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
    ),
    color: DesignTokens.warning.withValues(alpha: 0.08),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: DesignTokens.warning,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'security.security_alerts'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(securityAlerts.length, (index) {
            final alert = securityAlerts[index];
            final alertType = alert['type'] as String? ?? '';
            final alertDetails = alert['details'] as String? ?? '';
            final alertId = alert['id'] as String? ?? '';
            return Container(
              margin: EdgeInsets.only(top: index > 0 ? 10 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkCard
                    : DesignTokens.warning.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: DesignTokens.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (alertDetails.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      alertDetails,
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'security.was_this_you'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: DesignTokens.warning,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        label: 'btn-alert-yes-$alertId',
                        child: FilledButton(
                          onPressed: () => onAcknowledge(alertId),
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignTokens.success,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radius12,
                              ),
                            ),
                          ),
                          child: Text('security.yes_it_was_me'.tr()),
                        ),
                      ),
                      Semantics(
                        label: 'btn-alert-no-$alertId',
                        child: OutlinedButton(
                          onPressed: () => onAcknowledge(alertId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DesignTokens.error,
                            side: BorderSide(color: DesignTokens.error),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radius12,
                              ),
                            ),
                          ),
                          child: Text('common.no'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}
