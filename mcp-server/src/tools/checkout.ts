/**
 * Checkout Tools: create_checkout, confirm_checkout, apply_coupon
 */

import { CreateCheckoutParams, ApplyCouponParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function createCheckout(params: CreateCheckoutParams, ctx: LogContext) {
  Logger.info("create_checkout called", ctx);

  const user = await AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  // Validate shipping address
  const address = {
    street: Validation.string(params.shipping_address.street, 5, 200),
    city: Validation.string(params.shipping_address.city, 2, 100),
    province: Validation.string(params.shipping_address.province, 2, 2),
    postalCode: Validation.postalCode(params.shipping_address.postalCode),
    country: params.shipping_address.country || "CA",
  };

  const coupon = params.coupon ? Validation.couponCode(params.coupon) : undefined;

  const session = await apiClient.createCheckout(address, coupon, undefined, ctx);

  Logger.info("create_checkout succeeded", ctx, {
    sessionId: session.sessionId,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            sessionId: session.sessionId,
            sessionUrl: session.sessionUrl,
            clientSecret: session.clientSecret,
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

export async function confirmCheckout(params: any, ctx: LogContext) {
  Logger.info("confirm_checkout called", ctx, { token: params.confirmation_token });

  const user = await AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  const token = Validation.string(params.confirmation_token, 1, 500, "confirmation_token");

  // Note: Token verification and actual checkout execution happens in the index.ts
  // This function just confirms the token is valid format
  Logger.info("confirm_checkout token verified", ctx);

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            status: "confirmed",
            message: "Checkout confirmed and processing",
            token,
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

  await AuthService.getCurrentUser(ctx);

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
          },
          null,
          2
        ),
      },
    ],
  };
}
