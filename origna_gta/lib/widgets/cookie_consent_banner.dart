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
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.darkBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'cookie.consent'.tr(),
                style: const TextStyle(color: DesignTokens.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _decline,
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.white.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    child: Text('cookie.decline'.tr()),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _accept,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: DesignTokens.white,
                    ),
                    child: Text('cookie.accept'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
