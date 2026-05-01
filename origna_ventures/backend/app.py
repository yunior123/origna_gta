from __future__ import annotations

import base64
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
from concurrent.futures import ThreadPoolExecutor, as_completed
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse

import logging
import requests
from fastapi import FastAPI, HTTPException, Request

logger = logging.getLogger("origna_ventures")
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s"
)
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from reportlab.lib.pagesizes import LETTER
from reportlab.pdfgen import canvas

_EMAIL_EXECUTOR = ThreadPoolExecutor(max_workers=4)
_email_queue_sync_mode = False

_SERVICE_CODE_ORIGNA_CODE = "origna_code"
_SERVICE_CODE_ORIGNA_LAUNCH = "origna_launch"
_SERVICE_CODE_ORIGNA_TEAM = "origna_team"
_VALID_SERVICE_CODES = frozenset(
    {_SERVICE_CODE_ORIGNA_CODE, _SERVICE_CODE_ORIGNA_LAUNCH, _SERVICE_CODE_ORIGNA_TEAM}
)

_PAYMENT_STATUS_AWAITING = "awaiting_payment"
_PAYMENT_STATUS_PAID = "paid"
_PAYMENT_STATUS_EXPIRED = "expired"
_PAYMENT_STATUS_FAILED = "failed"

_SUBSCRIPTION_STATUS_ACTIVE = "active"
_SUBSCRIPTION_STATUS_PAST_DUE = "past_due"

_WEBHOOK_EVENT_CHECKOUT_COMPLETED = "checkout.session.completed"
_WEBHOOK_EVENT_CHECKOUT_EXPIRED = "checkout.session.expired"
_WEBHOOK_EVENT_SUBSCRIPTION_UPDATED = "customer.subscription.updated"
_WEBHOOK_EVENT_SUBSCRIPTION_DELETED = "customer.subscription.deleted"
_WEBHOOK_EVENT_INVOICE_PAYMENT_FAILED = "invoice.payment_failed"

_EMAIL_STATUS_PENDING = "pending"
_EMAIL_STATUS_SENT = "sent"
_EMAIL_STATUS_FAILED = "failed"
_EMAIL_STATUS_DEAD = "dead"

_EMAIL_MAX_RETRIES = 3
_EMAIL_RETRY_BASE_DELAY_SECONDS = 60
_EMAIL_PROVIDER_POSTAL = "postal"


@dataclass
class Settings:
    base_url: str = os.getenv(
        "ORIGNA_VENTURES_BASE_URL", "https://www.orignaventures.ca"
    )
    api_base_url: str = os.getenv(
        "ORIGNA_VENTURES_API_BASE_URL", "https://api.orignaventures.ca"
    )
    cors_allowed_origins: str = os.getenv(
        "ORIGNA_CORS_ALLOWED_ORIGINS",
        "https://orignaventures.ca,https://www.orignaventures.ca,http://localhost:3000,http://localhost:5000,http://localhost:8080",
    )
    support_email: str = os.getenv("ORIGNA_SUPPORT_EMAIL", "support@orignaventures.ca")
    support_delivery_email: str = os.getenv(
        "ORIGNA_SUPPORT_DELIVERY_EMAIL",
        os.getenv("ORIGNA_SUPPORT_EMAIL", "support@orignaventures.ca"),
    )
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
        "ORIGNA_STRIPE_SUCCESS_URL", "https://orignaventures.ca/?status=success"
    )
    stripe_cancel_url: str = os.getenv(
        "ORIGNA_STRIPE_CANCEL_URL", "https://orignaventures.ca/?status=cancelled"
    )
    environment: str = os.getenv("ENVIRONMENT", "dev")
    postal_api_key: str = os.getenv("ORIGNA_POSTAL_API_KEY", "")
    postal_api_url: str = os.getenv(
        "ORIGNA_POSTAL_API_URL", "https://mail.orignagta.ca/api/v1/send/message"
    )
    postal_from_email: str = os.getenv(
        "ORIGNA_POSTAL_FROM_EMAIL", "support@orignaventures.ca"
    )
    postal_from_name: str = os.getenv(
        "ORIGNA_POSTAL_FROM_NAME", "Origna Ventures Services"
    )
    email_provider: str = os.getenv("ORIGNA_EMAIL_PROVIDER", _EMAIL_PROVIDER_POSTAL).lower()
    github_token: str = os.getenv("ORIGNA_GITHUB_TOKEN", "")
    github_org: str = os.getenv("ORIGNA_GITHUB_ORG", "")
    github_template_repo: str = os.getenv("ORIGNA_GITHUB_TEMPLATE_REPO", "")
    github_permission: str = os.getenv("ORIGNA_GITHUB_PERMISSION", "pull")
    github_api_version: str = os.getenv("ORIGNA_GITHUB_API_VERSION", "2022-11-28")
    admin_api_key: str = os.getenv("ORIGNA_ADMIN_API_KEY", "")

    @property
    def email_provider_configured(self) -> bool:
        if self.email_provider == _EMAIL_PROVIDER_POSTAL:
            return bool(self.postal_api_key and self.postal_api_url)
        return False


settings = Settings()
Path(settings.storage_dir).mkdir(parents=True, exist_ok=True)
Path(settings.sqlite_path).parent.mkdir(parents=True, exist_ok=True)

SERVICE_CATALOG = {
    _SERVICE_CODE_ORIGNA_CODE: {
        "name_en": "OrignaCode",
        "name_fr": "OrignaCode",
        "price_cad": 500,
        "summary_en": "Lifetime source-code access with updates.",
        "summary_fr": "Accès à vie au code source avec mises à jour.",
    },
    _SERVICE_CODE_ORIGNA_LAUNCH: {
        "name_en": "OrignaLaunch",
        "name_fr": "OrignaLaunch",
        "price_cad": 3000,
        "summary_en": "Lifetime software access + launch + first-year Hetzner hosting (8 GB RAM + 80 GB disk) + first-year store enrollment + 20 human testers (20h QA).",
        "summary_fr": "Accès logiciel à vie + lancement + hébergement Hetzner première année (8 Go RAM + 80 Go disque) + inscription boutique première année + 20 testeurs humains (20h QA).",
    },
    _SERVICE_CODE_ORIGNA_TEAM: {
        "name_en": "OrignaTeam",
        "name_fr": "OrignaTeam",
        "price_cad": 1000,
        "summary_en": "Dedicated developer outsourcing from 1 to 20 developers at 1,000 CAD/month each, with optional tracked time and separate third-party costs.",
        "summary_fr": "Externalisation de 1 a 20 developpeurs dedies a 1 000 CAD/mois chacun, avec suivi du temps optionnel et couts tiers separes.",
    },
}

ORIGNA_TEAM_MAX_DEVELOPERS = 20


class PaymentSessionRequest(BaseModel):
    payer_email: Optional[EmailStr] = None
    payment_provider: str = Field(default="stripe", pattern="^(stripe)$")
    service_code: str = Field(
        default="", pattern=f"^(|{'|'.join(_VALID_SERVICE_CODES)})$"
    )
    locale: str = Field(default="en", pattern="^(en|fr|es)$")
    developer_count: int = Field(default=1, ge=1, le=ORIGNA_TEAM_MAX_DEVELOPERS)


class ContactFormRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    company: str = Field(default="", max_length=160)
    service: str = Field(default="general", max_length=40)
    message: str = Field(min_length=10, max_length=2000)


def render_contact_support_email(
    *,
    safe_name: str,
    safe_email: str,
    safe_company: str,
    safe_service: str,
    safe_message: str,
    ip: str,
) -> tuple[str, str]:
    text_body = (
        f"New contact form submission\n\n"
        f"Name: {safe_name}\n"
        f"Email: {safe_email}\n"
        f"Company: {safe_company or 'N/A'}\n"
        f"Service: {safe_service}\n\n"
        f"Message:\n{safe_message}\n\n"
        f"IP: {ip}\n"
        f"Time: {utc_now()}"
    )
    html_body = (
        "<div style='font-family:Arial,sans-serif;background:#f5f7fb;color:#111827;padding:24px;'>"
        "<div style='max-width:640px;margin:0 auto;background:#ffffff;border-radius:8px;padding:24px;border:1px solid #e5e7eb;'>"
        f"{render_email_brand_header()}"
        "<pre style='font-family:Arial,sans-serif;white-space:pre-wrap;color:#111827;margin:0;'>"
        + text_body
        + "</pre></div></div>"
    )
    return html_body, text_body


def normalize_checkout_locale(value: Optional[str]) -> str:
    return value if value in {"en", "fr", "es"} else "en"


def format_cad_cents(cents: Optional[int]) -> str:
    normalized = cents or 0
    dollars = normalized / 100
    return f"CA${dollars:,.2f}"


def render_payment_receipt_email(
    *,
    locale: str,
    service_code: str,
    subtotal_cents: Optional[int],
    tax_cents: Optional[int],
    total_cents: Optional[int],
    is_subscription: bool,
    stripe_session_id: str,
    developer_count: int = 1,
) -> tuple[str, str, str]:
    service = SERVICE_CATALOG.get(service_code, {})
    normalized_locale = normalize_checkout_locale(locale)
    service_name_en = service.get("name_en", service_code or "Origna Ventures")
    service_name_fr = service.get("name_fr", service_name_en)
    subtotal = format_cad_cents(subtotal_cents)
    tax = format_cad_cents(tax_cents)
    total = format_cad_cents(total_cents)
    cadence_en = (
        f"Monthly plan · {developer_count} developer(s)"
        if is_subscription
        else "One-time purchase"
    )
    cadence_fr = (
        f"Forfait mensuel · {developer_count} developpeur(s)"
        if is_subscription
        else "Achat ponctuel"
    )
    heading_en = "Your Origna Ventures receipt"
    heading_fr = "Votre recu Origna Ventures"
    subject_en = (
        "Subscription receipt — Origna Ventures"
        if is_subscription
        else "Payment receipt — Origna Ventures"
    )
    subject_fr = (
        "Recu d'abonnement — Origna Ventures"
        if is_subscription
        else "Recu de paiement — Origna Ventures"
    )

    def render_single_language(
        *,
        subject: str,
        heading: str,
        intro: str,
        service_label: str,
        cadence_label: str,
        subtotal_label: str,
        tax_label: str,
        total_label: str,
        reference_label: str,
        support_line: str,
        service_name: str,
        cadence_value: str,
    ) -> tuple[str, str]:
        html_body = (
            "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;"
            "padding:24px;'>"
            "<div style='max-width:640px;margin:0 auto;background:#171933;border-radius:18px;"
            "padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
            f"{render_email_brand_header()}"
            f"<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;"
            f"letter-spacing:0.12em;text-transform:uppercase;'>{html_escape(subject)}</p>"
            f"<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>{html_escape(heading)}</h2>"
            f"<p style='margin:0 0 16px;line-height:1.7;color:#d7dcf4;'>{html_escape(intro)}</p>"
            "<table style='width:100%;border-collapse:collapse;margin:0 0 18px;'>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;'>{html_escape(service_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(service_name)}</td></tr>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;'>{html_escape(cadence_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(cadence_value)}</td></tr>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;'>{html_escape(subtotal_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(subtotal)}</td></tr>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;'>{html_escape(tax_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(tax)}</td></tr>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;font-weight:700;'>{html_escape(total_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;font-weight:700;'>{html_escape(total)}</td></tr>"
            f"<tr><td style='padding:8px 0;color:#9aa3c7;'>{html_escape(reference_label)}</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(stripe_session_id)}</td></tr>"
            "</table>"
            f"<p style='margin:0;color:#9aa3c7;line-height:1.6;'>{html_escape(support_line)}</p>"
            "</div></div>"
        )
        text_body = (
            f"{heading}\n\n"
            f"{intro}\n\n"
            f"{service_label}: {service_name}\n"
            f"{cadence_label}: {cadence_value}\n"
            f"{subtotal_label}: {subtotal}\n"
            f"{tax_label}: {tax}\n"
            f"{total_label}: {total}\n"
            f"{reference_label}: {stripe_session_id}\n\n"
            f"{support_line}\n"
        )
        return html_body, text_body

    if normalized_locale == "fr":
        html_body, text_body = render_single_language(
            subject=subject_fr,
            heading=heading_fr,
            intro="Nous confirmons votre achat Origna Ventures. Ce message sert de recu recapitulatif.",
            service_label="Service",
            cadence_label="Type",
            subtotal_label="Sous-total",
            tax_label="Taxes",
            total_label="Total",
            reference_label="Reference Stripe",
            support_line=f"Besoin d'aide ? Ecrivez a {settings.support_email}.",
            service_name=service_name_fr,
            cadence_value=cadence_fr,
        )
        return subject_fr, html_body, text_body

    if normalized_locale == "es":
        bilingual_subject = "Payment receipt / Recu de paiement — Origna Ventures"
        html_body = (
            "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;padding:24px;'>"
            "<div style='max-width:640px;margin:0 auto;background:#171933;border-radius:18px;padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
            f"{render_email_brand_header()}"
            "<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;'>Origna Ventures</p>"
            "<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>Payment receipt / Recu de paiement</h2>"
            "<p style='margin:0 0 16px;line-height:1.7;color:#d7dcf4;'>English and French summary below.</p>"
            "<div style='padding:18px;border-radius:14px;background:#101227;border:1px solid rgba(255,255,255,0.06);margin:0 0 16px;'>"
            f"<p style='margin:0 0 8px;color:#9aa3c7;'><strong>EN</strong></p><p style='margin:0;color:#ffffff;line-height:1.6;'>Service: {html_escape(service_name_en)}<br>Type: {html_escape(cadence_en)}<br>Subtotal: {html_escape(subtotal)}<br>Tax: {html_escape(tax)}<br>Total: {html_escape(total)}<br>Stripe reference: {html_escape(stripe_session_id)}</p>"
            "</div>"
            "<div style='padding:18px;border-radius:14px;background:#101227;border:1px solid rgba(255,255,255,0.06);margin:0 0 16px;'>"
            f"<p style='margin:0 0 8px;color:#9aa3c7;'><strong>FR</strong></p><p style='margin:0;color:#ffffff;line-height:1.6;'>Service : {html_escape(service_name_fr)}<br>Type : {html_escape(cadence_fr)}<br>Sous-total : {html_escape(subtotal)}<br>Taxes : {html_escape(tax)}<br>Total : {html_escape(total)}<br>Reference Stripe : {html_escape(stripe_session_id)}</p>"
            "</div>"
            f"<p style='margin:0;color:#9aa3c7;line-height:1.6;'>Support: {html_escape(settings.support_email)}</p>"
            "</div></div>"
        )
        text_body = (
            "Payment receipt / Recu de paiement\n\n"
            f"EN\nService: {service_name_en}\nType: {cadence_en}\nSubtotal: {subtotal}\nTax: {tax}\nTotal: {total}\nStripe reference: {stripe_session_id}\n\n"
            f"FR\nService: {service_name_fr}\nType: {cadence_fr}\nSous-total: {subtotal}\nTaxes: {tax}\nTotal: {total}\nReference Stripe: {stripe_session_id}\n\n"
            f"Support: {settings.support_email}\n"
        )
        return bilingual_subject, html_body, text_body

    html_body, text_body = render_single_language(
        subject=subject_en,
        heading=heading_en,
        intro="We confirmed your Origna Ventures purchase. This email serves as your receipt summary.",
        service_label="Service",
        cadence_label="Type",
        subtotal_label="Subtotal",
        tax_label="Tax",
        total_label="Total",
        reference_label="Stripe reference",
        support_line=f"Need help? Email {settings.support_email}.",
        service_name=service_name_en,
        cadence_value=cadence_en,
    )
    return subject_en, html_body, text_body


def render_support_payment_notification_email(
    *,
    locale: str,
    service_code: str,
    payer_email: str,
    business_name: str,
    subtotal_cents: Optional[int],
    tax_cents: Optional[int],
    total_cents: Optional[int],
    is_subscription: bool,
    stripe_session_id: str,
    stripe_customer_id: str,
    tax_ids: List[Dict[str, Any]],
    developer_count: int = 1,
) -> tuple[str, str, str]:
    service = SERVICE_CATALOG.get(service_code, {})
    normalized_locale = normalize_checkout_locale(locale)
    service_name = service.get("name_en", service_code or "Origna Ventures")
    cadence = (
        f"Monthly subscription · {developer_count} developer(s)"
        if is_subscription
        else "One-time payment"
    )
    business_display = business_name or "N/A"
    customer_display = stripe_customer_id or "N/A"
    tax_id_lines = [
        f"{tax_id.get('type', 'unknown')}: {tax_id.get('value', '')}".strip()
        for tax_id in tax_ids
        if isinstance(tax_id, dict)
    ]
    tax_id_text = ", ".join(filter(None, tax_id_lines)) or "None provided"
    locale_display = normalized_locale.upper()
    subtotal = format_cad_cents(subtotal_cents)
    tax = format_cad_cents(tax_cents)
    total = format_cad_cents(total_cents)
    subject = f"Tier payment received — {service_name}"
    html_body = (
        "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;padding:24px;'>"
        "<div style='max-width:680px;margin:0 auto;background:#171933;border-radius:18px;padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
        f"{render_email_brand_header()}"
        "<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;'>Origna Ventures payment notification</p>"
        f"<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>{html_escape(service_name)}</h2>"
        "<table style='width:100%;border-collapse:collapse;margin:0 0 18px;'>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Payer email</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(payer_email or 'N/A')}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Business</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(business_display)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Locale</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(locale_display)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Type</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(cadence)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Subtotal</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(subtotal)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Tax</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(tax)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;font-weight:700;'>Total</td><td style='padding:8px 0;color:#ffffff;text-align:right;font-weight:700;'>{html_escape(total)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Stripe session</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(stripe_session_id or 'N/A')}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Stripe customer</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(customer_display)}</td></tr>"
        f"<tr><td style='padding:8px 0;color:#9aa3c7;'>Tax IDs</td><td style='padding:8px 0;color:#ffffff;text-align:right;'>{html_escape(tax_id_text)}</td></tr>"
        "</table>"
        "</div></div>"
    )
    text_body = (
        "Origna Ventures payment notification\n\n"
        f"Service: {service_name}\n"
        f"Payer email: {payer_email or 'N/A'}\n"
        f"Business: {business_display}\n"
        f"Locale: {locale_display}\n"
        f"Type: {cadence}\n"
        f"Subtotal: {subtotal}\n"
        f"Tax: {tax}\n"
        f"Total: {total}\n"
        f"Stripe session: {stripe_session_id or 'N/A'}\n"
        f"Stripe customer: {customer_display}\n"
        f"Tax IDs: {tax_id_text}\n"
    )
    return subject, html_body, text_body


def render_subscription_lifecycle_email(
    *,
    locale: str,
    service_code: str,
    subscription_id: str,
    new_status: str,
    event_type: str,
) -> tuple[str, str, str]:
    normalized_locale = normalize_checkout_locale(locale)
    service = SERVICE_CATALOG.get(service_code, {})
    service_name = service.get("name_en", service_code or "Origna Ventures")

    status_labels = {
        _SUBSCRIPTION_STATUS_PAST_DUE: {
            "en": "Past due — action required",
            "fr": "En retard — action requise",
        },
        "canceled": {
            "en": "Subscription canceled",
            "fr": "Abonnement annulé",
        },
        "active": {
            "en": "Subscription updated",
            "fr": "Abonnement mis à jour",
        },
        "incomplete_expired": {
            "en": "Subscription expired",
            "fr": "Abonnement expiré",
        },
    }
    default_label = {
        "en": f"Subscription status: {new_status}",
        "fr": f"Statut d'abonnement : {new_status}",
    }
    label = status_labels.get(new_status, default_label)

    if event_type == _WEBHOOK_EVENT_SUBSCRIPTION_DELETED:
        heading_en = "Your OrignaTeam subscription has been canceled"
        heading_fr = "Votre abonnement OrignaTeam a été annulé"
        body_en = f"Your OrignaTeam subscription ({subscription_id}) has been canceled. You will no longer be billed. If this was unintentional, contact support to reactivate."
        body_fr = f"Votre abonnement OrignaTeam ({subscription_id}) a été annulé. Vous ne serez plus facturé. Si c'était une erreur, contactez le support pour réactiver."
    elif event_type == _WEBHOOK_EVENT_INVOICE_PAYMENT_FAILED:
        heading_en = "Payment failed — subscription past due"
        heading_fr = "Paiement échoué — abonnement en retard"
        body_en = f"A payment for your OrignaTeam subscription ({subscription_id}) failed. Your subscription is now past due. Please update your payment method to avoid service interruption."
        body_fr = f"Un paiement pour votre abonnement OrignaTeam ({subscription_id}) a échoué. Votre abonnement est maintenant en retard. Veuillez mettre à jour votre méthode de paiement pour éviter une interruption de service."
    else:
        heading_en = f"Your OrignaTeam subscription status changed"
        heading_fr = f"Le statut de votre abonnement OrignaTeam a changé"
        body_en = f"Your OrignaTeam subscription ({subscription_id}) status changed to: {label['en']}. If you have questions, contact support."
        body_fr = f"Le statut de votre abonnement OrignaTeam ({subscription_id}) a changé pour : {label['fr']}. Si vous avez des questions, contactez le support."

    if normalized_locale == "fr":
        subject = f"{heading_fr} — Origna Ventures"
        html_body = (
            "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;padding:24px;'>"
            "<div style='max-width:640px;margin:0 auto;background:#171933;border-radius:18px;padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
            f"{render_email_brand_header()}"
            f"<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;'>Origna Ventures</p>"
            f"<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>{html_escape(heading_fr)}</h2>"
            f"<p style='margin:0 0 16px;line-height:1.7;color:#d7dcf4;'>{html_escape(body_fr)}</p>"
            f"<p style='margin:0;color:#9aa3c7;line-height:1.6;'>Service : {html_escape(service_name)}<br>Abonnement : {html_escape(subscription_id)}<br>Support : {html_escape(settings.support_email)}</p>"
            "</div></div>"
        )
        text_body = f"{heading_fr}\n\n{body_fr}\n\nService : {service_name}\nAbonnement : {subscription_id}\nSupport : {settings.support_email}\n"
        return subject, html_body, text_body

    if normalized_locale == "es":
        subject = f"{heading_en} / {heading_fr} — Origna Ventures"
        html_body = (
            "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;padding:24px;'>"
            "<div style='max-width:640px;margin:0 auto;background:#171933;border-radius:18px;padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
            f"{render_email_brand_header()}"
            f"<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;'>Origna Ventures</p>"
            f"<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>{html_escape(heading_en)}</h2>"
            f"<p style='margin:0 0 16px;line-height:1.7;color:#d7dcf4;'>{html_escape(body_en)}</p>"
            f"<p style='margin:0;color:#9aa3c7;line-height:1.6;'>Service: {html_escape(service_name)}<br>Subscription: {html_escape(subscription_id)}<br>Support: {html_escape(settings.support_email)}</p>"
            "</div></div>"
        )
        text_body = f"{heading_en}\n\n{body_en}\n\nService: {service_name}\nSubscription: {subscription_id}\nSupport: {settings.support_email}\n"
        return subject, html_body, text_body

    subject = f"{heading_en} — Origna Ventures"
    html_body = (
        "<div style='font-family:Arial,sans-serif;background:#0f1022;color:#f5f7ff;padding:24px;'>"
        "<div style='max-width:640px;margin:0 auto;background:#171933;border-radius:18px;padding:28px;border:1px solid rgba(255,255,255,0.08);'>"
        f"{render_email_brand_header()}"
        f"<p style='margin:0 0 10px;color:#8ea0ff;font-size:12px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;'>Origna Ventures</p>"
        f"<h2 style='margin:0 0 12px;font-size:28px;line-height:1.2;'>{html_escape(heading_en)}</h2>"
        f"<p style='margin:0 0 16px;line-height:1.7;color:#d7dcf4;'>{html_escape(body_en)}</p>"
        f"<p style='margin:0;color:#9aa3c7;line-height:1.6;'>Service: {html_escape(service_name)}<br>Subscription: {html_escape(subscription_id)}<br>Support: {html_escape(settings.support_email)}</p>"
        "</div></div>"
    )
    text_body = f"{heading_en}\n\n{body_en}\n\nService: {service_name}\nSubscription: {subscription_id}\nSupport: {settings.support_email}\n"
    return subject, html_body, text_body


def build_receipt_pdf_filename(service_code: str, stripe_session_id: str) -> str:
    safe_service = re.sub(r"[^a-z0-9_-]+", "-", (service_code or "receipt").lower())
    safe_session = re.sub(r"[^A-Za-z0-9_-]+", "-", stripe_session_id or "session")
    return f"origna-ventures-{safe_service}-{safe_session}.pdf"


def generate_receipt_pdf(
    *,
    locale: str,
    service_code: str,
    subtotal_cents: Optional[int],
    tax_cents: Optional[int],
    total_cents: Optional[int],
    is_subscription: bool,
    stripe_session_id: str,
    developer_count: int = 1,
) -> bytes:
    normalized_locale = normalize_checkout_locale(locale)
    service = SERVICE_CATALOG.get(service_code, {})
    service_name = service.get("name_fr" if normalized_locale == "fr" else "name_en")
    service_name = service_name or service_code or "Origna Ventures"
    invoice_number = (
        f"INV-{stripe_session_id.replace('cs_', '')}"
        if stripe_session_id
        else f"INV-{secrets.token_hex(4)}"
    )

    if normalized_locale == "fr":
        title = "Recu Origna Ventures"
        cadence = "Forfait mensuel" if is_subscription else "Achat ponctuel"
        label_service = "Service"
        label_type = "Type"
        label_subtotal = "Sous-total"
        label_tax = "Taxe"
        label_total = "Total"
        label_ref = "Reference Stripe"
        label_invoice = "Numero de facture"
        label_business = "Entreprise"
        label_bn = "Numero d'entreprise"
        label_support = "Support"
        label_generated = "Genere le"
        label_dev_count = "Nombre de developpeurs"
        label_qty = "Quantite"
    elif normalized_locale == "es":
        title = "Recibo de pago / Recu de paiement"
        cadence = "Plan mensual" if is_subscription else "Compra unica"
        label_service = "Servicio"
        label_type = "Tipo"
        label_subtotal = "Subtotal"
        label_tax = "Impuesto"
        label_total = "Total"
        label_ref = "Referencia Stripe"
        label_invoice = "Numero de factura"
        label_business = "Empresa"
        label_bn = "Numero de empresa"
        label_support = "Soporte"
        label_generated = "Generado el"
        label_dev_count = "Cantidad de desarrolladores"
        label_qty = "Cantidad"
    else:
        title = "Origna Ventures receipt"
        cadence = "Monthly plan" if is_subscription else "One-time purchase"
        label_service = "Service"
        label_type = "Type"
        label_subtotal = "Subtotal"
        label_tax = "Tax"
        label_total = "Total"
        label_ref = "Stripe reference"
        label_invoice = "Invoice number"
        label_business = "Business"
        label_bn = "Business number"
        label_support = "Support"
        label_generated = "Generated"
        label_dev_count = "Developer count"
        label_qty = "Quantity"

    buffer = io.BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=LETTER)
    width, height = LETTER
    y = height - 72

    pdf.setTitle(title)
    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawString(72, y, title)
    y -= 28
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(72, y, settings.company_legal_name)
    y -= 16
    pdf.setFont("Helvetica", 10)
    pdf.drawString(72, y, f"{label_bn}: {settings.company_bn}")
    y -= 16
    pdf.drawString(
        72, y, f"{label_support}: {settings.support_email} | {settings.support_phone}"
    )
    y -= 22
    pdf.setFont("Helvetica", 11)
    lines = [
        f"{label_invoice}: {invoice_number}",
        f"{label_service}: {service_name}",
        f"{label_type}: {cadence}",
    ]
    if is_subscription and developer_count > 1:
        lines.append(f"{label_dev_count}: {developer_count}")
    lines.extend(
        [
            f"{label_subtotal}: {format_cad_cents(subtotal_cents)}",
            f"{label_tax}: {format_cad_cents(tax_cents)}",
            f"{label_total}: {format_cad_cents(total_cents)}",
            f"{label_ref}: {stripe_session_id}",
            f"{label_generated}: {utc_now()}",
        ]
    )
    for line in lines:
        pdf.drawString(72, y, line)
        y -= 18
    pdf.showPage()
    pdf.save()
    return buffer.getvalue()


def build_email_pdf_attachment(filename: str, pdf_bytes: bytes) -> Dict[str, str]:
    return {
        "content_type": "application/pdf",
        "name": filename,
        "data": base64.b64encode(pdf_bytes).decode("ascii"),
    }


def dispatch_email_jobs(
    jobs: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    if not jobs:
        return []
    if len(jobs) == 1:
        job = jobs[0]
        return [
            {
                "to_email": job["to_email"],
                "result": try_send_email(
                    job["to_email"],
                    job["subject"],
                    job["html_body"],
                    job["text_body"],
                    attachments=job.get("attachments"),
                    reply_to_email=job.get("reply_to_email"),
                    reply_to_name=job.get("reply_to_name"),
                ),
            }
        ]

    results: List[Dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=min(4, len(jobs))) as executor:
        future_map = {
            executor.submit(
                try_send_email,
                job["to_email"],
                job["subject"],
                job["html_body"],
                job["text_body"],
                job.get("attachments"),
                job.get("reply_to_email"),
                job.get("reply_to_name"),
            ): job["to_email"]
            for job in jobs
        }
        for future in as_completed(future_map):
            results.append(
                {
                    "to_email": future_map[future],
                    "result": future.result(),
                }
            )
    return results


def dispatch_email_jobs_async(jobs: List[Dict[str, Any]]) -> None:
    for job in jobs:
        future = _EMAIL_EXECUTOR.submit(
            try_send_email,
            job["to_email"],
            job["subject"],
            job["html_body"],
            job["text_body"],
            job.get("attachments"),
            job.get("reply_to_email"),
            job.get("reply_to_name"),
        )

        def _log_result(done_future, to_email=job["to_email"]):
            try:
                result = done_future.result()
                if result.get("status") != "sent":
                    logger.warning(
                        "Async webhook email to %s: %s — %s",
                        to_email,
                        result.get("status"),
                        result.get("reason", ""),
                    )
            except Exception as exc:
                logger.warning(
                    "Async webhook email to %s crashed: %s",
                    to_email,
                    exc,
                )

        future.add_done_callback(_log_result)


def enqueue_email_job(job: Dict[str, Any]) -> str:
    email_id = f"eq-{secrets.token_hex(8)}"
    attachments_json = (
        json.dumps(job.get("attachments")) if job.get("attachments") else None
    )
    with db_conn() as conn:
        conn.execute(
            "INSERT INTO email_queue (id, to_email, subject, html_body, text_body, attachments_json, status, retry_count, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (
                email_id,
                job["to_email"],
                job["subject"],
                job["html_body"],
                job["text_body"],
                attachments_json,
                _EMAIL_STATUS_PENDING,
                0,
                utc_now(),
            ),
        )
        conn.commit()
    if _email_queue_sync_mode:
        _process_email_queue_entry(email_id)
    else:
        _EMAIL_EXECUTOR.submit(_process_email_queue_entry, email_id)
    return email_id


def enqueue_email_jobs(jobs: List[Dict[str, Any]]) -> List[str]:
    email_ids = []
    with db_conn() as conn:
        for job in jobs:
            email_id = f"eq-{secrets.token_hex(8)}"
            attachments_json = (
                json.dumps(job.get("attachments")) if job.get("attachments") else None
            )
            conn.execute(
                "INSERT INTO email_queue (id, to_email, subject, html_body, text_body, attachments_json, status, retry_count, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    email_id,
                    job["to_email"],
                    job["subject"],
                    job["html_body"],
                    job["text_body"],
                    attachments_json,
                    _EMAIL_STATUS_PENDING,
                    0,
                    utc_now(),
                ),
            )
            email_ids.append(email_id)
        conn.commit()
    for eid in email_ids:
        if _email_queue_sync_mode:
            _process_email_queue_entry(eid)
        else:
            _EMAIL_EXECUTOR.submit(_process_email_queue_entry, eid)
    return email_ids


def _process_email_queue_entry(email_id: str) -> None:
    try:
        with db_conn() as conn:
            conn.execute("BEGIN IMMEDIATE")
            row = conn.execute(
                "SELECT id, to_email, subject, html_body, text_body, attachments_json, retry_count FROM email_queue WHERE id = ? AND status IN (?, ?)",
                (email_id, _EMAIL_STATUS_PENDING, _EMAIL_STATUS_FAILED),
            ).fetchone()
            if not row:
                conn.rollback()
                return
            attachments = None
            if row["attachments_json"]:
                try:
                    attachments = json.loads(row["attachments_json"])
                except (json.JSONDecodeError, TypeError):
                    attachments = None
            result = try_send_email(
                row["to_email"],
                row["subject"],
                row["html_body"],
                row["text_body"],
                attachments=attachments,
            )
            new_retry_count = row["retry_count"] + 1
            if result.get("status") == "sent":
                conn.execute(
                    "UPDATE email_queue SET status = ?, retry_count = ?, last_attempt_at = ? WHERE id = ?",
                    (_EMAIL_STATUS_SENT, new_retry_count, utc_now(), email_id),
                )
            elif new_retry_count >= _EMAIL_MAX_RETRIES:
                conn.execute(
                    "UPDATE email_queue SET status = ?, retry_count = ?, last_attempt_at = ?, last_error = ? WHERE id = ?",
                    (
                        _EMAIL_STATUS_DEAD,
                        new_retry_count,
                        utc_now(),
                        result.get("reason", "max_retries_exceeded"),
                        email_id,
                    ),
                )
                logger.error(
                    "Email %s moved to dead letter after %d retries: %s",
                    email_id,
                    new_retry_count,
                    result.get("reason", ""),
                )
            else:
                conn.execute(
                    "UPDATE email_queue SET status = ?, retry_count = ?, last_attempt_at = ?, last_error = ? WHERE id = ?",
                    (
                        _EMAIL_STATUS_FAILED,
                        new_retry_count,
                        utc_now(),
                        result.get("reason", ""),
                        email_id,
                    ),
                )
                logger.warning(
                    "Email %s attempt %d failed: %s",
                    email_id,
                    new_retry_count,
                    result.get("reason", ""),
                )
            conn.commit()
    except Exception as exc:
        logger.error(
            "Email queue processor crashed for %s: %s", email_id, exc, exc_info=True
        )


def retry_failed_emails() -> int:
    retried = 0
    try:
        with db_conn() as conn:
            rows = conn.execute(
                "SELECT id FROM email_queue WHERE status = ? AND retry_count < ?",
                (_EMAIL_STATUS_FAILED, _EMAIL_MAX_RETRIES),
            ).fetchall()
        for row in rows:
            if _email_queue_sync_mode:
                _process_email_queue_entry(row["id"])
            else:
                _EMAIL_EXECUTOR.submit(_process_email_queue_entry, row["id"])
            retried += 1
    except Exception as exc:
        logger.error("Retry failed emails crashed: %s", exc, exc_info=True)
    return retried


def try_send_email(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: str,
    attachments: Optional[List[Dict[str, str]]] = None,
    reply_to_email: Optional[str] = None,
    reply_to_name: Optional[str] = None,
) -> Dict[str, Any]:
    if not settings.email_provider_configured:
        return {"status": "skipped", "reason": "email_provider_not_configured"}
    try:
        provider_response = send_email(
            to_email,
            subject,
            html_body,
            text_body,
            attachments=attachments,
            reply_to_email=reply_to_email,
            reply_to_name=reply_to_name,
        )
        return {
            "status": "sent",
            "provider": settings.email_provider,
            "response": provider_response,
        }
    except Exception as exc:
        return {
            "status": "failed",
            "reason": exc.__class__.__name__,
            "message": str(exc)[:240],
        }


class EmailTestRequest(BaseModel):
    to_email: EmailStr
    subject: str = Field(default="Origna Ventures test email")
    body: str = Field(default="Postal integration test.")


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
_TRUSTED_PROXY_COUNT = int(
    os.getenv(
        "ORIGNA_TRUSTED_PROXY_COUNT",
        os.getenv("TRUSTED_PROXY_COUNT", "0"),
    )
)
_MAX_USER_AGENT_LENGTH = 512
_STRIPE_SIGNATURE_TOLERANCE_SECONDS = 300
_RATE_LIMITS: Dict[str, List[float]] = {}
_rate_limit_counter = 0

_admin_api_key: str = os.getenv("ORIGNA_ADMIN_API_KEY", "")


def require_admin_key(request: Request) -> None:
    if not _admin_api_key:
        raise HTTPException(status_code=503, detail="Admin API not configured")
    auth = request.headers.get("authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    provided = auth[7:]
    if not secrets.compare_digest(provided.encode(), _admin_api_key.encode()):
        raise HTTPException(status_code=401, detail="Unauthorized")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(settings.sqlite_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


@contextmanager
def db_conn():
    conn = db()
    try:
        yield conn
    finally:
        conn.close()


def ensure_payments_table(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS payments (
            id TEXT PRIMARY KEY,
            service_code TEXT,
            payer_email TEXT,
            locale TEXT,
            stripe_session_id TEXT,
            status TEXT,
            subscription_id TEXT,
            subscription_status TEXT,
            stripe_customer_id TEXT,
            customer_business_name TEXT,
            customer_tax_id_json TEXT,
            amount_subtotal_cents INTEGER,
            amount_tax_cents INTEGER,
            amount_total_cents INTEGER,
            developer_count INTEGER,
            created_at TEXT
        )
        """
    )
    existing = {
        row["name"] for row in conn.execute("PRAGMA table_info(payments)").fetchall()
    }
    for column, ddl in [
        ("locale", "ALTER TABLE payments ADD COLUMN locale TEXT"),
        (
            "stripe_customer_id",
            "ALTER TABLE payments ADD COLUMN stripe_customer_id TEXT",
        ),
        (
            "customer_business_name",
            "ALTER TABLE payments ADD COLUMN customer_business_name TEXT",
        ),
        (
            "customer_tax_id_json",
            "ALTER TABLE payments ADD COLUMN customer_tax_id_json TEXT",
        ),
        (
            "amount_subtotal_cents",
            "ALTER TABLE payments ADD COLUMN amount_subtotal_cents INTEGER",
        ),
        (
            "amount_tax_cents",
            "ALTER TABLE payments ADD COLUMN amount_tax_cents INTEGER",
        ),
        (
            "amount_total_cents",
            "ALTER TABLE payments ADD COLUMN amount_total_cents INTEGER",
        ),
        ("developer_count", "ALTER TABLE payments ADD COLUMN developer_count INTEGER"),
    ]:
        if column not in existing:
            conn.execute(ddl)


def init_db() -> None:
    conn = db()
    try:
        conn.executescript(
            """
CREATE TABLE IF NOT EXISTS webhook_events (
    id TEXT PRIMARY KEY,
    event_type TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS email_queue (
    id TEXT PRIMARY KEY,
    to_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    html_body TEXT NOT NULL,
    text_body TEXT NOT NULL,
    attachments_json TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_attempt_at TEXT,
    last_error TEXT,
    created_at TEXT NOT NULL
);
        """
        )
        ensure_payments_table(conn)
        conn.commit()
    finally:
        conn.close()


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.post("/api/contact")
def submit_contact(payload: ContactFormRequest, request: Request) -> Dict[str, Any]:
    enforce_rate_limit(f"contact:{client_ip(request)}", limit=5, window_seconds=300)
    ip = client_ip(request)
    safe_name = html_escape(payload.name)
    safe_email = html_escape(payload.email)
    safe_company = html_escape(payload.company)
    safe_service = html_escape(payload.service)
    safe_message = html_escape(payload.message)
    subject = "New Origna Ventures inquiry"
    support_html, support_text = render_contact_support_email(
        safe_name=safe_name,
        safe_email=safe_email,
        safe_company=safe_company,
        safe_service=safe_service,
        safe_message=safe_message,
        ip=ip,
    )
    email_jobs = [
        {
            "to_email": settings.support_delivery_email,
            "subject": subject,
            "html_body": support_html,
            "text_body": support_text,
        },
    ]
    email_results = dispatch_email_jobs(email_jobs)
    support_email_result = (
        email_results[0]["result"]
        if len(email_results) > 0
        else {"status": "failed", "reason": "dispatch_missing"}
    )
    with db_conn() as conn:
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
                ip,
                utc_now(),
            ),
        )
        conn.commit()
    return {
        "status": "ok",
        "id": contact_id,
        "emails": {
            "support": {
                k: v for k, v in support_email_result.items() if k != "response"
            },
        },
    }


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
    forwarded = request.headers.get("x-forwarded-for", "")
    if forwarded and _TRUSTED_PROXY_COUNT > 0:
        parts = [p.strip() for p in forwarded.split(",")]
        if len(parts) >= _TRUSTED_PROXY_COUNT:
            return parts[-_TRUSTED_PROXY_COUNT][:64]
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


def _cleanup_rate_limits() -> None:
    global _rate_limit_counter
    _rate_limit_counter += 1
    if _rate_limit_counter % 100 != 0:
        return
    cutoff = time.time() - 600
    stale = [k for k, v in _RATE_LIMITS.items() if not v or v[-1] < cutoff]
    for k in stale:
        del _RATE_LIMITS[k]


def enforce_rate_limit(key: str, limit: int, window_seconds: int) -> None:
    _cleanup_rate_limits()
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


_EMAIL_LOGO_URL = "https://orignaventures.ca/brand/origna-ventures-logo-192.png"


def render_email_brand_header() -> str:
    return (
        "<div style='display:flex;align-items:center;gap:12px;margin:0 0 22px;'>"
        f"<img src='{_EMAIL_LOGO_URL}' alt='Origna Ventures' width='48' height='48' "
        "style='display:block;width:48px;height:48px;border-radius:12px;'>"
        "<div>"
        "<p style='margin:0;color:#ffffff;font-size:16px;font-weight:800;'>Origna Ventures</p>"
        "<p style='margin:3px 0 0;color:#9aa3c7;font-size:12px;'>Software services and ecommerce systems</p>"
        "</div>"
        "</div>"
    )


def normalize_email_attachments(
    attachments: Optional[List[Dict[str, str]]],
) -> List[Dict[str, str]]:
    normalized = []
    for attachment in attachments or []:
        normalized.append(
            {
                "name": attachment.get("name")
                or attachment.get("Filename")
                or attachment.get("filename", "attachment"),
                "content_type": attachment.get("content_type")
                or attachment.get("ContentType")
                or "application/octet-stream",
                "data": attachment.get("data")
                or attachment.get("Base64Content")
                or attachment.get("base64_content", ""),
            }
        )
    return normalized


def _send_with_postal(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: str,
    attachments: Optional[List[Dict[str, str]]] = None,
    reply_to_email: Optional[str] = None,
    reply_to_name: Optional[str] = None,
) -> Dict[str, Any]:
    from_header = f"{settings.postal_from_name} <{settings.postal_from_email}>"
    payload: Dict[str, Any] = {
        "to": [to_email],
        "from": from_header,
        "subject": subject,
        "plain_body": text_body,
        "html_body": html_body,
    }
    normalized_attachments = normalize_email_attachments(attachments)
    if normalized_attachments:
        payload["attachments"] = normalized_attachments
    if reply_to_email:
        if reply_to_name:
            payload["reply_to"] = f"{reply_to_name} <{reply_to_email}>"
        else:
            payload["reply_to"] = reply_to_email

    response = requests.post(
        settings.postal_api_url,
        headers={
            "Content-Type": "application/json",
            "X-Server-API-Key": settings.postal_api_key,
        },
        json=payload,
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    if data.get("status") == "error":
        raise HTTPException(status_code=502, detail="Postal send failed")
    return data


def send_email(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: str,
    attachments: Optional[List[Dict[str, str]]] = None,
    reply_to_email: Optional[str] = None,
    reply_to_name: Optional[str] = None,
) -> Dict[str, Any]:
    if not settings.email_provider_configured:
        raise HTTPException(status_code=500, detail="Email provider credentials missing")
    if settings.email_provider == _EMAIL_PROVIDER_POSTAL:
        return _send_with_postal(
            to_email,
            subject,
            html_body,
            text_body,
            attachments=attachments,
            reply_to_email=reply_to_email,
            reply_to_name=reply_to_name,
        )
    raise HTTPException(status_code=500, detail="Unsupported email provider")


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
        "X-GitHub-Api-Version": settings.github_api_version,
    }


def create_checkout_session_from_service(
    service_code: str,
    service: dict,
    payer_email: Optional[str] = None,
    locale: str = "en",
    developer_count: int = 1,
    idempotency_key: Optional[str] = None,
) -> Dict[str, Any]:
    base_cents = service["price_cad"] * 100
    is_subscription = service_code == "origna_team"
    normalized_locale = normalize_checkout_locale(locale)
    normalized_developer_count = developer_count if is_subscription else 1
    resolved_idempotency_key = (
        idempotency_key or f"checkout:{service_code}:{secrets.token_hex(12)}"
    )
    payload = {
        "mode": "subscription" if is_subscription else "payment",
        "success_url": settings.stripe_success_url,
        "cancel_url": settings.stripe_cancel_url,
        "billing_address_collection": "required",
        "automatic_tax[enabled]": "true",
        "tax_id_collection[enabled]": "true",
        "payment_method_types[0]": "card",
        "metadata[service_code]": service_code,
        "metadata[client_locale]": normalized_locale,
        "metadata[developer_count]": str(normalized_developer_count),
    }
    if not is_subscription:
        payload["submit_type"] = "pay"
        payload["customer_creation"] = "always"
        payload["payment_method_types[1]"] = "klarna"
        payload["line_items[0][price_data][currency]"] = "cad"
        payload["line_items[0][price_data][unit_amount]"] = str(base_cents)
        payload["line_items[0][price_data][product_data][name]"] = service["name_en"]
        payload["line_items[0][price_data][product_data][description]"] = (
            "Service base price"
        )
        payload["line_items[0][quantity]"] = "1"
    else:
        payload["line_items[0][price_data][currency]"] = "cad"
        payload["line_items[0][price_data][unit_amount]"] = str(base_cents)
        payload["line_items[0][price_data][recurring][interval]"] = "month"
        payload["line_items[0][price_data][product_data][name]"] = service["name_en"]
        payload["line_items[0][price_data][product_data][description]"] = (
            f"Monthly dedicated developer outsourcing for {normalized_developer_count} developer(s)"
        )
        payload["line_items[0][quantity]"] = str(normalized_developer_count)
        payload["subscription_data[metadata][service_code]"] = service_code
        payload["subscription_data[metadata][developer_count]"] = str(
            normalized_developer_count
        )
    if payer_email:
        payload["customer_email"] = payer_email
        payload["metadata[client_email]"] = payer_email
    response = requests.post(
        "https://api.stripe.com/v1/checkout/sessions",
        headers={
            **stripe_headers(),
            "Idempotency-Key": resolved_idempotency_key,
        },
        data=payload,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


@app.post("/api/payments/create-checkout-session")
def payment_session(payload: PaymentSessionRequest, request: Request) -> Dict[str, Any]:
    ip = client_ip(request)
    enforce_rate_limit(f"pay:{ip}", limit=20, window_seconds=300)
    service_code = payload.service_code
    if not service_code or service_code not in SERVICE_CATALOG:
        raise HTTPException(status_code=400, detail="Valid service_code is required")
    if service_code != _SERVICE_CODE_ORIGNA_TEAM and payload.developer_count != 1:
        raise HTTPException(
            status_code=400,
            detail="developer_count is only supported for OrignaTeam",
        )
    service = SERVICE_CATALOG[service_code]
    session = create_checkout_session_from_service(
        service_code,
        service,
        payload.payer_email,
        payload.locale,
        payload.developer_count,
    )
    try:
        with db_conn() as conn:
            payment_id = f"pay-{secrets.token_hex(8)}"
            conn.execute(
                "INSERT INTO payments (id, service_code, payer_email, locale, stripe_session_id, status, subscription_id, subscription_status, developer_count, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    payment_id,
                    service_code,
                    payload.payer_email,
                    payload.locale,
                    session.get("id"),
                    _PAYMENT_STATUS_AWAITING,
                    None,
                    None,
                    payload.developer_count
                    if service_code == _SERVICE_CODE_ORIGNA_TEAM
                    else 1,
                    utc_now(),
                ),
            )
            conn.commit()
    except sqlite3.OperationalError as exc:
        logger.error("Payment session DB error: %s", exc)
        raise HTTPException(status_code=503, detail="Temporary database error")
    return {
        "provider": "stripe",
        "sessionId": session.get("id"),
        "checkoutUrl": session.get("url"),
        "status": _PAYMENT_STATUS_AWAITING,
    }


@app.post("/api/email/test")
def email_test(payload: EmailTestRequest, request: Request) -> Dict[str, Any]:
    require_admin_key(request)
    ip = client_ip(request)
    enforce_rate_limit(f"email:{ip}", limit=5, window_seconds=300)
    send_email(
        payload.to_email,
        payload.subject,
        f"<p>{html_escape(payload.body)}</p>",
        payload.body,
    )
    return {"success": True}


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

    try:
        event = json.loads(payload.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise HTTPException(status_code=400, detail="Invalid JSON payload")
    event_id = event.get("id", secrets.token_hex(8))
    event_type = event.get("type", "")

    pending_emails: list[Dict[str, Any]] = []

    try:
        with db_conn() as conn:
            conn.execute("BEGIN IMMEDIATE")
            try:
                conn.execute(
                    "INSERT INTO webhook_events (id, event_type, payload_json, created_at) VALUES (?, ?, ?, ?)",
                    (event_id, event_type, json.dumps(event), utc_now()),
                )
            except sqlite3.IntegrityError:
                conn.rollback()
                return {"status": "duplicate", "eventId": event_id}

            if event_type == _WEBHOOK_EVENT_CHECKOUT_COMPLETED:
                session = event.get("data", {}).get("object", {})
                payment_row = conn.execute(
                    "SELECT status FROM payments WHERE stripe_session_id = ?",
                    (session.get("id"),),
                ).fetchone()
                payment_already_paid = (
                    payment_row is not None
                    and payment_row["status"] == _PAYMENT_STATUS_PAID
                )
                service_code = session.get("metadata", {}).get(
                    "service_code", "unknown"
                )
                client_email = session.get("metadata", {}).get("client_email", "")
                client_locale = normalize_checkout_locale(
                    session.get("metadata", {}).get("client_locale")
                )
                payer_email = session.get("customer_email", client_email)
                mode = session.get("mode", "payment")
                customer_details = session.get("customer_details", {}) or {}
                business_name = (
                    customer_details.get("business_name")
                    or customer_details.get("name")
                    or ""
                )
                tax_ids = customer_details.get("tax_ids")
                if not isinstance(tax_ids, list):
                    tax_ids = []
                total_details = session.get("total_details", {}) or {}
                amount_subtotal_cents = session.get("amount_subtotal")
                amount_tax_cents = total_details.get("amount_tax")
                amount_total_cents = session.get("amount_total")

                expected_service = SERVICE_CATALOG.get(service_code)
                if expected_service:
                    expected_base_cents = expected_service["price_cad"] * 100
                    is_subscription = service_code == _SERVICE_CODE_ORIGNA_TEAM
                    developer_count_meta = session.get("metadata", {}).get(
                        "developer_count"
                    )
                    try:
                        parsed_developer_count = int(developer_count_meta)
                    except (TypeError, ValueError):
                        parsed_developer_count = 1
                    expected_total_cents = expected_base_cents * (
                        parsed_developer_count if is_subscription else 1
                    )
                    if (
                        amount_subtotal_cents is not None
                        and amount_subtotal_cents != expected_total_cents
                    ):
                        logger.warning(
                            "Webhook %s price mismatch: service=%s expected_subtotal=%d actual_subtotal=%d",
                            event_id,
                            service_code,
                            expected_total_cents,
                            amount_subtotal_cents,
                        )

                conn.execute(
                    """
                    UPDATE payments
                    SET status = ?,
                    locale = ?,
                    stripe_customer_id = ?,
                    customer_business_name = ?,
                    customer_tax_id_json = ?,
                    amount_subtotal_cents = ?,
                    amount_tax_cents = ?,
                    amount_total_cents = ?
                    WHERE stripe_session_id = ?
                    """,
                    (
                        _PAYMENT_STATUS_PAID,
                        client_locale,
                        session.get("customer"),
                        business_name,
                        json.dumps(tax_ids),
                        amount_subtotal_cents,
                        amount_tax_cents,
                        amount_total_cents,
                        session.get("id"),
                    ),
                )
                developer_count = session.get("metadata", {}).get("developer_count")
                try:
                    parsed_developer_count = int(developer_count)
                except (TypeError, ValueError):
                    parsed_developer_count = 1
                conn.execute(
                    "UPDATE payments SET developer_count = ? WHERE stripe_session_id = ?",
                    (parsed_developer_count, session.get("id")),
                )
                if service_code == _SERVICE_CODE_ORIGNA_TEAM and mode == "subscription":
                    subscription_id = session.get("subscription")
                    if subscription_id:
                        conn.execute(
                            "UPDATE payments SET subscription_id = ? WHERE stripe_session_id = ?",
                            (subscription_id, session.get("id")),
                        )
                if payer_email and not payment_already_paid:
                    receipt_subject, receipt_html, receipt_text = (
                        render_payment_receipt_email(
                            locale=client_locale,
                            service_code=service_code,
                            subtotal_cents=amount_subtotal_cents,
                            tax_cents=amount_tax_cents,
                            total_cents=amount_total_cents,
                            is_subscription=mode == "subscription",
                            stripe_session_id=session.get("id", ""),
                            developer_count=parsed_developer_count,
                        )
                    )
                    receipt_attachment = build_email_pdf_attachment(
                        build_receipt_pdf_filename(
                            service_code,
                            session.get("id", ""),
                        ),
                        generate_receipt_pdf(
                            locale=client_locale,
                            service_code=service_code,
                            subtotal_cents=amount_subtotal_cents,
                            tax_cents=amount_tax_cents,
                            total_cents=amount_total_cents,
                            is_subscription=mode == "subscription",
                            stripe_session_id=session.get("id", ""),
                            developer_count=parsed_developer_count,
                        ),
                    )
                    pending_emails.append(
                        {
                            "to_email": payer_email,
                            "subject": receipt_subject,
                            "html_body": receipt_html,
                            "text_body": receipt_text,
                            "attachments": [receipt_attachment],
                        }
                    )
                support_subject, support_html, support_text = (
                    render_support_payment_notification_email(
                        locale=client_locale,
                        service_code=service_code,
                        payer_email=payer_email or "N/A",
                        business_name=business_name,
                        subtotal_cents=amount_subtotal_cents,
                        tax_cents=amount_tax_cents,
                        total_cents=amount_total_cents,
                        is_subscription=mode == "subscription",
                        stripe_session_id=session.get("id", ""),
                        stripe_customer_id=session.get("customer", ""),
                        tax_ids=tax_ids,
                        developer_count=parsed_developer_count,
                    )
                )
                if not payment_already_paid:
                    pending_emails.append(
                        {
                            "to_email": settings.support_delivery_email,
                            "subject": support_subject,
                            "html_body": support_html,
                            "text_body": support_text,
                        }
                    )

            elif event_type == _WEBHOOK_EVENT_CHECKOUT_EXPIRED:
                session = event.get("data", {}).get("object", {})
                conn.execute(
                    "UPDATE payments SET status = ? WHERE stripe_session_id = ? AND status = ?",
                    (
                        _PAYMENT_STATUS_EXPIRED,
                        session.get("id"),
                        _PAYMENT_STATUS_AWAITING,
                    ),
                )

            elif event_type in (
                _WEBHOOK_EVENT_SUBSCRIPTION_UPDATED,
                _WEBHOOK_EVENT_SUBSCRIPTION_DELETED,
            ):
                subscription = event.get("data", {}).get("object", {})
                sub_id = subscription.get("id")
                sub_status = subscription.get("status", "unknown")
                if sub_id:
                    payer_row = conn.execute(
                        "SELECT payer_email, service_code, locale, subscription_status FROM payments WHERE subscription_id = ?",
                        (sub_id,),
                    ).fetchone()
                    status_changed = (
                        payer_row is None
                        or payer_row["subscription_status"] != sub_status
                    )
                    conn.execute(
                        "UPDATE payments SET subscription_status = ? WHERE subscription_id = ?",
                        (sub_status, sub_id),
                    )
                    if status_changed and payer_row and payer_row["payer_email"]:
                        lifecycle_subject, lifecycle_html, lifecycle_text = (
                            render_subscription_lifecycle_email(
                                locale=payer_row["locale"] or "en",
                                service_code=payer_row["service_code"] or "unknown",
                                subscription_id=sub_id,
                                new_status=sub_status,
                                event_type=event_type,
                            )
                        )
                        pending_emails.append(
                            {
                                "to_email": payer_row["payer_email"],
                                "subject": lifecycle_subject,
                                "html_body": lifecycle_html,
                                "text_body": lifecycle_text,
                            }
                        )

            elif event_type == _WEBHOOK_EVENT_INVOICE_PAYMENT_FAILED:
                invoice = event.get("data", {}).get("object", {})
                sub_id = invoice.get("subscription")
                if sub_id:
                    payer_row = conn.execute(
                        "SELECT payer_email, service_code, locale, subscription_status FROM payments WHERE subscription_id = ?",
                        (sub_id,),
                    ).fetchone()
                    status_changed = (
                        payer_row is None
                        or payer_row["subscription_status"]
                        != _SUBSCRIPTION_STATUS_PAST_DUE
                    )
                    conn.execute(
                        "UPDATE payments SET subscription_status = ? WHERE subscription_id = ?",
                        (_SUBSCRIPTION_STATUS_PAST_DUE, sub_id),
                    )
                    if status_changed and payer_row and payer_row["payer_email"]:
                        lifecycle_subject, lifecycle_html, lifecycle_text = (
                            render_subscription_lifecycle_email(
                                locale=payer_row["locale"] or "en",
                                service_code=payer_row["service_code"] or "unknown",
                                subscription_id=sub_id,
                                new_status=_SUBSCRIPTION_STATUS_PAST_DUE,
                                event_type=event_type,
                            )
                        )
                        pending_emails.append(
                            {
                                "to_email": payer_row["payer_email"],
                                "subject": lifecycle_subject,
                                "html_body": lifecycle_html,
                                "text_body": lifecycle_text,
                            }
                        )

            conn.commit()
            logger.info("Webhook %s (%s) processed", event_id, event_type)

    except sqlite3.OperationalError as exc:
        logger.error("Webhook %s DB operational error: %s", event_id, exc)
        raise HTTPException(status_code=503, detail="Temporary database error")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Webhook %s unexpected error: %s", event_id, exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Webhook processing failed")

    if pending_emails:
        try:
            enqueue_email_jobs(pending_emails)
        except Exception as exc:
            logger.error(
                "Failed to enqueue emails for webhook %s: %s",
                event_id,
                exc,
                exc_info=True,
            )

    return {"status": "ok", "eventId": event_id, "type": event_type}
