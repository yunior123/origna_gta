part of '../security_settings_screen.dart';

/// Login history card — shows recent login attempts with IP, device, and
/// success/failure status.
Widget _buildLoginHistoryCard(
  List<Map<String, dynamic>> loginHistory,
  bool isLoadingSecurity,
  bool isDark,
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
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: DesignTokens.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'security.login_history'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loginHistory.isEmpty && !isLoadingSecurity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'security.no_login_history'.tr(),
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Semantics(
              label: 'login-history-list',
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loginHistory.length,
                separatorBuilder: (_, _) => Divider(
                  color: DesignTokens.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final entry = loginHistory[index];
                  final ip = entry['ip'] as String? ?? '';
                  final device = entry['device'] as String? ?? '';
                  final status = entry['status'] as String? ?? '';
                  final date = entry['date'] as String? ?? '';
                  final isSuccess = status == 'success';

                  String formattedDate = date;
                  try {
                    formattedDate = DateFormat(
                      'MMM d, yyyy HH:mm',
                    ).format(DateTime.parse(date));
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (device.isNotEmpty)
                                Text(
                                  device,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                '${'security.ip_address'.tr()}: $ip',
                                style: TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? DesignTokens.success.withValues(alpha: 0.12)
                                : DesignTokens.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSuccess
                                  ? DesignTokens.success
                                  : DesignTokens.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
