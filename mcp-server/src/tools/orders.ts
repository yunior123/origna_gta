/**
 * Order Tools: list_orders, get_order, request_return
 */

import { ListOrdersParams, GetOrderParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";
import { AppError } from "../utils/errors.js";

export async function listOrders(params: ListOrdersParams, ctx: LogContext) {
  Logger.info("list_orders called", ctx);

  const user = await AuthService.getCurrentUser(ctx);
  const { limit, offset } = Validation.pagination(params.limit, params.offset);

  let status: string | undefined = params.status;
  if (status) status = Validation.orderStatus(status);

  // Only buyers see their own orders filter applied server-side
  const result = await apiClient.listOrders(limit, offset, ctx);

  Logger.info("list_orders succeeded", ctx, { count: result.items?.length || 0 });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}

export async function getOrder(params: GetOrderParams, ctx: LogContext) {
  Logger.info("get_order called", ctx, { orderId: params.id });

  const user = await AuthService.getCurrentUser(ctx);
  const orderId = Validation.surrealId(params.id, "order_id");

  const order = await apiClient.getOrder(orderId, ctx);

  // Buyers can only see their own orders
  if (user.role === "buyer" && order.buyerId !== user.sub) {
    throw new AppError("Unauthorized - order not yours", "FORBIDDEN", 403);
  }

  // Sellers can only see their own orders
  if (user.role === "seller" && order.sellerId !== user.sub) {
    throw new AppError("Unauthorized - order not yours", "FORBIDDEN", 403);
  }

  Logger.info("get_order succeeded", ctx);

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(order, null, 2),
      },
    ],
  };
}

export async function requestReturn(params: any, ctx: LogContext) {
  Logger.info("request_return called", ctx, {
    orderId: params.order_id,
    reason: params.reason,
  });

  const user = await AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  const orderId = Validation.surrealId(params.order_id, "order_id");
  const reason = Validation.string(params.reason, 5, 500, "reason");

  // Verify order belongs to user
  const order = await apiClient.getOrder(orderId, ctx);
  if (order.buyerId !== user.sub) {
    throw new AppError("Unauthorized - order not yours", "FORBIDDEN", 403);
  }

  const result = await apiClient.requestReturn(orderId, reason, params.idempotency_key, ctx);

  Logger.info("request_return succeeded", ctx, { returnId: result.id });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}
