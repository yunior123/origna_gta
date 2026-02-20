import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class SubscriptionCancelScreen extends StatelessWidget {
  const SubscriptionCancelScreen({super.key});

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
                : [const Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Neutral icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.textDisabled.withValues(alpha: 0.1),
                    border: Border.all(
                      color: DesignTokens.outline,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: DesignTokens.textSecondary,
                    size: 44,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Checkout Cancelled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : DesignTokens.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'No charge was made. You can upgrade to Premium anytime to unlock all benefits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: DesignTokens.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Resubscribe
                Semantics(
                  button: true,
                  label: 'btn-resubscribe',
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.subscription),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text(
                        'Upgrade to Premium',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Back to home
                Semantics(
                  button: true,
                  label: 'btn-back-home',
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.home,
                        (route) => false,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
