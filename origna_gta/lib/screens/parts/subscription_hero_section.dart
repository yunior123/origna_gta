part of '../subscription_screen.dart';

/// Hero banner with gradient background, glow ring, mascot, and premium badge.
class _SubscriptionHeroSection extends StatelessWidget {
  final bool isPremium;

  const _SubscriptionHeroSection({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.gradientStart,
            DesignTokens.gradientMiddle,
            DesignTokens.gradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.accent.withValues(alpha: 0.18),
                    DesignTokens.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.tertiary.withValues(alpha: 0.15),
                    DesignTokens.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
            child: Column(
              children: [
                // Mascot + Glow ring row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Mascot cheering on the left
                    _PremiumMascot(isPremium: isPremium),
                    const SizedBox(width: 16),
                    // Glow ring + icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [DesignTokens.warning, DesignTokens.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.warning.withValues(alpha: 0.5),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: DesignTokens.warning.withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: DesignTokens.white,
                        size: 50,
                      ),
                    ),
                  ], // Row children
                ), // Row
                const SizedBox(height: 20),
                // "PREMIUM" chip badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DesignTokens.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u2728', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        isPremium
                            ? 'subscription.badge_premium_member'.tr()
                            : 'subscription.badge_unlock_premium'.tr(),
                        style: const TextStyle(
                          color: DesignTokens.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: isPremium
                      ? 'lbl-premium-member'
                      : 'lbl-upgrade-to-premium',
                  container: true,
                  excludeSemantics: true,
                  child: Text(
                    isPremium
                        ? 'subscription.youre_premium_member'.tr()
                        : 'subscription.upgrade_to_premium'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: isPremium ? 'lbl-enjoy-benefits' : 'lbl-price-monthly',
                  container: true,
                  excludeSemantics: true,
                  child: Text(
                    isPremium
                        ? 'subscription.enjoy_benefits'.tr()
                        : 'subscription.price_monthly'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: DesignTokens.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mascot that celebrates premium — lives in the subscription hero
class _PremiumMascot extends StatefulWidget {
  final bool isPremium;
  const _PremiumMascot({required this.isPremium});

  @override
  State<_PremiumMascot> createState() => _PremiumMascotState();
}

class _PremiumMascotState extends State<_PremiumMascot> {
  late final MascotController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MascotController();
    _controller.setExcitement(widget.isPremium ? 1.0 : 0.6);
    if (widget.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jump();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShopMascot(
      controller: _controller,
      size: 72,
      showSpeechBubble: false,
    );
  }
}
