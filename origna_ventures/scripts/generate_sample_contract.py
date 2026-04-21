#!/usr/bin/env python3
"""Generate sample contract PDFs with full Ontario/Canada legal clauses and both-party signatures."""

from __future__ import annotations

import hashlib
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

import qrcode
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

COMPANY = "1001475263 ONTARIO CORPORATION"
BN = "708286364TZ0001"
SUPPORT_EMAIL = "support@orignaventures.ca"
SUPPORT_PHONE = "4167865517"
BASE_URL = "https://orignaventures.ca"
PROVIDER_REP = "Yunior Rodriguez Osorio"
PROVIDER_TITLE = "Founder"

SERVICE_CATALOG = {
    "origna_code": {
        "name_en": "OrignaCode",
        "name_fr": "OrignaCode",
        "price_cad": 500,
    },
    "origna_launch": {
        "name_en": "OrignaLaunch",
        "name_fr": "OrignaLaunch",
        "price_cad": 1000,
    },
    "origna_team": {
        "name_en": "OrignaTeam",
        "name_fr": "OrignaTeam",
        "price_cad": 1000,
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


class CornerCanvas:
    @staticmethod
    def draw_shamrock(canvas_obj, x, y, scale=1.0):
        canvas_obj.saveState()
        canvas_obj.setFillColor(colors.HexColor("#0C8A43"))
        r = 12 * scale
        for dx, dy in ((0, 0), (r * 0.7, r * 0.55), (r * 1.4, 0)):
            canvas_obj.circle(x + dx, y + dy, r, stroke=0, fill=1)
        canvas_obj.setStrokeColor(colors.HexColor("#0C8A43"))
        canvas_obj.setLineWidth(2 * scale)
        canvas_obj.line(x + r * 0.9, y - r * 0.3, x + r * 1.6, y - r * 2)
        canvas_obj.restoreState()

    @staticmethod
    def draw_moose(canvas_obj, x, y, scale=1.0):
        canvas_obj.saveState()
        canvas_obj.setFillColor(colors.HexColor("#5C3A21"))
        canvas_obj.ellipse(x, y, x + 38 * scale, y + 20 * scale, stroke=0, fill=1)
        canvas_obj.circle(x + 34 * scale, y + 16 * scale, 8 * scale, stroke=0, fill=1)
        canvas_obj.setStrokeColor(colors.HexColor("#5C3A21"))
        canvas_obj.setLineWidth(2 * scale)
        canvas_obj.line(x + 36 * scale, y + 26 * scale, x + 42 * scale, y + 36 * scale)
        canvas_obj.line(x + 42 * scale, y + 36 * scale, x + 48 * scale, y + 34 * scale)
        canvas_obj.line(x + 42 * scale, y + 36 * scale, x + 46 * scale, y + 42 * scale)
        canvas_obj.line(x + 30 * scale, y + 26 * scale, x + 24 * scale, y + 36 * scale)
        canvas_obj.line(x + 24 * scale, y + 36 * scale, x + 18 * scale, y + 34 * scale)
        canvas_obj.line(x + 24 * scale, y + 36 * scale, x + 20 * scale, y + 42 * scale)
        for leg_x in (x + 8 * scale, x + 18 * scale, x + 28 * scale):
            canvas_obj.line(leg_x, y, leg_x, y - 14 * scale)
        canvas_obj.restoreState()


def contract_copy(locale, service_code, client_name, client_company):
    service = SERVICE_CATALOG[service_code]
    launch = service_code == "origna_launch"
    code_only = service_code == "origna_code"
    team = service_code == "origna_team"
    tier_label_en = (
        "POPULAR \u2014 OrignaLaunch"
        if launch
        else ("TEAM \u2014 OrignaTeam" if team else "STARTER \u2014 OrignaCode")
    )
    tier_label_fr = (
        "POPULAIRE \u2014 OrignaLaunch"
        if launch
        else (
            "\u00c9QUIPE \u2014 OrignaTeam"
            if team
            else "D\u00c9BUTANT \u2014 OrignaCode"
        )
    )
    base_price = service["price_cad"]
    hst = round(base_price * 0.13)
    total_with_hst = base_price + hst
    price_en = (
        f"{base_price:,} CAD one-time + {hst:,} CAD HST (13%) = {total_with_hst:,} CAD total"
        if not team
        else f"{base_price:,} CAD/month + {hst:,} CAD HST (13%) = {total_with_hst:,} CAD/month total"
    )
    price_fr = (
        f"{base_price:,} CAD payable une fois + {hst:,} CAD TVH (13 %) = {total_with_hst:,} CAD total"
        if not team
        else f"{base_price:,} CAD/mois + {hst:,} CAD TVH (13 %) = {total_with_hst:,} CAD/mois total"
    )

    if locale == "fr":
        return {
            "title": "Contrat de services num\u00e9riques \u2014 Origna Ventures",
            "subtitle": f"Forfait : {tier_label_fr}",
            "body": [
                f"Entre {COMPANY} (NE {BN}), ci-apr\u00e8s \u00ab le Fournisseur \u00bb, et {client_company}, ci-apr\u00e8s \u00ab le Client \u00bb.",
                f"Forfait s\u00e9lectionn\u00e9 : {tier_label_fr}.",
                f"Prix : {price_fr}. Tous les montants sont en dollars canadiens (CAD).",
                "Paiement : via Stripe Checkout en dollars canadiens. Le paiement int\u00e9gral est requis avant le d\u00e9blocage du d\u00e9p\u00f4t ou la livraison.",
                "Le pr\u00e9sent contrat est conclu par voie \u00e9lectronique conform\u00e9ment \u00e0 la Loi sur le commerce \u00e9lectronique de l\u2019Ontario (2000) et sera ex\u00e9cutoire apr\u00e8s signature \u00e9lectronique et paiement compens\u00e9.",
                "Licence : usage personnel et commercial interne autoris\u00e9 ; revente commerciale du logiciel est interdite. Tous les droits de propri\u00e9t\u00e9 intellectuelle sur les personnalisations r\u00e9alis\u00e9es dans le cadre de ce contrat sont c\u00e9d\u00e9s au Client \u00e0 la livraison compl\u00e8te, sous r\u00e9serve du paiement int\u00e9gral.",
                "Le d\u00e9p\u00f4t GitHub/Bitbucket est d\u00e9bloqu\u00e9 seulement apr\u00e8s signature compl\u00e8te des deux parties et paiement confirm\u00e9.",
                "L\u2019historique du d\u00e9p\u00f4t livr\u00e9 au client est nettoy\u00e9 avant l\u2019invitation d\u2019acc\u00e8s.",
                "Annulation et remboursement : remboursement int\u00e9gral possible avant le d\u00e9blocage du d\u00e9p\u00f4t. Apr\u00e8s d\u00e9blocage, aucun remboursement automatique ne s\u2019applique. Les demandes de remboursement doivent \u00eatre envoy\u00e9es par \u00e9crit \u00e0 support@orignaventures.ca dans les 30 jours suivant la signature.",
                "Confidentialit\u00e9 : les deux parties s\u2019engagent \u00e0 maintenir la confidentialit\u00e9 des informations commerciales sensibles \u00e9chang\u00e9es dans le cadre de ce contrat pour une dur\u00e9e de deux ans suivant la r\u00e9solution.",
                "Protection des donn\u00e9es : les informations personnelles sont collect\u00e9es et trait\u00e9es conform\u00e9ment \u00e0 la LPRPDE (PIPEDA). Le Client peut demander l\u2019acc\u00e8s, la correction ou la suppression de ses donn\u00e9es en \u00e9crivant \u00e0 support@orignaventures.ca.",
                "Responsabilit\u00e9 : la responsabilit\u00e9 totale du Fournisseur est limit\u00e9e aux frais pay\u00e9s en vertu du pr\u00e9sent contrat. Le Fournisseur n\u2019est pas responsable des dommages indirects, accessoires ou cons\u00e9cutifs.",
                "Force majeure : aucune des parties ne sera responsable d\u2019un manquement r\u00e9sultant d\u2019\u00e9v\u00e9nements hors de son contr\u00f4le raisonnable.",
                "Notification de violation : en cas de violation du contrat, la partie l\u00e9s\u00e9e doit en aviser l\u2019autre partie par \u00e9crit dans les 14 jours, avec un d\u00e9lai de 30 jours pour rem\u00e9dier \u00e0 la violation.",
                "Modifications : toute modification du pr\u00e9sent contrat doit \u00eatre communiqu\u00e9e par \u00e9crit avec un pr\u00e9avis de 14 jours. Le Client peut r\u00e9silier sans p\u00e9nalit\u00e9 dans les 14 jours suivant l\u2019avis de modification.",
                "M\u00e9diation : en cas de litige, les parties conviennent de tenter une m\u00e9diation avant toute proc\u00e9dure judiciaire. Aucune clause d\u2019arbitrage forc\u00e9 n\u2019est impos\u00e9e aux consommateurs.",
                "Droit applicable et juridiction : les lois de la province de l\u2019Ontario, Canada, s\u2019appliquent. Les tribunaux de l\u2019Ontario ont juridiction exclusive.",
                "Consentement \u00e0 la signature \u00e9lectronique : en signant ce contrat par voie \u00e9lectronique, les parties consentent \u00e0 ce que le contrat soit conclu, sign\u00e9 et stock\u00e9 sous forme \u00e9lectronique conform\u00e9ment \u00e0 la Loi sur le commerce \u00e9lectronique de l\u2019Ontario (2000).",
            ]
            + (
                [
                    "Le forfait POPULAIRE (OrignaLaunch) inclut l\u2019h\u00e9bergement Hetzner 8 Go pour la premi\u00e8re ann\u00e9e.",
                    "L\u2019inscription Apple Developer pour la premi\u00e8re ann\u00e9e et l\u2019inscription Google Play sont incluses.",
                    "Le d\u00e9ploiement App Store / Google Play est inclus selon la port\u00e9e convenue.",
                    "Les personnalisations demand\u00e9es par le client sont incluses sans frais additionnels dans la port\u00e9e convenue.",
                    "Livraison estim\u00e9e : environ 1 \u00e0 2 semaines apr\u00e8s signature et paiement, selon la port\u00e9e.",
                    "Quatre semaines de support post-lancement sont incluses.",
                    "\u00c9l\u00e9ments factur\u00e9s s\u00e9par\u00e9ment au Client : h\u00e9bergement apr\u00e8s la premi\u00e8re ann\u00e9e, renouvellements Apple Developer/Google Play, frais de transaction Stripe, services Mailjet, nom de domaine, certificats SSL suppl\u00e9mentaires, toute personnalisation au-del\u00e0 de la port\u00e9e convenue, et tout autre service tiers requis par le Client.",
                ]
                if launch
                else []
            )
            + (
                [
                    "Le forfait D\u00c9BUTANT (OrignaCode) donne un acc\u00e8s \u00e0 vie au code source, aux mises \u00e0 jour du code source et au d\u00e9p\u00f4t priv\u00e9.",
                    "Le Client g\u00e8re lui-m\u00eame l\u2019h\u00e9bergement, le d\u00e9ploiement et l\u2019exploitation apr\u00e8s la remise.",
                    "\u00c9l\u00e9ments factur\u00e9s s\u00e9par\u00e9ment au Client : h\u00e9bergement, noms de domaine, certificats SSL, frais Apple Developer/Google Play, services Mailjet, frais de transaction Stripe, et tout autre service tiers requis par le Client.",
                ]
                if code_only
                else []
            )
            + (
                [
                    "Le forfait \u00c9QUIPE (OrignaTeam) inclut au moins un d\u00e9veloppeur assign\u00e9.",
                    "Le Client participe \u00e0 une r\u00e9union quotidienne avec le(s) d\u00e9veloppeur(s) assign\u00e9(s).",
                    "Le temps de travail peut \u00eatre suivi avec des outils de suivi standards choisis avec le Client.",
                    f"Tarif mensuel de base : {base_price:,} CAD / mois + TVH (13 %) selon la cadence et le p\u00e9rim\u00e8tre le plus complet.",
                    "Tests QA web/mobile : 100+ heures de tests QA par mois \u2014 factur\u00e9s s\u00e9par\u00e9ment au Client.",
                    "Les co\u00fbts Mailjet, Stripe, h\u00e9bergement, APIs tierces et tout autre service externe sont factur\u00e9s s\u00e9par\u00e9ment au Client.",
                    "Statut de travailleur ind\u00e9pendant : le d\u00e9veloppeur assign\u00e9 est un entrepreneur ind\u00e9pendant et non un employ\u00e9 du Client. Aucune clause de non-concurrence ne s\u2019applique aux employ\u00e9s conform\u00e9ment \u00e0 la Loi sur les travailleurs (Working for Workers Act, 2021) de l\u2019Ontario.",
                ]
                if team
                else []
            ),
        }

    return {
        "title": "Digital Services Agreement \u2014 Origna Ventures",
        "subtitle": f"Package: {tier_label_en}",
        "body": [
            f'Between {COMPANY} (BN {BN}), hereinafter "the Provider", and {client_company}, hereinafter "the Client".',
            f"Selected package: {tier_label_en}.",
            f"Price: {price_en}. All amounts are in Canadian dollars (CAD).",
            "Payment: via Stripe Checkout in Canadian dollars. Full payment is required before repository unlock or delivery.",
            "This agreement is entered into electronically in accordance with the Ontario Electronic Commerce Act, 2000, and becomes enforceable after electronic signature and cleared payment.",
            "License: personal and commercial internal use allowed; commercial software resale is prohibited. All intellectual property rights in customizations created under this agreement are assigned to the Client upon full delivery, subject to full payment.",
            "GitHub/Bitbucket repository access unlocks only after signature completion by both parties and confirmed payment.",
            "Repository history is deleted/cleaned before client invite is issued.",
            "Cancellation and refund: full refund is available before repository unlock. After unlock, no automatic refund applies. Refund requests must be submitted in writing to support@orignaventures.ca within 30 days of signing.",
            "Confidentiality: both parties agree to keep confidential any sensitive business information exchanged under this agreement for a period of two years following termination.",
            "Privacy: personal information is collected and processed in compliance with PIPEDA (Personal Information Protection and Electronic Documents Act). The Client may request access, correction, or deletion of their data by contacting support@orignaventures.ca.",
            "Limitation of liability: the Provider's total liability is limited to fees paid under this agreement. The Provider is not liable for indirect, incidental, or consequential damages.",
            "Force majeure: neither party shall be liable for failure resulting from events beyond its reasonable control.",
            "Breach notification: in the event of a breach, the aggrieved party must notify the other in writing within 14 days, with a 30-day cure period.",
            "Amendments: any amendment to this agreement must be communicated in writing with 14 days' notice. The Client may terminate without penalty within 14 days of the amendment notice.",
            "Dispute resolution: the parties agree to attempt mediation before any court proceedings. No forced arbitration clause is imposed on consumers.",
            "Governing law and jurisdiction: the laws of the Province of Ontario, Canada, apply. Ontario courts have exclusive jurisdiction.",
            "Electronic signature consent: by signing this agreement electronically, the parties consent to this agreement being concluded, signed, and stored electronically in accordance with the Ontario Electronic Commerce Act, 2000.",
        ]
        + (
            [
                "The POPULAR package (OrignaLaunch) includes Hetzner 8 GB hosting for Year 1.",
                "Apple Developer enrollment for Year 1 and Google Play registration are included.",
                "App Store and Google Play deployment are included based on the agreed scope.",
                "Client-requested customization is included within the agreed scope at no extra charge.",
                "Estimated delivery: about 1\u20132 weeks after signature and payment, subject to scope.",
                "Four weeks of post-launch support are included.",
                "Items billed separately to the Client: hosting after Year 1, Apple Developer/Google Play renewals, Stripe transaction fees, Mailjet services, domain name, additional SSL certificates, any customization beyond the agreed scope, and any other third-party service required by the Client.",
            ]
            if launch
            else []
        )
        + (
            [
                "The STARTER package (OrignaCode) provides lifetime source-code access, source updates, and private repository delivery.",
                "The Client self-hosts and self-operates after delivery.",
                "Items billed separately to the Client: hosting, domain names, SSL certificates, Apple Developer/Google Play fees, Mailjet services, Stripe transaction fees, and any other third-party service required by the Client.",
            ]
            if code_only
            else []
        )
        + (
            [
                "The TEAM package (OrignaTeam) includes at least one assigned developer.",
                "The Client participates in a daily meeting with assigned developer(s).",
                "Working time may be tracked with standard time-tracking tools agreed with the Client.",
                f"Base monthly rate: {base_price:,} CAD/month + HST (13%) for the fullest monthly scope.",
                "QA testing: 100+ hours of QA testing per month \u2014 billed separately to the Client.",
                "Mailjet, Stripe, hosting, third-party API costs, and any other external services are billed separately to the Client.",
                "Independent contractor status: the assigned developer is an independent contractor and not an employee of the Client. No non-compete clause applies to employees per the Ontario Working for Workers Act, 2021.",
            ]
            if team
            else []
        ),
    }


def generate(out_path: Path, service_code: str = "origna_launch"):
    service = SERVICE_CATALOG[service_code]
    client_name = "Sample Client Name"
    client_company = "Sample Client Corp."
    client_email = "client@example.com"
    github_username = "sampleuser"
    signer_title = "CEO"
    typed_signature = "Sample Client Name"
    contract_id = "SAMPLE-OV-20260419"
    digest = hashlib.sha256(b"sample-contract-content").hexdigest()

    text_en = contract_copy("en", service_code, client_name, client_company)
    text_fr = contract_copy("fr", service_code, client_name, client_company)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "title",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=22,
        leading=26,
        textColor=colors.HexColor("#CC0000"),
        spaceAfter=14,
    )
    body_style = ParagraphStyle(
        "body",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9.6,
        leading=13,
        textColor=colors.HexColor("#222222"),
        spaceAfter=6,
    )
    section_style = ParagraphStyle(
        "section",
        parent=styles["Heading3"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=14,
        textColor=colors.HexColor("#8B0000"),
        spaceBefore=4,
        spaceAfter=8,
    )
    small_style = ParagraphStyle(
        "small",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#555555"),
        spaceAfter=5,
    )
    label_style = ParagraphStyle(
        "label",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=11,
        textColor=colors.HexColor("#8B0000"),
        spaceAfter=3,
    )

    story: List[Any] = []
    base_price = service["price_cad"]
    hst = round(base_price * 0.13)
    total = base_price + hst
    price_label = (
        f"1,000 CAD one-time + {hst:,} CAD HST = {total:,} CAD total"
        if service_code == "origna_launch"
        else (
            f"1,000 CAD/month + {hst:,} CAD HST = {total:,} CAD/month"
            if service_code == "origna_team"
            else f"500 CAD one-time + {hst:,} CAD HST = {total:,} CAD total"
        )
    )
    summary_table = Table(
        [
            ["Client", client_name],
            ["Company", client_company],
            ["Service", service["name_en"]],
            ["Base Price", f"{base_price:,} CAD"],
            ["HST (13%)", f"{hst:,} CAD"],
            ["Total", f"{total:,} CAD"],
            ["Email", client_email],
            ["GitHub", github_username],
        ],
        colWidths=[1.25 * inch, 4.95 * inch],
    )
    summary_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FFF7F7")),
                ("BOX", (0, 0), (-1, -1), 0.6, colors.HexColor("#D9B0B0")),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E6D4D4")),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#8B0000")),
                ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
                ("PADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )

    story.append(
        Paragraph(
            "Digital Services Agreement / Contrat de services num\u00e9riques",
            title_style,
        )
    )
    story.append(
        Paragraph(f"{text_en['subtitle']} / {text_fr['subtitle']}", body_style)
    )
    story.append(summary_table)
    story.append(Spacer(1, 12))
    story.append(Paragraph("Signature flow / Flux de signature", section_style))
    story.append(
        Paragraph(
            "Electronic signature and cleared payment are both required before private repository unlock, source delivery, or deployment handoff. / La signature \u00e9lectronique et le paiement compens\u00e9 sont tous deux requis avant le d\u00e9blocage du d\u00e9p\u00f4t priv\u00e9, la remise du code source ou le transfert de d\u00e9ploiement.",
            body_style,
        )
    )
    story.append(Paragraph("English terms", section_style))
    for line in text_en["body"]:
        story.append(Paragraph(f"\u2022 {line}", body_style))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Conditions en fran\u00e7ais", section_style))
    for line in text_fr["body"]:
        story.append(Paragraph(f"\u2022 {line}", body_style))
    story.append(Spacer(1, 10))
    story.append(
        Paragraph(
            "Electronic signature audit trail / Journal de signature \u00e9lectronique",
            section_style,
        )
    )
    audit_table = Table(
        [
            ["Contract ID", contract_id],
            ["Signed at", utc_now()],
            ["Signer", client_name],
            ["Title", signer_title],
            ["Typed signature", typed_signature],
            ["Consent version", "2026-04-19"],
            ["Document SHA-256", digest],
        ],
        colWidths=[1.8 * inch, 4.8 * inch],
    )
    audit_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F7F7F7")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#8B0000")),
                ("PADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story.append(audit_table)
    story.append(Spacer(1, 10))
    story.append(Paragraph("Signatures / Signatures", section_style))
    story.append(Spacer(1, 8))
    story.append(Paragraph("<b>CLIENT / CLIENT</b>", label_style))
    story.append(Paragraph(f"Name / Nom: {client_name}", body_style))
    story.append(Paragraph(f"Title / Titre: {signer_title}", body_style))
    story.append(Paragraph(f"Company / Entreprise: {client_company}", body_style))
    story.append(Paragraph(f"Email: {client_email}", body_style))
    story.append(
        Paragraph(
            f"Electronic signature / Signature \u00e9lectronique: {typed_signature}",
            body_style,
        )
    )
    story.append(Paragraph(f"Date: {utc_now()}", body_style))
    story.append(Spacer(1, 16))
    story.append(Paragraph("<b>PROVIDER / FOURNISSEUR</b>", label_style))
    story.append(Paragraph(f"{COMPANY} (BN {BN})", body_style))
    story.append(
        Paragraph(
            f"Authorized representative / Repr\u00e9sentant autoris\u00e9: {PROVIDER_REP}, {PROVIDER_TITLE}",
            body_style,
        )
    )
    story.append(Paragraph(f"Email: {SUPPORT_EMAIL}", body_style))
    story.append(
        Paragraph(
            f"Electronic signature / Signature \u00e9lectronique: {PROVIDER_REP}",
            body_style,
        )
    )
    story.append(Paragraph(f"Date: {utc_now()}", body_style))
    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            f"Support: {SUPPORT_EMAIL} \u00b7 SMS: {SUPPORT_PHONE} \u00b7 {BASE_URL}",
            small_style,
        )
    )

    def decorate(canvas_obj, doc):
        width, height = A4
        canvas_obj.saveState()
        canvas_obj.setFillColor(colors.HexColor("#CC0000"))
        canvas_obj.rect(0, height - 34, width, 34, stroke=0, fill=1)
        canvas_obj.setFillColor(colors.white)
        canvas_obj.setFont("Helvetica-Bold", 11.5)
        canvas_obj.drawString(36, height - 21, COMPANY)
        canvas_obj.setFont("Helvetica", 7.5)
        canvas_obj.drawRightString(
            width - 36, height - 21, f"{service['name_en']} \u00b7 {contract_id}"
        )
        canvas_obj.setStrokeColor(colors.HexColor("#E7B9B9"))
        canvas_obj.setLineWidth(0.6)
        canvas_obj.line(36, height - 40, width - 36, height - 40)
        canvas_obj.setFillColor(colors.HexColor("#555555"))
        canvas_obj.setFont("Helvetica", 7.5)
        canvas_obj.drawString(
            36, 20, f"{SUPPORT_EMAIL} \u00b7 {SUPPORT_PHONE} \u00b7 {BASE_URL}"
        )
        canvas_obj.drawRightString(width - 36, 20, f"Page {doc.page}")
        CornerCanvas.draw_shamrock(canvas_obj, 36, 42, 0.75)
        CornerCanvas.draw_moose(canvas_obj, width - 82, 34, 0.75)
        canvas_obj.restoreState()

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=54,
        bottomMargin=34,
    )
    doc.build(story, onFirstPage=decorate, onLaterPages=decorate)
    print(f"Generated: {out_path} ({out_path.stat().st_size:,} bytes)")


if __name__ == "__main__":
    desktop = Path("~/Desktop").expanduser()
    svc = sys.argv[1] if len(sys.argv) > 1 else "all"
    if svc == "all":
        for code in ("origna_code", "origna_launch", "origna_team"):
            out = desktop / f"contract_{code}.pdf"
            generate(out, code)
    else:
        out = desktop / f"contract_{svc}.pdf"
        generate(out, svc)
