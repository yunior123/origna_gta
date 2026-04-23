import 'package:flutter/material.dart';
import 'package:origna_ventures/theme_config.dart';

enum TierId { orignaCode, orignaLaunch, orignaTeam }

class TierDefinition {
  final TierId tierId;
  final String name;
  final int priceCents;
  final bool isSubscription;
  final Color color;
  final Color colorLight;
  final String serviceCode;
  final ({String en, String fr, String es}) tagline;
  final ({String en, String fr, String es}) tierLabel;
  final ({List<String> en, List<String> fr, List<String> es}) bullets;

  const TierDefinition({
    required this.tierId,
    required this.name,
    required this.priceCents,
    required this.isSubscription,
    required this.color,
    this.colorLight = const Color(0xFFE0E7FF),
    required this.serviceCode,
    required this.tagline,
    required this.tierLabel,
    required this.bullets,
  });

  String displayPrice() {
    final dollars = priceCents ~/ 100;
    return dollars >= 1000
        ? '${dollars ~/ 1000},${(dollars % 1000).toString().padLeft(3, '0')}'
        : dollars.toString();
  }

  bool get isPopular => tierId == TierId.orignaLaunch;

  static const tiers = <TierDefinition>[
    TierDefinition(
      tierId: TierId.orignaCode,
      name: 'OrignaCode',
      priceCents: 50000,
      isSubscription: false,
      color: ThemeConfig.primary,
      colorLight: Color(0xFFE0E7FF),
      serviceCode: 'origna_code',
      tierLabel: (
        en: 'SOURCE LICENSE',
        fr: 'LICENCE SOURCE',
        es: 'LICENCIA SOURCE'
      ),
      tagline: (
        en: 'Acquire the stack, the brand system, and the delivery playbook.',
        fr: 'Obtenez la stack, le systeme de marque et le playbook de livraison.',
        es: 'Obtenga la stack, el sistema de marca y el playbook de entrega.',
      ),
      bullets: (
        en: [
          'Full Flutter + Rust + PostgreSQL codebase ownership',
          'Private GitHub or Bitbucket repository access',
          'Brand assets, pricing structure, and launch checklist included',
          'Deploy on your own infrastructure with no recurring platform fee',
          'Commercial license (no software reselling)',
          'Full refund before repo unlock',
        ],
        fr: [
          'Propriete complete du code Flutter + Rust + PostgreSQL',
          'Acces au depot GitHub ou Bitbucket prive',
          'Assets de marque, structure tarifaire et checklist de lancement inclus',
          'Deploiement sur votre propre infrastructure sans frais plateforme recurrents',
          'Licence commerciale (revente interdite)',
          'Remboursement complet avant deverrouillage du depot',
        ],
        es: [
          'Propiedad completa del codigo Flutter + Rust + PostgreSQL',
          'Acceso al repositorio privado GitHub o Bitbucket',
          'Assets de marca, estructura de precios y checklist de lanzamiento incluidos',
          'Despliegue en su propia infraestructura sin tarifa recurrente de plataforma',
          'Licencia comercial (no reventa de software)',
          'Reembolso completo antes del desbloqueo del repositorio',
        ],
      ),
    ),
    TierDefinition(
      tierId: TierId.orignaLaunch,
      name: 'OrignaLaunch',
      priceCents: 300000,
      isSubscription: false,
      color: ThemeConfig.secondary,
      colorLight: Color(0xFFEDE9FE),
      serviceCode: 'origna_launch',
      tierLabel: (
        en: 'FULL LAUNCH',
        fr: 'LANCEMENT COMPLET',
        es: 'LANZAMIENTO COMPLETO'
      ),
      tagline: (
        en: 'The done-for-you operator package for premium launches.',
        fr: 'Le forfait opere pour vous pour un lancement premium.',
        es: 'El paquete operado por nosotros para lanzamientos premium.',
      ),
      bullets: (
        en: [
          'Everything in OrignaCode included',
          'Hetzner VPS hosting (8 GB RAM + 80 GB disk) for year 1',
          'App Store, Play Store, web, and desktop launch handling',
          '20 human testers with a 20-hour QA pass',
          'Payments, analytics, and launch-day checklist configured',
          '4 weeks of post-launch support',
          'Target go-live in about 1-2 weeks',
        ],
        fr: [
          "Tout d'OrignaCode inclus",
          'Serveur VPS Hetzner (8 Go RAM + 80 Go disque) pour la premiere annee',
          'Prise en charge App Store, Play Store, web et desktop',
          '20 testeurs humains avec un passage QA de 20 h',
          'Paiements, analytique et checklist de lancement configures',
          '4 semaines de support apres lancement',
          'Mise en ligne cible en 1 a 2 semaines',
        ],
        es: [
          'Todo de OrignaCode incluido',
          'Alojamiento VPS Hetzner (8 GB RAM + 80 GB de disco) para el ano 1',
          'Gestion de lanzamiento para App Store, Play Store, web y escritorio',
          '20 testers humanos con una pasada QA de 20 h',
          'Pagos, analitica y checklist de lanzamiento configurados',
          '4 semanas de soporte despues del lanzamiento',
          'Objetivo de salida en vivo en 1 a 2 semanas',
        ],
      ),
    ),
    TierDefinition(
      tierId: TierId.orignaTeam,
      name: 'OrignaTeam',
      priceCents: 100000,
      isSubscription: true,
      color: ThemeConfig.accent,
      colorLight: Color(0xFFCFFAFE),
      serviceCode: 'origna_team',
      tierLabel: (
        en: 'DEDICATED TEAM',
        fr: 'EQUIPE DEDIEE',
        es: 'EQUIPO DEDICADO'
      ),
      tagline: (
        en: 'A retained product team for iterative work after launch, from 1 to 20 developers.',
        fr: 'Une equipe produit retenue pour iterer apres le lancement, de 1 a 20 developpeurs.',
        es: 'Un equipo de producto retenido para iterar despues del lanzamiento, de 1 a 20 desarrolladores.',
      ),
      bullets: (
        en: [
          'Monthly subscription from 1 to 20 retained developers on your roadmap',
          'Daily standup and weekly planning cadence',
          'Ecommerce, apps, web, mobile, and desktop support',
          '100+ hours of QA testing coverage per month',
          'Starts within 48 h',
          'Third-party API, hosting, and ad spend billed separately',
        ],
        fr: [
          'Abonnement mensuel de 1 a 20 developpeurs dedies a votre roadmap',
          'Standup quotidien et cadence hebdomadaire de planification',
          'Ecommerce, apps, web, mobile et desktop',
          '100+ heures de tests QA par mois',
          'Demarrage sous 48 h',
          'API tiers, hebergement et depenses publicitaires factures separement',
        ],
        es: [
          'Suscripcion mensual de 1 a 20 desarrolladores retenidos en su roadmap',
          'Standup diario y ritmo semanal de planificacion',
          'Comercio electronico, apps, web, movil y escritorio',
          '100+ horas de cobertura de pruebas QA por mes',
          'Inicio dentro de 48 h',
          'API de terceros, alojamiento y gasto publicitario facturados por separado',
        ],
      ),
    ),
  ];

  static TierDefinition byId(TierId id) =>
      tiers.firstWhere((t) => t.tierId == id);

  static TierDefinition byServiceCode(String code) =>
      tiers.firstWhere((t) => t.serviceCode == code);
}
