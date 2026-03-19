#!/usr/bin/env node
/**
 * OrignaGTA MCP Server — Main Entry Point
 * Model Context Protocol server for AI agents to purchase products using Stripe
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  TextContent,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { Logger, LogContext } from "./utils/logger.js";
import { AppError, sanitizeError } from "./utils/errors.js";

// Import tool handlers
import * as productsTools from "./tools/products.js";
import * as ordersTools from "./tools/orders.js";
import * as cartTools from "./tools/cart.js";
import * as checkoutTools from "./tools/checkout.js";
import * as reviewsTools from "./tools/reviews.js";
import * as analyticsTools from "./tools/analytics.js";

const server = new Server({
  name: "orignagta-mcp",
  version: "1.0.0",
});

// Tool Definitions
const TOOLS = [
  // Products (READ)
  {
    name: "search_products",
    description: "Search products by query, category, price range, and sorting",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query",
        },
        category: {
          type: "string",
          description: "Optional category filter",
        },
        min_price: {
          type: "number",
          description: "Minimum price in cents (optional)",
        },
        max_price: {
          type: "number",
          description: "Maximum price in cents (optional)",
        },
        sort: {
          type: "string",
          enum: ["price_asc", "price_desc", "newest", "popular"],
          description: "Sort order (optional)",
        },
        limit: {
          type: "number",
          description: "Results per page, default 20, max 100",
        },
        offset: {
          type: "number",
          description: "Page offset for pagination",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "get_product",
    description: "Get detailed product information including images, reviews, stock",
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
    description: "Check real-time stock levels for a product",
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

  // Cart (READ/WRITE)
  {
    name: "get_cart",
    description: "Get current shopping cart with items, totals, and estimates",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "add_to_cart",
    description: "Add a product to shopping cart",
    inputSchema: {
      type: "object",
      properties: {
        product_id: {
          type: "string",
          description: "Product ID",
        },
        quantity: {
          type: "number",
          description: "Quantity to add",
        },
      },
      required: ["product_id", "quantity"],
    },
  },
  {
    name: "remove_from_cart",
    description: "Remove a product from shopping cart",
    inputSchema: {
      type: "object",
      properties: {
        product_id: {
          type: "string",
          description: "Product ID to remove",
        },
      },
      required: ["product_id"],
    },
  },

  // Coupons
  {
    name: "apply_coupon",
    description: "Apply a coupon code to cart for discount",
    inputSchema: {
      type: "object",
      properties: {
        code: {
          type: "string",
          description: "Coupon code",
        },
      },
      required: ["code"],
    },
  },

  // Checkout (WRITE - Agent can PURCHASE)
  {
    name: "create_checkout",
    description:
      "Create Stripe Checkout Session with latest features (embedded, automatic tax, multiple payment methods)",
    inputSchema: {
      type: "object",
      properties: {
        shipping_address: {
          type: "object",
          description: "Shipping address details",
          properties: {
            street: { type: "string" },
            city: { type: "string" },
            province: { type: "string" },
            postalCode: { type: "string" },
            country: { type: "string" },
            phone: { type: "string" },
          },
          required: ["street", "city", "province", "postalCode", "phone"],
        },
        coupon: {
          type: "string",
          description: "Optional coupon code",
        },
      },
      required: ["shipping_address"],
    },
  },

  // Orders (READ)
  {
    name: "list_orders",
    description: "List user orders with optional filtering by status",
    inputSchema: {
      type: "object",
      properties: {
        status: {
          type: "string",
          enum: ["pending", "confirmed", "shipped", "delivered", "cancelled"],
          description: "Filter by order status",
        },
        seller_id: {
          type: "string",
          description: "Filter by seller (admin only)",
        },
        limit: {
          type: "number",
          description: "Results per page",
        },
        offset: {
          type: "number",
          description: "Page offset",
        },
      },
    },
  },
  {
    name: "get_order",
    description: "Get detailed order information",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Order ID",
        },
      },
      required: ["id"],
    },
  },
  {
    name: "request_return",
    description: "Request a return for order items",
    inputSchema: {
      type: "object",
      properties: {
        order_id: {
          type: "string",
          description: "Order ID",
        },
        items: {
          type: "array",
          description: "Items to return",
          items: {
            type: "object",
            properties: {
              product_id: { type: "string" },
              quantity: { type: "number" },
            },
          },
        },
        reason: {
          type: "string",
          description: "Reason for return",
        },
      },
      required: ["order_id", "items", "reason"],
    },
  },

  // Reviews (WRITE)
  {
    name: "submit_review",
    description: "Submit a product review with rating and text",
    inputSchema: {
      type: "object",
      properties: {
        product_id: {
          type: "string",
          description: "Product ID",
        },
        rating: {
          type: "number",
          description: "Rating 1-5",
        },
        text: {
          type: "string",
          description: "Review text",
        },
      },
      required: ["product_id", "rating", "text"],
    },
  },

  // Analytics (ADMIN ONLY)
  {
    name: "get_analytics",
    description: "Get sales analytics (admin access required)",
    inputSchema: {
      type: "object",
      properties: {
        period: {
          type: "string",
          enum: ["day", "week", "month", "year"],
          description: "Analytics period",
        },
      },
      required: ["period"],
    },
  },
];

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const ctx = Logger.createContext(request.name);

  try {
    Logger.info("Tool call received", ctx, {
      tool: request.name,
      paramCount: Object.keys(request.params).length,
    });

    const result = await handleToolCall(request.name, request.params, ctx);

    Logger.info("Tool call succeeded", ctx);
    return result;
  } catch (error) {
    Logger.error("Tool call failed", ctx, error instanceof Error ? (error as Error) : undefined);

    const { message, code } = sanitizeError(error);
    const statusCode = error instanceof AppError ? error.statusCode : 500;

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify({
            error: message,
            code,
            statusCode,
          }),
        },
      ],
      isError: true,
    };
  }
});

/**
 * Route tool calls to handlers
 */
async function handleToolCall(
  tool: string,
  params: Record<string, any>,
  ctx: LogContext
): Promise<any> {
  switch (tool) {
    // Products
    case "search_products":
      return await productsTools.searchProducts(params, ctx);
    case "get_product":
      return await productsTools.getProduct(params, ctx);
    case "check_inventory":
      return await productsTools.checkInventory(params, ctx);

    // Cart
    case "get_cart":
      return await cartTools.getCart(ctx);
    case "add_to_cart":
      return await cartTools.addToCart(params, ctx);
    case "remove_from_cart":
      return await cartTools.removeFromCart(params, ctx);

    // Coupons
    case "apply_coupon":
      return await checkoutTools.applyCoupon(params, ctx);

    // Checkout
    case "create_checkout":
      return await checkoutTools.createCheckout(params, ctx);

    // Orders
    case "list_orders":
      return await ordersTools.listOrders(params, ctx);
    case "get_order":
      return await ordersTools.getOrder(params, ctx);
    case "request_return":
      return await ordersTools.requestReturn(params, ctx);

    // Reviews
    case "submit_review":
      return await reviewsTools.submitReview(params, ctx);

    // Analytics
    case "get_analytics":
      return await analyticsTools.getAnalytics(params, ctx);

    default:
      throw new Error(`Unknown tool: ${tool}`);
  }
}

/**
 * Start the MCP server
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  Logger.info("OrignaGTA MCP Server started", Logger.createContext());
}

main().catch((error) => {
  console.error("Failed to start MCP server:", error);
  process.exit(1);
});
