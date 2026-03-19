/**
 * Checkout Tools: create_checkout, apply_coupon
 * Integrates Stripe Payment Links and Checkout Sessions with latest features
 */

import { CreateCheckoutParams, ApplyCouponParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function createCheckout(params: CreateCheckoutParams, ctx: LogContext) {
  Logger.info("create_checkout called", ctx);

  const user = AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  // Validate shipping address
  const address = {
    street: Validation.string(params.shipping_address.street, 5, 200),
    city: Validation.string(params.shipping_address.city, 2, 100),
    province: Validation.string(params.shipping_address.province, 2, 2), // e.g., "ON"
    postalCode: Validation.postalCode(params.shipping_address.postalCode),
    country: params.shipping_address.country || "CA",
    phone: Validation.phone(params.shipping_address.phone),
  };

  const checkoutData: Record<string, any> = {
    shippingAddress: address,
    buyerId: user.sub,
    // Stripe features
    stripeConfig: {
      uiMode: "embedded", // Latest embedded checkout
      automaticTax: { enabled: true }, // Enable automatic tax calculation
      paymentMethodTypes: [
        "card",
        "link", // Stripe Link
        "cashapp", // Cash App
        "afterpay_clearpay", // Afterpay/Clearpay for international
      ],
      // Shipping options with real-time calculation
      shippingOptions: {
        type: "shipping_address_collection",
      },
    },
    idempotencyKey: ctx.requestId,
  };

  if (params.coupon) {
    checkoutData.coupon = Validation.couponCode(params.coupon);
  }

  const session = await apiClient.createCheckout(checkoutData, ctx);

  Logger.info("create_checkout succeeded", ctx, {
    sessionId: session.sessionId,
  });

  // Return both session and payment link options
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            sessionId: session.sessionId,
            sessionUrl: session.sessionUrl,
            clientSecret: session.clientSecret,
            publishableKey: session.publishableKey,
            paymentLinks: session.paymentLinks || [],
            totalCents: session.totalCents,
            status: "ready_for_payment",
          },
          null,
          2
        ),
      },
    ],
  };
}

export async function applyCoupon(params: ApplyCouponParams, ctx: LogContext) {
  Logger.info("apply_coupon called", ctx, { code: params.code });

  AuthService.getCurrentUser(ctx); // Ensure authenticated

  const code = Validation.couponCode(params.code);

  const result = await apiClient.applyCoupon(code, ctx);

  Logger.info("apply_coupon succeeded", ctx, {
    discountCents: result.discountCents,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            code,
            discountCents: result.discountCents,
            discountPercent: result.discountPercent,
            newCartTotal: result.newTotalCents,
            validUntil: result.validUntil,
          },
          null,
          2
        ),
      },
    ],
  };
}

/**
 * Create a one-click Payment Link (optional advanced feature)
 * Stripe Payment Links allow sharing a URL that goes directly to checkout
 */
export async function createPaymentLink(
  productId: string,
  quantity: number,
  ctx: LogContext
) {
  Logger.info("create_payment_link called", ctx, {
    productId,
    quantity,
  });

  const user = AuthService.getCurrentUser(ctx);
  const pProductId = Validation.surrealId(productId, "product_id");
  const pQuantity = Validation.quantity(quantity);

  // Get product details to create the link
  const product = await apiClient.getProduct(pProductId, ctx);

  const linkData = {
    productId: pProductId,
    quantity: pQuantity,
    buyerId: user.sub,
    stripeConfig: {
      oneTime: true, // Non-recurring payment
      paymentMethodTypes: ["card", "link", "cashapp", "afterpay_clearpay"],
    },
  };

  // This would call an endpoint to generate a Payment Link
  // For now, we mock it
  const paymentLink = {
    url: `https://buy.stripe.com/test_... (generated)`,
    id: `plink_${Date.now()}`,
    expiresAt: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30 days
    productTitle: product.title,
    price: product.priceCents,
    quantity: pQuantity,
  };

  Logger.info("create_payment_link succeeded", ctx, {
    linkId: paymentLink.id,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(paymentLink, null, 2),
      },
    ],
  };
}
