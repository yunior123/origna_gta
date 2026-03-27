part of '../checkout_screen.dart';

class _TermsText extends ConsumerWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final termsAccepted = ref.watch(checkoutTermsAcceptedProvider);
    final hasInteracted = ref.watch(checkoutTermsInteractedProvider);
    final showError = hasInteracted && !termsAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          key: const Key('checkout_terms_link'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-terms-accepted',
                checked: termsAccepted,
                child: Checkbox(
                  key: const Key('checkout_terms_checkbox'),
                  value: termsAccepted,
                  onChanged: (value) {
                    ref.read(checkoutTermsInteractedProvider.notifier).state =
                        true;
                    ref.read(checkoutTermsAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'checkout.terms_agree'.tr()),
                    WidgetSpan(
                      child: Semantics(
                        link: true,
                        label: 'link-terms-conditions',
                        child: GestureDetector(
                          onTap: () => openTermsOfService(context),
                          child: Text(
                            'checkout.terms_link'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: DesignTokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: ' ${'checkout.and_label'.tr()} '),
                    WidgetSpan(
                      child: Semantics(
                        link: true,
                        label: 'link-privacy-policy',
                        child: GestureDetector(
                          onTap: () => openPrivacyPolicy(context),
                          child: Text(
                            'checkout.privacy_link'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: DesignTokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EULA checkbox shown when digital products (software, ebooks, etc.) are in the cart.
/// Canadian consumer law requires explicit license acceptance before digital delivery.
class _DigitalEulaText extends ConsumerWidget {
  const _DigitalEulaText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eulaAccepted = ref.watch(checkoutEulaAcceptedProvider);
    final hasInteracted = ref.watch(checkoutEulaInteractedProvider);
    final showError = hasInteracted && !eulaAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          key: const Key('checkout_digital_eula'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-eula-accepted',
                checked: eulaAccepted,
                child: Checkbox(
                  key: const Key('checkout_eula_checkbox'),
                  value: eulaAccepted,
                  onChanged: (value) {
                    ref.read(checkoutEulaInteractedProvider.notifier).state =
                        true;
                    ref.read(checkoutEulaAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'checkout.digital_eula_agree'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? DesignTokens.textOnDark
                      : DesignTokens.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Age gate widget — shown when cart contains age-restricted items.
/// Canadian law (CRTC / provincial liquor/tobacco acts) requires age confirmation before purchase.
class _AgeGateText extends ConsumerWidget {
  const _AgeGateText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageVerifAccepted = ref.watch(checkoutAgeVerifAcceptedProvider);
    final hasInteracted = ref.watch(checkoutAgeVerifInteractedProvider);
    final showError = hasInteracted && !ageVerifAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          key: const Key('checkout_age_gate'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-age-gate-accepted',
                checked: ageVerifAccepted,
                child: Checkbox(
                  key: const Key('checkout_age_gate_checkbox'),
                  value: ageVerifAccepted,
                  onChanged: (value) {
                    ref
                            .read(checkoutAgeVerifInteractedProvider.notifier)
                            .state =
                        true;
                    ref.read(checkoutAgeVerifAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'checkout.age_gate_agree'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? DesignTokens.textOnDark
                      : DesignTokens.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// @Preview skipped — requires live auth/navigation context
// CheckoutScreen requires List<CartItemDetailModel> which depends on live database/Timestamp.
