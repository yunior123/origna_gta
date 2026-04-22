import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  static const _prefsKey = 'cookie_consent_accepted';

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> resetConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(CookieConsentBanner._prefsKey);
    if (mounted) {
      setState(() {
        _visible = accepted != true;
      });
    }
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(CookieConsentBanner._prefsKey, true);
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _decline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(CookieConsentBanner._prefsKey, false);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Semantics(
      label: 'cookie.consent'.tr(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.darkBackground.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DesignTokens.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'cookie.consent'.tr(),
                    style: const TextStyle(
                      color: DesignTokens.textOnDark,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _decline,
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.textOnDarkSecondary,
                          minimumSize: const Size(88, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text('cookie.decline'.tr()),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _accept,
                        style: FilledButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: DesignTokens.white,
                          minimumSize: const Size(104, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text('cookie.accept'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
