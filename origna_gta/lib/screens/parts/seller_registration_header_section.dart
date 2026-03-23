part of '../seller_registration_screen.dart';

/// Hero header card for the seller registration page.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.95),
            DesignTokens.secondary.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DesignTokens.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.store, size: 50, color: DesignTokens.white),
          ),
          const SizedBox(height: 20),
          Text(
            'seller.sell_on_origna'.tr(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DesignTokens.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'seller.reach_customers'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Why sell with us" benefits card.
class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? DesignTokens.textPrimary.withValues(alpha: 0.6)
                : DesignTokens.white.withValues(alpha: 0.8),
            isDark
                ? DesignTokens.textPrimary.withValues(alpha: 0.4)
                : DesignTokens.surface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [DesignTokens.primary, DesignTokens.secondary],
            ).createShader(bounds),
            child: Text(
              'seller.why_sell_with_us'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DesignTokens.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _BenefitItem(
            icon: Icons.people,
            text: 'seller.access_customers'.tr(),
          ),
          const SizedBox(height: 12),
          _BenefitItem(
            icon: Icons.credit_card,
            text: 'seller.secure_processing'.tr(),
          ),
          const SizedBox(height: 12),
          _BenefitItem(icon: Icons.speed, text: 'seller.fast_payouts'.tr()),
          const SizedBox(height: 12),
          _BenefitItem(icon: Icons.analytics, text: 'seller.track_sales'.tr()),
        ],
      ),
    );
  }
}

/// Single benefit row with icon and text.
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.primary.withValues(alpha: 0.2),
                DesignTokens.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(icon, color: DesignTokens.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
