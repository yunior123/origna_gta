import hashlib
import hmac
import html
import logging
import os
from datetime import datetime
from urllib.parse import quote

from mailjet_rest import Client

from config import IS_EMULATOR, MAILJET_API_KEY, MAILJET_SECRET_KEY, UNSUBSCRIBE_HMAC_SECRET
from schema_constants import AppConfig, EmailConfig, Fields

logger = logging.getLogger(__name__)

# Allow real email sending in emulator mode for E2E testing
FORCE_REAL_EMAIL = os.environ.get("FORCE_REAL_EMAIL", "false").lower() == "true"

# Dynamic base URL for email links — Flutter web local in emulator, prod otherwise
APP_BASE_URL = EmailConfig.DEV_URL if IS_EMULATOR else EmailConfig.PROD_URL

# Dynamic unsubscribe URL
UNSUBSCRIBE_URL = EmailConfig.UNSUBSCRIBE_URL_DEV if IS_EMULATOR else EmailConfig.UNSUBSCRIBE_URL_PROD

# HMAC secret for signed unsubscribe tokens (prevents unauthorized unsubscription)
# Loaded from GCP Secret Manager in production, from .env in emulator
_UNSUBSCRIBE_SECRET = UNSUBSCRIBE_HMAC_SECRET or "origna-unsub-default-dev-key"


def _generate_unsubscribe_token(email: str) -> str:
    """Generate an HMAC-SHA256 token for secure unsubscribe links.
    Prevents attackers from unsubscribing arbitrary emails."""
    return hmac.new(_UNSUBSCRIBE_SECRET.encode(), email.lower().encode(), hashlib.sha256).hexdigest()[:32]


def _get_signed_unsubscribe_url(email: str) -> str:
    """Generate a signed unsubscribe URL (email + HMAC token)."""
    token = _generate_unsubscribe_token(email)
    return f"{UNSUBSCRIBE_URL}?email={quote(email)}&token={token}"


def _casl_compliant_footer(include_gst: bool = False) -> str:
    """Generate CASL-compliant email footer with physical address, unsubscribe, and optional GST/HST.

    Required by:
    - CASL (Canadian Anti-Spam Legislation): Physical address + unsubscribe link
    - Excise Tax Act: GST/HST registration number on receipts
    - Quebec Law 25: Privacy officer contact
    """
    gst_line = (
        f'<p style="margin: 0 0 8px 0; font-size: 11px; color: rgba(255,255,255,0.35);">GST/HST Registration: {EmailConfig.GST_HST_NUMBER}</p>'
        if include_gst
        else ""
    )
    return f"""
        <tr><td bgcolor="#1a1a2e" style="background-color: #1a1a2e; padding: 32px 40px; text-align: center;">
            <div style="margin-bottom: 16px;">
                <span style="font-size: 12px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; color: rgba(255,255,255,0.5);">O R I G N A</span>
            </div>
            <p style="margin: 0 0 8px 0; font-size: 13px; color: rgba(255,255,255,0.5);">{EmailConfig.APP_TAGLINE}</p>
            <p style="margin: 0 0 8px 0; font-size: 12px; color: rgba(255,255,255,0.35);">{EmailConfig.PHYSICAL_ADDRESS}</p>
            {gst_line}
            <p style="margin: 0 0 8px 0; font-size: 12px; color: rgba(255,255,255,0.35);">Questions? <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a> | Privacy: <a href="mailto:{EmailConfig.PRIVACY_OFFICER_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.PRIVACY_OFFICER_EMAIL}</a></p>
            <p style="margin: 0 0 12px 0; font-size: 12px; color: rgba(255,255,255,0.35);"><a href="{UNSUBSCRIBE_URL}" style="color: #667EEA; text-decoration: underline;">Unsubscribe from marketing emails</a> | <a href="{APP_BASE_URL}/privacy-policy" style="color: #667EEA; text-decoration: none;">Privacy Policy</a></p>
            <div style="border-top: 1px solid rgba(255,255,255,0.1); padding-top: 16px;">
                <p style="margin: 0; font-size: 11px; color: rgba(255,255,255,0.25);">{EmailConfig.COPYRIGHT_TEXT}</p>
            </div>
        </td></tr>"""


def get_order_confirmation_email(order_data, order_id=None):
    """Generate HTML email for customer order confirmation

    Args:
        order_data: Dict containing order information
        order_id: Optional order ID (can be in order_data[Fields.ORDER_ID] instead)
    """
    oid = order_data.get(Fields.ORDER_ID, order_id or "N/A")
    short_oid = oid[:8] if len(oid) > 8 else oid

    items_html = ""
    for i, item in enumerate(order_data.get(Fields.ITEMS, [])):
        safe_name = html.escape(str(item.get(Fields.NAME, "Product")))
        qty = item.get(Fields.QUANTITY, 1)
        price = item.get(Fields.PRICE, 0)
        line_total = price * qty
        bg = "#f8f9ff" if i % 2 == 0 else "#ffffff"
        items_html += f"""
        <tr style="background: {bg};">
            <td style="padding: 14px 16px; font-size: 14px; color: #1a1a2e;">
                <span style="font-weight: 600;">{safe_name}</span>
            </td>
            <td style="padding: 14px 16px; text-align: center; font-size: 14px; color: #555;">
                ×{qty}
            </td>
            <td style="padding: 14px 16px; text-align: right; font-size: 14px; font-weight: 600; color: #1a1a2e;">
                ${line_total:.2f}
            </td>
        </tr>
        """

    subtotal = order_data.get(Fields.SUBTOTAL_CENTS, 0) / 100
    shipping = order_data.get(Fields.SHIPPING_COST_CENTS, 0) / 100
    taxes_dict = order_data.get(Fields.TAXES, {})
    taxes = sum(taxes_dict.values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
    num_items = sum(item.get(Fields.QUANTITY, 1) for item in order_data.get(Fields.ITEMS, []))

    # Build itemized tax breakdown (Instacart-style: show GST, HST, PST, QST separately)
    tax_rows_html = ""
    if len(taxes_dict) > 1 or (len(taxes_dict) == 1 and list(taxes_dict.keys())[0] != "HST"):
        for tax_name, tax_amount in sorted(taxes_dict.items()):
            tax_rows_html += f"""
                        <tr>
                            <td style="padding: 4px 0 4px 16px; font-size: 13px; color: #888888;">{html.escape(tax_name)}</td>
                            <td style="padding: 4px 0; font-size: 13px; color: #1a1a2e; text-align: right;">${tax_amount:.2f}</td>
                        </tr>"""

    delivery_info = order_data.get(Fields.SHIPPING_ADDRESS, {})
    address_parts = [
        delivery_info.get(Fields.STREET, ""),
        delivery_info.get(Fields.APARTMENT, ""),
        f"{delivery_info.get(Fields.CITY, '')}, {delivery_info.get(Fields.STATE, '')} {delivery_info.get(Fields.POSTAL_CODE, '')}",
        delivery_info.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME),
    ]
    formatted_address = "<br>".join(p for p in address_parts if p and p.strip())
    phone_html = f"<br>📱 {delivery_info[Fields.PHONE_NUMBER]}" if delivery_info.get(Fields.PHONE_NUMBER) else ""

    order_date = datetime.now().strftime("%B %d, %Y at %I:%M %p")

    # CPA Ontario: estimated delivery date (7 business days from now as default)
    from datetime import timedelta

    estimated_delivery = (datetime.now() + timedelta(days=10)).strftime("%B %d, %Y")

    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Confirmed - Origna</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f0f2f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; -webkit-font-smoothing: antialiased;">
        <!-- Preheader: inbox preview text (hidden in body) -->
        <div style="display:none;font-size:1px;color:#f0f2f8;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;">Your order #{short_oid} has been confirmed and is being prepared for shipment.</div>

        <!-- Outer wrapper -->
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f0f2f8;">
        <tr><td align="center" style="padding: 24px 16px;">

        <!-- Email container -->
        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 20px 60px rgba(102, 126, 234, 0.15);">

        <!-- HERO HEADER -->
        <tr><td bgcolor="#1F235A" style="background-color: #1F235A; background-image: linear-gradient(135deg, #1F235A 0%, #2F3B8F 40%, #764BA2 100%); padding: 48px 40px 40px 40px; text-align: center;">
            <!-- Logo text -->
            <div style="margin-bottom: 8px;">
                <span style="font-size: 14px; font-weight: 700; letter-spacing: 4px; text-transform: uppercase; color: rgba(255,255,255,0.6);">O R I G N A</span>
            </div>
            <!-- Confirmation icon -->
            <div style="width: 72px; height: 72px; margin: 16px auto; background: rgba(16, 185, 129, 0.2); border-radius: 50%; line-height: 72px; font-size: 36px;">
                ✅
            </div>
            <h1 style="margin: 16px 0 8px 0; font-size: 28px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">Order Confirmed!</h1>
            <p style="margin: 0; font-size: 15px; color: rgba(255,255,255,0.75);">Thank you for shopping with us, your order is being prepared.</p>
            <!-- Order badge -->
            <div style="display: inline-block; margin-top: 20px; background: rgba(255,255,255,0.12); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2); border-radius: 50px; padding: 10px 24px;">
                <span style="font-size: 12px; color: rgba(255,255,255,0.6); text-transform: uppercase; letter-spacing: 1px;">Order</span>
                <span style="font-size: 15px; color: #ffffff; font-weight: 700; margin-left: 6px; font-family: 'Courier New', monospace;">#{short_oid}</span>
            </div>
        </td></tr>

        <!-- ORDER STATUS TRACKER -->
        <tr><td style="padding: 32px 40px 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
            <tr>
                <td width="25%" align="center">
                    <div style="width: 36px; height: 36px; background: linear-gradient(135deg, #667EEA, #764BA2); border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: white;">✓</div>
                    <div style="font-size: 11px; font-weight: 700; color: #667EEA; text-transform: uppercase; letter-spacing: 0.5px;">Confirmed</div>
                </td>
                <td width="25%" align="center">
                    <div style="width: 36px; height: 36px; background: #e8ebf0; border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: #999;">📦</div>
                    <div style="font-size: 11px; font-weight: 600; color: #999; text-transform: uppercase; letter-spacing: 0.5px;">Processing</div>
                </td>
                <td width="25%" align="center">
                    <div style="width: 36px; height: 36px; background: #e8ebf0; border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: #999;">🚚</div>
                    <div style="font-size: 11px; font-weight: 600; color: #999; text-transform: uppercase; letter-spacing: 0.5px;">Shipped</div>
                </td>
                <td width="25%" align="center">
                    <div style="width: 36px; height: 36px; background: #e8ebf0; border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: #999;">🏠</div>
                    <div style="font-size: 11px; font-weight: 600; color: #999; text-transform: uppercase; letter-spacing: 0.5px;">Delivered</div>
                </td>
            </tr>
            <!-- Progress bar -->
            <tr><td colspan="4" style="padding-top: 12px;">
                <div style="height: 4px; background: #e8ebf0; border-radius: 4px; overflow: hidden;">
                    <div style="width: 12%; height: 100%; background: linear-gradient(90deg, #667EEA, #764BA2); border-radius: 4px;"></div>
                </div>
            </td></tr>
            </table>
        </td></tr>

        <!-- DIVIDER -->
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background-color: #e8ebf0;"></div></td></tr>

        <!-- ITEMS TABLE -->
        <tr><td style="padding: 28px 40px 0 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #667EEA; padding-bottom: 6px;">{num_items} Item{"s" if num_items != 1 else ""} Ordered</span>
            </h2>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-radius: 12px; overflow: hidden; border: 1px solid #e8ebf0;">
                <thead>
                    <tr bgcolor="#667EEA" style="background-color: #667EEA;">
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Product</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: center; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Qty</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: right; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                </tbody>
            </table>
        </td></tr>

        <!-- ORDER RECEIPT (Gmail-safe: uses bgcolor fallbacks) -->
        <tr><td style="padding: 24px 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #667EEA; padding-bottom: 6px;">Order Receipt</span>
            </h2>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" bgcolor="#f8f9ff" style="background-color: #f8f9ff; border-radius: 16px; border: 1px solid #e0e3f0; overflow: hidden;">
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 20px 24px 4px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Subtotal ({num_items} item{"s" if num_items != 1 else ""})</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${subtotal:.2f}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Shipping</td>
                            <td style="padding: 6px 0; font-size: 14px; color: {"#10B981" if shipping == 0 else "#1a1a2e"}; text-align: right; font-weight: 500;">{"Free" if shipping == 0 else f"${shipping:.2f}"}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Taxes</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${taxes:.2f}</td>
                        </tr>
                        {tax_rows_html}
                    </table>
                </td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 0 24px;"><div style="height: 1px; background-color: #d0d4e8;"></div></td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 16px 24px 20px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="font-size: 16px; font-weight: 700; color: #1a1a2e;">Total (CAD)</td>
                            <td style="font-size: 22px; font-weight: 800; color: #667EEA; text-align: right; letter-spacing: -0.5px;">${total:.2f}</td>
                        </tr>
                    </table>
                </td></tr>
            </table>
        </td></tr>

        <!-- SHIPPING ADDRESS -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background: #ffffff; border: 1px solid #e8ebf0; border-radius: 16px; padding: 20px 24px;">
                <div style="display: flex; align-items: center; margin-bottom: 12px;">
                    <span style="font-size: 18px; margin-right: 8px;">📍</span>
                    <span style="font-size: 14px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 0.5px;">Shipping To</span>
                </div>
                <p style="margin: 0; font-size: 14px; line-height: 1.8; color: #555;">
                    {formatted_address}{phone_html}
                </p>
            </div>
        </td></tr>

        <!-- ORDER DATE -->
        <tr><td style="padding: 0 40px 24px 40px; text-align: center;">
            <p style="margin: 0 0 4px 0; font-size: 12px; color: #999;">🕐 Ordered on {order_date}</p>
            <p style="margin: 0 0 4px 0; font-size: 12px; color: #999;">📦 Estimated delivery by {estimated_delivery}</p>
            <p style="margin: 0; font-size: 12px; color: #999;">Sold by: Origna Ventures Inc. | GST/HST: {EmailConfig.GST_HST_NUMBER}</p>
        </td></tr>

        <!-- CTA BUTTON -->
        <tr><td style="padding: 0 40px 32px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="#667EEA" style="background-color: #667EEA; border-radius: 50px;">
                <a href="{APP_BASE_URL}/orders" target="_blank" style="display: inline-block; padding: 16px 48px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px; letter-spacing: 0.5px;">Track Your Order →</a>
            </td>
            </tr></table>
        </td></tr>

        <!-- CPA ONTARIO COMPLIANCE: Cancellation rights notice -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e8ebf0; border-radius: 12px; padding: 16px 20px;">
                <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: #1a1a2e;">Return &amp; Refund Policy</p>
                <p style="margin: 0; font-size: 12px; color: #555555; line-height: 1.6;">Returns and refunds are accepted within <strong>7 days of delivery</strong>. After 7 days post-delivery, all sales are final. If the goods are defective or not as described, contact <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA;">{EmailConfig.SUPPORT_EMAIL}</a> with your order ID within the return window. Under Ontario's Consumer Protection Act, you may cancel before shipment.</p>
            </div>
        </td></tr>

        <!-- CASL-COMPLIANT FOOTER with GST/HST (Excise Tax Act) -->
        {_casl_compliant_footer(include_gst=True)}

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """


def get_seller_notification_email(order_data, order_id=None, seller_id=None):
    """Generate HTML email for seller notification

    Args:
        order_data: Dict containing order information
        order_id: Optional order ID (can be in order_data[Fields.ORDER_ID])
        seller_id: Seller ID to filter items — only shows this seller's items (multi-seller privacy)
    """
    oid = order_data.get(Fields.ORDER_ID, order_id or "N/A")
    short_oid = oid[:8] if len(oid) > 8 else oid

    # CRITICAL: Filter items to show only this seller's items (multi-seller privacy)
    all_items = order_data.get(Fields.ITEMS, [])
    seller_items = [item for item in all_items if item.get(Fields.SELLER_ID) == seller_id] if seller_id else all_items

    items_html = ""
    for i, item in enumerate(seller_items):
        safe_name = html.escape(str(item.get(Fields.NAME, "Product")))
        qty = item.get(Fields.QUANTITY, 1)
        price = item.get(Fields.PRICE, 0)
        line_total = price * qty
        bg = "#f8f9ff" if i % 2 == 0 else "#ffffff"
        items_html += f"""
        <tr style="background: {bg};">
            <td style="padding: 14px 16px; font-size: 14px; color: #1a1a2e;">
                <span style="font-weight: 600;">{safe_name}</span>
            </td>
            <td style="padding: 14px 16px; text-align: center; font-size: 14px; color: #555;">
                ×{qty}
            </td>
            <td style="padding: 14px 16px; text-align: right; font-size: 14px; font-weight: 600; color: #1a1a2e;">
                ${line_total:.2f}
            </td>
        </tr>
        """

    # Calculate totals only for this seller's items (not the full order)
    seller_subtotal = sum(item.get(Fields.PRICE, 0) * item.get(Fields.QUANTITY, 1) for item in seller_items)
    num_items = sum(item.get(Fields.QUANTITY, 1) for item in seller_items)

    # Seller sees only their portion — not full order shipping/taxes/total
    subtotal = seller_subtotal  # Seller revenue = subtotal of their items only
    shipping = 0  # Shipping is charged to buyer, not split per seller
    taxes = 0  # Taxes apply to the buyer's total, not per-seller
    total = seller_subtotal  # Seller revenue = subtotal of their items only
    # AUDIT FIX: Removed duplicate num_items that was overwriting seller-only count with full order count

    delivery_info = order_data.get(Fields.SHIPPING_ADDRESS, {})
    addr_parts = [
        delivery_info.get(Fields.STREET, ""),
        delivery_info.get(Fields.APARTMENT, ""),
        f"{delivery_info.get(Fields.CITY, '')}, {delivery_info.get(Fields.STATE, '')} {delivery_info.get(Fields.POSTAL_CODE, '')}",
        delivery_info.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME),
    ]
    address_html = "<br>".join(p for p in addr_parts if p and p.strip())
    phone_html = f"<br>📱 {delivery_info[Fields.PHONE_NUMBER]}" if delivery_info.get(Fields.PHONE_NUMBER) else ""

    order_date = datetime.now().strftime("%B %d, %Y at %I:%M %p")
    customer_email = html.escape(order_data.get(Fields.CUSTOMER_EMAIL, "N/A"))

    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>New Order - Origna Seller</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f0f2f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; -webkit-font-smoothing: antialiased;">
        <!-- Preheader: inbox preview text (hidden in body) -->
        <div style="display:none;font-size:1px;color:#f0f2f8;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;">New order ${total:.2f} — {num_items} items to ship. Order #{short_oid}</div>

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f0f2f8;">
        <tr><td align="center" style="padding: 24px 16px;">

        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 20px 60px rgba(102, 126, 234, 0.15);">

        <!-- HERO HEADER -->
        <tr><td bgcolor="#1F235A" style="background-color: #1F235A; background-image: linear-gradient(135deg, #1F235A 0%, #2F3B8F 40%, #764BA2 100%); padding: 48px 40px 40px 40px; text-align: center;">
            <div style="margin-bottom: 8px;">
                <span style="font-size: 14px; font-weight: 700; letter-spacing: 4px; text-transform: uppercase; color: rgba(255,255,255,0.6);">O R I G N A</span>
            </div>
            <!-- Ka-ching icon -->
            <div style="width: 72px; height: 72px; margin: 16px auto; background: rgba(245, 158, 11, 0.2); border-radius: 50%; line-height: 72px; font-size: 36px;">
                💰
            </div>
            <h1 style="margin: 16px 0 8px 0; font-size: 28px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">New Order Received!</h1>
            <p style="margin: 0; font-size: 15px; color: rgba(255,255,255,0.75);">You have a new order to fulfill. Ship it fast!</p>

            <!-- Stats row -->
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top: 28px;">
            <tr>
                <td width="33%" align="center">
                    <div style="background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.15); border-radius: 16px; padding: 14px 8px;">
                        <div style="font-size: 22px; font-weight: 800; color: #ffffff;">${total:.2f}</div>
                        <div style="font-size: 10px; font-weight: 600; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 1px; margin-top: 4px;">Revenue</div>
                    </div>
                </td>
                <td width="33%" align="center">
                    <div style="background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.15); border-radius: 16px; padding: 14px 8px;">
                        <div style="font-size: 22px; font-weight: 800; color: #ffffff;">{num_items}</div>
                        <div style="font-size: 10px; font-weight: 600; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 1px; margin-top: 4px;">Items</div>
                    </div>
                </td>
                <td width="33%" align="center">
                    <div style="background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.15); border-radius: 16px; padding: 14px 8px;">
                        <div style="font-size: 22px; font-weight: 800; color: #ffffff;">#{short_oid}</div>
                        <div style="font-size: 10px; font-weight: 600; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 1px; margin-top: 4px;">Order ID</div>
                    </div>
                </td>
            </tr>
            </table>
        </td></tr>

        <!-- URGENT ACTION BANNER -->
        <tr><td bgcolor="#F59E0B" style="background-color: #F59E0B; background-image: linear-gradient(90deg, #F59E0B, #F97316); padding: 14px 40px; text-align: center;">
            <span style="font-size: 13px; font-weight: 700; color: #ffffff; letter-spacing: 0.5px;">⚡ ACTION REQUIRED — Confirm and ship this order within 48 hours</span>
        </td></tr>

        <!-- CUSTOMER INFO -->
        <tr><td style="padding: 28px 40px 0 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e0e3f0; border-radius: 16px; padding: 20px 24px;">
                <div style="margin-bottom: 12px;">
                    <span style="font-size: 18px; margin-right: 8px;">👤</span>
                    <span style="font-size: 14px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 0.5px;">Customer Info</span>
                </div>
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888; width: 90px;">Email:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 500;">{customer_email}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Ordered:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 500;">{order_date}</td>
                    </tr>
                </table>
            </div>
        </td></tr>

        <!-- ITEMS TABLE -->
        <tr><td style="padding: 24px 40px 0 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #764BA2; padding-bottom: 6px;">Items to Ship</span>
            </h2>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-radius: 12px; overflow: hidden; border: 1px solid #e8ebf0;">
                <thead>
                    <tr bgcolor="#667EEA" style="background-color: #667EEA; background-image: linear-gradient(135deg, #667EEA, #764BA2);">
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Product</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: center; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Qty</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: right; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                </tbody>
            </table>
        </td></tr>

        <!-- PRICE SUMMARY (Gmail-safe: uses bgcolor fallbacks) -->
        <tr><td style="padding: 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" bgcolor="#f8f9ff" style="background-color: #f8f9ff; border-radius: 16px; border: 1px solid #e0e3f0; overflow: hidden;">
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 20px 24px 4px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Subtotal</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${subtotal:.2f}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Shipping</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">{"Free" if shipping == 0 else f"${shipping:.2f}"}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Taxes</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${taxes:.2f}</td>
                        </tr>
                    </table>
                </td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 0 24px;"><div style="height: 1px; background-color: #d0d4e8;"></div></td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 16px 24px 20px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="font-size: 16px; font-weight: 700; color: #1a1a2e;">Order Total</td>
                            <td style="font-size: 22px; font-weight: 800; color: #10B981; text-align: right; letter-spacing: -0.5px;">${total:.2f} <span style="font-size: 13px; font-weight: 600; color: #999999;">CAD</span></td>
                        </tr>
                    </table>
                </td></tr>
            </table>
        </td></tr>

        <!-- SHIPPING ADDRESS -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background: #ffffff; border: 1px solid #e8ebf0; border-radius: 16px; padding: 20px 24px;">
                <div style="margin-bottom: 12px;">
                    <span style="font-size: 18px; margin-right: 8px;">📦</span>
                    <span style="font-size: 14px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 0.5px;">Ship To</span>
                </div>
                <p style="margin: 0; font-size: 14px; line-height: 1.8; color: #555;">
                    {address_html}{phone_html}
                </p>
            </div>
        </td></tr>

        <!-- CTA BUTTON -->
        <tr><td style="padding: 0 40px 32px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="#667EEA" style="background-color: #667EEA; border-radius: 50px;">
                <a href="{APP_BASE_URL}/seller/orders" target="_blank" style="display: inline-block; padding: 16px 48px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px; letter-spacing: 0.5px;">Manage Orders →</a>
            </td>
            </tr></table>
        </td></tr>

        <!-- CASL-COMPLIANT FOOTER -->
        {_casl_compliant_footer(include_gst=False)}

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """


def _email_wrapper(title: str, content_html: str, include_gst: bool = False) -> str:
    """Wrap email content in full branded HTML email template with CASL-compliant footer.

    Gmail-safe: uses bgcolor fallbacks, no CSS-only gradients for backgrounds.
    """
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{html.escape(title)} - Origna</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f0f2f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; -webkit-font-smoothing: antialiased;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f0f2f8;">
        <tr><td align="center" style="padding: 24px 16px;">
        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 20px 60px rgba(102, 126, 234, 0.15);">

        {content_html}

        {_casl_compliant_footer(include_gst=include_gst)}

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """


def _hero_header(icon: str, heading: str, subtext: str, icon_bg: str = "rgba(102, 126, 234, 0.2)") -> str:
    """Generate a branded hero header section for emails."""
    return f"""
        <tr><td bgcolor="#1F235A" style="background-color: #1F235A; background-image: linear-gradient(135deg, #1F235A 0%, #2F3B8F 40%, #764BA2 100%); padding: 48px 40px 40px 40px; text-align: center;">
            <div style="margin-bottom: 8px;">
                <span style="font-size: 14px; font-weight: 700; letter-spacing: 4px; text-transform: uppercase; color: rgba(255,255,255,0.6);">O R I G N A</span>
            </div>
            <div style="width: 72px; height: 72px; margin: 16px auto; background: {icon_bg}; border-radius: 50%; line-height: 72px; font-size: 36px;">
                {icon}
            </div>
            <h1 style="margin: 16px 0 8px 0; font-size: 28px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">{html.escape(heading)}</h1>
            <p style="margin: 0; font-size: 15px; color: rgba(255,255,255,0.75);">{html.escape(subtext)}</p>
        </td></tr>
    """


def _order_status_tracker(active_step: int) -> str:
    """Generate order status progress tracker. active_step: 1=Confirmed, 2=Processing, 3=Shipped, 4=Delivered."""
    steps = [
        ("Confirmed", "✓"),
        ("Processing", "📦"),
        ("Shipped", "🚚"),
        ("Delivered", "🏠"),
    ]
    rows = ""
    for i, (label, icon) in enumerate(steps):
        step_num = i + 1
        if step_num <= active_step:
            bg = "background: linear-gradient(135deg, #667EEA, #764BA2);"
            color = "#667EEA"
            weight = "700"
            text_color = "white"
        else:
            bg = "background-color: #e8ebf0;"
            color = "#999999"
            weight = "600"
            text_color = "#999999"
        rows += f"""
                <td width="25%" align="center">
                    <div style="width: 36px; height: 36px; {bg} border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: {text_color};">{icon}</div>
                    <div style="font-size: 11px; font-weight: {weight}; color: {color}; text-transform: uppercase; letter-spacing: 0.5px;">{label}</div>
                </td>"""

    pct = ["12%", "37%", "62%", "100%"][active_step - 1] if active_step > 0 else "0%"
    return f"""
        <tr><td style="padding: 32px 40px 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
            <tr>{rows}</tr>
            <tr><td colspan="4" style="padding-top: 12px;">
                <div style="height: 4px; background-color: #e8ebf0; border-radius: 4px; overflow: hidden;">
                    <div style="width: {pct}; height: 100%; background: linear-gradient(90deg, #667EEA, #764BA2); border-radius: 4px;"></div>
                </div>
            </td></tr>
            </table>
        </td></tr>
    """


def _cta_button(url: str, label: str, color: str = "#667EEA") -> str:
    """Generate a pill-shaped CTA button."""
    return f"""
        <tr><td style="padding: 0 40px 32px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="{color}" style="background-color: {color}; border-radius: 50px;">
                <a href="{url}" target="_blank" style="display: inline-block; padding: 16px 48px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px; letter-spacing: 0.5px;">{html.escape(label)}</a>
            </td>
            </tr></table>
        </td></tr>
    """


def _items_summary_table(items: list) -> str:
    """Generate a table of order items for receipt emails."""
    if not items:
        return ""
    rows = ""
    for i, item in enumerate(items):
        safe_name = html.escape(str(item.get(Fields.NAME, "Product")))
        qty = item.get(Fields.QUANTITY, 1)
        price = item.get(Fields.PRICE, 0)
        line_total = price * qty
        bg = "#f8f9ff" if i % 2 == 0 else "#ffffff"
        rows += f"""
        <tr style="background-color: {bg};">
            <td style="padding: 14px 16px; font-size: 14px; color: #1a1a2e;">
                <span style="font-weight: 600;">{safe_name}</span>
            </td>
            <td style="padding: 14px 16px; text-align: center; font-size: 14px; color: #555555;">
                &times;{qty}
            </td>
            <td style="padding: 14px 16px; text-align: right; font-size: 14px; font-weight: 600; color: #1a1a2e;">
                ${line_total:.2f}
            </td>
        </tr>"""

    return f"""
        <tr><td style="padding: 28px 40px 0 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #667EEA; padding-bottom: 6px;">Items Ordered</span>
            </h2>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-radius: 12px; overflow: hidden; border: 1px solid #e8ebf0;">
                <thead>
                    <tr bgcolor="#667EEA" style="background-color: #667EEA;">
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Product</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: center; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Qty</th>
                        <th bgcolor="#667EEA" style="padding: 12px 16px; text-align: right; font-size: 11px; font-weight: 700; color: white; text-transform: uppercase; letter-spacing: 1px;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {rows}
                </tbody>
            </table>
        </td></tr>
    """


def _price_summary_block(subtotal: float, shipping: float, taxes: float, total: float) -> str:
    """Generate Gmail-safe price summary block with receipt-style layout."""
    return f"""
        <tr><td style="padding: 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" bgcolor="#f8f9ff" style="background-color: #f8f9ff; border-radius: 16px; border: 1px solid #e0e3f0; overflow: hidden;">
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 20px 24px 4px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Subtotal</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${subtotal:.2f}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Shipping</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">{"Free" if shipping == 0 else f"${shipping:.2f}"}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #555555;">Taxes</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${taxes:.2f}</td>
                        </tr>
                    </table>
                </td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 0 24px;"><div style="height: 1px; background-color: #d0d4e8;"></div></td></tr>
                <tr><td bgcolor="#f8f9ff" style="background-color: #f8f9ff; padding: 16px 24px 20px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="font-size: 16px; font-weight: 700; color: #1a1a2e;">Total</td>
                            <td style="font-size: 22px; font-weight: 800; color: #667EEA; text-align: right; letter-spacing: -0.5px;">${total:.2f} <span style="font-size: 13px; font-weight: 600; color: #999999;">CAD</span></td>
                        </tr>
                    </table>
                </td></tr>
            </table>
        </td></tr>
    """


def get_order_shipped_email(order_data: dict, order_id: str, tracking_number: str = "N/A", carrier: str = "N/A") -> str:
    """Generate branded HTML email for order shipped notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id
    safe_tracking = html.escape(str(tracking_number))
    safe_carrier = html.escape(str(carrier))

    items = order_data.get(Fields.ITEMS, [])
    subtotal = order_data.get(Fields.SUBTOTAL_CENTS, 0) / 100
    shipping = order_data.get(Fields.SHIPPING_COST_CENTS, 0) / 100
    taxes = sum(order_data.get(Fields.TAXES, {}).values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    content = _hero_header("🚚", "Your Order Has Shipped!", "Your items are on the way.", "rgba(59, 130, 246, 0.2)")
    content += _order_status_tracker(3)

    content += f"""
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background-color: #e8ebf0;"></div></td></tr>

        <!-- Tracking Info -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e0e3f0; border-radius: 16px; padding: 20px 24px;">
                <div style="margin-bottom: 12px;">
                    <span style="font-size: 18px; margin-right: 8px;">📦</span>
                    <span style="font-size: 14px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 0.5px;">Tracking Details</span>
                </div>
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888; width: 120px;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600; font-family: 'Courier New', monospace;">#{short_oid}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Carrier:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 500;">{safe_carrier}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Tracking #:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #667EEA; font-weight: 600;">{safe_tracking}</td>
                    </tr>
                </table>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _price_summary_block(subtotal, shipping, taxes, total)
    content += _cta_button(f"{APP_BASE_URL}/orders", "Track Your Order →")

    return _email_wrapper("Order Shipped", content, include_gst=True)


def get_order_in_transit_email(order_data: dict, order_id: str) -> str:
    """Generate branded HTML email for order in-transit notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id

    tracking_number = order_data.get(Fields.TRACKING_NUMBER, "N/A")
    carrier = order_data.get(Fields.CARRIER, "N/A")
    safe_tracking = html.escape(str(tracking_number))
    safe_carrier = html.escape(str(carrier))

    items = order_data.get(Fields.ITEMS, [])
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    content = _hero_header(
        "🚚", "Your Order Is In Transit!", "Your package is on its way to you.", "rgba(59, 130, 246, 0.2)"
    )
    content += _order_status_tracker(3)  # Between shipped and delivered

    content += f"""
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background-color: #e8ebf0;"></div></td></tr>

        <!-- Tracking Info -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 16px; padding: 20px 24px;">
                <div style="margin-bottom: 12px;">
                    <span style="font-size: 18px; margin-right: 8px;">📍</span>
                    <span style="font-size: 14px; font-weight: 700; color: #1E40AF; text-transform: uppercase; letter-spacing: 0.5px;">Tracking Details</span>
                </div>
                <table role="presentation" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 16px 4px 0; font-size: 13px; color: #888888;">Order:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600; font-family: 'Courier New', monospace;">#{short_oid}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 16px 4px 0; font-size: 13px; color: #888888;">Carrier:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 500;">{safe_carrier}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 16px 4px 0; font-size: 13px; color: #888888;">Tracking #:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #667EEA; font-weight: 600;">{safe_tracking}</td>
                    </tr>
                </table>
            </div>
        </td></tr>

        <tr><td style="padding: 0 40px 16px 40px; text-align: center;">
            <p style="margin: 0; font-size: 13px; color: #6B7280; line-height: 1.6;">Your package with {len(items)} item{"s" if len(items) != 1 else ""} worth <strong>${total:.2f} CAD</strong> is on the move. You'll receive another update once it's delivered.</p>
        </td></tr>
    """

    content += _cta_button(f"{APP_BASE_URL}/orders", "Track Your Order →")

    return _email_wrapper("Order In Transit", content, include_gst=False)


def get_order_delivered_email(order_data: dict, order_id: str) -> str:
    """Generate branded HTML email for order delivered notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id

    items = order_data.get(Fields.ITEMS, [])
    subtotal = order_data.get(Fields.SUBTOTAL_CENTS, 0) / 100
    shipping = order_data.get(Fields.SHIPPING_COST_CENTS, 0) / 100
    taxes = sum(order_data.get(Fields.TAXES, {}).values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    from schema_constants import BusinessRules

    content = _hero_header(
        "🏠", "Your Order Has Been Delivered!", "We hope you love your items.", "rgba(16, 185, 129, 0.2)"
    )
    content += _order_status_tracker(4)

    content += f"""
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background-color: #e8ebf0;"></div></td></tr>

        <!-- Confirmation Notice -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #ECFDF5; border: 1px solid #A7F3D0; border-radius: 16px; padding: 20px 24px;">
                <p style="margin: 0 0 8px 0; font-size: 14px; font-weight: 700; color: #065F46;">📋 Please Confirm Receipt</p>
                <p style="margin: 0 0 8px 0; font-size: 13px; color: #047857; line-height: 1.6;">Confirming receipt helps us release payment to the seller and improves the marketplace for everyone.</p>
                <p style="margin: 0; font-size: 12px; color: #6B7280;"><strong>Note:</strong> Payment will be auto-released after {BusinessRules.AUTO_CONFIRM_DAYS} days if not confirmed.</p>
            </div>
        </td></tr>

        <!-- Order ID badge -->
        <tr><td style="padding: 0 40px 16px 40px; text-align: center;">
            <div style="display: inline-block; background-color: #f8f9ff; border: 1px solid #e0e3f0; border-radius: 50px; padding: 10px 24px;">
                <span style="font-size: 12px; color: #888888; text-transform: uppercase; letter-spacing: 1px;">Order</span>
                <span style="font-size: 15px; color: #1a1a2e; font-weight: 700; margin-left: 6px; font-family: 'Courier New', monospace;">#{short_oid}</span>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _price_summary_block(subtotal, shipping, taxes, total)

    # Return & refund policy notice
    content += f"""
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e8ebf0; border-radius: 12px; padding: 16px 20px;">
                <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: #1a1a2e;">Return &amp; Refund Policy</p>
                <p style="margin: 0; font-size: 12px; color: #555555; line-height: 1.6;">Returns and refunds are accepted within <strong>{BusinessRules.RETURN_WINDOW_DAYS} days of delivery</strong>. After that, all sales are final. Contact <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA;">{EmailConfig.SUPPORT_EMAIL}</a> with your order ID within the return window.</p>
            </div>
        </td></tr>
    """

    content += _cta_button(f"{APP_BASE_URL}/orders", "Confirm Receipt →", "#10B981")

    return _email_wrapper("Order Delivered", content, include_gst=True)


def get_order_cancelled_email(order_data: dict, order_id: str, reason: str = "Unknown") -> str:
    """Generate branded HTML email for order cancelled notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id
    safe_reason = html.escape(str(reason))

    items = order_data.get(Fields.ITEMS, [])
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    content = _hero_header("❌", "Order Cancelled", "Your order has been cancelled.", "rgba(220, 38, 38, 0.2)")

    content += f"""
        <!-- Cancellation details -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #FEF2F2; border: 1px solid #FECACA; border-radius: 16px; padding: 20px 24px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888; width: 100px;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600; font-family: 'Courier New', monospace;">#{short_oid}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Amount:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600;">${total:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Reason:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #DC2626; font-weight: 500;">{safe_reason}</td>
                    </tr>
                </table>
            </div>
        </td></tr>

        <!-- Refund notice -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e8ebf0; border-radius: 12px; padding: 16px 20px;">
                <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: #1a1a2e;">💰 Refund Information</p>
                <p style="margin: 0; font-size: 12px; color: #555555; line-height: 1.6;">If payment was captured, a full refund will be issued to your original payment method within 5-10 business days. If you don't see the refund, contact your bank or <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA;">{EmailConfig.SUPPORT_EMAIL}</a>.</p>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _cta_button(f"{APP_BASE_URL}/orders", "View Orders →")

    return _email_wrapper("Order Cancelled", content, include_gst=False)


def get_order_processing_email(order_data: dict, order_id: str) -> str:
    """Generate branded HTML email for order processing (payment captured successfully)."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id

    items = order_data.get(Fields.ITEMS, [])
    subtotal = order_data.get(Fields.SUBTOTAL_CENTS, 0) / 100
    shipping = order_data.get(Fields.SHIPPING_COST_CENTS, 0) / 100
    taxes = sum(order_data.get(Fields.TAXES, {}).values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    content = _hero_header(
        "⚙️",
        "Your Order Is Being Processed!",
        "Payment confirmed — sellers are preparing your items.",
        "rgba(99, 102, 241, 0.2)",
    )
    content += _order_status_tracker(2)

    content += f"""
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background-color: #e8ebf0;"></div></td></tr>

        <!-- Processing notice -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #EEF2FF; border: 1px solid #C7D2FE; border-radius: 16px; padding: 20px 24px;">
                <p style="margin: 0 0 8px 0; font-size: 14px; font-weight: 700; color: #3730A3;">✅ Payment Confirmed</p>
                <p style="margin: 0 0 8px 0; font-size: 13px; color: #4338CA; line-height: 1.6;">Your payment of <strong>${total:.2f} CAD</strong> has been captured. Sellers have been notified and are now preparing your items for shipment.</p>
                <p style="margin: 0; font-size: 12px; color: #6B7280;">You'll receive a shipping notification with tracking details once your items are on the way.</p>
            </div>
        </td></tr>

        <!-- Order ID badge -->
        <tr><td style="padding: 0 40px 16px 40px; text-align: center;">
            <div style="display: inline-block; background-color: #f8f9ff; border: 1px solid #e0e3f0; border-radius: 50px; padding: 10px 24px;">
                <span style="font-size: 12px; color: #888888; text-transform: uppercase; letter-spacing: 1px;">Order</span>
                <span style="font-size: 15px; color: #1a1a2e; font-weight: 700; margin-left: 6px; font-family: 'Courier New', monospace;">#{short_oid}</span>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _price_summary_block(subtotal, shipping, taxes, total)
    content += _cta_button(f"{APP_BASE_URL}/orders", "View Order →")

    return _email_wrapper("Order Processing", content, include_gst=True)


def get_order_refunded_email(order_data: dict, order_id: str, refund_amount_cents: int = 0) -> str:
    """Generate branded HTML email for full refund notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id

    items = order_data.get(Fields.ITEMS, [])
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
    refund_amount = refund_amount_cents / 100 if refund_amount_cents else total

    content = _hero_header(
        "💰",
        "Your Refund Has Been Processed",
        "A full refund has been issued for your order.",
        "rgba(16, 185, 129, 0.2)",
    )

    content += f"""
        <!-- Refund details -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #ECFDF5; border: 1px solid #A7F3D0; border-radius: 16px; padding: 20px 24px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888; width: 120px;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600; font-family: 'Courier New', monospace;">#{short_oid}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Refund Amount:</td>
                        <td style="padding: 4px 0; font-size: 16px; color: #059669; font-weight: 700;">${refund_amount:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Status:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #059669; font-weight: 600;">Full Refund</td>
                    </tr>
                </table>
            </div>
        </td></tr>

        <!-- Timeline notice -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e8ebf0; border-radius: 12px; padding: 16px 20px;">
                <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: #1a1a2e;">🏦 When Will I See My Refund?</p>
                <p style="margin: 0; font-size: 12px; color: #555555; line-height: 1.6;">Refunds typically appear on your statement within <strong>5-10 business days</strong>, depending on your bank. If you don't see the refund after 10 business days, contact your bank or reach out to <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA;">{EmailConfig.SUPPORT_EMAIL}</a>.</p>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _cta_button(f"{APP_BASE_URL}/orders", "View Orders →")

    return _email_wrapper("Order Refunded", content, include_gst=False)


def get_order_partially_refunded_email(order_data: dict, order_id: str, refund_amount_cents: int = 0) -> str:
    """Generate branded HTML email for partial refund notification."""
    short_oid = order_id[:8] if len(order_id) > 8 else order_id

    items = order_data.get(Fields.ITEMS, [])
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
    refund_amount = refund_amount_cents / 100 if refund_amount_cents else 0

    content = _hero_header(
        "💸", "Partial Refund Processed", "A partial refund has been issued for your order.", "rgba(245, 158, 11, 0.2)"
    )

    content += f"""
        <!-- Partial refund details -->
        <tr><td style="padding: 24px 40px;">
            <div style="background-color: #FFFBEB; border: 1px solid #FDE68A; border-radius: 16px; padding: 20px 24px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888; width: 120px;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 600; font-family: 'Courier New', monospace;">#{short_oid}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Original Total:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; font-weight: 500;">${total:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Refund Amount:</td>
                        <td style="padding: 4px 0; font-size: 16px; color: #D97706; font-weight: 700;">${refund_amount:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888888;">Status:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #D97706; font-weight: 600;">Partial Refund</td>
                    </tr>
                </table>
            </div>
        </td></tr>

        <!-- Timeline notice -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <div style="background-color: #f8f9ff; border: 1px solid #e8ebf0; border-radius: 12px; padding: 16px 20px;">
                <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: #1a1a2e;">🏦 When Will I See My Refund?</p>
                <p style="margin: 0; font-size: 12px; color: #555555; line-height: 1.6;">Partial refunds typically appear on your statement within <strong>5-10 business days</strong>. The remaining balance of <strong>${(total - refund_amount):.2f} CAD</strong> is not affected. Questions? Contact <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA;">{EmailConfig.SUPPORT_EMAIL}</a>.</p>
            </div>
        </td></tr>
    """

    content += _items_summary_table(items)
    content += _cta_button(f"{APP_BASE_URL}/orders", "View Orders →")

    return _email_wrapper("Partial Refund", content, include_gst=False)


def send_email(to_email, subject, html_content, from_email=EmailConfig.SUPPORT_EMAIL, attachments=None):
    """Send email using Mailjet — CASL compliant with List-Unsubscribe header

    Args:
        to_email: Recipient email address
        subject: Email subject line
        html_content: HTML body
        from_email: Sender email (default: support@)
        attachments: Optional list of dicts with keys:
            - ContentType (str): MIME type, e.g. 'application/pdf'
            - Filename (str): Attachment filename
            - Base64Content (str): Base64-encoded file content
    """
    try:
        if (IS_EMULATOR and not FORCE_REAL_EMAIL) or not MAILJET_API_KEY:
            MAILJET_CREDENTIAL_REDACTED(f"\U0001f4e7 [EMULATOR] Would send email to {to_email}: {subject}")
            if attachments:
                logger.info(f"   📎 With {len(attachments)} attachment(s): {[a.get('Filename') for a in attachments]}")
            return True

        mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version=EmailConfig.MAILJET_API_VERSION)

        message = {
            "From": {"Email": from_email, "Name": EmailConfig.SENDER_NAME},
            "To": [{"Email": to_email}],
            "Subject": subject,
            "HTMLPart": html_content,
            "Headers": {
                "List-Unsubscribe": f"<{_get_signed_unsubscribe_url(to_email)}>, <mailto:{EmailConfig.SUPPORT_EMAIL}?subject=Unsubscribe>",
                "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
            },
        }

        # Attach files (e.g. PDF invoice)
        if attachments:
            message["Attachments"] = attachments

        data = {"Messages": [message]}

        result = mailjet.send.create(data=data)
        if result.status_code == 200:
            logger.info(f"✉️ Mailjet email sent to {to_email}")
            return True
        else:
            logger.error(f"❌ Mailjet failed: {result.json()}")
            return False
    except Exception as e:
        logger.error(f"❌ Mailjet error: {str(e)}")
        return False


def send_authorization_expired_email(order_id: str, order_data: dict) -> None:
    """Send notification when payment authorization expires after 7 days"""
    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        logger.info(f"🔧 EMULATOR: Would send authorization expired email for order {order_id}")
        return

    if not MAILJET_API_KEY or not MAILJET_SECRET_KEY:
        MAILJET_CREDENTIAL_REDACTED("⚠️ Mailjet credentials not configured")
        return

    try:
        mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version=EmailConfig.MAILJET_API_VERSION)

        customer_email = order_data.get(Fields.CUSTOMER_EMAIL)
        total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
        items_summary = ", ".join(
            [
                f"{html.escape(str(item.get(Fields.NAME, '')))} x{item.get(Fields.QUANTITY, 1)}"
                for item in order_data.get(Fields.ITEMS, [])[:3]
            ]
        )

        # Email to buyer
        buyer_message = {
            "Messages": [
                {
                    "From": {"Email": EmailConfig.SUPPORT_EMAIL, "Name": EmailConfig.SENDER_NAME},
                    "To": [{"Email": customer_email}],
                    "Subject": f"Order {order_id[:8]} - Authorization Expired",
                    "HTMLPart": f"""
                <html>
                <body style="font-family: Arial, sans-serif; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #FF6B35;">⏰ Payment Authorization Expired</h2>
                        <p>Your order authorization has expired after 7 days without seller confirmation.</p>

                        <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
                            <p><strong>Order ID:</strong> {order_id}</p>
                            <p><strong>Items:</strong> {items_summary}</p>
                            <p><strong>Amount:</strong> ${total:.2f} CAD</p>
                        </div>

                        <p>The hold on your payment has been released. No charge was made to your card.</p>
                        <p>If you still want these items, please place a new order.</p>

                        <p style="margin-top: 20px; font-size: 12px; color: #666;">
                            {EmailConfig.PHYSICAL_ADDRESS}<br>
                            Questions? Contact <a href="mailto:{EmailConfig.SUPPORT_EMAIL}">{EmailConfig.SUPPORT_EMAIL}</a><br>
                            <a href="{UNSUBSCRIBE_URL}">Unsubscribe</a> | <a href="{APP_BASE_URL}/privacy-policy">Privacy Policy</a>
                        </p>
                        <p style="margin-top: 8px; font-size: 11px; color: #999;">{EmailConfig.COPYRIGHT_TEXT}</p>
                    </div>
                </body>
                </html>
                """,
                }
            ]
        }

        mailjet.send.create(data=buyer_message)
        logger.info(f"✅ Authorization expired email sent to {customer_email}")

    except Exception as e:
        logger.warning(f"⚠️ Failed to send authorization expired email: {str(e)}")


def send_payment_capture_failed_email(
    order_id: str, customer_email: str, customer_name: str, amount: float, error_message: str
):
    """
    Send email notification when payment capture fails.
    Instructs buyer to update payment method or contact support.
    """
    if not customer_email:
        logger.info("Cannot send capture failure email: missing customer_email")
        return

    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        logger.info(f"EMULATOR: Would send capture failure email for order {order_id[:8]}")
        return

    # AUDIT FIX: Guard against missing Mailjet credentials (prevents crash)
    if not MAILJET_API_KEY or not MAILJET_SECRET_KEY:
        MAILJET_CREDENTIAL_REDACTED("Mailjet not configured — skipping capture failure email")
        return

    # Sanitize user-controlled inputs before HTML injection
    safe_name = html.escape(str(customer_name or ""))
    safe_error = html.escape(str(error_message or "Unknown error"))

    # Initialize Mailjet client
    mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version=EmailConfig.MAILJET_API_VERSION)

    subject = f"Payment Issue - Order #{order_id[:8]}"
    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Issue - Origna</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f0f2f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
        <div style="display:none;font-size:1px;color:#f0f2f8;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">Action required: payment issue with order #{order_id[:8]}</div>
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f0f2f8;">
        <tr><td align="center" style="padding: 24px 16px;">
        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 20px; overflow: hidden;">

        <!-- Header -->
        <tr><td bgcolor="#1F235A" style="background-color: #1F235A; padding: 40px 40px 32px 40px; text-align: center;">
            <div style="margin-bottom: 8px;">
                <span style="font-size: 14px; font-weight: 700; letter-spacing: 4px; text-transform: uppercase; color: #9999b3;">O R I G N A</span>
            </div>
            <div style="font-size: 48px; margin: 12px 0;">⚠️</div>
            <h1 style="margin: 12px 0 8px 0; font-size: 24px; font-weight: 800; color: #ffffff;">Payment Issue</h1>
            <p style="margin: 0; font-size: 14px; color: #b0b0cc;">Action required for Order #{order_id[:8]}</p>
        </td></tr>

        <!-- Alert Banner -->
        <tr><td bgcolor="#FEF3C7" style="background-color: #FEF3C7; border-left: 4px solid #F59E0B; padding: 16px 40px;">
            <span style="font-size: 14px; font-weight: 700; color: #92400E;">⚠️ Action Required</span><br>
            <span style="font-size: 14px; color: #78350F;">We couldn't complete the payment for your order.</span>
        </td></tr>

        <!-- Content -->
        <tr><td style="padding: 28px 40px;">
            <p style="margin: 0 0 20px 0; font-size: 15px; color: #333;">Hi {safe_name},</p>

            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f8f9ff; border-radius: 12px; border: 1px solid #e5e8f5; margin-bottom: 24px;">
            <tr><td style="padding: 16px 20px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 600;">{order_id[:8]}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Amount:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 600;">${amount:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Issue:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #dc2626; text-align: right; font-weight: 500;">{safe_error}</td>
                    </tr>
                </table>
            </td></tr>
            </table>

            <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1a1a2e;">What happened?</p>
            <p style="margin: 0 0 12px 0; font-size: 14px; color: #555; line-height: 1.6;">Your payment was authorized but couldn't be charged. Common causes:</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">&bull; Card has insufficient funds</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">&bull; Card was canceled or expired</p>
            <p style="margin: 0 0 20px 0; font-size: 14px; color: #555;">&bull; Bank declined the transaction</p>

            <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1a1a2e;">Next steps:</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">1. Log in to your account</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">2. Update your payment method</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">3. Contact your bank if the issue persists</p>
        </td></tr>

        <!-- CTA Button -->
        <tr><td style="padding: 0 40px 28px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="#667EEA" style="background-color: #667EEA; border-radius: 50px;">
                <a href="{APP_BASE_URL}/orders/{order_id}" target="_blank" style="display: inline-block; padding: 14px 40px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px;">View Order</a>
            </td>
            </tr></table>
        </td></tr>

        <tr><td style="padding: 0 40px 24px 40px;">
            <p style="margin: 0; font-size: 13px; color: #888; text-align: center;">Need help? Contact us with order ID: <strong>{order_id[:8]}</strong></p>
        </td></tr>

        <!-- CASL-COMPLIANT FOOTER -->
        {_casl_compliant_footer(include_gst=False)}

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """

    try:
        result = mailjet.send.create(
            data={
                "Messages": [
                    {
                        "From": {"Email": EmailConfig.SUPPORT_EMAIL, "Name": EmailConfig.SENDER_NAME},
                        "To": [{"Email": customer_email, "Name": customer_name}],
                        "Subject": subject,
                        "HTMLPart": html_body,
                        "Headers": {
                            "List-Unsubscribe": f"<{_get_signed_unsubscribe_url(customer_email)}>, <mailto:{EmailConfig.SUPPORT_EMAIL}?subject=Unsubscribe>",
                            "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
                        },
                    }
                ]
            }
        )
        logger.info(f"✅ Capture failure email sent to {customer_email}")
        return result
    except Exception as e:
        logger.error(f"❌ Failed to send capture failure email: {str(e)}")
        raise


def send_3ds_authentication_email(
    order_id: str, customer_email: str, customer_name: str, authentication_url: str, amount: float
):
    """
    Send email with 3DS authentication link for Airwallex payments.
    Required when card issuer needs additional verification.
    """
    if not customer_email or not authentication_url:
        logger.warning("⚠️ Cannot send 3DS email: missing customer_email or authentication_url")
        return

    # AUDIT FIX: Validate authentication URL domain to prevent phishing
    from urllib.parse import urlparse

    parsed_url = urlparse(authentication_url)
    ALLOWED_3DS_DOMAINS = {
        "checkout.airwallex.com",
        "pci-host.airwallex.com",
        "pci-api.airwallex.com",
        "api.airwallex.com",
    }
    if parsed_url.hostname not in ALLOWED_3DS_DOMAINS:
        logger.critical(f"SECURITY: Blocked suspicious 3DS URL domain: {parsed_url.hostname}")
        return

    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        logger.info(f"🧪 EMULATOR: Would send 3DS authentication email to {customer_email}")
        logger.info(f"   Order: {order_id}, Amount: ${amount:.2f}, URL: {authentication_url}")
        return

    # Sanitize user-controlled values to prevent HTML injection
    safe_name = html.escape(str(customer_name or ""))

    # Initialize Mailjet client
    mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version=EmailConfig.MAILJET_API_VERSION)

    subject = f"Action Required: Verify Your Payment - Order #{order_id[:8]}"
    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verify Payment - Origna</title>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f0f2f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
        <div style="display:none;font-size:1px;color:#f0f2f8;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">Action required: verify your payment for order #{order_id[:8]} — ${amount:.2f} CAD</div>
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f0f2f8;">
        <tr><td align="center" style="padding: 24px 16px;">
        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 20px; overflow: hidden;">

        <!-- Header -->
        <tr><td bgcolor="#1F235A" style="background-color: #1F235A; padding: 40px 40px 32px 40px; text-align: center;">
            <div style="margin-bottom: 8px;">
                <span style="font-size: 14px; font-weight: 700; letter-spacing: 4px; text-transform: uppercase; color: #9999b3;">O R I G N A</span>
            </div>
            <div style="font-size: 48px; margin: 12px 0;">&#128274;</div>
            <h1 style="margin: 12px 0 8px 0; font-size: 24px; font-weight: 800; color: #ffffff;">Secure Payment Verification</h1>
            <p style="margin: 0; font-size: 14px; color: #b0b0cc;">Your bank requires additional verification</p>
        </td></tr>

        <!-- Alert -->
        <tr><td bgcolor="#DBEAFE" style="background-color: #DBEAFE; border-left: 4px solid #2563EB; padding: 16px 40px;">
            <span style="font-size: 14px; font-weight: 700; color: #1E40AF;">Action Required: Verify Your Payment</span><br>
            <span style="font-size: 14px; color: #1E3A5F;">Your bank requires 3D Secure authentication to complete this transaction.</span>
        </td></tr>

        <!-- Content -->
        <tr><td style="padding: 28px 40px;">
            <p style="margin: 0 0 20px 0; font-size: 15px; color: #333;">Hi {safe_name},</p>

            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f8f9ff; border-radius: 12px; border: 1px solid #e5e8f5; margin-bottom: 24px;">
            <tr><td style="padding: 16px 20px;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Order ID:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 600;">{order_id[:8]}</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Amount:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 600;">${amount:.2f} CAD</td>
                    </tr>
                    <tr>
                        <td style="padding: 4px 0; font-size: 13px; color: #888;">Status:</td>
                        <td style="padding: 4px 0; font-size: 14px; color: #2563EB; text-align: right; font-weight: 600;">Pending Verification</td>
                    </tr>
                </table>
            </td></tr>
            </table>

            <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1a1a2e;">What is 3D Secure?</p>
            <p style="margin: 0 0 20px 0; font-size: 14px; color: #555; line-height: 1.6;">3D Secure (3DS) is an additional security layer that protects your payment. Your bank requires you to verify your identity before completing this purchase.</p>
        </td></tr>

        <!-- CTA Button -->
        <tr><td style="padding: 0 40px 20px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="#2563EB" style="background-color: #2563EB; border-radius: 50px;">
                <a href="{authentication_url}" target="_blank" style="display: inline-block; padding: 16px 48px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px;">Verify Payment Now</a>
            </td>
            </tr></table>
        </td></tr>

        <!-- Warning -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" bgcolor="#FEF3C7" style="background-color: #FEF3C7; border-left: 4px solid #F59E0B; border-radius: 8px;">
            <tr><td style="padding: 16px 20px;">
                <span style="font-size: 14px; font-weight: 700; color: #92400E;">&#9200; Time Sensitive</span><br>
                <span style="font-size: 14px; color: #78350F;">Please complete verification within 15 minutes. After that, you'll need to place a new order.</span>
            </td></tr>
            </table>
        </td></tr>

        <!-- Security Tips -->
        <tr><td style="padding: 0 40px 24px 40px;">
            <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1a1a2e;">Security Tips:</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">&#9989; This email is from Origna's official address</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">&#9989; The verification link goes to your bank's secure portal</p>
            <p style="margin: 0 0 4px 0; font-size: 14px; color: #555;">&#10060; We will never ask for your card details via email</p>
            <p style="margin: 0 0 12px 0; font-size: 14px; color: #555;">&#10060; Never share verification codes with anyone</p>
            <p style="margin: 0; font-size: 13px; color: #888;">If you didn't place this order, <a href="{APP_BASE_URL}/support" style="color: #667EEA; text-decoration: none;">contact support immediately</a>.</p>
        </td></tr>

        <!-- Footer -->
        <tr><td bgcolor="#1a1a2e" style="background-color: #1a1a2e; padding: 28px 40px; text-align: center;">
            <div style="margin-bottom: 12px;">
                <span style="font-size: 12px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; color: #808097;">O R I G N A</span>
            </div>
            <p style="margin: 0 0 8px 0; font-size: 12px; color: #5c5c72;">{EmailConfig.PHYSICAL_ADDRESS}</p>
            <p style="margin: 0 0 8px 0; font-size: 12px; color: #5c5c72;">Questions? <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a></p>
            <p style="margin: 0 0 8px 0; font-size: 11px; color: #4a4a60;">Order ID: {order_id}</p>
            <p style="margin: 0 0 12px 0; font-size: 12px; color: #5c5c72;"><a href="{UNSUBSCRIBE_URL}" style="color: #667EEA; text-decoration: underline;">Unsubscribe</a> | <a href="{APP_BASE_URL}/privacy-policy" style="color: #667EEA; text-decoration: none;">Privacy Policy</a></p>
            <div style="border-top: 1px solid #333348; padding-top: 12px;">
                <p style="margin: 0; font-size: 11px; color: #4a4a60;">{EmailConfig.COPYRIGHT_TEXT}</p>
            </div>
        </td></tr>

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """

    # RETRY LOGIC: We do NOT catch exceptions here.
    # Cloud Functions will retry execution if an exception is raised.
    # This prevents email loss during temporary Mailjet outages.
    result = mailjet.send.create(
        data={
            "Messages": [
                {
                    "From": {"Email": EmailConfig.SUPPORT_EMAIL, "Name": EmailConfig.SENDER_NAME_SECURITY},
                    "To": [{"Email": customer_email, "Name": customer_name}],
                    "Subject": subject,
                    "HTMLPart": html_body,
                    "Headers": {
                        "List-Unsubscribe": f"<{_get_signed_unsubscribe_url(customer_email)}>, <mailto:{EmailConfig.SUPPORT_EMAIL}?subject=Unsubscribe>",
                        "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
                    },
                }
            ]
        }
    )

    logger.info(f"✅ 3DS authentication email sent to {customer_email}")
    return result
