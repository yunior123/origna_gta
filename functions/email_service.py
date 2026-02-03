from datetime import datetime
import html
from mailjet_rest import Client
from config import IS_EMULATOR, MAILJET_API_KEY, MAILJET_SECRET_KEY

def get_order_confirmation_email(order_data):
    """Generate HTML email for customer order confirmation"""
    items_html = ""
    for item in order_data.get('items', []):
        safe_name = html.escape(str(item.get('name', 'Product')))
        items_html += f"""
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #eee;">
                {safe_name}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
                {item.get('quantity', 1)}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">
                ${(item.get('price', 0) * item.get('quantity', 1)):.2f}
            </td>
        </tr>
        """
    
    delivery_info = order_data.get('deliveryInfo', {})
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Order Confirmed!</h1>
            <p style="color: white; margin: 10px 0 0 0;">Thank you for your purchase</p>
        </div>
        
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-top: none;">
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h2 style="margin: 0 0 10px 0; color: #FF6B35;">Order Details</h2>
                <p style="margin: 5px 0;"><strong>Order ID:</strong> {order_data.get('orderId', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.now().strftime('%B %d, %Y')}</p>
            </div>
            
            <h3 style="color: #333; border-bottom: 2px solid #FF6B35; padding-bottom: 10px;">Items Ordered</h3>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
                <thead>
                    <tr style="background: #f8f9fa;">
                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Item</th>
                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                        <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                    <tr style="font-weight: bold; background: #f8f9fa;">
                        <td colspan="2" style="padding: 12px; text-align: right; border-top: 2px solid #ddd;">Total:</td>
                        <td style="padding: 12px; text-align: right; color: #FF6B35; font-size: 18px; border-top: 2px solid #ddd;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </tbody>
            </table>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #333;">Delivery Address</h3>
                <p style="margin: 0; line-height: 1.8;">
                    {delivery_info.get('formattedAddress', 'N/A')}<br>
                    {f"Phone: {delivery_info.get('phoneNumber', 'N/A')}" if delivery_info.get('phoneNumber') else ''}
                </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="https://orignagta.ca/orders" style="background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Track Your Order</a>
            </div>
        </div>
        
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
            <p>Questions? Contact us at support@orignagta.com</p>
            <p>© 2025 Origna GTA. All rights reserved.</p>
        </div>
    </body>
    </html>
    """

def get_seller_notification_email(order_data):
    """Generate HTML email for seller notification"""
    items_html = ""
    for item in order_data.get('items', []):
        items_html += f"""
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #eee;">
                {item.get('name', 'Product')}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
                {item.get('quantity', 1)}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">
                ${(item.get('price', 0) * item.get('quantity', 1)):.2f}
            </td>
        </tr>
        """
    
    delivery_info = order_data.get('deliveryInfo', {})
    address_html = f"""
        {delivery_info.get('formattedAddress', 'N/A')}<br>
        {f"Phone: {delivery_info.get('phoneNumber', 'N/A')}" if delivery_info.get('phoneNumber') else ''}
    """
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 New Order Received!</h1>
        </div>
        
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-top: none; border-radius: 0 0 10px 10px;">
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h2 style="margin: 0 0 10px 0; color: #FF6B35;">Order Details</h2>
                <p style="margin: 5px 0;"><strong>Order ID:</strong> {order_data.get('orderId', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Customer Email:</strong> {order_data.get('customerEmail', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.now().strftime('%B %d, %Y at %I:%M %p UTC')}</p>
            </div>
            
            <h3 style="color: #333; border-bottom: 2px solid #FF6B35; padding-bottom: 10px;">Items Ordered</h3>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
                <thead>
                    <tr style="background: #f8f9fa;">
                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Item</th>
                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                        <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                </tbody>
            </table>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #333;">Delivery Address</h3>
                <p style="margin: 0; line-height: 1.8;">{address_html}</p>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #856404;">Order Summary</h3>
                <table style="width: 100%;">
                    <tr>
                        <td style="padding: 5px 0;">Subtotal:</td>
                        <td style="text-align: right; padding: 5px 0;">${order_data.get('subtotal', 0):.2f}</td>
                    </tr>
                    <tr>
                        <td style="padding: 5px 0;">Shipping:</td>
                        <td style="text-align: right; padding: 5px 0;">${order_data.get('shippingCost', 0):.2f}</td>
                    </tr>
                    <tr>
                        <td style="padding: 5px 0;">Taxes:</td>
                        <td style="text-align: right; padding: 5px 0;">${sum(order_data.get('taxes', {}).values()):.2f}</td>
                    </tr>
                    <tr style="font-size: 18px; font-weight: bold; border-top: 2px solid #856404;">
                        <td style="padding: 10px 0 5px 0;">Total:</td>
                        <td style="text-align: right; padding: 10px 0 5px 0; color: #FF6B35;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </table>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="https://orignagta.ca/seller/orders" style="background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Manage Orders</a>
            </div>
        </div>
        
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
            <p>© 2025 Origna GTA. All rights reserved.</p>
        </div>
    </body>
    </html>
    """

def send_email(to_email, subject, html_content, from_email="orders@orignagta.com"):
    """Send email using Mailjet"""
    try:
        if IS_EMULATOR or not MAILJET_API_KEY:
            print(f"📧 [EMULATOR] Would send email to {to_email}: {subject}")
            return True

        mailjet = Client(
            auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY),
            version='v3.1'
        )

        data = {
            'Messages': [
                {
                    "From": {
                        "Email": from_email,
                        "Name": "Origna GTA"
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
    if IS_EMULATOR:
        print(f"🔧 EMULATOR: Would send authorization expired email for order {order_id}")
        return
    
    if not MAILJET_API_KEY or not MAILJET_SECRET_KEY:
        print("⚠️ Mailjet credentials not configured")
        return
    
    try:
        mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version='v3.1')
        
        customer_email = order_data.get('customerEmail')
        total = order_data.get('total', 0)
        items_summary = ', '.join([f"{item.get('name')} x{item.get('quantity', 1)}" 
                                   for item in order_data.get('items', [])[:3]])
        
        # Email to buyer
        buyer_message = {
            'Messages': [{
                'From': {'Email': 'noreply@orignagta.com', 'Name': 'Origna GTA'},
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
                            Questions? Contact support@orignagta.com
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
    
    if IS_EMULATOR:
        print(f"🧪 EMULATOR: Would send capture failure email to {customer_email}")
        print(f"   Order: {order_id}, Amount: ${amount:.2f}, Error: {error_message}")
        return
    
    # Initialize Mailjet client
    mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version='v3.1')
    
    subject = f"Payment Issue - Order #{order_id[:8]}"
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background: linear-gradient(135deg, #FF6B35 0%, #FF8C00 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
            .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
            .alert {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
            .button {{ display: inline-block; background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
            .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Payment Capture Failed</h1>
            </div>
            <div class="content">
                <p>Hi {customer_name},</p>
                
                <div class="alert">
                    <strong>⚠️ Action Required</strong><br>
                    We couldn't complete the payment for your order.
                </div>
                
                <p><strong>Order Details:</strong></p>
                <ul>
                    <li>Order ID: <strong>{order_id}</strong></li>
                    <li>Amount: <strong>${amount:.2f} CAD</strong></li>
                    <li>Issue: {error_message}</li>
                </ul>
                
                <p><strong>What happened?</strong></p>
                <p>Your payment method was authorized but couldn't be charged. This usually happens when:</p>
                <ul>
                    <li>Card has insufficient funds</li>
                    <li>Card was canceled or expired</li>
                    <li>Bank declined the transaction</li>
                </ul>
                
                <p><strong>Next steps:</strong></p>
                <ol>
                    <li>Log in to your account</li>
                    <li>Update your payment method</li>
                    <li>Contact your bank if the issue persists</li>
                </ol>
                
                <a href="https://orignagta.web.app/orders/{order_id}" class="button">View Order</a>
                
                <p>If you need help, contact support with order ID: <strong>{order_id}</strong></p>
            </div>
            <div class="footer">
                <p>OrignaGTA Marketplace | Canada's Trusted Platform</p>
                <p>Questions? Email support@orignaventures.ca</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    try:
        result = mailjet.send.create(data={
            'Messages': [{
                'From': {'Email': 'noreply@orignagta.com', 'Name': 'OrignaGTA'},
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
    
    if IS_EMULATOR:
        print(f"🧪 EMULATOR: Would send 3DS authentication email to {customer_email}")
        print(f"   Order: {order_id}, Amount: ${amount:.2f}, URL: {authentication_url}")
        return
    
    # Initialize Mailjet client
    mailjet = Client(auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY), version='v3.1')
    
    subject = f"Action Required: Verify Your Payment - Order #{order_id[:8]}"
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background: linear-gradient(135deg, #FF6B35 0%, #FF8C00 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
            .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
            .alert {{ background: #e3f2fd; border-left: 4px solid #2196f3; padding: 15px; margin: 20px 0; }}
            .button {{ display: inline-block; background: #2196f3; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }}
            .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
            .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔒 Secure Payment Verification</h1>
            </div>
            <div class="content">
                <p>Hi {customer_name},</p>
                
                <div class="alert">
                    <strong>Action Required: Verify Your Payment</strong><br>
                    Your bank requires additional authentication (3D Secure) to complete this transaction.
                </div>
                
                <p><strong>Order Details:</strong></p>
                <ul>
                    <li>Order ID: <strong>{order_id}</strong></li>
                    <li>Amount: <strong>${amount:.2f} CAD</strong></li>
                    <li>Status: <strong>Pending Verification</strong></li>
                </ul>
                
                <p><strong>What is 3D Secure?</strong></p>
                <p>3D Secure (3DS) is an additional security layer that protects your payment. Your bank requires you to verify your identity before completing this purchase.</p>
                
                <div style="text-align: center;">
                    <a href="{authentication_url}" class="button">Verify Payment Now</a>
                </div>
                
                <div class="warning">
                    <strong>⏰ Time Sensitive</strong><br>
                    Please complete verification within 15 minutes. After that, you'll need to place a new order.
                </div>
                
                <p><strong>Security Tips:</strong></p>
                <ul>
                    <li>✅ This email is from OrignaGTA's official email</li>
                    <li>✅ The verification link goes to your bank's secure portal</li>
                    <li>❌ We will never ask for your card details via email</li>
                    <li>❌ Never share verification codes with anyone</li>
                </ul>
                
                <p>If you didn't place this order, <a href="https://orignagta.web.app/support">contact support immediately</a>.</p>
            </div>
            <div class="footer">
                <p>OrignaGTA Marketplace | Canada's Trusted Platform</p>
                <p>Questions? Email support@orignaventures.ca</p>
                <p>Order ID: {order_id}</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    # RETRY LOGIC: We do NOT catch exceptions here.
    # Cloud Functions will retry execution if an exception is raised.
    # This prevents email loss during temporary Mailjet outages.
    result = mailjet.send.create(data={
        'Messages': [{
            'From': {'Email': 'noreply@orignagta.com', 'Name': 'OrignaGTA Security'},
            'To': [{'Email': customer_email, 'Name': customer_name}],
            'Subject': subject,
            'HTMLPart': html_body,
        }]
    })
    
    print(f"✅ 3DS authentication email sent to {customer_email}")
    return result

