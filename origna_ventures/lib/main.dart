import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
import 'theme_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrignaVenturesApp());
}

const _brandPrimary = ThemeConfig.primary;
const _brandDark = ThemeConfig.darkBackground;
const _brandGreen = ThemeConfig.success;
const _brandLight = ThemeConfig.surface;
const _supportEmail = 'support@orignaventures.ca';
const _supportPhone = '4167865517';
const _companyLegal = '1001475263 ONTARIO CORPORATION';
const _companyBn = '708286364TZ0001';
const _baseUrl = 'https://orignaventures.ca';
const _demoUrl = 'https://dev.orignagta.ca';
const _apiBase = 'https://api.orignagta.ca/ventures/api';
const _onepagerPdfUrl =
    'https://orignaventures.ca/docs/origna_ventures_onepager.pdf';
const _fullDeckPdfUrl =
    'https://orignaventures.ca/docs/origna_ventures_full_presentation.pdf';
const _apkUrl = String.fromEnvironment(
  'APK_URL',
  defaultValue: 'https://dev.orignagta.ca',
);
const _donationUrl = String.fromEnvironment('DONATION_URL', defaultValue: '');
const _donationReportUrl = _onepagerPdfUrl;
const _smsUrl = 'sms:$_supportPhone';
const _telUrl = 'tel:$_supportPhone';
const _mailtoUrl = 'mailto:$_supportEmail';
const _whatsappUrl = 'https://wa.me/1$_supportPhone';

String _sanitizeRoute(String path) {
  if (path.isEmpty) return '/';
  final normalized = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  switch (normalized) {
    case '/':
    case '/software':
    case '/services':
    case '/pay':
    case '/deck':
    case '/donate':
    case '/partner':
    case '/contact':
      return normalized;
    default:
      return '/';
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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Origna Ventures Services',
      initialRoute: _sanitizeRoute(Uri.base.path),
      routes: {
        '/': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const HomePage(),
            ),
        '/software': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const SoftwarePage(),
            ),
        '/services': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const ServicesPage(),
            ),
        '/pay': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const PayPage(),
            ),
        '/deck': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const DeckPage(),
            ),
        '/donate': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const DonatePage(),
            ),
        '/partner': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const PartnerPage(),
            ),
        '/contact': (_) => SiteShell(
              locale: locale,
              onLocaleChanged: _setLocale,
              child: const ContactPage(),
            ),
      },
      theme: ThemeConfig.lightTheme(),
      darkTheme: ThemeConfig.darkTheme(),
    );
  }

  void _setLocale(LocaleMode value) => setState(() => locale = value);
}

enum LocaleMode { en, fr, es }

extension LocaleModeTr on LocaleMode {
  String tr(String en, String fr, [String? es]) =>
      this == LocaleMode.fr ? fr : (this == LocaleMode.es ? (es ?? en) : en);
}

class SiteShell extends StatelessWidget {
  final LocaleMode locale;
  final ValueChanged<LocaleMode> onLocaleChanged;
  final Widget child;

  const SiteShell({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.child,
  });

  String tr(String en, String fr, [String? es]) => locale == LocaleMode.fr
      ? fr
      : (locale == LocaleMode.es ? (es ?? en) : en);

  static const _navItems = [
    ('/', 'Home'),
    ('/software', 'Software'),
    ('/services', 'Services'),
    ('/pay', 'Pay'),
    ('/deck', 'Deck'),
    ('/partner', 'Partner'),
    ('/donate', 'Donate'),
    ('/contact', 'Contact'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: _brandDark,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 20,
              vertical: 10,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TrebolBadge(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Origna Ventures Services',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 17 : 20,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_companyLegal · BN $_companyBn',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isMobile ? 11 : 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMobile) ...[
                        const SizedBox(width: 8),
                        ToggleButtons(
                          isSelected: [
                            locale == LocaleMode.en,
                            locale == LocaleMode.fr,
                            locale == LocaleMode.es,
                          ],
                          onPressed: (index) =>
                              onLocaleChanged(LocaleMode.values[index]),
                          constraints: const BoxConstraints(
                            minHeight: 32,
                            minWidth: 32,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white70,
                          selectedColor: Colors.white,
                          fillColor: _brandPrimary,
                          children: const [Text('EN'), Text('FR'), Text('ES')],
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'menu',
                          color: Colors.white,
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onSelected: (route) =>
                              Navigator.of(context).pushNamed(route),
                          itemBuilder: (context) => [
                            for (final item in _navItems)
                              PopupMenuItem<String>(
                                value: item.$1,
                                child: Text(item.$2),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (!isMobile) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in _navItems.take(5))
                            _NavChip(label: item.$2, route: item.$1),
                          ToggleButtons(
                            isSelected: [
                              locale == LocaleMode.en,
                              locale == LocaleMode.fr,
                              locale == LocaleMode.es,
                            ],
                            onPressed: (index) =>
                                onLocaleChanged(LocaleMode.values[index]),
                            constraints: const BoxConstraints(
                              minHeight: 36,
                              minWidth: 44,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white70,
                            selectedColor: Colors.white,
                            fillColor: _brandPrimary,
                            children: const [
                              Text('EN'),
                              Text('FR'),
                              Text('ES'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: child,
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    heroTag: 'whatsapp',
                    backgroundColor: const Color(0xFF25D366),
                    onPressed: () => launchUrl(
                      Uri.parse(_whatsappUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: _brandLight,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 20,
              vertical: 18,
            ),
            child: Wrap(
              spacing: 18,
              runSpacing: 12,
              alignment: isMobile ? WrapAlignment.start : WrapAlignment.center,
              children: [
                Text('${tr('Support', 'Support', 'Soporte')} · $_supportEmail'),
                Text(
                  '${tr('SMS preferred', 'SMS préféré', 'SMS preferido')} · $_supportPhone',
                ),
                Text(_baseUrl),
                Text(_demoUrl),
                Text(
                  tr(
                    'Service payments are made to Origna Ventures. Separate donations support church/community giving.',
                    'Les paiements de service sont faits à Origna Ventures. Les dons séparés soutiennent l’église/la communauté.',
                    'Los pagos de servicio se hacen a Origna Ventures. Las donaciones separadas apoyan la iglesia/comunidad.',
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

class _NavChip extends StatelessWidget {
  final String label;
  final String route;

  const _NavChip({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}

class _TrebolBadge extends StatelessWidget {
  const _TrebolBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('☘', style: TextStyle(fontSize: 24, color: _brandGreen)),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    final loc = locale;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        _CorporateHero(loc: loc),
        const SizedBox(height: 24),
        _HomePricingSection(loc: loc),
        const SizedBox(height: 24),
        _AboutSection(loc: loc),
        const SizedBox(height: 24),
        _MenuCardsSection(loc: loc),
        const SizedBox(height: 24),
        _WhySection(loc: loc),
        const SizedBox(height: 24),
        _ContactFormSection(loc: loc),
      ],
    );
  }
}

class _CorporateHero extends StatelessWidget {
  final LocaleMode loc;
  const _CorporateHero({required this.loc});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_brandPrimary, _brandDark]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CornerToken(symbol: '☘', color: _brandGreen),
              _CornerToken(symbol: '🫎', color: Colors.white),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            loc.tr(
              'Origna Ventures — Software Services & Ecommerce',
              'Origna Ventures — Services logiciels et commerce électronique',
              'Origna Ventures — Servicios de software y comercio electrónico',
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.tr(
              'Origna Ventures is a company dedicated to ecommerce, wholesale, retail, software services, and outsourcing. We build platforms, deliver custom solutions, and provide remote professional services.',
              "Origna Ventures est une entreprise dédiée au commerce électronique, à la vente en gros, au détail, aux services logiciels et à l'externalisation. Nous construisons des plateformes et fournissons des services professionnels à distance.",
              'Origna Ventures es una empresa dedicada al comercio electrónico, venta al por mayor, venta al por menor, servicios de software y subcontratación. Construimos plataformas y proporcionamos servicios profesionales remotos.',
            ),
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 14 : 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(
                label: loc.tr(
                  'Ecommerce software',
                  'Logiciel ecommerce',
                  'Software de comercio electrónico',
                ),
              ),
              _HeroBadge(
                label: loc.tr(
                  'Remote services',
                  'Services à distance',
                  'Servicios remotos',
                ),
              ),
              _HeroBadge(
                label: loc.tr(
                  'Flutter + Rust + PostgreSQL',
                  'Flutter + Rust + PostgreSQL',
                  'Flutter + Rust + PostgreSQL',
                ),
              ),
              _HeroBadge(
                label: loc.tr(
                  'Toronto, Canada based',
                  'Basé à Toronto, Canada',
                  'Basado en Toronto, Canadá',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _brandPrimary,
                ),
                onPressed: () => Navigator.of(context).pushNamed('/software'),
                child: Text(
                  loc.tr('Our software', 'Nos logiciels', 'Nuestro software'),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pushNamed('/services'),
                child: Text(
                  loc.tr('Our services', 'Nos services', 'Nuestros servicios'),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () => launchUrl(Uri.parse(_demoUrl)),
                child: Text(
                  loc.tr('View live demo', 'Voir la démo', 'Ver demo en vivo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomePricingSection extends StatelessWidget {
  final LocaleMode loc;
  const _HomePricingSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final cardWidth = isMobile ? double.infinity : 340.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr(
            'Choose your plan',
            'Choisissez votre forfait',
            'Elija su plan',
          ),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 24 : 30,
            color: _brandDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.tr(
            'Three clear tiers. Pay securely via Stripe. No recurring fees for code or launch.',
            'Trois forfaits clairs. Paiement sécurisé via Stripe. Pas de frais récurrents pour le code ou le lancement.',
            'Tres niveles claros. Pago seguro via Stripe. Sin tarifas recurrentes por código o lanzamiento.',
          ),
          style: const TextStyle(
            color: Colors.black54,
            height: 1.45,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _HomePricingCard(
                tier: loc.tr('STARTER', 'DÉBUTANT', 'INICIAL'),
                title: 'OrignaCode',
                price: '500',
                priceSuffix: loc.tr(
                  'CAD one-time',
                  'CAD paiement unique',
                  'CAD pago único',
                ),
                tagline: loc.tr(
                  'Get the source code. Deploy it yourself.',
                  'Obtenez le code source. Déployez vous-même.',
                  'Obtenga el código fuente. Despliéguelo usted mismo.',
                ),
                bullets: loc == LocaleMode.fr
                    ? [
                        'Code source Flutter + Rust + PostgreSQL à vie',
                        'Accès au dépôt GitHub ou Bitbucket privé',
                        'Mises à jour du code source à vie incluses',
                        'Vous hébergez et déploiez vous-même',
                        'Licence commerciale (revente interdite)',
                        'Remboursement complet avant déverrouillage du dépôt',
                      ]
                    : (loc == LocaleMode.es
                        ? [
                            'Código fuente Flutter + Rust + PostgreSQL para siempre',
                            'Acceso al repositorio privado GitHub o Bitbucket',
                            'Actualizaciones de código fuente de por vida incluidas',
                            'Usted aloja y despliega en su propia infraestructura',
                            'Licencia comercial (no reventa de software)',
                            'Reembolso completo antes del desbloqueo del repositorio',
                          ]
                        : [
                            'Full Flutter + Rust + PostgreSQL source code, forever',
                            'Private GitHub or Bitbucket repo access',
                            'Lifetime source-code updates included',
                            'You host and deploy on your own infrastructure',
                            'Commercial license (no software reselling)',
                            'Full refund before repo unlock',
                          ]),
                color: const Color(0xFF0B57D0),
                serviceCode: 'origna_code',
                isPopular: false,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _HomePricingCard(
                tier: loc.tr('POPULAR', 'POPULAIRE', 'POPULAR'),
                title: 'OrignaLaunch',
                price: '3,000',
                priceSuffix: loc.tr(
                  'CAD one-time',
                  'CAD paiement unique',
                  'CAD pago único',
                ),
                tagline: loc.tr(
                  'We launch everything for you. Code + hosting + stores.',
                  'On lance tout pour vous. Code + hébergement + stores.',
                  'Lanzamos todo por usted. Código + alojamiento + tiendas.',
                ),
                bullets: loc == LocaleMode.fr
                    ? [
                        'Tout d\'OrignaCode inclus',
                        'Serveur VPS 8 Go Hetzner — année 1 incluse',
                        'Déploiement App Store + Play Store inclus',
                        'Déploiement web + desktop inclus',
                        '20 testeurs humains (20 h QA)',
                        '4 semaines de support après lancement',
                        'Live en 1 à 2 semaines',
                      ]
                    : (loc == LocaleMode.es
                        ? [
                            'Todo de OrignaCode incluido',
                            'Alojamiento VPS 8 GB Hetzner — Año 1 incluido',
                            'Despliegue App Store + Play Store incluido',
                            'Despliegue web + escritorio incluido',
                            '20 probadores humanos (20 h QA)',
                            '4 semanas de soporte después del lanzamiento',
                            'En vivo en 1 a 2 semanas',
                          ]
                        : [
                            'Everything in OrignaCode included',
                            'Hetzner 8 GB VPS hosting — Year 1 included',
                            'App Store + Play Store deployment included',
                            'Web + desktop deployment included',
                            '20 human testers (20h QA)',
                            '4 weeks of post-launch support',
                            'Live in about 1–2 weeks',
                          ]),
                color: _brandPrimary,
                serviceCode: 'origna_launch',
                isPopular: true,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _HomePricingCard(
                tier: loc.tr('TEAM', 'ÉQUIPE', 'EQUIPO'),
                title: 'OrignaTeam',
                price: '2,000+',
                priceSuffix: loc.tr('CAD / month', 'CAD / mois', 'CAD / mes'),
                tagline: loc.tr(
                  'Dedicated developer on your project. Cancel anytime.',
                  'Développeur dédié sur votre projet. Annulez en tout temps.',
                  'Desarrollador dedicado en su proyecto. Cancele en cualquier momento.',
                ),
                bullets: loc == LocaleMode.fr
                    ? [
                        'Développeur assigné à votre projet',
                        'Standup quotidien avec votre développeur',
                        'Ecommerce, apps, web, mobile, desktop',
                        '100+ heures de tests QA par mois',
                        'Démarrage sous 48 h',
                        'API, hébergement et tests facturés séparément',
                      ]
                    : (loc == LocaleMode.es
                        ? [
                            'Desarrollador dedicado asignado a su proyecto',
                            'Standup diario con su desarrollador',
                            'Comercio electrónico, apps, web, móvil, escritorio',
                            '100+ horas de cobertura de pruebas QA por mes',
                            'Inicio dentro de 48 h',
                            'API, alojamiento y pruebas facturados por separado',
                          ]
                        : [
                            'Dedicated developer assigned to your project',
                            'Daily standup with your developer',
                            'Ecommerce, apps, web, mobile, desktop',
                            '100+ hours of QA testing coverage per month',
                            'Starts within 48 h',
                            'API, hosting, and testing billed separately',
                          ]),
                color: _brandGreen,
                serviceCode: 'origna_team',
                isPopular: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomePricingCard extends StatelessWidget {
  final String tier;
  final String title;
  final String price;
  final String priceSuffix;
  final String tagline;
  final List<String> bullets;
  final Color color;
  final String serviceCode;
  final bool isPopular;
  const _HomePricingCard({
    required this.tier,
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.tagline,
    required this.bullets,
    required this.color,
    required this.serviceCode,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()?.locale ??
        LocaleMode.en;
    return GlassContainer(
      color: isPopular ? color.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).pushNamed(
          '/pay',
          arguments: {'serviceCode': serviceCode},
        ),
        child: Stack(
          children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tier,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tagline,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          priceSuffix,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final bullet in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 8),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(height: 1.45, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/pay',
                      arguments: {'serviceCode': serviceCode},
                    ),
                    child: Text(
                      loc.tr('Get $title', 'Choisir $title', 'Obtener $title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  loc.tr('BEST VALUE', 'MEILLEURE VALEUR', 'MEJOR VALOR'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final LocaleMode loc;
  const _AboutSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr(
        'About Origna Ventures',
        'À propos d\'Origna Ventures',
        'Sobre Origna Ventures',
      ),
      subtitle: loc.tr(
        'Ontario corporation specializing in software and ecommerce services.',
        'Entreprise ontarienne spécialisée en logiciels et services ecommerce.',
        'Corporación de Ontario especializada en servicios de software y comercio electrónico.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr(
              'Origna Ventures is an Ontario-registered corporation (1001475263 ONTARIO CORPORATION, BN 708286364TZ0001) that designs, develops, and deploys ecommerce platforms and custom software solutions. We also provide remote professional services — customer service, data entry, software development, and more — to help businesses operate efficiently in the digital age.',
              'Origna Ventures est une société enregistrée en Ontario (1001475263 ONTARIO CORPORATION, BN 708286364TZ0001) qui conçoit, développe et déploie des plateformes ecommerce et des solutions logicielles sur mesure. Nous offrons également des services professionnels à distance — service client, saisie de données, développement logiciel et plus encore — pour aider les entreprises à fonctionner efficacement à l\'ère numérique.',
              'Origna Ventures es una corporación registrada en Ontario (1001475263 ONTARIO CORPORATION, BN 708286364TZ0001) que diseña, desarrolla e implanta plataformas de comercio electrónico y soluciones de software personalizadas. También ofrecemos servicios profesionales remotos — servicio al cliente, entrada de datos, desarrollo de software y más — para ayudar a las empresas a operar eficientemente en la era digital.',
            ),
            style: const TextStyle(height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _AboutChip(
                icon: Icons.code,
                label: loc.tr(
                  'Software development',
                  'Développement logiciel',
                  'Desarrollo de software',
                ),
              ),
              _AboutChip(
                icon: Icons.storefront,
                label: loc.tr(
                  'Ecommerce platforms',
                  'Plateformes ecommerce',
                  'Plataformas de comercio electrónico',
                ),
              ),
              _AboutChip(
                icon: Icons.support_agent,
                label: loc.tr(
                  'Remote customer service',
                  'Service client à distance',
                  'Servicio al cliente remoto',
                ),
              ),
              _AboutChip(
                icon: Icons.keyboard,
                label: loc.tr(
                  'Data entry',
                  'Saisie de données',
                  'Entrada de datos',
                ),
              ),
              _AboutChip(
                icon: Icons.cloud_upload,
                label: loc.tr(
                  'Cloud deployment',
                  'Déploiement cloud',
                  'Despliegue en la nube',
                ),
              ),
              _AboutChip(
                icon: Icons.phone_in_talk,
                label: loc.tr(
                  'Remote work',
                  'Travail à distance',
                  'Trabajo remoto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AboutChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _brandPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _brandPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MenuCardsSection extends StatelessWidget {
  final LocaleMode loc;
  const _MenuCardsSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr('What we offer', 'Ce que nous offrons', 'Lo que ofrecemos'),
      subtitle: loc.tr(
        'Explore our software solutions and professional services.',
        'Explorez nos solutions logicielles et nos services professionnels.',
        'Explore nuestras soluciones de software y servicios profesionales.',
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _MenuCard(
            icon: Icons.shopping_cart,
            color: _brandPrimary,
            title: loc.tr(
              'Ecommerce software',
              'Logiciel ecommerce',
              'Software de comercio electrónico',
            ),
            description: loc.tr(
              'Custom ecommerce platforms built with Flutter + Rust + PostgreSQL. Source code included, cross-platform deployment.',
              'Plateformes ecommerce sur mesure avec Flutter + Rust + PostgreSQL. Code source inclus, déploiement multiplateforme.',
              'Plataformas de comercio electrónico personalizadas con Flutter + Rust + PostgreSQL. Código fuente incluido, despliegue multiplataforma.',
            ),
            route: '/software',
          ),
          _MenuCard(
            icon: Icons.work_outline,
            color: _brandGreen,
            title: loc.tr(
              'Remote services',
              'Services à distance',
              'Servicios remotos',
            ),
            description: loc.tr(
              'Customer service, data entry, software development and more — delivered by a dedicated remote team.',
              'Service client, saisie de données, développement logiciel et plus — exécutés par une équipe dédiée à distance.',
              'Servicio al cliente, entrada de datos, desarrollo de software y más — entregados por un equipo remoto dedicado.',
            ),
            route: '/services',
          ),
          _MenuCard(
            icon: Icons.handshake_outlined,
            color: const Color(0xFF0B57D0),
            title: loc.tr(
              'Partner program',
              'Partenariat',
              'Programa de socios',
            ),
            description: loc.tr(
              'Free OrignaLaunch + 5% of net revenue + stacked referral bonus.',
              'OrignaLaunch gratuit + 5 % des revenus nets + bonus de référencement cumulatif.',
              'OrignaLaunch gratis + 5% de ingresos netos + bono de referido acumulativo.',
            ),
            route: '/partner',
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String route;
  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 720 ? width - 28 : 340.0;
    return SizedBox(
      width: cardWidth,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(height: 1.45, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      currentLocale(
                        context,
                      ).tr('Learn more', 'En savoir plus', 'Más información'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

LocaleMode currentLocale(BuildContext context) {
  final shell = context.findAncestorWidgetOfExactType<SiteShell>();
  return shell?.locale ?? LocaleMode.en;
}

class _WhySection extends StatelessWidget {
  final LocaleMode loc;
  const _WhySection({required this.loc});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.verified,
        loc.tr(
          'Source code included',
          'Code source inclus',
          'Código fuente incluido',
        ),
        loc.tr(
          'You own your platform. No vendor lock-in.',
          'Vous possédez votre plateforme. Pas de verrouillage vendeur.',
          'Usted es dueño de su plataforma. Sin dependencia del proveedor.',
        ),
      ),
      (
        Icons.phone_android,
        loc.tr(
          'Native cross-platform',
          'Multiplateforme natif',
          'Multiplataforma nativo',
        ),
        loc.tr(
          'Web, iOS, Android, and desktop — one codebase.',
          'Web, iOS, Android et desktop — une seule base de code.',
          'Web, iOS, Android y escritorio — una sola base de código.',
        ),
      ),
      (
        Icons.people_outline,
        loc.tr(
          'Dedicated remote team',
          'Équipe dédiée à distance',
          'Equipo remoto dedicado',
        ),
        loc.tr(
          'Developers, CSRs, and data entry staff assigned to your project.',
          'Développeurs, CSR et saisie de données assignés à votre projet.',
          'Desarrolladores, CSR y personal de entrada de datos asignados a su proyecto.',
        ),
      ),
      (
        Icons.rocket_launch,
        loc.tr('Fast launch', 'Lancement rapide', 'Lanzamiento rápido'),
        loc.tr(
          'Live in 1–2 weeks with OrignaLaunch.',
          'En ligne en 1 à 2 semaines avec OrignaLaunch.',
          'En vivo en 1–2 semanas con OrignaLaunch.',
        ),
      ),
      (
        Icons.security,
        loc.tr(
          'Security & compliance',
          'Sécurité et conformité',
          'Seguridad y cumplimiento',
        ),
        loc.tr(
          'PostgreSQL, Stripe, JWT RS256 auth, and PIPEDA compliance.',
          'PostgreSQL, Stripe, auth JWT RS256, et conformité PIPEDA.',
          'PostgreSQL, Stripe, autenticación JWT RS256 y cumplimiento PIPEDA.',
        ),
      ),
      (
        Icons.attach_money,
        loc.tr(
          'Transparent pricing',
          'Prix transparents',
          'Precios transparentes',
        ),
        loc.tr(
          'No recurring fees for code. Cancel services anytime.',
          'Pas de frais récurrents pour le code. Annulez les services en tout temps.',
          'Sin tarifas recurrentes por código. Cancele servicios en cualquier momento.',
        ),
      ),
    ];
    return _SectionCard(
      title: loc.tr(
        'Why Origna Ventures',
        'Pourquoi Origna Ventures',
        'Por qué Origna Ventures',
      ),
      subtitle: loc.tr(
        'Proprietary software, flexible services, real delivery.',
        'Logiciel propriétaire, services flexibles, livraison réelle.',
        'Software propietario, servicios flexibles, entrega real.',
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final item in items)
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 720
                  ? MediaQuery.sizeOf(context).width - 28
                  : 340.0,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(18),
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$1, color: _brandPrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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

/// Full inline contact form that POSTs to the Hetzner backend.
class _ContactFormSection extends StatefulWidget {
  final LocaleMode loc;
  const _ContactFormSection({required this.loc});

  @override
  State<_ContactFormSection> createState() => _ContactFormSectionState();
}

class _ContactFormSectionState extends State<_ContactFormSection> {
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

  Future<void> _submit(LocaleMode loc) async {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() {
        _result = loc.tr('Enter your name.', 'Entrez votre nom.', 'Ingrese su nombre.');
        _success = false;
      });
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      setState(() {
        _result = loc.tr('Enter a valid email.', 'Entrez un courriel valide.', 'Ingrese un correo válido.');
        _success = false;
      });
      return;
    }
    if (_msgCtrl.text.trim().length < 10) {
      setState(() {
        _result = loc.tr('Message too short.', 'Message trop court.', 'Mensaje demasiado corto.');
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final resp = await http.post(
        Uri.parse('$_apiBase/contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'company': _companyCtrl.text.trim(),
          'service': _service,
          'message': _msgCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && body['status'] == 'ok') {
        setState(() {
          _success = true;
          _result = loc.tr(
            'Message sent! We will reply to ${_emailCtrl.text.trim()} shortly.',
            'Message envoyé! Nous répondrons à ${_emailCtrl.text.trim()} sous peu.',
            'Mensaje enviado. Le responderemos a ${_emailCtrl.text.trim()} pronto.',
          );
          _nameCtrl.clear();
          _emailCtrl.clear();
          _companyCtrl.clear();
          _msgCtrl.clear();
        });
      } else {
        setState(() {
          _success = false;
          _result = body['detail']?.toString() ?? loc.tr('Something went wrong.', 'Une erreur est survenue.', 'Algo salió mal.');
        });
      }
    } catch (_) {
      setState(() {
        _success = false;
        _result = loc.tr('Network error. Try again.', 'Erreur réseau. Réessayez.', 'Error de red. Inténtelo de nuevo.');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: _brandDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('Contact us', 'Contactez-nous', 'Contáctenos'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.tr(
              'We reply within 24 hours.',
              'Nous répondons en moins de 24 heures.',
              'Respondemos en menos de 24 horas.',
            ),
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: _GlassTextField(
                  controller: _nameCtrl,
                  label: loc.tr('Full name *', 'Nom complet *', 'Nombre completo *'),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: _GlassTextField(
                  controller: _emailCtrl,
                  label: loc.tr('Email *', 'Courriel *', 'Correo *'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: _GlassTextField(
                  controller: _companyCtrl,
                  label: loc.tr('Company', 'Entreprise', 'Empresa'),
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: _GlassDropdown(
                  value: _service,
                  label: loc.tr('Service interest', 'Service d\'intérêt', 'Servicio de interés'),
                  items: {
                    'general': loc.tr('General inquiry', 'Renseignement général', 'Consulta general'),
                    'origna_code': 'OrignaCode (\$500 CAD)',
                    'origna_launch': 'OrignaLaunch (\$3,000 CAD)',
                    'origna_team': 'OrignaTeam (\$2,000+/mo CAD)',
                    'partnership': loc.tr('Partnership', 'Partenariat', 'Asociación'),
                  },
                  onChanged: (v) => setState(() => _service = v ?? _service),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassTextField(
            controller: _msgCtrl,
            label: loc.tr('Message *', 'Message *', 'Mensaje *'),
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _loading ? null : () => _submit(loc),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading
                      ? loc.tr('Sending…', 'Envoi…', 'Enviando…')
                      : loc.tr('Send message', 'Envoyer', 'Enviar mensaje'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                onPressed: () => launchUrl(
                  Uri.parse(_whatsappUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(loc.tr('WhatsApp', 'WhatsApp', 'WhatsApp')),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                onPressed: () => launchUrl(Uri.parse(_mailtoUrl)),
                icon: const Icon(Icons.email_outlined),
                label: Text(loc.tr('Email', 'Courriel', 'Correo')),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 14),
            _StatusBanner(message: _result!, success: _success),
          ],
        ],
      ),
    );
  }
}

/// Dark-themed text field for use on dark backgrounds.
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _GlassTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeConfig.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

/// Dark-themed dropdown for use on dark backgrounds.
class _GlassDropdown extends StatelessWidget {
  final String value;
  final String label;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _GlassDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1A1A2E),
      style: const TextStyle(color: Colors.white),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeConfig.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CornerToken extends StatelessWidget {
  final String symbol;
  final Color color;
  const _CornerToken({required this.symbol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(symbol, style: TextStyle(fontSize: 22, color: color)),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final LocaleMode loc;
  const _ComparisonSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    final rows = [
      [
        'Shopify',
        '≈ 468–1,788 CAD/yr + transaction/app fees',
        loc.tr('No', 'Non', 'No'),
        loc.tr('Partial', 'Partiel', 'Parcial'),
        loc.tr('No', 'Non', 'No'),
      ],
      [
        'Replit',
        '≈ 300+ CAD/yr + build/ops time',
        loc.tr(
            'Yes, but DIY', 'Oui, mais bricolé', 'Sí, pero hágalo usted mismo'),
        loc.tr('Not native', 'Pas natif', 'No nativo'),
        loc.tr('No', 'Non', 'No'),
      ],
      [
        'Lovable',
        '≈ 600+ CAD/yr + backend costs',
        loc.tr('Limited', 'Limité', 'Limitado'),
        loc.tr('No', 'Non', 'No'),
        loc.tr('No', 'Non', 'No'),
      ],
      [
        'OrignaGTA',
        '500 CAD code / 2,000 CAD launch / 1,000+ CAD team',
        loc.tr('Yes', 'Oui', 'Sí'),
        loc.tr('Yes', 'Oui', 'Sí'),
        loc.tr('Yes', 'Oui', 'Sí'),
      ],
    ];
    return _SectionCard(
      title: loc.tr(
        'Market comparison',
        'Comparatif marché',
        'Comparativa de mercado',
      ),
      subtitle: loc.tr(
        'Pricing, source-code ownership, and cross-platform delivery.',
        'Prix, propriété du code source et livraison multiplateforme.',
        'Precios, propiedad del código fuente y entrega multiplataforma.',
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(loc.tr('Solution', 'Solution', 'Solución'))),
            DataColumn(label: Text(loc.tr('Cost', 'Coût', 'Costo'))),
            DataColumn(
              label: Text(
                loc.tr('Source code', 'Code source', 'Código fuente'),
              ),
            ),
            DataColumn(
              label: Text(
                loc.tr('Mobile/Desktop', 'Mobile/Desktop', 'Móvil/Escritorio'),
              ),
            ),
            DataColumn(
              label: Text(
                loc.tr(
                  'Hosting year 1',
                  'Hébergement année 1',
                  'Alojamiento año 1',
                ),
              ),
            ),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (cell) =>
                            DataCell(SizedBox(width: 180, child: Text(cell))),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final LocaleMode loc;
  const _ServicesSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr(
        'Choose your package',
        'Choisissez votre forfait',
        'Elija su paquete',
      ),
      subtitle: loc.tr(
        'Three clear tiers. No recurring fees for code or launch. Cancel team anytime.',
        'Trois forfaits clairs. Pas de frais récurrents pour le code ou le lancement. Annulez l\'équipe en tout temps.',
        'Tres niveles claros. Sin tarifas recurrentes por código o lanzamiento. Cancele equipo en cualquier momento.',
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _ServiceCard(
            tier: loc.tr('STARTER', 'DÉBUTANT', 'INICIAL'),
            title: 'OrignaCode',
            price: '500 CAD',
            priceSuffix: loc.tr('one-time', 'paiement unique', 'pago único'),
            tagline: loc.tr(
              'Get the source code. Deploy it yourself.',
              'Obtenez le code source. Déployez vous-même.',
              'Obtenga el código fuente. Despliéguelo usted mismo.',
            ),
            bullets: loc == LocaleMode.fr
                ? [
                    'Code source Flutter + Rust + PostgreSQL à vie',
                    'Accès au dépôt GitHub ou Bitbucket privé',
                    'Mises à jour du code source à vie',
                    'Vous hébergez et déploiez vous-même',
                    'Licence commerciale (revente du logiciel interdite)',
                    'Remboursement complet avant déverrouillage du dépôt',
                  ]
                : (loc == LocaleMode.es
                    ? [
                        'Código fuente Flutter + Rust + PostgreSQL para siempre',
                        'Acceso al repositorio privado GitHub o Bitbucket',
                        'Actualizaciones de código fuente de por vida incluidas',
                        'Usted aloja y despliega en su propia infraestructura',
                        'Licencia comercial (no reventa de software)',
                        'Reembolso completo antes del desbloqueo del repositorio',
                      ]
                    : [
                        'Full Flutter + Rust + PostgreSQL source code, forever',
                        'Private GitHub or Bitbucket repo access',
                        'Lifetime source-code updates included',
                        'You host and deploy on your own infrastructure',
                        'Commercial license (no software reselling)',
                        'Full refund before repo unlock',
                      ]),
            color: const Color(0xFF0B57D0),
            serviceCode: 'origna_code',
            isPopular: false,
          ),
          _ServiceCard(
            tier: loc.tr('POPULAR', 'POPULAIRE', 'POPULAR'),
            title: 'OrignaLaunch',
            price: '2,000 CAD',
            priceSuffix: loc.tr('one-time', 'paiement unique', 'pago único'),
            tagline: loc.tr(
              'We launch everything for you. Code + hosting + stores.',
              'On lance tout pour vous. Code + hébergement + stores.',
              'Lanzamos todo por usted. Código + alojamiento + tiendas.',
            ),
            bullets: loc == LocaleMode.fr
                ? [
                    'Tout d\'OrignaCode inclus',
                    'Serveur VPS 8 Go Hetzner — année 1 incluse',
                    'Déploiement App Store + Play Store inclus',
                    'Déploiement web + desktop inclus',
                    '20 testeurs humains (20 h QA)',
                    '4 semaines de support après lancement',
                    'Live en 1 à 2 semaines',
                    'Paiement validé → dépôt déverrouillé auto',
                  ]
                : (loc == LocaleMode.es
                    ? [
                        'Todo de OrignaCode incluido',
                        'Alojamiento VPS 8 GB Hetzner — Año 1 incluido',
                        'Despliegue App Store + Play Store incluido',
                        'Despliegue web + escritorio incluido',
                        '20 probadores humanos (20 h QA)',
                        '4 semanas de soporte después del lanzamiento',
                        'En vivo en 1 a 2 semanas',
                        'Pago validado → repositorio desbloqueado automáticamente',
                      ]
                    : [
                        'Everything in OrignaCode included',
                        'Hetzner 8 GB VPS hosting — Year 1 included',
                        'App Store + Play Store deployment included',
                        'Web + desktop deployment included',
                        '20 human testers (20h QA)',
                        '4 weeks of post-launch support',
                        'Live in about 1–2 weeks',
                        'Cleared payment → auto repo unlock',
                      ]),
            color: _brandPrimary,
            serviceCode: 'origna_launch',
            isPopular: true,
          ),
          _ServiceCard(
            tier: loc.tr('TEAM', 'ÉQUIPE', 'EQUIPO'),
            title: 'OrignaTeam',
            price: '1,000+ CAD',
            priceSuffix: loc.tr(
              '/ month · cancel anytime',
              '/ mois · annulez en tout temps',
              '/ mes · cancele en cualquier momento',
            ),
            tagline: loc.tr(
              'Dedicated developer on your project.',
              'Développeur dédié sur votre projet.',
              'Desarrollador dedicado en su proyecto.',
            ),
            bullets: loc == LocaleMode.fr
                ? [
                    'Développeur assigné à votre projet',
                    'Standup quotidien avec votre développeur',
                    'Ecommerce, apps, web, mobile, desktop',
                    'Démarrage sous 48 h après paiement',
                    'API, hébergement et tests facturés séparément — voir détails',
                    'Remboursement sous 24 h avant déverrouillage',
                  ]
                : (loc == LocaleMode.es
                    ? [
                        'Desarrollador dedicado asignado a su proyecto',
                        'Standup diario con su desarrollador',
                        'Comercio electrónico, apps, web, móvil, escritorio',
                        'Inicio dentro de 48 h después del pago',
                        'API, alojamiento y pruebas facturados por separado — ver detalles',
                        'Reembolso dentro de 24 h antes del desbloqueo del repositorio',
                      ]
                    : [
                        'Dedicated developer assigned to your project',
                        'Daily standup with your developer',
                        'Ecommerce, apps, web, mobile, desktop',
                        'Starts within 48 h of cleared payment',
                        'API, hosting, and testing billed separately — see details',
                        'Refund within 24 h before repo unlock',
                      ]),
            color: _brandGreen,
            serviceCode: 'origna_team',
            isPopular: false,
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String tier;
  final String title;
  final String price;
  final String priceSuffix;
  final String tagline;
  final List<String> bullets;
  final Color color;
  final String serviceCode;
  final bool isPopular;
  const _ServiceCard({
    required this.tier,
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.tagline,
    required this.bullets,
    required this.color,
    required this.serviceCode,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()?.locale ??
        LocaleMode.en;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 720 ? width - 28 : 340.0;
    return SizedBox(
      width: cardWidth,
      child: Card(
        color: Colors.white,
        elevation: isPopular ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isPopular
              ? BorderSide(color: color, width: 2)
              : BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tier,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tagline,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            priceSuffix,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final bullet in bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: color,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(
                                height: 1.45,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/pay',
                        arguments: {'serviceCode': serviceCode},
                      ),
                      child: Text(
                        loc.tr(
                            'Get $title', 'Choisir $title', 'Obtener $title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    loc.tr('POPULAR', 'POPULAIRE', 'POPULAR'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgramsSection extends StatelessWidget {
  final LocaleMode loc;
  const _ProgramsSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr('Programs', 'Programmes', 'Programas'),
      subtitle: loc.tr(
        'Referral, partner, sponsorship, and community giving.',
        'Referral, partenariat, commandite et don communautaire.',
        'Referidos, socios, patrocinio y donaciones comunitarias.',
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _MiniProgramCard(
            title: loc.tr('Referral', 'Référencement', 'Referido'),
            content: loc.tr(
              '50 CAD when a referred person/business pays 500 CAD or more.',
              '50 CAD quand une personne ou entreprise paie 500 CAD ou plus.',
              '50 CAD cuando una persona/empresa referida paga 500 CAD o más.',
            ),
          ),
          _MiniProgramCard(
            title: loc.tr('Partner', 'Partenaire', 'Socio'),
            content: loc.tr(
              'Free OrignaLaunch + 5% of generated net revenue + stacked 50 CAD referral bonus.',
              'OrignaLaunch gratuit + 5 % du revenu net généré + bonus referral de 50 CAD.',
              'OrignaLaunch gratis + 5% de ingresos netos + bono de referido acumulativo de 50 CAD.',
            ),
          ),
          _MiniProgramCard(
            title: loc.tr('Sponsorship', 'Commandite', 'Patrocinio'),
            content: loc.tr(
              'Bronze 500 / Silver 1,500 / Gold 5,000 CAD yearly for visibility and co-marketing.',
              'Bronze 500 / Argent 1 500 / Or 5 000 CAD par an pour visibilité et co-marketing.',
              'Bronce 500 / Plata 1,500 / Oro 5,000 CAD anuales para visibilidad y co-marketing.',
            ),
          ),
          _MiniProgramCard(
            title: loc.tr(
              'Community giving',
              'Don communautaire',
              'Donaciones comunitarias',
            ),
            content: loc.tr(
              'Service payments go to Origna Ventures. Separate donations and 10% of net profits support church/community programs.',
              'Les paiements de service vont à Origna Ventures. Les dons séparés et 10 % des profits nets soutiennent l\'église / les programmes communautaires.',
              'Los pagos de servicio van a Origna Ventures. Las donaciones separadas y el 10% de las ganancias netas apoyan programas de iglesia/comunidad.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgramCard extends StatelessWidget {
  final String title;
  final String content;
  const _MiniProgramCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 720 ? width - 28 : 280,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _brandPrimary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(content, style: const TextStyle(height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  final LocaleMode loc;
  const _QrSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr('Quick actions', 'Actions rapides', 'Acciones rápidas'),
      subtitle: loc.tr(
        'Payment, Android APK, demo, deck, donation, partner.',
        'Paiement, APK Android, démo, deck, don, partenaire.',
        'Pago, APK Android, demo, presentación, donación, socio.',
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ActionTile(
            label: loc.tr('Payment', 'Paiement', 'Pago'),
            route: '/pay',
          ),
          _ActionTile(
            label: loc.tr('Android APK', 'APK Android', 'APK Android'),
            external: _apkUrl,
          ),
          _ActionTile(
            label: loc.tr('Live demo', 'Démo live', 'Demo en vivo'),
            external: _demoUrl,
          ),
          _ActionTile(
            label: loc.tr('300+ deck', 'Deck 300+', 'Presentación 300+'),
            route: '/deck',
          ),
          _ActionTile(
            label: loc.tr('Partner', 'Partenaire', 'Socio'),
            route: '/partner',
          ),
          _ActionTile(
            label: loc.tr('Donate', 'Faire un don', 'Donar'),
            route: '/donate',
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final String? route;
  final String? external;
  const _ActionTile({required this.label, this.route, this.external});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 720 ? width - 28 : 180,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _brandDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        onPressed: () async {
          if (external != null) {
            await launchUrl(Uri.parse(external!));
          } else if (route != null) {
            Navigator.of(context).pushNamed(route!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final _email = TextEditingController();
  String _serviceCode = 'origna_launch';
  bool _loading = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['serviceCode'] is String) {
        _serviceCode = args['serviceCode'] as String;
      }
      if (args['payerEmail'] is String && _email.text.isEmpty) {
        _email.text = args['payerEmail'] as String;
      }
    }
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        _JourneyStepper(step: 1, loc: loc),
        const SizedBox(height: 14),
        _SectionCard(
          title: loc.tr('Secure payment', 'Paiement sécurisé', 'Pago seguro'),
          subtitle: loc.tr(
            'Secure live Stripe payment with fast checkout redirect.',
            'Paiement Stripe sécurisé en direct avec redirection rapide vers la caisse.',
            'Pago seguro por Stripe con redirección rápida al checkout.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  loc.tr(
                    'Select your service and enter your email, then continue directly to Stripe. Service payments are made to Origna Ventures in CAD; this page is not a donation flow.',
                    'Choisissez votre service et entrez votre courriel, puis continuez directement vers Stripe. Les paiements de service sont faits à Origna Ventures en CAD; cette page n\'est pas un flux de don.',
                    'Seleccione su servicio e ingrese su correo, luego continúe directamente a Stripe. Los pagos de servicio se realizan a Origna Ventures en CAD; esta página no es un flujo de donación.',
                  ),
                  style: const TextStyle(height: 1.45),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width:
                        isMobile ? MediaQuery.sizeOf(context).width - 76 : 340,
                    child: DropdownButtonFormField<String>(
                      initialValue: _serviceCode,
                      items: [
                        DropdownMenuItem(
                          value: 'origna_code',
                          child: Text(
                            loc.tr(
                              'OrignaCode · 500 + 65 HST = 565 CAD',
                              'OrignaCode · 500 + 65 HST = 565 CAD',
                              'OrignaCode · 500 + 65 HST = 565 CAD',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'origna_launch',
                          child: Text(
                            loc.tr(
                              'OrignaLaunch · 3,000 + 390 HST = 3,390 CAD',
                              'OrignaLaunch · 3 000 + 390 HST = 3 390 CAD',
                              'OrignaLaunch · 3.000 + 390 HST = 3.390 CAD',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'origna_team',
                          child: Text(
                            loc.tr(
                              'OrignaTeam · 2,000+ + HST CAD / month',
                              'OrignaTeam · 2 000+ + HST CAD / mois',
                              'OrignaTeam · 2.000+ + HST CAD / mes',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _serviceCode = value ?? _serviceCode),
                      decoration: InputDecoration(
                        labelText: loc.tr('Service', 'Service', 'Servicio'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        isMobile ? MediaQuery.sizeOf(context).width - 76 : 340,
                    child: TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: loc.tr(
                          'Payer email',
                          'Courriel payeur',
                          'Correo del pagador',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Stripe'),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _loading ? null : () => _startPayment(loc),
                    child: Text(
                      _loading
                          ? (loc.tr('Loading…', 'Chargement…', 'Cargando…'))
                          : (loc.tr(
                              'Pay now',
                              'Payer maintenant',
                              'Pagar ahora',
                            )),
                    ),
                  ),
                ],
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  message: _status!,
                  success: _status!.toLowerCase().contains('stripe') ||
                      _status!.toLowerCase().contains('redirection'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startPayment(LocaleMode loc) async {
    if (_email.text.trim().isEmpty) {
      setState(() {
        _status = loc.tr(
          'Enter your payer email.',
          'Entrez votre courriel de payeur.',
          'Ingrese su correo de pagador.',
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _status = null;
    });
    final response = await http.post(
      Uri.parse('$_apiBase/payments/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_code': _serviceCode,
        'payer_email': _email.text.trim(),
        'payment_provider': 'stripe',
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    setState(() => _loading = false);
    if (body['checkoutUrl'] != null) {
      await launchUrl(
        Uri.parse(body['checkoutUrl'] as String),
        mode: LaunchMode.externalApplication,
      );
      setState(
        () => _status = loc.tr(
          'Redirecting to Stripe.',
          'Redirection vers Stripe.',
          'Redirigiendo a Stripe.',
        ),
      );
      return;
    }
    setState(() => _status = body['message']?.toString() ?? body.toString());
  }
}

class DeckPage extends StatelessWidget {
  const DeckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 720 ? 14 : 24),
      children: [
        _SectionCard(
          title: loc.tr(
            'Full screenshot deck',
            'Deck complet des captures',
            'Presentación completa de capturas',
          ),
          subtitle: loc.tr(
            'Generated from the Python deck script with codebase stats + features + local screenshots.',
            'Généré depuis le script Python avec statistiques codebase + features + captures locales.',
            'Generado desde el script Python con estadísticas del código + funcionalidades + capturas locales.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• 464,386 total lines of code'),
              const Text(
                '• 814 Dart files · 182 Rust files · 150 TypeScript files',
              ),
              const Text(
                '• Full-screen captures are filtered from real lib/screens routes only',
              ),
              const Text('• Flutter web + iOS + Android + desktop'),
              const Text(
                '• Rust backend + PostgreSQL + Stripe + Mailjet + Turnstile + webhooks',
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr(
                  'The final deck includes: business overview, comparison, technical architecture, API/pricing audit, feature highlights, then validated full-screen captures from real app screens.',
                  'Le deck final inclut : aperçu business, comparatif marché, architecture technique, audit API/prix, fonctionnalités, puis des captures plein écran validées provenant des vrais écrans de l\'app.',
                  'La presentación final incluye: visión del negocio, comparación, arquitectura técnica, auditoría API/precios, destacados de funcionalidades, luego capturas de pantalla validadas de las pantallas reales de la app.',
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => launchUrl(Uri.parse(_onepagerPdfUrl)),
                    child: Text(
                      loc.tr(
                        'View one-pager PDF',
                        'Afficher le one-pager PDF',
                        'Ver PDF de una página',
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => triggerDownload(_onepagerPdfUrl),
                    child: Text(
                      loc.tr(
                        'Download one-pager',
                        'Télécharger le one-pager',
                        'Descargar PDF de una página',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => launchUrl(Uri.parse(_fullDeckPdfUrl)),
                    child: Text(
                      loc.tr(
                        'View full deck PDF',
                        'Afficher le deck PDF',
                        'Ver presentación PDF completa',
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => triggerDownload(_fullDeckPdfUrl),
                    child: Text(
                      loc.tr(
                        'Download full deck',
                        'Télécharger le deck',
                        'Descargar presentación completa',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 720 ? 14 : 24),
      children: [
        _SectionCard(
          title: loc.tr(
            'Community giving',
            'Don communautaire',
            'Donaciones comunitarias',
          ),
          subtitle: loc.tr(
            'Service payments go to Origna Ventures. Separate donations and 10% of net profits support church/community giving.',
            'Les paiements de service vont à Origna Ventures. Les dons séparés et 10 % des profits nets soutiennent l\'église / la communauté.',
            'Los pagos de servicios van a Origna Ventures. Las donaciones separadas y el 10 % de las ganancias netas apoyan donaciones a la iglesia/comunidad.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr(
                  'This page is only for separate donations. Payments for OrignaCode, OrignaLaunch, and OrignaTeam go to Origna Ventures through Stripe directly. Unless a qualified recipient is explicitly identified, this flow does not promise a tax receipt.',
                  'Cette page sert uniquement aux dons séparés. Les paiements pour OrignaCode, OrignaLaunch et OrignaTeam sont faits à Origna Ventures via Stripe directement. Sauf indication contraire d\'un organisme admissible, ce flux ne promet aucun reçu fiscal.',
                  'Esta página es solo para donaciones separadas. Los pagos de OrignaCode, OrignaLaunch y OrignaTeam se hacen a Origna Ventures a través de Stripe directamente. Salvo que se identifique explícitamente un destinatario calificado, este flujo no promete un recibo fiscal.',
                ),
                style: const TextStyle(color: Colors.black87, height: 1.45),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (_donationUrl.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_donationUrl)),
                      icon: const Icon(Icons.favorite),
                      label: Text(
                        loc.tr(
                          'Make a separate donation',
                          'Faire un don séparé',
                          'Hacer una donación separada',
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_smsUrl)),
                      icon: const Icon(Icons.favorite_outline),
                      label: Text(
                        loc.tr(
                          'Request a separate donation link',
                          'Demander un lien de don séparé',
                          'Solicitar un enlace de donación separada',
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_smsUrl)),
                    icon: const Icon(Icons.sms_outlined),
                    label: Text(
                      loc.tr('Donate by SMS', 'Don par SMS', 'Donar por SMS'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_mailtoUrl)),
                    icon: const Icon(Icons.email_outlined),
                    label: Text(
                      loc.tr(
                        'Donate by email',
                        'Don par courriel',
                        'Donar por correo',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_telUrl)),
                    icon: const Icon(Icons.phone_outlined),
                    label: Text(loc.tr('Call', 'Appeler', 'Llamar')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_donationReportUrl)),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(loc.tr('View PDF', 'Voir le PDF', 'Ver PDF')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr(
                  'Service payments: Origna Ventures · Separate donations: request the recipient/link by SMS at $_supportPhone or by email at $_supportEmail',
                  'Paiements de service : Origna Ventures · Dons séparés : demandez le destinataire/lien par SMS au $_supportPhone ou par courriel à $_supportEmail',
                  'Pagos de servicios: Origna Ventures · Donaciones separadas: solicite el destinatario/enlace por SMS al $_supportPhone o por correo electrónico a $_supportEmail',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SoftwarePage extends StatelessWidget {
  const SoftwarePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 720 ? 14 : 24),
      children: [
        _JourneyStepper(step: 0, loc: loc),
        const SizedBox(height: 18),
        _ComparisonSection(loc: loc),
        const SizedBox(height: 24),
        _ServicesSection(loc: loc),
        const SizedBox(height: 24),
        _ProgramsSection(loc: loc),
        const SizedBox(height: 24),
        _QrSection(loc: loc),
      ],
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        _SectionCard(
          title: loc.tr(
            'Remote professional services',
            'Services professionnels à distance',
            'Servicios profesionales remotos',
          ),
          subtitle: loc.tr(
            'Dedicated team for customer service, data entry, software development, and more.',
            'Équipe dédiée pour service client, saisie de données, développement logiciel et plus encore.',
            'Equipo dedicado para servicio al cliente, entrada de datos, desarrollo de software y más.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _RemoteServiceCard(
                    icon: Icons.support_agent,
                    title: loc.tr(
                      'Customer Service (CSR)',
                      'Service client (CSR)',
                      'Servicio al cliente (CSR)',
                    ),
                    description: loc.tr(
                      'Remote representatives for inbound and outbound support, email, chat, and phone.',
                      'Représentants à distance pour support entrant et sortant, courriel, chat et téléphone.',
                      'Representantes remotos para soporte entrante y saliente, correo, chat y teléfono.',
                    ),
                    color: _brandPrimary,
                  ),
                  _RemoteServiceCard(
                    icon: Icons.code,
                    title: loc.tr(
                      'Software development',
                      'Développement logiciel',
                      'Desarrollo de software',
                    ),
                    description: loc.tr(
                      'Dedicated developers for ecommerce, apps, web, mobile, and desktop. Flutter, Rust, PostgreSQL.',
                      'Développeurs dédiés pour ecommerce, apps, web, mobile et desktop. Flutter, Rust, PostgreSQL.',
                      'Desarrolladores dedicados para comercio electrónico, apps, web, móvil y escritorio. Flutter, Rust, PostgreSQL.',
                    ),
                    color: const Color(0xFF0B57D0),
                  ),
                  _RemoteServiceCard(
                    icon: Icons.keyboard,
                    title: loc.tr(
                      'Data entry',
                      'Saisie de données',
                      'Entrada de datos',
                    ),
                    description: loc.tr(
                      'Fast, accurate operators for data input, updates, and database management.',
                      'Opérateurs rapides et précis pour la saisie, la mise à jour et la gestion de bases de données.',
                      'Operadores rápidos y precisos para entrada de datos, actualizaciones y gestión de bases de datos.',
                    ),
                    color: _brandGreen,
                  ),
                  _RemoteServiceCard(
                    icon: Icons.analytics_outlined,
                    title: loc.tr(
                      'Data analysis',
                      'Analyse de données',
                      'Análisis de datos',
                    ),
                    description: loc.tr(
                      'Remote analysts for reports, dashboards, and insights from your data.',
                      'Analystes à distance pour rapports, tableaux de bord et insights à partir de vos données.',
                      'Analistas remotos para informes, paneles e insights de sus datos.',
                    ),
                    color: const Color(0xFF8E24AA),
                  ),
                  _RemoteServiceCard(
                    icon: Icons.translate,
                    title: loc.tr(
                      'Translation & localization',
                      'Traduction et localisation',
                      'Traducción y localización',
                    ),
                    description: loc.tr(
                      'EN/FR/ES translation and cultural adaptation for software, sites, and documents.',
                      'Traduction EN/FR/ES et adaptation culturelle pour logiciels, sites et documents.',
                      'Traducción EN/FR/ES y adaptación cultural para software, sitios y documentos.',
                    ),
                    color: const Color(0xFF00838F),
                  ),
                  _RemoteServiceCard(
                    icon: Icons.campaign_outlined,
                    title: loc.tr(
                      'Digital marketing',
                      'Marketing numérique',
                      'Marketing digital',
                    ),
                    description: loc.tr(
                      'Social media management, SEO, ads, and content creation delivered remotely.',
                      'Gestion de médias sociaux, référencement, publicités et création de contenu à distance.',
                      'Gestión de redes sociales, SEO, anuncios y creación de contenido entregados de forma remota.',
                    ),
                    color: const Color(0xFFFF6F00),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _OutsourcingDetailsSection(loc: loc),
      ],
    );
  }
}

class _RemoteServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _RemoteServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 720 ? width - 28 : 340.0;
    return SizedBox(
      width: cardWidth,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(height: 1.45, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutsourcingDetailsSection extends StatelessWidget {
  final LocaleMode loc;
  const _OutsourcingDetailsSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: loc.tr(
        'OrignaTeam · Outsourcing',
        'OrignaTeam · Externalisation',
        'OrignaTeam · Externalización',
      ),
      subtitle: loc.tr(
        'Dedicated developer for ecommerce, apps, web, mobile, and desktop.',
        'Développeur dédié pour ecommerce, apps, web, mobile et desktop.',
        'Desarrollador dedicado para comercio electrónico, apps, web, móvil y escritorio.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brandGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _brandGreen.withValues(alpha: 0.24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '1,000+ CAD',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: _brandGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.tr(
                      '/ month · cancel anytime',
                      '/ mois · annulez en tout temps',
                      '/ mes · cancele en cualquier momento',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            loc.tr("What's included", 'Ce qui est inclus', 'Qué está incluido'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          for (final bullet in (loc == LocaleMode.fr
              ? [
                  'Développeur assigné à votre projet — pas de file d\'attente',
                  'Standup quotidien avec votre développeur',
                  'Ecommerce, apps vibe-coded, web, mobile, desktop',
                  'Démarrage sous 48 h après paiement',
                  '100+ heures de tests QA par mois',
                  'Remboursement sous 24 h avant déverrouillage du dépôt',
                ]
              : (loc == LocaleMode.es
                  ? [
                      'Desarrollador dedicado asignado a su proyecto — sin fila',
                      'Standup diario con su desarrollador',
                      'Comercio electrónico, apps vibe-coded, web, móvil, escritorio',
                      'Inicio dentro de 48 h después del pago',
                      '100+ horas de cobertura de pruebas QA por mes',
                      'Reembolso dentro de 24 h antes del desbloqueo del repositorio',
                    ]
                  : [
                      'Dedicated developer assigned to your project — no queue',
                      'Daily standup with your developer',
                      'Ecommerce, vibe-coded apps, web, mobile, desktop',
                      'Starts within 48 h of cleared payment',
                      '100+ hours of QA testing coverage per month',
                      'Refund within 24 h before repo unlock',
                    ])))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: _brandGreen,
                    ),
                  ),
                  Expanded(
                    child: Text(bullet, style: const TextStyle(height: 1.45)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text(
            loc.tr(
              'Billed separately',
              'Frais séparés',
              'Facturado por separado',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          for (final bullet in (loc == LocaleMode.fr
              ? [
                  'API et hébergement (VPS, domaines, certificats SSL)',
                  'Tests web/mobile (environ 900 CAD)',
                  'Mailjet, Stripe et autres intégrations tierces',
                  'Stores (Apple Developer 119 CAD/an, Google Play 35 CAD)',
                  'Mise à jour et maintenance au-delà de la portée convenue',
                  'Services cloud tiers (Meilisearch, stockage, CDN)',
                  'Travail au-delà du forfait mensuel (facturé à l\'heure)',
                  'Toute dépense tierce liée au projet non listée ci-dessus',
                ]
              : (loc == LocaleMode.es
                  ? [
                      'API y alojamiento (VPS, dominios, certificados SSL)',
                      'Pruebas web/móvil (aproximadamente 900 CAD)',
                      'Mailjet, Stripe y otras integraciones de terceros',
                      'Tiendas (Apple Developer 119 CAD/año, Google Play 35 CAD)',
                      'Actualizaciones y mantenimiento más allá del alcance acordado',
                      'Servicios en la nube de terceros (Meilisearch, almacenamiento, CDN)',
                      'Trabajo más allá de la retención mensual (facturado por hora)',
                      'Cualquier gasto de terceros relacionado con el proyecto no listado arriba',
                    ]
                  : [
                      'API and hosting (VPS, domains, SSL certificates)',
                      'Web/mobile testing (approximately 900 CAD)',
                      'Mailjet, Stripe, and other third-party integrations',
                      'Stores (Apple Developer 119 CAD/yr, Google Play 35 CAD)',
                      'Updates and maintenance beyond agreed scope',
                      'Third-party cloud services (Meilisearch, storage, CDN)',
                      'Work beyond monthly retainer (billed hourly)',
                      'Any project-related third-party expense not listed above',
                    ])))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        height: 1.45,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/pay', arguments: {'serviceCode': 'origna_team'}),
              child: Text(
                loc.tr(
                  'Get OrignaTeam',
                  'Choisir OrignaTeam',
                  'Obtener OrignaTeam',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerPage extends StatelessWidget {
  const PartnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        _SectionCard(
          title: loc.tr(
            'Partner program',
            'Programme partenaire',
            'Programa de socios',
          ),
          subtitle: loc.tr(
            'Free OrignaLaunch + 5% of net revenue + stacked referral bonus.',
            'OrignaLaunch gratuit + 5 % des revenus nets + bonus referral cumulatif.',
            'OrignaLaunch gratis + 5% de ingresos netos + bono de referido acumulativo.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _PartnerTierCard(
                    tier: loc.tr('AFFILIATE', 'AFFILIÉ', 'AFILIADO'),
                    color: const Color(0xFF5F6368),
                    bullets: loc == LocaleMode.fr
                        ? [
                            'Lien de référencement unique',
                            '50 CAD par client qualifié (500+ CAD)',
                            'Aucun frais d\'inscription',
                            'Rapport mensuel de performance',
                          ]
                        : (loc == LocaleMode.es
                            ? [
                                'Enlace de referido único para compartir',
                                '50 CAD por cliente calificado (500+ CAD)',
                                'Sin tarifa de registro',
                                'Informe mensual de rendimiento',
                              ]
                            : [
                                'Unique referral link for sharing',
                                '50 CAD per qualified client (500+ CAD)',
                                'No sign-up fee',
                                'Monthly performance report',
                              ]),
                  ),
                  _PartnerTierCard(
                    tier: loc.tr('RESELLER', 'REVENDEUR', 'REVENDEDOR'),
                    color: _brandPrimary,
                    bullets: loc == LocaleMode.fr
                        ? [
                            'Tout d\'Affilié inclus',
                            '5 % du revenu net généré',
                            'OrignaLaunch gratuit (valeur 1 000 CAD)',
                            'Matériel de co-marketing fourni',
                            'Tableau de bord des revenus',
                          ]
                        : (loc == LocaleMode.es
                            ? [
                                'Todo de Afiliado incluido',
                                '5% de ingresos netos generados',
                                'OrignaLaunch gratis (valor de 2,000 CAD)',
                                'Materiales de co-marketing proporcionados',
                                'Acceso al panel de ingresos',
                              ]
                            : [
                                'Everything in Affiliate included',
                                '5% of generated net revenue',
                                'Free OrignaLaunch (2,000 CAD value)',
                                'Co-branded marketing materials provided',
                                'Revenue dashboard access',
                              ]),
                  ),
                  _PartnerTierCard(
                    tier: loc.tr('STRATEGIC', 'STRATÉGIQUE', 'ESTRATÉGICO'),
                    color: _brandGreen,
                    bullets: loc == LocaleMode.fr
                        ? [
                            'Tout de Revendeur inclus',
                            'Appels stratégiques trimestriels',
                            'Accès anticipé aux nouvelles fonctionnalités',
                            'Conditions de partage de revenus personnalisées',
                            'Support prioritaire',
                          ]
                        : (loc == LocaleMode.es
                            ? [
                                'Todo de Revendedor incluido',
                                'Llamadas de planificación estratégica trimestrales',
                                'Acceso anticipado a nuevas funciones',
                                'Términos personalizados de participación en ingresos',
                                'Canal de soporte prioritario',
                              ]
                            : [
                                'Everything in Reseller included',
                                'Quarterly strategic planning calls',
                                'Early access to new features',
                                'Custom revenue-share terms',
                                'Priority support channel',
                              ]),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  loc == LocaleMode.fr
                      ? 'Le bonus referral de 50 CAD s\'empile sur le partage de revenus. Aucune limite sur le nombre de referrals. Les paiements dans les 30 jours suivant le paiement validé du client. Appliquez via SMS au $_supportPhone ou par courriel à $_supportEmail.'
                      : (loc == LocaleMode.es
                          ? 'El bono de referido de 50 CAD se acumula sobre la participación de ingresos. Sin límite en el número de referidos. Pago dentro de los 30 días del pago validado del cliente. Aplique por SMS al $_supportPhone o por correo a $_supportEmail.'
                          : 'The 50 CAD referral bonus stacks on top of revenue share. No cap on the number of referrals. Payout within 30 days of the referred client\'s cleared payment. Apply by SMS at $_supportPhone or by email at $_supportEmail.'),
                  style: const TextStyle(color: Colors.black54, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerTierCard extends StatelessWidget {
  final String tier;
  final Color color;
  final List<String> bullets;
  const _PartnerTierCard({
    required this.tier,
    required this.color,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 720 ? width - 28 : 340.0;
    return SizedBox(
      width: cardWidth,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final bullet in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 8),
                        child: Icon(Icons.check_circle, size: 16, color: color),
                      ),
                      Expanded(
                        child: Text(
                          bullet,
                          style: const TextStyle(height: 1.45),
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

class _JourneyStepper extends StatelessWidget {
  final int step;
  final LocaleMode loc;

  const _JourneyStepper({required this.step, required this.loc});

  @override
  Widget build(BuildContext context) {
    final labels = [
      loc.tr('Choose package', 'Choisir le forfait', 'Elija paquete'),
      loc.tr('Pay with Stripe', 'Payer avec Stripe', 'Pague con Stripe'),
      loc.tr(
        'GitHub repo invite',
        'Invitation dépôt GitHub',
        'Invitación al repo de GitHub',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < labels.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: i <= step
                    ? _brandPrimary.withValues(alpha: i == step ? 0.12 : 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: i <= step
                      ? _brandPrimary.withValues(alpha: 0.24)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: i <= step ? _brandPrimary : Colors.black26,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i <= step ? _brandDark : Colors.black54,
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

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool success;

  const _StatusBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success
            ? _brandGreen.withValues(alpha: 0.10)
            : _brandPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: success
              ? _brandGreen.withValues(alpha: 0.24)
              : _brandPrimary.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: success ? _brandGreen : _brandPrimary,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 19 : 26,
                fontWeight: FontWeight.w900,
                color: _brandDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// Standalone /contact page — full contact form.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.findAncestorWidgetOfExactType<SiteShell>()!.locale;
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        _ContactFormSection(loc: loc),
        const SizedBox(height: 24),
      ],
    );
  }
}
