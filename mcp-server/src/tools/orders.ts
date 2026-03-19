/**
 * Order Tools: list_orders, get_order, request_return
 */

import { ListOrdersParams, GetOrderParams, RequestReturnParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function listOrders(params: ListOrdersParams, ctx: LogContext) {
  Logger.info("list_orders called", ctx);

  const user = AuthService.getCurrentUser(ctx);
  const { limit, offset } = Validation.pagination(params.limit, params.offset);

  const filters: Record<string, any> = { limit, offset };
  if (params.status) filters.status = Validation.orderStatus(params.status);
  if (params.seller_id) filters.sellerId = Validation.surrealId(params.seller_id);

  // Buyers can only see their own orders
  if (user.role === "buyer") {
    filters.buyerId = user.sub;
  }

  const result = await apiClient.listOrders(filters, ctx);

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

  const user = AuthService.getCurrentUser(ctx);
  const orderId = Validation.surrealId(params.id, "order_id");

  const order = await apiClient.getOrder(orderId, ctx);

  // Buyers can only see their own orders
  if (user.role === "buyer" && order.buyerId !== user.sub) {
    throw new Error("Unauthorized - order not yours");
  }

  // Sellers can only see their own orders
  if (user.role === "seller" && order.sellerId !== user.sub) {
    throw new Error("Unauthorized - order not yours");
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

export async function requestReturn(params: RequestReturnParams, ctx: LogContext) {
  Logger.info("request_return called", ctx, { orderId: params.order_id });

  const user = AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  const orderId = Validation.surrealId(params.order_id, "order_id");
  const reason = Validation.returnReason(params.reason);

  // Validate items
  if (!Array.isArray(params.items) || params.items.length === 0) {
    throw new Error("items array required and must not be empty");
  }

  const items = params.items.map((item) => ({
    productId: Validation.surrealId(item.product_id, "product_id"),
    quantity: Validation.quantity(item.quantity),
  }));

  const returnRequest = await apiClient.requestReturn(
    {
      orderId,
      buyerId: user.sub,
      items,
      reason,
    },
    ctx
  );

  Logger.info("request_return succeeded", ctx, {
    returnRequestId: returnRequest.id,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(returnRequest, null, 2),
      },
    ],
  };
}
