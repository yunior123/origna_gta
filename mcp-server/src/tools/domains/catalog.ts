/**
 * OrignaGTA MCP Server — Catalog Tools (READ-ONLY)
 * Public product discovery — no auth required
 */

import { Tool } from "../../types.js";
import * as productsTools from "../products.js";

export const CATALOG_TOOLS: Tool[] = [
  {
    name: "search_products",
    description: "Search products by query, category, price range, and sorting",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query (title, description, keywords)",
        },
        category: {
          type: "string",
          description: "Filter by category ID",
        },
        min_price: {
          type: "number",
          description: "Minimum price in cents (e.g., 5000 for $50)",
        },
        max_price: {
          type: "number",
          description: "Maximum price in cents",
        },
        sort: {
          type: "string",
          enum: ["price_asc", "price_desc", "newest", "popular"],
          description: "Sort order",
        },
        limit: {
          type: "number",
          description: "Number of results (default: 20, max: 100)",
        },
        offset: {
          type: "number",
          description: "Pagination offset",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "get_product",
    description: "Get full product details by ID",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Product ID (e.g., products:abc123)",
        },
      },
      required: ["id"],
    },
  },
  {
    name: "check_inventory",
    description: "Check product stock availability",
    inputSchema: {
      type: "object",
      properties: {
        product_id: {
          type: "string",
          description: "Product ID",
        },
      },
      required: ["product_id"],
    },
  },
];

export const catalogToolHandlers: Record<string, Function> = {
  search_products: productsTools.searchProducts,
  get_product: productsTools.getProduct,
  check_inventory: productsTools.checkInventory,
};

export const CATALOG_RATE_LIMITS = {
  search_products: { requestsPerMinute: 60 },
  get_product: { requestsPerMinute: 100 },
  check_inventory: { requestsPerMinute: 100 },
};
