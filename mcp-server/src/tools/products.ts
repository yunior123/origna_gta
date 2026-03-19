/**
 * Product Tools: search_products, get_product, check_inventory
 */

import { SearchProductsParams, GetProductParams, CheckInventoryParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function searchProducts(params: SearchProductsParams, ctx: LogContext) {
  Logger.info("search_products called", ctx, { query: params.query });

  const query = Validation.string(params.query, 1, 200, "query");
  const { limit, offset } = Validation.pagination(params.limit, params.offset);

  const filters: Record<string, any> = { limit, offset };
  if (params.category) filters.category = params.category;
  if (params.min_price !== undefined) filters.minPrice = Validation.priceCents(params.min_price);
  if (params.max_price !== undefined) filters.maxPrice = Validation.priceCents(params.max_price);
  if (params.sort) filters.sort = params.sort;

  const result = await apiClient.searchProducts(query, filters, ctx);

  Logger.info("search_products succeeded", ctx, {
    count: result.items?.length || 0,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}

export async function getProduct(params: GetProductParams, ctx: LogContext) {
  Logger.info("get_product called", ctx, { productId: params.id });

  const productId = Validation.surrealId(params.id, "product_id");
  const result = await apiClient.getProduct(productId, ctx);

  Logger.info("get_product succeeded", ctx);

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}

export async function checkInventory(params: CheckInventoryParams, ctx: LogContext) {
  Logger.info("check_inventory called", ctx, { productId: params.product_id });

  const productId = Validation.surrealId(params.product_id, "product_id");
  const result = await apiClient.checkInventory(productId, ctx);

  Logger.info("check_inventory succeeded", ctx, {
    stockQuantity: result.stockQuantity,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            productId,
            stockQuantity: result.stockQuantity,
            isInStock: result.stockQuantity > 0,
            reorderThreshold: result.reorderThreshold || 10,
          },
          null,
          2
        ),
      },
    ],
  };
}
