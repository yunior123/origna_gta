import html
import os
from datetime import datetime

from mailjet_rest import Client

from config import IS_EMULATOR, MAILJET_API_KEY, MAILJET_SECRET_KEY
from schema_constants import AppConfig, EmailConfig, Fields

# Allow real email sending in emulator mode for E2E testing
FORCE_REAL_EMAIL = os.environ.get('FORCE_REAL_EMAIL', 'false').lower() == 'true'

# Dynamic base URL for email links — Flutter web local in emulator, prod otherwise
APP_BASE_URL = EmailConfig.DEV_URL if IS_EMULATOR else EmailConfig.PROD_URL

def get_order_confirmation_email(order_data, order_id=None):
    """Generate HTML email for customer order confirmation

    Args:
        order_data: Dict containing order information
        order_id: Optional order ID (can be in order_data[Fields.ORDER_ID] instead)
    """
    oid = order_data.get(Fields.ORDER_ID, order_id or 'N/A')
    short_oid = oid[:8] if len(oid) > 8 else oid

    items_html = ""
    for i, item in enumerate(order_data.get(Fields.ITEMS, [])):
        safe_name = html.escape(str(item.get(Fields.NAME, 'Product')))
        qty = item.get(Fields.QUANTITY, 1)
        price = item.get(Fields.PRICE, 0)
        line_total = price * qty
        bg = '#f8f9ff' if i % 2 == 0 else '#ffffff'
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
    taxes = sum(order_data.get(Fields.TAXES, {}).values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100

    delivery_info = order_data.get(Fields.SHIPPING_ADDRESS, {})
    address_parts = [
        delivery_info.get(Fields.STREET, ''),
        delivery_info.get(Fields.APARTMENT, ''),
        f"{delivery_info.get(Fields.CITY, '')}, {delivery_info.get(Fields.STATE, '')} {delivery_info.get(Fields.POSTAL_CODE, '')}",
        delivery_info.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME),
    ]
    formatted_address = '<br>'.join(p for p in address_parts if p and p.strip())
    phone_html = f"<br>📱 {delivery_info[Fields.PHONE_NUMBER]}" if delivery_info.get(Fields.PHONE_NUMBER) else ''

    order_date = datetime.now().strftime('%B %d, %Y at %I:%M %p')

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
        <tr><td style="padding: 0 40px;"><div style="height: 1px; background: linear-gradient(90deg, transparent, #e8ebf0, transparent);"></div></td></tr>

        <!-- ITEMS TABLE -->
        <tr><td style="padding: 28px 40px 0 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #667EEA; padding-bottom: 6px;">Items Ordered</span>
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

        <!-- PRICE SUMMARY -->
        <tr><td style="padding: 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background: linear-gradient(135deg, #f8f9ff 0%, #f3f0ff 100%); border-radius: 16px; border: 1px solid rgba(102, 126, 234, 0.1); overflow: hidden;">
                <tr><td style="padding: 20px 24px 4px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Subtotal</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${subtotal:.2f}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Shipping</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">{"Free" if shipping == 0 else f"${shipping:.2f}"}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Taxes</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${taxes:.2f}</td>
                        </tr>
                    </table>
                </td></tr>
                <tr><td style="padding: 0 24px;"><div style="height: 1px; background: rgba(102, 126, 234, 0.15);"></div></td></tr>
                <tr><td style="padding: 16px 24px 20px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="font-size: 16px; font-weight: 700; color: #1a1a2e;">Total</td>
                            <td style="font-size: 22px; font-weight: 800; color: #667EEA; text-align: right; letter-spacing: -0.5px;">${total:.2f} <span style="font-size: 13px; font-weight: 600; color: #999;">CAD</span></td>
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
            <p style="margin: 0; font-size: 12px; color: #999;">🕐 Ordered on {order_date}</p>
        </td></tr>

        <!-- CTA BUTTON -->
        <tr><td style="padding: 0 40px 32px 40px; text-align: center;">
            <table role="presentation" cellspacing="0" cellpadding="0" align="center" style="margin: 0 auto;"><tr>
            <td align="center" bgcolor="#667EEA" style="background-color: #667EEA; border-radius: 50px;">
                <a href="{APP_BASE_URL}/orders" target="_blank" style="display: inline-block; padding: 16px 48px; font-size: 15px; font-weight: 700; color: #ffffff; text-decoration: none; border-radius: 50px; letter-spacing: 0.5px;">Track Your Order →</a>
            </td>
            </tr></table>
        </td></tr>

        <!-- FOOTER -->
        <tr><td bgcolor="#1a1a2e" style="background-color: #1a1a2e; padding: 32px 40px; text-align: center;">
            <div style="margin-bottom: 16px;">
                <span style="font-size: 12px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; color: rgba(255,255,255,0.5);">O R I G N A</span>
            </div>
            <p style="margin: 0 0 8px 0; font-size: 13px; color: rgba(255,255,255,0.5);">{EmailConfig.APP_TAGLINE}</p>
            <p style="margin: 0 0 16px 0; font-size: 12px; color: rgba(255,255,255,0.35);">Questions? Reach us at <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a></p>
            <div style="border-top: 1px solid rgba(255,255,255,0.1); padding-top: 16px;">
                <p style="margin: 0; font-size: 11px; color: rgba(255,255,255,0.25);">{EmailConfig.COPYRIGHT_TEXT}</p>
            </div>
        </td></tr>

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
        seller_id: Optional seller ID to filter items

    Note: seller_id is currently unused but kept for API compatibility
    """
    oid = order_data.get(Fields.ORDER_ID, order_id or 'N/A')
    short_oid = oid[:8] if len(oid) > 8 else oid

    items_html = ""
    for i, item in enumerate(order_data.get(Fields.ITEMS, [])):
        safe_name = html.escape(str(item.get(Fields.NAME, 'Product')))
        qty = item.get(Fields.QUANTITY, 1)
        price = item.get(Fields.PRICE, 0)
        line_total = price * qty
        bg = '#f8f9ff' if i % 2 == 0 else '#ffffff'
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
    taxes = sum(order_data.get(Fields.TAXES, {}).values())
    total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
    num_items = sum(item.get(Fields.QUANTITY, 1) for item in order_data.get(Fields.ITEMS, []))

    delivery_info = order_data.get(Fields.SHIPPING_ADDRESS, {})
    addr_parts = [
        delivery_info.get(Fields.STREET, ''),
        delivery_info.get(Fields.APARTMENT, ''),
        f"{delivery_info.get(Fields.CITY, '')}, {delivery_info.get(Fields.STATE, '')} {delivery_info.get(Fields.POSTAL_CODE, '')}",
        delivery_info.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME),
    ]
    address_html = '<br>'.join(p for p in addr_parts if p and p.strip())
    phone_html = f"<br>📱 {delivery_info[Fields.PHONE_NUMBER]}" if delivery_info.get(Fields.PHONE_NUMBER) else ''

    order_date = datetime.now().strftime('%B %d, %Y at %I:%M %p')
    customer_email = html.escape(order_data.get(Fields.CUSTOMER_EMAIL, 'N/A'))

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
            <div style="background: linear-gradient(135deg, #f8f9ff 0%, #f3f0ff 100%); border: 1px solid rgba(102, 126, 234, 0.1); border-radius: 16px; padding: 20px 24px;">
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

        <!-- PRICE SUMMARY -->
        <tr><td style="padding: 24px 40px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background: linear-gradient(135deg, #f8f9ff 0%, #f3f0ff 100%); border-radius: 16px; border: 1px solid rgba(102, 126, 234, 0.1); overflow: hidden;">
                <tr><td style="padding: 20px 24px 4px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Subtotal</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${subtotal:.2f}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Shipping</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">{"Free" if shipping == 0 else f"${shipping:.2f}"}</td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 0; font-size: 14px; color: #666;">Taxes</td>
                            <td style="padding: 6px 0; font-size: 14px; color: #1a1a2e; text-align: right; font-weight: 500;">${taxes:.2f}</td>
                        </tr>
                    </table>
                </td></tr>
                <tr><td style="padding: 0 24px;"><div style="height: 1px; background: rgba(102, 126, 234, 0.15);"></div></td></tr>
                <tr><td style="padding: 16px 24px 20px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                        <tr>
                            <td style="font-size: 16px; font-weight: 700; color: #1a1a2e;">Order Total</td>
                            <td style="font-size: 22px; font-weight: 800; color: #10B981; text-align: right; letter-spacing: -0.5px;">${total:.2f} <span style="font-size: 13px; font-weight: 600; color: #999;">CAD</span></td>
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

        <!-- FOOTER -->
        <tr><td bgcolor="#1a1a2e" style="background-color: #1a1a2e; padding: 32px 40px; text-align: center;">
            <div style="margin-bottom: 16px;">
                <span style="font-size: 12px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; color: rgba(255,255,255,0.5);">O R I G N A</span>
            </div>
            <p style="margin: 0 0 8px 0; font-size: 13px; color: rgba(255,255,255,0.5);">Seller Dashboard Notification</p>
            <p style="margin: 0 0 16px 0; font-size: 12px; color: rgba(255,255,255,0.35);">Questions? <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a></p>
            <div style="border-top: 1px solid rgba(255,255,255,0.1); padding-top: 16px;">
                <p style="margin: 0; font-size: 11px; color: rgba(255,255,255,0.25);">{EmailConfig.COPYRIGHT_TEXT}</p>
            </div>
        </td></tr>

        </table>
        </td></tr>
        </table>
    </body>
    </html>
    """

def send_email(to_email, subject, html_content, from_email=EmailConfig.SUPPORT_EMAIL):
    """Send email using Mailjet"""
    try:
        if (IS_EMULATOR and not FORCE_REAL_EMAIL) or not MAILJET_API_KEY:
            print(f"\U0001f4e7 [EMULATOR] Would send email to {to_email}: {subject}")
            return True

        mailjet = Client(
            auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY),
            version=EmailConfig.MAILJET_API_VERSION
        )

        data = {
            'Messages': [
                {
                    "From": {
                        "Email": from_email,
                        "Name": EmailConfig.SENDER_NAME
                    },
                    "To": [
                        {
                            "Email": to_email
                        }
                    ],
                    "Subject": subject,
                    "HTMLPart": html_content
                }
            ]
        }

        result = mailjet.send.create(data=data)
        if result.status_code == 200:
            print(f"✉️ Mailjet email sent to {to_email}")
            return True
        else:
            print(f"❌ Mailjet failed: {result.json()}")
            return False
    except Exception as e:
        print(f"❌ Mailjet error: {str(e)}")
        return False


def send_authorization_expired_email(order_id: str, order_data: dict) -> None:
    """Send notification when payment authorization expires after 7 days"""
    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        print(f"🔧 EMULATOR: Would send authorization expired email for order {order_id}")
        return

    if not MAILJET_API_KEY or not MAILJET_SECRET_KEY:
        print("⚠️ Mailjet credentials not configured")
        return

    try:
        mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version=EmailConfig.MAILJET_API_VERSION)

        customer_email = order_data.get(Fields.CUSTOMER_EMAIL)
        total = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) / 100
        items_summary = ', '.join([f"{item.get(Fields.NAME)} x{item.get(Fields.QUANTITY, 1)}"
                                   for item in order_data.get(Fields.ITEMS, [])[:3]])

        # Email to buyer
        buyer_message = {
            'Messages': [{
                'From': {'Email': EmailConfig.SUPPORT_EMAIL, 'Name': EmailConfig.SENDER_NAME},
                'To': [{'Email': customer_email}],
                'Subject': f'Order {order_id[:8]} - Authorization Expired',
                'HTMLPart': f"""
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

                        <p style="margin-top: 30px; color: #999; font-size: 12px;">
                            Questions? Contact {EmailConfig.SUPPORT_EMAIL}
                        </p>
                    </div>
                </body>
                </html>
                """
            }]
        }

        mailjet.send.create(data=buyer_message)
        print(f"✅ Authorization expired email sent to {customer_email}")

    except Exception as e:
        print(f"⚠️ Failed to send authorization expired email: {str(e)}")


def send_payment_capture_failed_email(order_id: str, customer_email: str, customer_name: str, amount: float, error_message: str):
    """
    Send email notification when payment capture fails.
    Instructs buyer to update payment method or contact support.
    """
    if not customer_email:
        print("⚠️ Cannot send capture failure email: missing customer_email")
        return

    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        print(f"🧪 EMULATOR: Would send capture failure email to {customer_email}")
        print(f"   Order: {order_id}, Amount: ${amount:.2f}, Error: {error_message}")
        return

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
            <p style="margin: 0 0 20px 0; font-size: 15px; color: #333;">Hi {customer_name},</p>

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
                        <td style="padding: 4px 0; font-size: 14px; color: #dc2626; text-align: right; font-weight: 500;">{error_message}</td>
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

        <!-- Footer -->
        <tr><td bgcolor="#1a1a2e" style="background-color: #1a1a2e; padding: 28px 40px; text-align: center;">
            <div style="margin-bottom: 12px;">
                <span style="font-size: 12px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase; color: #808097;">O R I G N A</span>
            </div>
            <p style="margin: 0 0 12px 0; font-size: 12px; color: #5c5c72;">Questions? <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a></p>
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

    try:
        result = mailjet.send.create(data={
            'Messages': [{
                'From': {'Email': EmailConfig.SUPPORT_EMAIL, 'Name': EmailConfig.SENDER_NAME},
                'To': [{'Email': customer_email, 'Name': customer_name}],
                'Subject': subject,
                'HTMLPart': html_body,
            }]
        })
        print(f"✅ Capture failure email sent to {customer_email}")
        return result
    except Exception as e:
        print(f"❌ Failed to send capture failure email: {str(e)}")
        raise


def send_3ds_authentication_email(order_id: str, customer_email: str, customer_name: str, authentication_url: str, amount: float):
    """
    Send email with 3DS authentication link for Airwallex payments.
    Required when card issuer needs additional verification.
    """
    if not customer_email or not authentication_url:
        print("⚠️ Cannot send 3DS email: missing customer_email or authentication_url")
        return

    if IS_EMULATOR and not FORCE_REAL_EMAIL:
        print(f"🧪 EMULATOR: Would send 3DS authentication email to {customer_email}")
        print(f"   Order: {order_id}, Amount: ${amount:.2f}, URL: {authentication_url}")
        return

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
            <p style="margin: 0 0 20px 0; font-size: 15px; color: #333;">Hi {customer_name},</p>

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
            <p style="margin: 0 0 8px 0; font-size: 12px; color: #5c5c72;">Questions? <a href="mailto:{EmailConfig.SUPPORT_EMAIL}" style="color: #667EEA; text-decoration: none;">{EmailConfig.SUPPORT_EMAIL}</a></p>
            <p style="margin: 0 0 12px 0; font-size: 11px; color: #4a4a60;">Order ID: {order_id}</p>
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
    result = mailjet.send.create(data={
        'Messages': [{
            'From': {'Email': EmailConfig.SUPPORT_EMAIL, 'Name': EmailConfig.SENDER_NAME_SECURITY},
            'To': [{'Email': customer_email, 'Name': customer_name}],
            'Subject': subject,
            'HTMLPart': html_body,
        }]
    })

    print(f"✅ 3DS authentication email sent to {customer_email}")
    return result

