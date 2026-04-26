import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'browser_env_stub.dart'
    if (dart.library.js_interop) 'browser_env_web.dart' as browser_env;

import 'theme_config.dart';
import 'tiers_config.dart' show TierDefinition, TierId;

const _supportEmail = 'support@orignaventures.ca';
const _supportPhone = '4167865517';
const _whatsAppPhoneIntl = '14167865517';
const venturesApiBase = 'https://api.orignaventures.ca/api';
const _fullDeckPdfUrl =
    'https://orignaventures.ca/docs/origna_ventures_full_presentation.pdf';
const _demoUrl = 'https://dev.orignagta.ca';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrignaVenturesApp());
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

class OrignaVenturesApp extends StatefulWidget {
  const OrignaVenturesApp({super.key});

  @override
  State<OrignaVenturesApp> createState() => _OrignaVenturesAppState();
}

class _OrignaVenturesAppState extends State<OrignaVenturesApp> {
  LocaleMode locale = LocaleMode.en;

  @override
  void initState() {
    super.initState();
    _initLocale();
  }

  void _initLocale() {
    if (!kIsWeb) return;
    try {
      final stored = browser_env.getStoredLocale();
      if (stored != null) {
        final mode = LocaleMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => LocaleMode.en,
        );
        if (mode != locale) {
          setState(() => locale = mode);
        }
        return;
      }
      _detectBrowserLocale();
    } catch (e) {
      debugPrint(
          'OrignaVentures: stored locale read failed, detecting from browser: $e');
      _detectBrowserLocale();
    }
  }

  void _detectBrowserLocale() {
    if (!kIsWeb) return;
    try {
      final rawLanguage = browser_env.getBrowserLanguage();
      if (rawLanguage == null) return;
      final lang = rawLanguage.toLowerCase();
      if (lang.isEmpty) return;
      final detected = lang.startsWith('fr')
          ? LocaleMode.fr
          : lang.startsWith('es')
              ? LocaleMode.es
              : LocaleMode.en;
      if (detected != locale) {
        setState(() => locale = detected);
      }
    } catch (e) {
      debugPrint('OrignaVentures: browser locale detection failed: $e');
    }
  }

  void _setLocale(LocaleMode value) {
    setState(() => locale = value);
    if (!kIsWeb) return;
    try {
      browser_env.setStoredLocale(value.name);
    } catch (e) {
      debugPrint('OrignaVentures: locale storage write failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Origna Ventures',
      home: _SinglePage(locale: locale, onLocaleChanged: _setLocale),
      theme: ThemeConfig.lightTheme(),
      darkTheme: ThemeConfig.darkTheme(),
    );
  }
}

enum LocaleMode { en, fr, es }

extension LocaleModeTr on LocaleMode {
  String tr(String en, String fr, [String? es]) =>
      this == LocaleMode.fr ? fr : (this == LocaleMode.es ? (es ?? en) : en);
}

class _SinglePage extends StatefulWidget {
  final LocaleMode locale;
  final ValueChanged<LocaleMode> onLocaleChanged;

  const _SinglePage({required this.locale, required this.onLocaleChanged});

  @override
  State<_SinglePage> createState() => _SinglePageState();
}

class _SinglePageState extends State<_SinglePage> {
  final _scrollCtrl = ScrollController();
  final _listKey = GlobalKey();
  final _contactKey = GlobalKey();
  final _pricingKey = GlobalKey();
  bool _showCookieBanner = false;

  @override
  void initState() {
    super.initState();
    _loadCookieConsent();
  }

  void _loadCookieConsent() {
    if (!kIsWeb) return;
    try {
      final consent = browser_env.getCookieConsentAccepted();
      setState(() => _showCookieBanner = consent == null);
    } catch (e) {
      debugPrint(
          'OrignaVentures: cookie consent read failed, showing banner: $e');
      setState(() => _showCookieBanner = true);
    }
  }

  void _setCookieConsent(bool accepted) {
    if (kIsWeb) {
      try {
        browser_env.setCookieConsentAccepted(accepted);
      } catch (e) {
        debugPrint('OrignaVentures: cookie consent write failed: $e');
      }
    }
    setState(() => _showCookieBanner = false);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  int _scrollRetryCount = 0;
  static const _maxScrollRetries = 10;

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    final listContext = _listKey.currentContext;
    if (targetContext == null ||
        listContext == null ||
        !_scrollCtrl.hasClients) {
      if (_scrollRetryCount < _maxScrollRetries) {
        _scrollRetryCount++;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(key));
      }
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final listBox = listContext.findRenderObject() as RenderBox?;
    if (targetBox == null || listBox == null) return;

    _scrollRetryCount = 0;
    final targetOffset =
        targetBox.localToGlobal(Offset.zero, ancestor: listBox).dy +
            _scrollCtrl.offset;

    _scrollCtrl.animateTo(
      math.max(0, targetOffset - 20),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsAppPhoneIntl');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return Scaffold(
      backgroundColor: ThemeConfig.surface,
      floatingActionButton: isMobile
          ? _WhatsAppFloatingButton(
              locale: locale,
              onTap: _launchWhatsApp,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _showCookieBanner
          ? _CookieConsentBanner(
              locale: locale,
              onAccept: () => _setCookieConsent(true),
              onDecline: () => _setCookieConsent(false),
            )
          : null,
      body: ListView(
        key: _listKey,
        controller: _scrollCtrl,
        cacheExtent: 3000,
        padding: EdgeInsets.zero,
        children: [
          _Header(
            locale: locale,
            onLocaleChanged: widget.onLocaleChanged,
            onPricingTap: () => _scrollTo(_pricingKey),
          ),
          _HeroSection(
            locale: locale,
            isMobile: isMobile,
            onGetStarted: () => _scrollTo(_pricingKey),
          ),
          _PricingSection(
            key: _pricingKey,
            locale: locale,
            isMobile: isMobile,
          ),
          _PartnerSection(locale: locale, isMobile: isMobile),
          _WhySection(locale: locale, isMobile: isMobile),
          _ContactFormBlock(
            key: _contactKey,
            locale: locale,
            isMobile: isMobile,
          ),
          _Footer(locale: locale),
        ],
      ),
    );
  }
}

class _WhatsAppFloatingButton extends StatelessWidget {
  final LocaleMode locale;
  final Future<void> Function() onTap;

  const _WhatsAppFloatingButton({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: locale.tr(
        'Open WhatsApp chat with Origna Ventures',
        'Ouvrir la discussion WhatsApp avec Origna Ventures',
        'Abrir chat de WhatsApp con Origna Ventures',
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.success.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        locale.tr('Chat with us', 'Parlez-nous',
                            'Chatea con nosotros'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

class _Header extends StatelessWidget {
  final LocaleMode locale;
  final ValueChanged<LocaleMode> onLocaleChanged;
  final VoidCallback onPricingTap;

  const _Header({
    required this.locale,
    required this.onLocaleChanged,
    required this.onPricingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      decoration: const BoxDecoration(
        color: ThemeConfig.darkBackground,
        border: Border(
          bottom: BorderSide(color: ThemeConfig.darkBorder),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
        vertical: 12,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const _LogoBadge(),
            const SizedBox(width: 10),
            Text(
              'Origna Ventures',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 15 : 18,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(
                label: locale.tr('Pricing', 'Tarifs', 'Precios'),
                onTap: onPricingTap,
                semanticsLabel: 'btn-nav-pricing',
              ),
              const SizedBox(width: 16),
            ],
            _LocaleToggle(locale: locale, onChanged: onLocaleChanged),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? semanticsLabel;

  const _NavLink({
    required this.label,
    required this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: ThemeConfig.brandGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

class _LocaleToggle extends StatelessWidget {
  final LocaleMode locale;
  final ValueChanged<LocaleMode> onChanged;

  const _LocaleToggle({required this.locale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ToggleButtons(
        isSelected: LocaleMode.values.map((m) => m == locale).toList(),
        onPressed: (i) => onChanged(LocaleMode.values[i]),
        constraints: BoxConstraints(
          minHeight: isMobile ? 30 : 32,
          minWidth: isMobile ? 30 : 36,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.45),
        selectedColor: Colors.white,
        fillColor: ThemeConfig.primary,
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        children: [
          Semantics(
            button: true,
            label: 'btn-locale-en',
            child: Text(
              'EN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-locale-fr',
            child: Text(
              'FR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-locale-es',
            child: Text(
              'ES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;
  final VoidCallback onGetStarted;

  const _HeroSection({
    required this.locale,
    required this.isMobile,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.heroGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _GridPattern()),
          Positioned(
            top: -80,
            right: isMobile ? -60 : 60,
            child: _GlowOrb(
              color: ThemeConfig.primary.withValues(alpha: 0.25),
              size: isMobile ? 200 : 340,
            ),
          ),
          Positioned(
            bottom: -40,
            left: isMobile ? -40 : 80,
            child: _GlowOrb(
              color: ThemeConfig.secondary.withValues(alpha: 0.18),
              size: isMobile ? 160 : 260,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: isMobile ? 40 : 80,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 860 : 1180),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroContent(
                              locale: locale,
                              isMobile: true,
                              onGetStarted: onGetStarted),
                          const SizedBox(height: 20),
                          _HeroProofPanel(locale: locale, isMobile: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 11,
                            child: _HeroContent(
                              locale: locale,
                              isMobile: false,
                              onGetStarted: onGetStarted,
                            ),
                          ),
                          const SizedBox(width: 36),
                          Expanded(
                            flex: 9,
                            child: _HeroProofPanel(
                                locale: locale, isMobile: false),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;
  final VoidCallback onGetStarted;

  const _HeroContent({
    required this.locale,
    required this.isMobile,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeConfig.primary.withValues(alpha: 0.25),
                ThemeConfig.secondary.withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ThemeConfig.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  color: ThemeConfig.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                locale.tr(
                  'Toronto, Canada · Fast launch partner',
                  'Toronto, Canada · Partenaire de lancement rapide',
                  'Toronto, Canada · Socio de lanzamiento rapido',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 20 : 28),
        Text(
          locale.tr(
            'Software Services\n& Ecommerce',
            'Services Logiciels\n& Commerce Electronique',
            'Servicios de Software\n& Comercio Electronico',
          ),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 32 : 56,
            height: 1.06,
            letterSpacing: -1.8,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),
        GradientText(
          'Flutter · Rust · Stripe · PostgreSQL',
          gradient: ThemeConfig.brandGradient,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isMobile ? 16 : 22,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isMobile ? 14 : 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Text(
            locale.tr(
              'Source code, full-stack launch packages, and dedicated developer subscriptions. Built for speed, deployed with confidence.',
              'Code source, forfaits de lancement complets et abonnements developpeur dedie. Concu pour la vitesse, deploye en toute confiance.',
              'Codigo fuente, paquetes de lanzamiento completos y suscripciones de desarrollador dedicado. Construido para la velocidad, desplegado con confianza.',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: isMobile ? 14 : 17,
              height: 1.6,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 36),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _HeroCTA(
              label: locale.tr('View plans', 'Voir les forfaits', 'Ver planes'),
              onTap: onGetStarted,
              filled: true,
              semanticsLabel: 'btn-hero-view-plans',
            ),
            _HeroCTA(
              label: locale.tr('Live demo', 'Demo live', 'Demo en vivo'),
              onTap: () => launchUrl(Uri.parse(_demoUrl)),
              filled: false,
              semanticsLabel: 'btn-hero-live-demo',
            ),
          ],
        ),
        SizedBox(height: isMobile ? 22 : 48),
        Wrap(
          spacing: isMobile ? 12 : 16,
          runSpacing: 12,
          children: [
            _HeroStat(value: '1-2', unit: locale.tr('wks', 'sem', 'sem')),
            _HeroStat(
              value: '4',
              unit: locale.tr('platforms', 'plateformes', 'plataformas'),
            ),
            _HeroStat(
              value: '20+',
              unit: locale.tr('QA testers', 'testeurs QA', 'evaluadores QA'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroProofPanel extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;

  const _HeroProofPanel({required this.locale, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final chips = [
      locale.tr('Web', 'Web', 'Web'),
      locale.tr('iOS', 'iOS', 'iOS'),
      locale.tr('Android', 'Android', 'Android'),
      locale.tr('Desktop', 'Bureau', 'Escritorio'),
      'Stripe',
      'Hetzner',
    ];
    final deliverables = [
      locale.tr(
        'Production-ready source code handoff',
        'Remise du code source pret pour la production',
        'Entrega de codigo fuente listo para produccion',
      ),
      locale.tr(
        'Checkout, hosting, QA, and launch support included',
        'Paiement, hebergement, QA et support de lancement inclus',
        'Checkout, hosting, QA y soporte de lanzamiento incluidos',
      ),
      locale.tr(
        'Direct access to the builder, not an agency maze',
        'Acces direct au createur, sans labyrinthe dagence',
        'Acceso directo al creador, sin laberinto de agencia',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          blur: 20,
          padding: EdgeInsets.all(isMobile ? 18 : 22),
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF141437),
          opacity: 0.78,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: ThemeConfig.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.tr(
                            'Premium launch delivery',
                            'Livraison premium prete au lancement',
                            'Entrega premium lista para lanzamiento',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locale.tr(
                            'Built to look expensive, ship cleanly, and convert faster.',
                            'Concu pour paraitre premium, etre livre proprement et convertir plus vite.',
                            'Disenado para verse premium, entregarse limpio y convertir mas rapido.',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in chips) _HeroTechChip(label: chip),
                ],
              ),
              const SizedBox(height: 20),
              for (final item in deliverables)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ThemeConfig.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: ThemeConfig.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: ThemeConfig.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _HeroMetricBlock(
                        label: locale.tr(
                            'Typical start', 'Debut typique', 'Inicio tipico'),
                        value: locale.tr('48 h', '48 h', '48 h'),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _HeroMetricBlock(
                        label: locale.tr(
                            'Launch target', 'Cible live', 'Objetivo live'),
                        value: locale.tr(
                            '1-2 weeks', '1-2 semaines', '1-2 semanas'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 14 : 18),
        Row(
          children: [
            Expanded(
              child: _HeroMiniCard(
                eyebrow:
                    locale.tr('MOST CHOSEN', 'LE PLUS CHOISI', 'MAS ELEGIDO'),
                title: 'OrignaLaunch',
                detail: locale.tr(
                  'Code, hosting, store setup, and QA included',
                  'Code, hebergement, mise en place boutique et QA inclus',
                  'Codigo, hosting, tienda configurada y QA incluidos',
                ),
                accent: ThemeConfig.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HeroMiniCard(
                eyebrow: locale.tr('MONTHLY', 'MENSUEL', 'MENSUAL'),
                title: 'OrignaTeam',
                detail: locale.tr(
                  'Dedicated product + engineering subscription',
                  'Abonnement produit + ingenierie dedie',
                  'Suscripcion dedicada de producto + ingenieria',
                ),
                accent: ThemeConfig.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCTA extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final String semanticsLabel;

  const _HeroCTA({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: ThemeConfig.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          child: Text(label),
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.85),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        child: Text(label),
      ),
    );
  }
}

class _HeroTechChip extends StatelessWidget {
  final String label;

  const _HeroTechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String unit;

  const _HeroStat({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetricBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String detail;
  final Color accent;

  const _HeroMiniCard({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlinePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlinePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ThemeConfig.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ThemeConfig.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ThemeConfig.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;

  const _PricingSection({
    super.key,
    required this.locale,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      color: ThemeConfig.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 32 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SectionLabel(label: locale.tr('PRICING', 'TARIFS', 'PRECIOS')),
              const SizedBox(height: 12),
              Text(
                locale.tr(
                  'Choose the operating model',
                  'Choisissez le modele operatoire',
                  'Elija el modelo operativo',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 26 : 38,
                  letterSpacing: -1,
                  color: ThemeConfig.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                locale.tr(
                  'Secure Stripe checkout · Policy-first delivery · Canadian company',
                  'Paiement Stripe securise · Livraison orientee politiques · Entreprise canadienne',
                  'Pago Stripe seguro · Entrega orientada por politicas · Empresa canadiense',
                ),
                style: const TextStyle(
                  color: ThemeConfig.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InlinePill(
                    icon: Icons.bolt_rounded,
                    label: locale.tr(
                        '1-2 week launch',
                        'Lancement en 1-2 semaines',
                        'Lanzamiento en 1-2 semanas'),
                  ),
                  _InlinePill(
                    icon: Icons.workspace_premium_rounded,
                    label: locale.tr(
                      'Source ownership',
                      'Propriete du code',
                      'Propiedad del codigo',
                    ),
                  ),
                  _InlinePill(
                    icon: Icons.verified_user_rounded,
                    label: locale.tr(
                      'Canadian invoicing',
                      'Facturation canadienne',
                      'Facturacion canadiense',
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 40),
              if (isMobile)
                Column(
                  children: TierDefinition.tiers
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TierCard(
                            tier: t,
                            locale: locale,
                            isMobile: true,
                            width: screenWidth - 32,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < TierDefinition.tiers.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(
                          child: _TierCard(
                            tier: TierDefinition.tiers[i],
                            locale: locale,
                            isMobile: false,
                            width: null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatefulWidget {
  final TierDefinition tier;
  final LocaleMode locale;
  final bool isMobile;
  final double? width;

  const _TierCard({
    required this.tier,
    required this.locale,
    required this.isMobile,
    required this.width,
  });

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _status;
  bool _success = false;
  int _teamDeveloperCount = 1;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  List<String> _bullets() {
    final loc = widget.locale;
    return loc == LocaleMode.fr
        ? widget.tier.bullets.fr
        : (loc == LocaleMode.es
            ? widget.tier.bullets.es
            : widget.tier.bullets.en);
  }

  String _label() {
    final loc = widget.locale;
    return loc == LocaleMode.fr
        ? widget.tier.tierLabel.fr
        : (loc == LocaleMode.es
            ? widget.tier.tierLabel.es
            : widget.tier.tierLabel.en);
  }

  String _tagline() {
    final loc = widget.locale;
    return loc == LocaleMode.fr
        ? widget.tier.tagline.fr
        : (loc == LocaleMode.es
            ? widget.tier.tagline.es
            : widget.tier.tagline.en);
  }

  String _formatPrice(int priceCents) {
    final dollars = priceCents ~/ 100;
    return dollars >= 1000
        ? '${dollars ~/ 1000},${(dollars % 1000).toString().padLeft(3, '0')}'
        : dollars.toString();
  }

  String _teamDeveloperLabel(LocaleMode loc) {
    if (_teamDeveloperCount == 1) {
      return loc.tr('1 developer', '1 developpeur', '1 desarrollador');
    }
    return loc.tr(
      '$_teamDeveloperCount developers',
      '$_teamDeveloperCount developpeurs',
      '$_teamDeveloperCount desarrolladores',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    final loc = widget.locale;
    final isPopular = t.isPopular;
    final displayedPriceCents = t.tierId == TierId.orignaTeam
        ? t.priceCents * _teamDeveloperCount
        : t.priceCents;
    final priceSuffix = t.isSubscription
        ? loc.tr('CAD / month', 'CAD / mois', 'CAD / mes')
        : loc.tr('CAD one-time', 'CAD paiement unique', 'CAD pago unico');
    final ctaLabel = t.tierId == TierId.orignaCode
        ? loc.tr('Buy source code', 'Acheter le code source',
            'Comprar codigo fuente')
        : t.tierId == TierId.orignaLaunch
            ? loc.tr('Launch my app', 'Lancer mon application', 'Lanzar mi app')
            : loc.tr(
                'Book the team', 'Reserver l\'equipe', 'Reservar el equipo');
    final buyButtonSemanticsLabel = 'btn-tier-buy-${t.serviceCode}';
    final deckButtonSemanticsLabel = 'btn-tier-deck-${t.serviceCode}';

    final card = AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final value = _glowController.value;
        final glowOffsetA = Offset(
          lerpDouble(-36, 34, value)!,
          lerpDouble(-24, 22, (value * 0.85) % 1)!,
        );
        final glowOffsetB = Offset(
          lerpDouble(28, -30, (value * 0.9) % 1)!,
          lerpDouble(30, -26, (value * 1.1) % 1)!,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Stack(
                    children: [
                      _FloatingGlassGlow(
                        offset: glowOffsetA,
                        size: isPopular ? 156 : 128,
                        color:
                            t.color.withValues(alpha: isPopular ? 0.22 : 0.14),
                      ),
                      _FloatingGlassGlow(
                        offset: glowOffsetB,
                        size: isPopular ? 132 : 116,
                        color: ThemeConfig.gold.withValues(
                          alpha: isPopular ? 0.14 : 0.08,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: widget.width,
              decoration: BoxDecoration(
                color: isPopular
                    ? const Color(0xFF0F0F2E)
                    : ThemeConfig.surfaceElevated.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPopular
                      ? t.color.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.52),
                  width: isPopular ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.color.withValues(alpha: isPopular ? 0.22 : 0.08),
                    blurRadius: isPopular ? 40 : 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isPopular ? 0.12 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Padding(
                    padding: EdgeInsets.all(widget.isMobile ? 20 : 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                                label: _label(),
                                color: t.color,
                                bright: isPopular),
                            if (isPopular) ...[
                              _Chip(
                                label: loc.tr(
                                  'MOST SELECTED',
                                  'LE PLUS CHOISI',
                                  'EL MAS ELEGIDO',
                                ),
                                color: t.color,
                                filled: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                            color: isPopular
                                ? Colors.white
                                : ThemeConfig.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tagline(),
                          style: TextStyle(
                            color: isPopular
                                ? Colors.white.withValues(alpha: 0.6)
                                : ThemeConfig.textSecondary,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              '\$${_formatPrice(displayedPriceCents)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 38,
                                letterSpacing: -2,
                                color: isPopular ? Colors.white : t.color,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                priceSuffix,
                                style: TextStyle(
                                  color: isPopular
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : ThemeConfig.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (t.tierId == TierId.orignaTeam) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.tr(
                                          'Team size',
                                          'Taille de l\'equipe',
                                          'Tamano del equipo',
                                        ),
                                        style: TextStyle(
                                          color: isPopular
                                              ? Colors.white
                                                  .withValues(alpha: 0.7)
                                              : ThemeConfig.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_teamDeveloperLabel(loc)} · ${loc.tr("server-priced at 1,000 CAD each", "tarification serveur a 1 000 CAD chacun", "precio del servidor a 1,000 CAD cada uno")}',
                                        style: TextStyle(
                                          color: isPopular
                                              ? Colors.white
                                                  .withValues(alpha: 0.55)
                                              : ThemeConfig.textMuted,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: loc.tr(
                                    'Decrease team size',
                                    'Reduire la taille de l\'equipe',
                                    'Reducir tamano del equipo',
                                  ),
                                  onPressed: _teamDeveloperCount > 1
                                      ? () =>
                                          setState(() => _teamDeveloperCount--)
                                      : null,
                                  icon: const Icon(Icons.remove_rounded),
                                ),
                                Text(
                                  '$_teamDeveloperCount',
                                  style: TextStyle(
                                    color: isPopular
                                        ? Colors.white
                                        : ThemeConfig.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  tooltip: loc.tr(
                                    'Increase team size',
                                    'Augmenter la taille de l\'equipe',
                                    'Aumentar tamano del equipo',
                                  ),
                                  onPressed: _teamDeveloperCount < 20
                                      ? () =>
                                          setState(() => _teamDeveloperCount++)
                                      : null,
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Divider(
                          color: isPopular
                              ? Colors.white.withValues(alpha: 0.1)
                              : ThemeConfig.divider,
                          height: 1,
                        ),
                        const SizedBox(height: 16),
                        for (final b in _bullets())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: t.color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: t.color,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isPopular
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : ThemeConfig.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Semantics(
                            button: true,
                            label: buyButtonSemanticsLabel,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: t.color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: _loading ? null : _handleBuy,
                              child: _loading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    )
                                  : Text(ctaLabel),
                            ),
                          ),
                        ),
                        if (t.tierId == TierId.orignaCode) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Semantics(
                              button: true,
                              label: deckButtonSemanticsLabel,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () =>
                                    launchUrl(Uri.parse(_fullDeckPdfUrl)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    loc.tr(
                                      'View the investor deck ->',
                                      'Voir le deck investisseur ->',
                                      'Ver el deck para inversionistas ->',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPopular
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : ThemeConfig.textMuted,
                                      decoration: TextDecoration.underline,
                                      decorationColor: isPopular
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : ThemeConfig.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_status != null) ...[
                          const SizedBox(height: 12),
                          _StatusBanner(message: _status!, success: _success),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (isPopular && !widget.isMobile) {
      return Transform.scale(scale: 1.03, child: card);
    }
    return card;
  }

  Future<void> _handleBuy() async {
    final loc = widget.locale;
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$venturesApiBase/payments/create-checkout-session'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_code': widget.tier.serviceCode,
              'payment_provider': 'stripe',
              'locale': loc.name,
              'developer_count': widget.tier.tierId == TierId.orignaTeam
                  ? _teamDeveloperCount
                  : 1,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = _decodeCheckoutBody(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _CheckoutException(
          (body['message'] ?? body['detail'])?.toString() ??
              loc.tr(
                'Checkout failed. Please try again.',
                'Echec du paiement. Reessayez.',
                'Error en el pago. Intentelo de nuevo.',
              ),
        );
      }
      final url = body['checkoutUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        final checkoutUri = Uri.parse(url);
        if (kIsWeb) {
          final launched = await launchUrl(
            checkoutUri,
            webOnlyWindowName: '_self',
          );
          if (!launched) {
            throw Exception('Could not open Stripe checkout');
          }
          return;
        } else {
          final launched = await launchUrl(
            checkoutUri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            throw Exception('Could not open Stripe checkout');
          }
        }
        if (mounted) {
          setState(() {
            _status = loc.tr(
              'Redirecting to Stripe...',
              'Redirection vers Stripe...',
              'Redirigiendo a Stripe...',
            );
            _success = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _status = (body['message'] ?? body['detail'])?.toString() ??
                loc.tr(
                  'Something went wrong.',
                  'Une erreur est survenue.',
                  'Algo salio mal.',
                );
            _success = false;
          });
        }
      }
    } on _CheckoutException catch (e) {
      debugPrint('OrignaVentures: checkout rejected: ${e.message}');
      if (mounted) {
        setState(() {
          _status = e.message;
          _success = false;
        });
      }
    } catch (e) {
      debugPrint('OrignaVentures: checkout error: $e');
      if (mounted) {
        setState(() {
          _status = loc.tr(
            'Network error. Please try again.',
            'Erreur reseau. Reessayez.',
            'Error de red. Intentelo de nuevo.',
          );
          _success = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

Map<String, dynamic> _decodeCheckoutBody(String rawBody) {
  if (rawBody.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(rawBody);
  if (decoded is Map<String, dynamic>) return decoded;
  return <String, dynamic>{'detail': decoded.toString()};
}

class _CheckoutException implements Exception {
  final String message;

  const _CheckoutException(this.message);
}

class _FloatingGlassGlow extends StatelessWidget {
  final Offset offset;
  final double size;
  final Color color;

  const _FloatingGlassGlow({
    required this.offset,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Align(
        alignment: Alignment.center,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: color.a * 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool bright;

  const _Chip({
    required this.label,
    required this.color,
    this.filled = false,
    this.bright = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: bright ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PartnerSection extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;

  const _PartnerSection({required this.locale, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final loc = locale;
    return Container(
      color: const Color(0xFF08081A),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 32 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                label: loc.tr('PARTNER PROGRAM', 'PROGRAMME PARTENAIRES',
                    'PROGRAMA SOCIOS'),
                light: true,
              ),
              const SizedBox(height: 12),
              Text(
                loc.tr('Earn while you refer', 'Gagnez en referant',
                    'Gane refiriendo'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 24 : 34,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.tr(
                  'Free OrignaLaunch + 5% net revenue + \$50 CAD per client. No cap.',
                  'OrignaLaunch gratuit + 5% du revenu net + 50 \$ CAD par client. Aucune limite.',
                  'OrignaLaunch gratis + 5% de ingresos netos + \$50 CAD por cliente. Sin limite.',
                ),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), height: 1.5),
              ),
              SizedBox(height: isMobile ? 22 : 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PartnerBenefit(
                    icon: Icons.link_rounded,
                    text: loc.tr('Unique referral link',
                        'Lien de parrainage unique', 'Link de referido unico'),
                  ),
                  _PartnerBenefit(
                    icon: Icons.attach_money_rounded,
                    text: loc.tr('\$50 CAD per client', '50 \$ CAD par client',
                        '\$50 CAD por cliente'),
                  ),
                  _PartnerBenefit(
                    icon: Icons.card_giftcard_rounded,
                    text: loc.tr(
                      'Free OrignaLaunch (\$3,000 value)',
                      'OrignaLaunch gratuit (3 000 \$ CAD)',
                      'OrignaLaunch gratis (\$3,000 CAD)',
                    ),
                  ),
                  _PartnerBenefit(
                    icon: Icons.dashboard_rounded,
                    text: loc.tr('Revenue dashboard', 'Tableau de bord revenus',
                        'Panel de ingresos'),
                  ),
                  _PartnerBenefit(
                    icon: Icons.check_circle_outline_rounded,
                    text: loc.tr('No sign-up fee', 'Aucun frais',
                        'Sin costo de registro'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline_rounded,
                        color: ThemeConfig.primaryLight, size: 16),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        loc.tr(
                          'Apply via SMS: $_supportPhone  ·  email: $_supportEmail',
                          'Postulez par SMS: $_supportPhone  ·  courriel: $_supportEmail',
                          'Aplique por SMS: $_supportPhone  ·  correo: $_supportEmail',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PartnerBenefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ThemeConfig.primaryLight),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  final LocaleMode locale;
  final bool isMobile;

  const _WhySection({required this.locale, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final loc = locale;
    final features = [
      (
        Icons.code_rounded,
        loc.tr('Full source code included', 'Code source complet inclus',
            'Codigo fuente completo incluido'),
        loc.tr('All IP is yours from day one.', 'Toute la PI vous appartient.',
            'Toda la IP es suya desde el dia 1.'),
      ),
      (
        Icons.phone_android_rounded,
        loc.tr('iOS · Android · Web · Desktop', 'iOS · Android · Web · Bureau',
            'iOS · Android · Web · Escritorio'),
        loc.tr(
            'One codebase, all platforms.',
            'Une base de code, toutes les plateformes.',
            'Una base de codigo, todas las plataformas.'),
      ),
      (
        Icons.groups_rounded,
        loc.tr('Dedicated remote team', 'Equipe distante dediee',
            'Equipo remoto dedicado'),
        loc.tr(
            'Daily standups & direct Slack access.',
            'Standups quotidiens et acces Slack direct.',
            'Standups diarios y acceso directo a Slack.'),
      ),
      (
        Icons.bolt_rounded,
        loc.tr('Live in 1-2 weeks', 'En ligne en 1-2 semaines',
            'En vivo en 1-2 semanas'),
        loc.tr('Fast, iterative launches.', 'Lancements rapides et iteratifs.',
            'Lanzamientos rapidos e iterativos.'),
      ),
      (
        Icons.verified_user_rounded,
        loc.tr(
            'Secure by design', 'Securise par conception', 'Seguro por diseno'),
        loc.tr(
            'Rust backend + HTTPS + HST-compliant invoices.',
            'Backend Rust + HTTPS + factures conformes a la TVH.',
            'Backend Rust + HTTPS + facturas conformes.'),
      ),
      (
        Icons.receipt_long_rounded,
        loc.tr('Transparent pricing', 'Tarification transparente',
            'Precios transparentes'),
        loc.tr('HST included. No surprise fees.',
            'TVH incluse. Aucune surprise.', 'HST incluido. Sin sorpresas.'),
      ),
    ];

    return Container(
      color: ThemeConfig.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 32 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SectionLabel(
                  label: loc.tr('WHY US', 'POURQUOI NOUS', 'POR QUE?')),
              const SizedBox(height: 12),
              Text(
                loc.tr('Why Origna Ventures', 'Pourquoi Origna Ventures',
                    'Por que Origna Ventures'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 26 : 36,
                  letterSpacing: -1,
                  color: ThemeConfig.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 24 : 36),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final cols = constraints.maxWidth > 600 ? 2 : 1;
                  return _FeatureGrid(features: features, cols: cols);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<(IconData, String, String)> features;
  final int cols;

  const _FeatureGrid({required this.features, required this.cols});

  @override
  Widget build(BuildContext context) {
    final rows = (features.length / cols).ceil();
    return Column(
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 14),
          Row(
            children: [
              for (int c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: 14),
                Expanded(
                  child: () {
                    final i = r * cols + c;
                    if (i >= features.length) return const SizedBox();
                    return _FeatureCard(
                      icon: features[i].$1,
                      title: features[i].$2,
                      desc: features[i].$3,
                    );
                  }(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeConfig.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeConfig.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: ThemeConfig.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ThemeConfig.textSecondary,
                    height: 1.4,
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

class _ContactFormBlock extends StatefulWidget {
  final LocaleMode locale;
  final bool isMobile;

  const _ContactFormBlock({
    super.key,
    required this.locale,
    required this.isMobile,
  });

  @override
  State<_ContactFormBlock> createState() => _ContactFormBlockState();
}

class _ContactFormBlockState extends State<_ContactFormBlock> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _service = 'general';
  bool _loading = false;
  String? _result;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _serviceItems() {
    final loc = widget.locale;
    return {
      'general': loc.tr(
        'General inquiry',
        'Renseignement general',
        'Consulta general',
      ),
      'origna_code': 'OrignaCode (\$500 CAD)',
      'origna_launch': 'OrignaLaunch (\$3,000 CAD)',
      'origna_team': loc.tr(
        'OrignaTeam (\$1,000 CAD/mo)',
        'OrignaTeam (1 000 \$ CAD/mois)',
        'OrignaTeam (\$1,000 CAD/mes)',
      ),
      'partnership': loc.tr('Partnership', 'Partenariat', 'Asociacion'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.locale;
    final items = _serviceItems();
    return Container(
      color: ThemeConfig.darkBackground,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 16 : 32,
        vertical: widget.isMobile ? 32 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                  label: loc.tr('CONTACT', 'CONTACT', 'CONTACTO'), light: true),
              const SizedBox(height: 12),
              Text(
                loc.tr('Get in touch', 'Contactez-nous', 'Contactenos'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: widget.isMobile ? 26 : 36,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.tr(
                  'We reply within 24 hours.',
                  'Nous repondons en moins de 24 heures.',
                  'Respondemos en menos de 24 horas.',
                ),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), height: 1.4),
              ),
              SizedBox(height: widget.isMobile ? 24 : 32),
              _formRow([
                _DarkField(
                  controller: _nameCtrl,
                  label: loc.tr(
                      'Full name *', 'Nom complet *', 'Nombre completo *'),
                  semanticsLabel: 'input-contact-name',
                ),
                _DarkField(
                  controller: _emailCtrl,
                  label: loc.tr('Email *', 'Courriel *', 'Correo *'),
                  semanticsLabel: 'input-contact-email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ], isMobile: widget.isMobile),
              const SizedBox(height: 14),
              _formRow([
                _DarkField(
                  controller: _companyCtrl,
                  label: loc.tr('Company', 'Entreprise', 'Empresa'),
                  semanticsLabel: 'input-contact-company',
                ),
                _DarkDropdown(
                  value: _service,
                  label: loc.tr('Service interest', "Service d'interet",
                      'Servicio de interes'),
                  semanticsLabel: 'select-contact-service',
                  items: items,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _service = v);
                    }
                  },
                ),
              ], isMobile: widget.isMobile),
              const SizedBox(height: 14),
              _DarkField(
                controller: _msgCtrl,
                label: loc.tr('Message *', 'Message *', 'Mensaje *'),
                semanticsLabel: 'input-contact-message',
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'btn-contact-submit',
                child: SizedBox(
                  width: widget.isMobile ? double.infinity : null,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ThemeConfig.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    onPressed: _loading ? null : () => _submit(loc),
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _loading
                          ? loc.tr('Sending...', 'Envoi...', 'Enviando...')
                          : loc.tr('Send message', 'Envoyer', 'Enviar mensaje'),
                    ),
                  ),
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 14),
                Semantics(
                  label: 'status-contact-result',
                  child: _StatusBanner(message: _result!, success: _success),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _formRow(List<Widget> fields, {required bool isMobile}) {
    if (isMobile) {
      return Column(
        children: fields
            .map((f) =>
                Padding(padding: const EdgeInsets.only(bottom: 14), child: f))
            .toList(),
      );
    }
    return Row(
      children: [
        for (int i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: fields[i]),
        ],
      ],
    );
  }

  Future<void> _submit(LocaleMode loc) async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    if (name.length < 2) {
      setState(() {
        _result = loc.tr(
            'Enter your name.', 'Entrez votre nom.', 'Ingrese su nombre.');
        _success = false;
      });
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _result = loc.tr(
          'Enter a valid email.',
          'Entrez un courriel valide.',
          'Ingrese un correo valido.',
        );
        _success = false;
      });
      return;
    }
    if (msg.length < 10) {
      setState(() {
        _result = loc.tr(
          'Message too short (min 10 characters).',
          'Message trop court (min 10 caracteres).',
          'Mensaje muy corto (min 10 caracteres).',
        );
        _success = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final resp = await http
          .post(
            Uri.parse('$venturesApiBase/contact'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'company': _companyCtrl.text.trim(),
              'service': _service,
              'message': msg,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && body['status'] == 'ok') {
        final emails = body['emails'] is Map<String, dynamic>
            ? body['emails'] as Map<String, dynamic>
            : <String, dynamic>{};
        final confirmation = emails['confirmation'] is Map<String, dynamic>
            ? emails['confirmation'] as Map<String, dynamic>
            : <String, dynamic>{};
        final confirmationStatus = confirmation['status']?.toString();
        _nameCtrl.clear();
        _emailCtrl.clear();
        _companyCtrl.clear();
        _msgCtrl.clear();
        setState(() {
          _success = true;
          _result = loc.tr(
            confirmationStatus == 'sent'
                ? "Message sent! We also emailed your confirmation and will reply within 24 hours."
                : "Message sent! We'll be in touch within 24 hours.",
            confirmationStatus == 'sent'
                ? 'Message envoye! Nous avons aussi envoye votre confirmation et nous repondrons dans les 24 heures.'
                : 'Message envoye! Nous vous repondrons dans les 24 heures.',
            confirmationStatus == 'sent'
                ? 'Mensaje enviado. Tambien enviamos su confirmacion y responderemos en menos de 24 horas.'
                : 'Mensaje enviado. Le responderemos en menos de 24 horas.',
          );
        });
      } else {
        setState(() {
          _success = false;
          _result = (body['detail'] ?? body['message'])?.toString() ??
              loc.tr(
                'Something went wrong. Please try again.',
                'Une erreur est survenue. Veuillez reessayer.',
                'Algo salio mal. Por favor, intentelo de nuevo.',
              );
        });
      }
    } catch (e) {
      debugPrint('[ContactForm] Network/submit error: $e');
      setState(() {
        _success = false;
        _result = loc.tr(
          'Network error. Please try again.',
          'Erreur reseau. Reessayez.',
          'Error de red. Intentelo de nuevo.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _CookieConsentBanner extends StatelessWidget {
  final LocaleMode locale;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _CookieConsentBanner({
    required this.locale,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ThemeConfig.darkBackground,
        border: Border(top: BorderSide(color: ThemeConfig.darkBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                locale.tr(
                  'We use essential cookies to remember language, keep checkout stable, and improve launch analytics.',
                  'Nous utilisons des temoins essentiels pour memoriser la langue, stabiliser le paiement et ameliorer l analytique de lancement.',
                  'Usamos cookies esenciales para recordar el idioma, mantener estable el pago y mejorar la analitica de lanzamiento.',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  button: true,
                  label: 'btn-cookie-decline',
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(locale.tr('Decline', 'Refuser', 'Rechazar')),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'btn-cookie-accept',
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: ThemeConfig.gold,
                      foregroundColor: ThemeConfig.primaryDark,
                    ),
                    child: Text(locale.tr('Accept', 'Accepter', 'Aceptar')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? semanticsLabel;
  final TextInputType? keyboardType;
  final int maxLines;

  const _DarkField({
    required this.controller,
    required this.label,
    this.semanticsLabel,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticsLabel ?? label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          floatingLabelStyle: TextStyle(
            color: ThemeConfig.primaryLight.withValues(alpha: 0.9),
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: ThemeConfig.primaryLight, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _DarkDropdown extends StatefulWidget {
  final String value;
  final String label;
  final String? semanticsLabel;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.label,
    this.semanticsLabel,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_DarkDropdown> createState() => _DarkDropdownState();
}

class _DarkDropdownState extends State<_DarkDropdown> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(covariant _DarkDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _current = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.items.containsKey(_current)) {
      _current = widget.items.keys.first;
    }
    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      child: DropdownButtonFormField<String>(
        initialValue: _current,
        isExpanded: true,
        items: widget.items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _current = v);
          }
          widget.onChanged(v);
        },
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          floatingLabelStyle: TextStyle(
            color: ThemeConfig.primaryLight.withValues(alpha: 0.9),
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: ThemeConfig.primaryLight, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        dropdownColor: const Color(0xFF1A1A38),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        iconEnabledColor: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool light;

  const _SectionLabel({required this.label, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeConfig.primary.withValues(alpha: light ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: light ? ThemeConfig.primaryLight : ThemeConfig.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool success;

  const _StatusBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? ThemeConfig.success : ThemeConfig.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final LocaleMode locale;

  const _Footer({required this.locale});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      color: const Color(0xFF06060F),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 24 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            _LogoBadge(),
                            SizedBox(width: 8),
                            Text(
                              'Origna Ventures',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          locale.tr(
                            'Software services, ecommerce, retail, and wholesale.',
                            'Services logiciels, commerce electronique, detail et gros.',
                            'Servicios de software, comercio electronico, retail y mayorista.',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _supportEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _supportPhone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 14),
                Text(
                  _supportEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} Origna Ventures. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
