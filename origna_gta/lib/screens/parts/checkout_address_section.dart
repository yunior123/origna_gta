// coverage:ignore-file
part of '../checkout_screen.dart';
class _AddressSection extends StatelessWidget {
  final Address address;
  final VoidCallback onRefreshShipping;

  const _AddressSection({required this.address, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const Key('checkout_address_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [DesignTokens.primary, DesignTokens.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'checkout.delivery_address_title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DesignTokens.white),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'btn-edit-address',
              child: Material(
                color: DesignTokens.transparent,
                child: InkWell(
                  key: const Key('checkout_edit_address_button'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.addressManagement).then((_) => onRefreshShipping());
                  },
                  borderRadius: BorderRadius.circular(8),
                  splashColor: DesignTokens.primary.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text(
                          'checkout.edit_action'.tr(),
                          style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.2), DesignTokens.secondary.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    address.label!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(address.formattedAddress, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? DesignTokens.outline : DesignTokens.textPrimary)),
              if (address.phoneNumber != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: DesignTokens.primary),
                    const SizedBox(width: 10),
                    Text(address.phoneNumber!, style: TextStyle(color: isDark ? DesignTokens.outline : DesignTokens.textPrimary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NoAddressView extends StatelessWidget {
  final VoidCallback onRefreshShipping;

  const _NoAddressView({required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: DesignTokens.textDisabled),
            const SizedBox(height: 24),
            Text('checkout.no_address_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'checkout.no_address_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              child: ModernButton(
                semanticsLabel: 'btn-add-address',
                label: 'checkout.add_address'.tr(),
                icon: Icons.add_location,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addressManagement).then((_) => onRefreshShipping());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
