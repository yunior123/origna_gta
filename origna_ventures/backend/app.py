from __future__ import annotations

import hashlib
import hmac
import html
import io
import json
import os
import re
import secrets
import sqlite3
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

import qrcode
import requests
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, EmailStr, Field
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


@dataclass
class Settings:
    base_url: str = os.getenv(
        "ORIGNA_VENTURES_BASE_URL", "https://www.orignaventures.ca"
    )
    api_base_url: str = os.getenv(
        "ORIGNA_VENTURES_API_BASE_URL", "https://api.orignagta.ca/ventures"
    )
    cors_allowed_origins: str = os.getenv(
        "ORIGNA_CORS_ALLOWED_ORIGINS",
        "https://orignaventures.ca,https://www.orignaventures.ca,https://origna-ventures.web.app,http://localhost:3000,http://localhost:5000,http://localhost:8080",
    )
    support_email: str = os.getenv("ORIGNA_SUPPORT_EMAIL", "support@orignaventures.ca")
    support_phone: str = os.getenv("ORIGNA_SUPPORT_PHONE", "4167865517")
    company_legal_name: str = os.getenv(
        "ORIGNA_COMPANY_LEGAL_NAME", "1001475263 ONTARIO CORPORATION"
    )
    company_bn: str = os.getenv("ORIGNA_COMPANY_BN", "708286364TZ0001")
    sqlite_path: str = os.getenv("ORIGNA_SQLITE_PATH", "./storage/origna_ventures.db")
    storage_dir: str = os.getenv("ORIGNA_STORAGE_DIR", "./storage")
    stripe_secret_key: str = os.getenv("ORIGNA_STRIPE_SECRET_KEY", "")
    stripe_webhook_secret: str = os.getenv("ORIGNA_STRIPE_WEBHOOK_SECRET", "")
    stripe_success_url: str = os.getenv(
        "ORIGNA_STRIPE_SUCCESS_URL", "https://orignaventures.ca/pay?status=success"
    )
    stripe_cancel_url: str = os.getenv(
        "ORIGNA_STRIPE_CANCEL_URL", "https://orignaventures.ca/pay?status=cancelled"
    )
    environment: str = os.getenv("ENVIRONMENT", "dev")
    mailjet_api_key: str = os.getenv("ORIGNA_MAILJET_API_KEY", "")
    mailjet_secret_key: str = os.getenv("ORIGNA_MAILJET_SECRET_KEY", "")
    mailjet_api_url: str = os.getenv(
        "ORIGNA_MAILJET_API_URL", "https://api.mailjet.com/v3.1/send"
    )
    mailjet_from_email: str = os.getenv(
        "ORIGNA_MAILJET_FROM_EMAIL", "support@orignaventures.ca"
    )
    mailjet_from_name: str = os.getenv(
        "ORIGNA_MAILJET_FROM_NAME", "Origna Ventures Services"
    )
    github_token: str = os.getenv("ORIGNA_GITHUB_TOKEN", "")
    github_org: str = os.getenv("ORIGNA_GITHUB_ORG", "")
    github_template_repo: str = os.getenv("ORIGNA_GITHUB_TEMPLATE_REPO", "")
    github_permission: str = os.getenv("ORIGNA_GITHUB_PERMISSION", "pull")


settings = Settings()
Path(settings.storage_dir).mkdir(parents=True, exist_ok=True)
Path(settings.sqlite_path).parent.mkdir(parents=True, exist_ok=True)

SERVICE_CATALOG = {
    "origna_code": {
        "name_en": "OrignaCode",
        "name_fr": "OrignaCode",
        "price_cad": 500,
        "summary_en": "Lifetime source-code access with updates.",
        "summary_fr": "Accès à vie au code source avec mises à jour.",
    },
    "origna_launch": {
        "name_en": "OrignaLaunch",
        "name_fr": "OrignaLaunch",
        "price_cad": 3000,
        "summary_en": "Lifetime software access + launch + first-year hosting + first-year store enrollment + 20 human testers (20h QA).",
        "summary_fr": "Accès logiciel à vie + lancement + hébergement première année + inscription boutique première année + 20 testeurs humains (20h QA).",
    },
    "origna_team": {
        "name_en": "OrignaTeam",
        "name_fr": "OrignaTeam",
        "price_cad": 1000,
        "summary_en": "Dedicated developer outsourcing at up to 1,000 CAD/month with optional tracked time and separate third-party costs.",
        "summary_fr": "Externalisation avec développeur dédié jusqu’à 1 000 CAD/mois avec suivi du temps optionnel et coûts tiers séparés.",
    },
}


class SignContractRequest(BaseModel):
    service_code: str = Field(pattern="^(origna_code|origna_launch|origna_team)$")
    locale: str = Field(default="en", pattern="^(en|fr)$")
    client_name: str = Field(min_length=2, max_length=120)
    client_email: EmailStr
    client_company: str = Field(min_length=2, max_length=160)
    client_phone: str = Field(min_length=7, max_length=30)
    client_address: str = Field(min_length=5, max_length=240)
    signer_full_name: str = Field(min_length=2, max_length=120)
    signer_title: str = Field(min_length=2, max_length=120)
    github_username: Optional[str] = Field(default=None, max_length=120)
    bitbucket_username: Optional[str] = Field(default=None, max_length=120)
    referral_code: Optional[str] = Field(default=None, max_length=64)
    typed_signature: str = Field(min_length=2, max_length=160)
    consent_checked: bool
    consent_version: str = Field(default="2026-04-19")


class PaymentSessionRequest(BaseModel):
    contract_id: str = Field(default="")
    payer_email: EmailStr
    payment_provider: str = Field(default="stripe", pattern="^(stripe)$")
    service_code: str = Field(
        default="", pattern="^(|origna_code|origna_launch|origna_team)$"
    )


class ContactFormRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    company: str = Field(default="", max_length=160)
    service: str = Field(default="general", max_length=40)
    message: str = Field(min_length=10, max_length=2000)


class EmailTestRequest(BaseModel):
    to_email: EmailStr
    subject: str = Field(default="Origna Ventures test email")
    body: str = Field(default="Mailjet integration test.")


app = FastAPI(title="Origna Ventures Payment API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip()
        for origin in settings.cors_allowed_origins.split(",")
        if origin.strip()
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Stripe-Signature"],
)

_USERNAME_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$")
_REFERRAL_RE = re.compile(r"^[A-Za-z0-9_-]{0,64}$")
_MAX_USER_AGENT_LENGTH = 512
_STRIPE_SIGNATURE_TOLERANCE_SECONDS = 300
_RATE_LIMITS: Dict[str, List[float]] = {}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(settings.sqlite_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    conn = db()
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS contracts (
            id TEXT PRIMARY KEY,
            service_code TEXT NOT NULL,
            locale TEXT NOT NULL,
            client_name TEXT NOT NULL,
            client_email TEXT NOT NULL,
            client_company TEXT NOT NULL,
            client_phone TEXT NOT NULL,
            client_address TEXT NOT NULL,
            signer_full_name TEXT NOT NULL,
            signer_title TEXT NOT NULL,
            github_username TEXT,
            bitbucket_username TEXT,
            referral_code TEXT,
            typed_signature TEXT NOT NULL,
            consent_checked INTEGER NOT NULL,
            consent_version TEXT NOT NULL,
            signer_ip TEXT NOT NULL,
            user_agent TEXT NOT NULL,
            document_sha256 TEXT NOT NULL,
            pdf_path TEXT NOT NULL,
            status TEXT NOT NULL,
            stripe_session_id TEXT,
            stripe_payment_status TEXT,
            payer_email TEXT,
            provider TEXT,
            repo_unlock_status TEXT,
            repo_unlock_error TEXT,
            github_invitation_id TEXT,
            created_at TEXT NOT NULL,
            signed_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS audit_events (
            id TEXT PRIMARY KEY,
            contract_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            ip_address TEXT NOT NULL,
            user_agent TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS webhook_events (
            id TEXT PRIMARY KEY,
            event_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        );
        """
    )
    conn.commit()
    existing = {
        row["name"] for row in conn.execute("PRAGMA table_info(contracts)").fetchall()
    }
    for column, ddl in [
        ("payer_email", "ALTER TABLE contracts ADD COLUMN payer_email TEXT"),
        (
            "repo_unlock_status",
            "ALTER TABLE contracts ADD COLUMN repo_unlock_status TEXT",
        ),
        (
            "repo_unlock_error",
            "ALTER TABLE contracts ADD COLUMN repo_unlock_error TEXT",
        ),
        (
            "github_invitation_id",
            "ALTER TABLE contracts ADD COLUMN github_invitation_id TEXT",
        ),
    ]:
        if column not in existing:
            conn.execute(ddl)
    conn.close()


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.post("/api/contact")
def submit_contact(payload: ContactFormRequest, request: Request) -> Dict[str, Any]:
    enforce_rate_limit(f"contact:{client_ip(request)}", limit=5, window_seconds=300)
    safe_name = html_escape(payload.name)
    safe_email = html_escape(payload.email)
    safe_company = html_escape(payload.company)
    safe_service = html_escape(payload.service)
    safe_message = html_escape(payload.message)
    subject = f"Contact form: {safe_service} — {safe_name}"
    html_body = (
        f"<h2>New contact form submission</h2>"
        f"<p><b>Name:</b> {safe_name}</p>"
        f"<p><b>Email:</b> {safe_email}</p>"
        f"<p><b>Company:</b> {safe_company or 'N/A'}</p>"
        f"<p><b>Service:</b> {safe_service}</p>"
        f"<p><b>Message:</b></p><p>{safe_message}</p>"
        f"<hr><p><small>IP: {client_ip(request)} · Time: {utc_now()}</small></p>"
    )
    text_body = (
        f"Name: {safe_name}\nEmail: {safe_email}\nCompany: {safe_company or 'N/A'}\n"
        f"Service: {safe_service}\nMessage: {safe_message}\nIP: {client_ip(request)}"
    )
    if settings.mailjet_api_key and settings.mailjet_secret_key:
        try:
            send_mailjet_email(settings.support_email, subject, html_body, text_body)
        except Exception:
            pass
    conn = db()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS contacts (id TEXT PRIMARY KEY, name TEXT, email TEXT, company TEXT, service TEXT, message TEXT, ip TEXT, created_at TEXT)",
    )
    contact_id = f"ct-{secrets.token_hex(8)}"
    conn.execute(
        "INSERT INTO contacts (id, name, email, company, service, message, ip, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            contact_id,
            payload.name,
            payload.email,
            payload.company,
            payload.service,
            payload.message,
            client_ip(request),
            utc_now(),
        ),
    )
    conn.commit()
    conn.close()
    return {"status": "ok", "id": contact_id}


@app.get("/health")
@app.get("/api/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/api/meta")
def meta() -> Dict[str, Any]:
    return {
        "company": settings.company_legal_name,
        "bn": settings.company_bn,
        "supportEmail": settings.support_email,
        "supportPhone": settings.support_phone,
        "services": SERVICE_CATALOG,
    }


def client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()[:64]
    return (request.client.host if request.client else "unknown")[:64]


def normalize_optional_username(value: Optional[str], field_name: str) -> Optional[str]:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if not _USERNAME_RE.fullmatch(normalized):
        raise HTTPException(status_code=400, detail=f"Invalid {field_name}")
    return normalized


def normalize_optional_referral(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if not _REFERRAL_RE.fullmatch(normalized):
        raise HTTPException(status_code=400, detail="Invalid referral_code")
    return normalized


def sanitize_user_agent(value: str) -> str:
    return value.strip()[:_MAX_USER_AGENT_LENGTH] or "unknown"


def enforce_rate_limit(key: str, limit: int, window_seconds: int) -> None:
    now = time.time()
    window_start = now - window_seconds
    bucket = [
        timestamp
        for timestamp in _RATE_LIMITS.get(key, [])
        if timestamp >= window_start
    ]
    if len(bucket) >= limit:
        raise HTTPException(status_code=429, detail="Too many requests")
    bucket.append(now)
    _RATE_LIMITS[key] = bucket


def html_escape(value: str) -> str:
    return html.escape(value, quote=True)


def build_contract_digest(payload: Dict[str, Any]) -> str:
    canonical = json.dumps(payload, sort_keys=True, ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


class CornerCanvas:
    @staticmethod
    def draw_shamrock(canvas_obj, x: float, y: float, scale: float = 1.0) -> None:
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
    def draw_moose(canvas_obj, x: float, y: float, scale: float = 1.0) -> None:
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


def make_qr_image(url: str):
    qr = qrcode.QRCode(box_size=8, border=1)
    qr.add_data(url)
    qr.make(fit=True)
    return qr.make_image(fill_color="black", back_color="white")


def contract_copy(locale: str, payload: SignContractRequest) -> Dict[str, Any]:
    service = SERVICE_CATALOG[payload.service_code]
    launch = payload.service_code == "origna_launch"
    code_only = payload.service_code == "origna_code"
    team = payload.service_code == "origna_team"
    tier_label_en = (
        "POPULAR — OrignaLaunch"
        if launch
        else ("TEAM — OrignaTeam" if team else "STARTER — OrignaCode")
    )
    tier_label_fr = (
        "POPULAIRE — OrignaLaunch"
        if launch
        else ("ÉQUIPE — OrignaTeam" if team else "DÉBUTANT — OrignaCode")
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
            "title": "Contrat de services numériques — Origna Ventures",
            "subtitle": f"Forfait : {tier_label_fr}",
            "body": [
                f"Entre {settings.company_legal_name} (NE {settings.company_bn}), ci-après « le Fournisseur », et {payload.client_company}, ci-après « le Client ».",
                f"Forfait sélectionné : {tier_label_fr}.",
                f"Prix : {price_fr}. Tous les montants sont en dollars canadiens (CAD).",
                "Paiement : via Stripe Checkout en dollars canadiens. Le paiement intégral est requis avant le déblocage du dépôt ou la livraison.",
                "Le présent contrat est conclu par voie électronique conformément à la Loi sur le commerce électronique de l'Ontario (2000) et sera exécutoire après signature électronique et paiement compensé.",
                "Licence : usage personnel et commercial interne autorisé ; revente commerciale du logiciel est interdite. Tous les droits de propriété intellectuelle sur les personnalisations réalisées dans le cadre de ce contrat sont cédés au Client à la livraison complète, sous réserve du paiement intégral.",
                "Le dépôt GitHub/Bitbucket est débloqué seulement après signature complète des deux parties et paiement confirmé.",
                "L'historique du dépôt livré au client est nettoyé avant l'invitation d'accès.",
                "Annulation et remboursement : remboursement intégral possible avant le déblocage du dépôt. Après déblocage, aucun remboursement automatique ne s'applique. Les demandes de remboursement doivent être envoyées par écrit à support@orignaventures.ca dans les 30 jours suivant la signature.",
                "Confidentialité : les deux parties s'engagent à maintenir la confidentialité des informations commerciales sensibles échangées dans le cadre de ce contrat pour une durée de deux ans suivant la résolution.",
                "Protection des données : les informations personnelles sont collectées et traitées conformément à la LPRPDE (PIPEDA). Le Client peut demander l'accès, la correction ou la suppression de ses données en écrivant à support@orignaventures.ca.",
                "Responsabilité : la responsabilité totale du Fournisseur est limitée aux frais payés en vertu du présent contrat. Le Fournisseur n'est pas responsable des dommages indirects, accessoires ou consécutifs.",
                "Force majeure : aucune des parties ne sera responsable d'un manquement résultant d'événements hors de son contrôle raisonnable.",
                "Notification de violation : en cas de violation du contrat, la partie lésée doit en aviser l'autre partie par écrit dans les 14 jours, avec un délai de 30 jours pour remédier à la violation.",
                "Modifications : toute modification du présent contrat doit être communiquée par écrit avec un préavis de 14 jours. Le Client peut résilier sans pénalité dans les 14 jours suivant l'avis de modification.",
                "Médiation : en cas de litige, les parties conviennent de tenter une médiation avant toute procédure judiciaire. Aucune clause d'arbitrage forcé n'est imposée aux consommateurs.",
                "Droit applicable et juridiction : les lois de la province de l'Ontario, Canada, s'appliquent. Les tribunaux de l'Ontario ont juridiction exclusive.",
                "Consentement à la signature électronique : en signant ce contrat par voie électronique, les parties consentent à ce que le contrat soit conclu, signé et stocké sous forme électronique conformément à la Loi sur le commerce électronique de l'Ontario (2000).",
            ]
            + (
                [
                    "Le forfait POPULAIRE (OrignaLaunch) inclut l'hébergement Hetzner 8 Go pour la première année.",
                    "L'inscription Apple Developer pour la première année et l'inscription Google Play sont incluses.",
                    "Le déploiement App Store / Google Play est inclus selon la portée convenue.",
                    "Les personnalisations demandées par le client sont incluses sans frais additionnels dans la portée convenue.",
                    "Livraison estimée : environ 1 à 2 semaines après signature et paiement, selon la portée.",
                    "Quatre semaines de support post-lancement sont incluses.",
                    "Éléments facturés séparément au Client : hébergement après la première année, renouvellements Apple Developer/Google Play, frais de transaction Stripe, services Mailjet, nom de domaine, certificats SSL supplémentaires, toute personnalisation au-delà de la portée convenue, et tout autre service tiers requis par le Client.",
                ]
                if launch
                else []
            )
            + (
                [
                    "Le forfait DÉBUTANT (OrignaCode) donne un accès à vie au code source, aux mises à jour du code source et au dépôt privé.",
                    "Le Client gère lui-même l'hébergement, le déploiement et l'exploitation après la remise.",
                    "Éléments facturés séparément au Client : hébergement, noms de domaine, certificats SSL, frais Apple Developer/Google Play, services Mailjet, frais de transaction Stripe, et tout autre service tiers requis par le Client.",
                ]
                if code_only
                else []
            )
            + (
                [
                    "Le forfait ÉQUIPE (OrignaTeam) inclut au moins un développeur assigné.",
                    "Le Client participe à une réunion quotidienne avec le(s) développeur(s) assigné(s).",
                    "Le temps de travail peut être suivi avec des outils de suivi standards choisis avec le Client.",
                    f"Tarif mensuel de base : {base_price:,} CAD / mois + TVH (13 %) selon la cadence et le périmètre le plus complet.",
                    "Tests QA web/mobile : 100+ heures de tests QA par mois — facturés séparément au Client.",
                    "Les coûts Mailjet, Stripe, hébergement, APIs tierces et tout autre service externe sont facturés séparément au Client.",
                    "Statut de travailleur indépendant : le développeur assigné est un entrepreneur indépendant et non un employé du Client. Aucune clause de non-concurrence ne s'applique aux employés conformément à la Loi sur les travailleurs (Working for Workers Act, 2021) de l'Ontario.",
                ]
                if team
                else []
            ),
        }
    return {
        "title": "Digital Services Agreement — Origna Ventures",
        "subtitle": f"Package: {tier_label_en}",
        "body": [
            f'Between {settings.company_legal_name} (BN {settings.company_bn}), hereinafter "the Provider", and {payload.client_company}, hereinafter "the Client".',
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
                "Estimated delivery: about 1–2 weeks after signature and payment, subject to scope.",
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
                "QA testing: 100+ hours of QA testing per month — billed separately to the Client.",
                "Mailjet, Stripe, hosting, third-party API costs, and any other external services are billed separately to the Client.",
                "Independent contractor status: the assigned developer is an independent contractor and not an employee of the Client. No non-compete clause applies to employees per the Ontario Working for Workers Act, 2021.",
            ]
            if team
            else []
        ),
    }


def generate_contract_pdf(
    payload: SignContractRequest, contract_id: str, digest: str
) -> Path:
    text_en = contract_copy("en", payload)
    text_fr = contract_copy("fr", payload)
    out_path = Path(settings.storage_dir) / f"contract_{contract_id}.pdf"
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "title",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=22,
        textColor=colors.HexColor("#CC0000"),
        leading=26,
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
    service = SERVICE_CATALOG[payload.service_code]
    base_price = service["price_cad"]
    hst = round(base_price * 0.13)
    total = base_price + hst
    summary_table = Table(
        [
            ["Client", payload.client_name],
            ["Company", payload.client_company],
            ["Service", service["name_en"]],
            ["Base Price", f"{base_price:,} CAD"],
            ["HST (13%)", f"{hst:,} CAD"],
            ["Total", f"{total:,} CAD"],
            ["Email", payload.client_email],
            ["GitHub", payload.github_username or "Collected separately if needed"],
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
            "Digital Services Agreement / Contrat de services numériques", title_style
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
            "Electronic signature and cleared payment are both required before private repository unlock, source delivery, or deployment handoff. / La signature électronique et le paiement compensé sont tous deux requis avant le déblocage du dépôt privé, la remise du code source ou le transfert de déploiement.",
            body_style,
        )
    )
    story.append(Paragraph("English terms", section_style))
    for line in text_en["body"]:
        story.append(Paragraph(f"• {line}", body_style))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Conditions en français", section_style))
    for line in text_fr["body"]:
        story.append(Paragraph(f"• {line}", body_style))
    story.append(Spacer(1, 10))
    story.append(
        Paragraph(
            "Electronic signature audit trail / Journal de signature électronique",
            section_style,
        )
    )
    audit_table = Table(
        [
            ["Contract ID", contract_id],
            ["Signed at", utc_now()],
            ["Signer", payload.signer_full_name],
            ["Title", payload.signer_title],
            ["Typed signature", payload.typed_signature],
            ["Consent version", payload.consent_version],
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
    story.append(Paragraph(f"Name / Nom: {payload.signer_full_name}", body_style))
    story.append(Paragraph(f"Title / Titre: {payload.signer_title}", body_style))
    story.append(
        Paragraph(f"Company / Entreprise: {payload.client_company}", body_style)
    )
    story.append(Paragraph(f"Email: {payload.client_email}", body_style))
    story.append(
        Paragraph(
            f"Electronic signature / Signature électronique: {payload.typed_signature}",
            body_style,
        )
    )
    story.append(Paragraph(f"Date: {utc_now()}", body_style))
    story.append(Spacer(1, 16))
    story.append(Paragraph("<b>PROVIDER / FOURNISSEUR</b>", label_style))
    story.append(
        Paragraph(
            f"{settings.company_legal_name} (BN {settings.company_bn})", body_style
        )
    )
    story.append(
        Paragraph(
            "Authorized representative / Représentant autorisé: Yunior Rodriguez Osorio, Founder",
            body_style,
        )
    )
    story.append(Paragraph(f"Email: {settings.support_email}", body_style))
    story.append(
        Paragraph(
            "Electronic signature / Signature électronique: Yunior Rodriguez Osorio",
            body_style,
        )
    )
    story.append(Paragraph(f"Date: {utc_now()}", body_style))
    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            f"Support: {settings.support_email} · SMS: {settings.support_phone} · {settings.base_url}",
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
        canvas_obj.drawString(36, height - 21, settings.company_legal_name)
        canvas_obj.setFont("Helvetica", 7.5)
        canvas_obj.drawRightString(
            width - 36, height - 21, f"{service['name_en']} · {contract_id}"
        )
        canvas_obj.setStrokeColor(colors.HexColor("#E7B9B9"))
        canvas_obj.setLineWidth(0.6)
        canvas_obj.line(36, height - 40, width - 36, height - 40)
        canvas_obj.setFillColor(colors.HexColor("#555555"))
        canvas_obj.setFont("Helvetica", 7.5)
        canvas_obj.drawString(
            36,
            20,
            f"{settings.support_email} · {settings.support_phone} · {settings.base_url}",
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
    return out_path


def save_audit_event(
    contract_id: str, event_type: str, payload: Dict[str, Any], ip: str, user_agent: str
) -> None:
    conn = db()
    insert_audit_event(conn, contract_id, event_type, payload, ip, user_agent)
    conn.commit()
    conn.close()


def insert_audit_event(
    conn: sqlite3.Connection,
    contract_id: str,
    event_type: str,
    payload: Dict[str, Any],
    ip: str,
    user_agent: str,
) -> None:
    conn.execute(
        "INSERT INTO audit_events (id, contract_id, event_type, payload_json, ip_address, user_agent, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            secrets.token_hex(16),
            contract_id,
            event_type,
            json.dumps(payload, ensure_ascii=False),
            ip,
            user_agent,
            utc_now(),
        ),
    )


def send_mailjet_email(
    to_email: str, subject: str, html_body: str, text_body: str
) -> Dict[str, Any]:
    if not settings.mailjet_api_key or not settings.mailjet_secret_key:
        raise HTTPException(status_code=500, detail="Mailjet credentials missing")

    is_sandbox = settings.environment.lower() not in ["production", "prod"]

    response = requests.post(
        settings.mailjet_api_url,
        auth=(settings.mailjet_api_key, settings.mailjet_secret_key),
        json={
            "SandboxMode": is_sandbox,
            "Messages": [
                {
                    "From": {
                        "Email": settings.mailjet_from_email,
                        "Name": settings.mailjet_from_name,
                    },
                    "To": [{"Email": to_email}],
                    "Subject": subject,
                    "TextPart": text_body,
                    "HTMLPart": html_body,
                }
            ],
        },
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


def stripe_headers() -> Dict[str, str]:
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=500, detail="Stripe key missing")
    return {
        "Authorization": f"Bearer {settings.stripe_secret_key}",
        "Content-Type": "application/x-www-form-urlencoded",
    }


def github_repo_target() -> tuple[str, str]:
    repo = settings.github_template_repo.strip()
    if not repo:
        raise HTTPException(status_code=500, detail="GitHub target repo missing")
    if "/" in repo:
        owner, repo_name = repo.split("/", 1)
        return owner, repo_name
    if settings.github_org:
        return settings.github_org, repo
    raise HTTPException(status_code=500, detail="GitHub org missing for repo target")


def github_headers() -> Dict[str, str]:
    if not settings.github_token:
        raise HTTPException(status_code=500, detail="GitHub token missing")
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {settings.github_token}",
        "X-GitHub-Api-Version": "2026-03-10",
    }


def invite_github_collaborator(username: str) -> Dict[str, Any]:
    owner, repo_name = github_repo_target()
    response = requests.put(
        f"https://api.github.com/repos/{owner}/{repo_name}/collaborators/{username}",
        headers=github_headers(),
        json={"permission": settings.github_permission},
        timeout=30,
    )
    if response.status_code == 422:
        body = response.json()
        message = json.dumps(body)
        if "owner cannot be a collaborator" in message.lower():
            return {
                "status": "already_has_access",
                "permission": settings.github_permission,
            }
    if response.status_code not in (201, 204):
        detail = response.text[:500]
        raise HTTPException(
            status_code=502,
            detail=f"GitHub invite failed: {response.status_code} {detail}",
        )
    if response.status_code == 204:
        return {
            "status": "already_has_access",
            "permission": settings.github_permission,
        }
    return response.json()


def maybe_unlock_repo_after_payment(
    conn: sqlite3.Connection,
    contract_id: str,
    row: sqlite3.Row,
) -> None:
    service_code = row["service_code"]

    if service_code not in ("origna_code", "origna_launch"):
        conn.execute(
            "UPDATE contracts SET repo_unlock_status = ?, repo_unlock_error = ? WHERE id = ?",
            ("not_applicable", None, contract_id),
        )
        return

    # User explicitly requested manual processing instead of automatic invite via GitHub API
    conn.execute(
        "UPDATE contracts SET repo_unlock_status = ?, repo_unlock_error = ? WHERE id = ?",
        (
            "manual_processing_required",
            "Manual processing required for security.",
            contract_id,
        ),
    )


def create_checkout_session(contract: sqlite3.Row, payer_email: str) -> Dict[str, Any]:
    service = SERVICE_CATALOG[contract["service_code"]]
    base_cents = service["price_cad"] * 100
    hst_cents = round(service["price_cad"] * 0.13) * 100
    payload = {
        "mode": "payment",
        "success_url": settings.stripe_success_url,
        "cancel_url": settings.stripe_cancel_url,
        "customer_email": payer_email,
        "submit_type": "pay",
        "billing_address_collection": "required",
        "payment_method_types[0]": "card",
        "payment_method_types[1]": "klarna",
        "line_items[0][price_data][currency]": "cad",
        "line_items[0][price_data][unit_amount]": str(base_cents),
        "line_items[0][price_data][product_data][name]": service["name_en"],
        "line_items[0][price_data][product_data][description]": "Service base price",
        "line_items[0][quantity]": "1",
        "line_items[1][price_data][currency]": "cad",
        "line_items[1][price_data][unit_amount]": str(hst_cents),
        "line_items[1][price_data][product_data][name]": "HST (13%)",
        "line_items[1][price_data][product_data][description]": "Ontario Harmonized Sales Tax",
        "line_items[1][quantity]": "1",
        "metadata[contract_id]": contract["id"],
        "metadata[service_code]": contract["service_code"],
        "metadata[client_email]": contract["client_email"],
    }
    response = requests.post(
        "https://api.stripe.com/v1/checkout/sessions",
        headers=stripe_headers(),
        data=payload,
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    conn = db()
    conn.execute(
        "UPDATE contracts SET stripe_session_id = ?, provider = ?, payer_email = ?, status = ? WHERE id = ?",
        (data.get("id"), "stripe", payer_email, "awaiting_payment", contract["id"]),
    )
    conn.commit()
    conn.close()
    return data


def create_checkout_session_from_service(
    service_code: str, service: dict, payer_email: str
) -> Dict[str, Any]:
    base_cents = service["price_cad"] * 100
    hst_cents = round(service["price_cad"] * 0.13) * 100
    mode = "subscription" if service_code == "origna_team" else "payment"
    payload = {
        "mode": mode,
        "success_url": settings.stripe_success_url,
        "cancel_url": settings.stripe_cancel_url,
        "customer_email": payer_email,
        "submit_type": "pay",
        "billing_address_collection": "required",
        "payment_method_types[0]": "card",
        "payment_method_types[1]": "klarna",
        "line_items[0][price_data][currency]": "cad",
        "line_items[0][price_data][unit_amount]": str(base_cents),
        "line_items[0][price_data][product_data][name]": service["name_en"],
        "line_items[0][price_data][product_data][description]": "Service base price",
        "line_items[0][quantity]": "1",
        "line_items[1][price_data][currency]": "cad",
        "line_items[1][price_data][unit_amount]": str(hst_cents),
        "line_items[1][price_data][product_data][name]": "HST (13%)",
        "line_items[1][price_data][product_data][description]": "Ontario Harmonized Sales Tax",
        "line_items[1][quantity]": "1",
        "metadata[service_code]": service_code,
        "metadata[client_email]": payer_email,
    }
    response = requests.post(
        "https://api.stripe.com/v1/checkout/sessions",
        headers=stripe_headers(),
        data=payload,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


@app.post("/api/contracts/sign")
async def sign_contract(
    payload: SignContractRequest, request: Request
) -> Dict[str, Any]:
    if not payload.consent_checked:
        raise HTTPException(status_code=400, detail="Consent checkbox is required")
    ip = client_ip(request)
    enforce_rate_limit(f"sign:{ip}", limit=10, window_seconds=300)
    contract_id = f"ovc_{secrets.token_hex(8)}"
    user_agent = sanitize_user_agent(request.headers.get("user-agent", "unknown"))
    github_username = normalize_optional_username(
        payload.github_username, "github_username"
    )
    bitbucket_username = normalize_optional_username(
        payload.bitbucket_username, "bitbucket_username"
    )
    referral_code = normalize_optional_referral(payload.referral_code)
    contract_payload = payload.model_dump()
    contract_payload["github_username"] = github_username
    contract_payload["bitbucket_username"] = bitbucket_username
    contract_payload["referral_code"] = referral_code
    contract_payload.update(
        {"ip": ip, "user_agent": user_agent, "signed_at": utc_now()}
    )
    digest = build_contract_digest(contract_payload)
    pdf_path = generate_contract_pdf(payload, contract_id, digest)

    conn = db()
    conn.execute(
        """
        INSERT INTO contracts (
            id, service_code, locale, client_name, client_email, client_company,
            client_phone, client_address, signer_full_name, signer_title,
            github_username, bitbucket_username, referral_code, typed_signature,
            consent_checked, consent_version, signer_ip, user_agent,
            document_sha256, pdf_path, status, created_at, signed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            contract_id,
            payload.service_code,
            payload.locale,
            payload.client_name,
            payload.client_email,
            payload.client_company,
            payload.client_phone,
            payload.client_address,
            payload.signer_full_name,
            payload.signer_title,
            github_username,
            bitbucket_username,
            referral_code,
            payload.typed_signature,
            int(payload.consent_checked),
            payload.consent_version,
            ip,
            user_agent,
            digest,
            str(pdf_path),
            "signed_pending_payment",
            utc_now(),
            utc_now(),
        ),
    )
    conn.commit()
    conn.close()

    save_audit_event(contract_id, "contract_signed", contract_payload, ip, user_agent)

    pdf_url = f"{settings.api_base_url}/api/contracts/{contract_id}/pdf"
    subject = (
        "Contrat signé — Origna Ventures"
        if payload.locale == "fr"
        else "Signed agreement — Origna Ventures"
    )
    safe_client_name = html_escape(payload.client_name)
    safe_pdf_url = html_escape(pdf_url)
    html = (
        f"<p>Bonjour {safe_client_name},</p><p>Votre contrat électronique a été enregistré.</p><p><a href='{safe_pdf_url}'>Télécharger le PDF signé</a></p>"
        if payload.locale == "fr"
        else f"<p>Hello {safe_client_name},</p><p>Your electronic agreement has been recorded.</p><p><a href='{safe_pdf_url}'>Download signed PDF</a></p>"
    )
    text = (
        f"Votre contrat a été enregistré: {pdf_url}"
        if payload.locale == "fr"
        else f"Your agreement has been recorded: {pdf_url}"
    )
    if settings.mailjet_api_key and settings.mailjet_secret_key:
        try:
            send_mailjet_email(payload.client_email, subject, html, text)
            send_mailjet_email(
                settings.support_email,
                f"New signed contract {contract_id}",
                html,
                text,
            )
        except Exception:
            pass

    return {
        "contractId": contract_id,
        "pdfUrl": pdf_url,
        "documentSha256": digest,
        "status": "signed_pending_payment",
    }


@app.get("/api/contracts/{contract_id}/pdf")
def get_contract_pdf(contract_id: str):
    conn = db()
    row = conn.execute(
        "SELECT pdf_path FROM contracts WHERE id = ?", (contract_id,)
    ).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Contract not found")
    path = Path(row["pdf_path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="PDF not found")
    return FileResponse(
        path,
        media_type="application/pdf",
        filename=f"{contract_id}.pdf",
        content_disposition_type="inline",
    )


@app.post("/api/payments/create-checkout-session")
def payment_session(payload: PaymentSessionRequest, request: Request) -> Dict[str, Any]:
    ip = client_ip(request)
    enforce_rate_limit(f"pay:{ip}", limit=20, window_seconds=300)
    service_code = payload.service_code
    if service_code and service_code in SERVICE_CATALOG:
        service = SERVICE_CATALOG[service_code]
        session = create_checkout_session_from_service(
            service_code, service, payload.payer_email
        )
        save_audit_event(
            service_code,
            "checkout_session_created",
            session,
            client_ip(request),
            request.headers.get("user-agent", "unknown"),
        )
        return {
            "provider": "stripe",
            "sessionId": session.get("id"),
            "checkoutUrl": session.get("url"),
            "status": "awaiting_payment",
        }
    conn = db()
    contract = conn.execute(
        "SELECT * FROM contracts WHERE id = ?", (payload.contract_id,)
    ).fetchone()
    conn.close()
    if not contract:
        raise HTTPException(status_code=404, detail="Contract or service not found")
    session = create_checkout_session(contract, payload.payer_email)
    save_audit_event(
        payload.contract_id,
        "checkout_session_created",
        session,
        client_ip(request),
        request.headers.get("user-agent", "unknown"),
    )
    return {
        "provider": "stripe",
        "sessionId": session.get("id"),
        "checkoutUrl": session.get("url"),
        "status": "awaiting_payment",
    }


@app.post("/api/email/test")
def email_test(payload: EmailTestRequest, request: Request) -> Dict[str, Any]:
    ip = client_ip(request)
    enforce_rate_limit(f"email:{ip}", limit=5, window_seconds=300)
    result = send_mailjet_email(
        payload.to_email,
        payload.subject,
        f"<p>{payload.body}</p>",
        payload.body,
    )
    return {"success": True, "mailjet": result}


def verify_stripe_signature(payload: bytes, header: str) -> bool:
    if not settings.stripe_webhook_secret:
        raise HTTPException(status_code=500, detail="Stripe webhook secret missing")
    pieces = dict(part.split("=", 1) for part in header.split(",") if "=" in part)
    ts = pieces.get("t")
    sig = pieces.get("v1")
    if not ts or not sig:
        return False
    try:
        timestamp = int(ts)
    except ValueError:
        return False
    if abs(int(time.time()) - timestamp) > _STRIPE_SIGNATURE_TOLERANCE_SECONDS:
        return False
    signed_payload = f"{ts}.".encode("utf-8") + payload
    expected = hmac.new(
        settings.stripe_webhook_secret.encode("utf-8"),
        signed_payload,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, sig)


@app.post("/api/stripe/webhook")
async def stripe_webhook(request: Request) -> Dict[str, Any]:
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")
    if not verify_stripe_signature(payload, sig_header):
        raise HTTPException(status_code=400, detail="Invalid Stripe signature")

    event = json.loads(payload.decode("utf-8"))
    event_id = event.get("id", secrets.token_hex(8))
    conn = db()
    already = conn.execute(
        "SELECT id FROM webhook_events WHERE id = ?", (event_id,)
    ).fetchone()
    if already:
        conn.close()
        return {"status": "duplicate", "eventId": event_id}

    conn.execute(
        "INSERT INTO webhook_events (id, event_type, payload_json, created_at) VALUES (?, ?, ?, ?)",
        (event_id, event.get("type", "unknown"), json.dumps(event), utc_now()),
    )

    event_type = event.get("type", "")
    if event_type == "checkout.session.completed":
        session = event.get("data", {}).get("object", {})
        contract_id = session.get("metadata", {}).get("contract_id")
        if contract_id:
            conn.execute(
                "UPDATE contracts SET status = ?, stripe_payment_status = ?, stripe_session_id = ? WHERE id = ?",
                (
                    "paid",
                    session.get("payment_status", "paid"),
                    session.get("id"),
                    contract_id,
                ),
            )
            insert_audit_event(
                conn,
                contract_id,
                "payment_confirmed",
                session,
                client_ip(request),
                request.headers.get("user-agent", "stripe"),
            )
            row = conn.execute(
                "SELECT * FROM contracts WHERE id = ?", (contract_id,)
            ).fetchone()
            if row:
                try:
                    maybe_unlock_repo_after_payment(conn, contract_id, row)
                except Exception as exc:
                    conn.execute(
                        "UPDATE contracts SET repo_unlock_status = ?, repo_unlock_error = ? WHERE id = ?",
                        ("unlock_failed", str(exc)[:500], contract_id),
                    )
                row = conn.execute(
                    "SELECT * FROM contracts WHERE id = ?", (contract_id,)
                ).fetchone()
            if row and settings.mailjet_api_key and settings.mailjet_secret_key:
                pdf_url = f"{settings.api_base_url}/api/contracts/{contract_id}/pdf"
                try:
                    send_mailjet_email(
                        row["client_email"],
                        "Payment confirmed — Origna Ventures",
                        f"<p>Your payment is confirmed.</p><p><a href='{pdf_url}'>Signed contract PDF</a></p>",
                        f"Payment confirmed. Contract: {pdf_url}",
                    )
                except Exception:
                    pass
    conn.commit()
    conn.close()
    return {"status": "ok", "eventId": event_id, "type": event_type}


@app.get("/api/contracts")
def list_contracts() -> Dict[str, Any]:
    conn = db()
    rows = conn.execute(
        "SELECT id, service_code, client_company, client_email, payer_email, github_username, status, repo_unlock_status, repo_unlock_error, github_invitation_id, created_at FROM contracts ORDER BY created_at DESC LIMIT 100"
    ).fetchall()
    conn.close()
    return {"contracts": [dict(row) for row in rows]}
