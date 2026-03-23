part of '../security_settings_screen.dart';

/// Known devices card — shows trusted devices with option to remove them.
Widget _buildKnownDevicesCard(
  List<Map<String, dynamic>> knownDevices,
  bool isLoadingSecurity,
  bool isDark,
  void Function(String deviceId) onRemoveDevice,
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
                Icons.devices_rounded,
                color: DesignTokens.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'security.known_devices'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (knownDevices.isEmpty && !isLoadingSecurity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'security.no_devices'.tr(),
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Semantics(
              label: 'known-devices-list',
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: knownDevices.length,
                separatorBuilder: (_, _) => Divider(
                  color: DesignTokens.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final device = knownDevices[index];
                  final deviceName = device['device_name'] as String? ?? '';
                  final lastUsed = device['last_used'] as String? ?? '';
                  final deviceId = device['id'] as String? ?? '';

                  String formattedDate = lastUsed;
                  try {
                    formattedDate = DateFormat(
                      'MMM d, yyyy HH:mm',
                    ).format(DateTime.parse(lastUsed));
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smartphone_rounded,
                          color: DesignTokens.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
                        Semantics(
                          label: 'btn-remove-device-$deviceId',
                          child: IconButton(
                            onPressed: () => onRemoveDevice(deviceId),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: DesignTokens.error,
                              size: 20,
                            ),
                            tooltip: 'security.remove_device'.tr(),
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

/// Error banner — displays an error message with icon.
Widget _buildErrorBanner(String message) {
  return Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DesignTokens.error.withValues(alpha: 0.08),
      border: Border.all(color: DesignTokens.error.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: DesignTokens.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: TextStyle(color: DesignTokens.error)),
        ),
      ],
    ),
  );
}
