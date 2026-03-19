/**
 * Cart Tools: add_to_cart, remove_from_cart, get_cart
 */

import { AddToCartParams, RemoveFromCartParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function getCart(ctx: LogContext) {
  Logger.info("get_cart called", ctx);

  await AuthService.getCurrentUser(ctx); // Ensure authenticated

  const cart = await apiClient.getCart(ctx);

  Logger.info("get_cart succeeded", ctx, {
    itemCount: cart.items?.length || 0,
    totalCents: cart.totalCents,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(cart, null, 2),
      },
    ],
  };
}

export async function addToCart(params: AddToCartParams, ctx: LogContext) {
  Logger.info("add_to_cart called", ctx, {
    productId: params.product_id,
    quantity: params.quantity,
    idempotencyKey: params.idempotency_key,
  });

  await AuthService.getCurrentUser(ctx); // Ensure authenticated

  const productId = Validation.surrealId(params.product_id, "product_id");
  const quantity = Validation.quantity(params.quantity);

  const cart = await apiClient.addToCart(productId, quantity, params.idempotency_key, ctx);

  Logger.info("add_to_cart succeeded", ctx, {
    itemCount: cart.items?.length || 0,
    idempotencyKey: params.idempotency_key,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(cart, null, 2),
      },
    ],
  };
}

export async function removeFromCart(params: RemoveFromCartParams, ctx: LogContext) {
  Logger.info("remove_from_cart called", ctx, {
    productId: params.product_id,
  });

  await AuthService.getCurrentUser(ctx); // Ensure authenticated

  const productId = Validation.surrealId(params.product_id, "product_id");

  const cart = await apiClient.removeFromCart(productId, ctx);

  Logger.info("remove_from_cart succeeded", ctx, {
    itemCount: cart.items?.length || 0,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(cart, null, 2),
      },
    ],
  };
}
