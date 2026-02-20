import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_button.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  State<SubscriptionSuccessScreen> createState() => _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [DesignTokens.darkBackground, DesignTokens.darkSurface]
                : [const Color(0xFFF0F2FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated premium badge
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [DesignTokens.primary, DesignTokens.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primary.withValues(alpha: _glowAnimation.value),
                              blurRadius: 32,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  'Welcome to Premium!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : DesignTokens.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your subscription is active. Enjoy all the benefits below.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DesignTokens.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                _BenefitRow(
                  icon: Icons.percent_rounded,
                  title: 'No Platform Fee',
                  subtitle: '0% platform fee on every purchase.',
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Chat with Sellers',
                  subtitle: 'Message sellers directly about products.',
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.question_answer_outlined,
                  title: 'Ask Questions',
                  subtitle: 'Post questions on any product Q&A board.',
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.photo_camera_outlined,
                  title: 'Photo Reviews',
                  subtitle: 'Add up to 3 photos to your product reviews.',
                  isDark: isDark,
                ),
                _BenefitRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Smart Notifications',
                  subtitle: 'Get notified on new products and trending items.',
                  isDark: isDark,
                ),

                const Spacer(),

                Semantics(
                  button: true,
                  label: 'btn-start-shopping',
                  child: ModernButton(
                    label: 'Start Shopping',
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (route) => false,
                    ),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignTokens.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded, color: DesignTokens.success, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
