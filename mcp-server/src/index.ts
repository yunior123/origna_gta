#!/usr/bin/env node
/**
 * OrignaGTA MCP Server — Main Entry Point
 * Model Context Protocol server for AI agents to purchase products using Stripe
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { Logger } from "./utils/logger.js";
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
  description: "MCP server for AI agents to purchase products end-to-end",
});

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
          description: "Number of results (default: 10, max: 50)",
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

  // Cart (READ + WRITE)
  {
    name: "add_to_cart",
    description: "Add product to cart",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID" },
        quantity: { type: "number", description: "Quantity (default: 1)" },
      },
      required: ["product_id", "quantity"],
    },
  },
  {
    name: "get_cart",
    description: "Get current cart contents and totals",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "remove_from_cart",
    description: "Remove product from cart",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID to remove" },
      },
      required: ["product_id"],
    },
  },

  // Checkout (WRITE)
  {
    name: "create_checkout",
    description: "Create Stripe Checkout Session for cart items",
    inputSchema: {
      type: "object",
      properties: {
        shipping_address: {
          type: "object",
          description: "Shipping address",
          properties: {
            street: { type: "string" },
            city: { type: "string" },
            province: { type: "string" },
            postalCode: { type: "string" },
            country: { type: "string" },
          },
          required: ["street", "city", "province", "postalCode", "country"],
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
    description: "List buyer's orders with status and totals",
    inputSchema: {
      type: "object",
      properties: {
        status: {
          type: "string",
          enum: ["pending", "confirmed", "shipped", "delivered", "cancelled"],
          description: "Filter by status",
        },
        limit: { type: "number", description: "Max results (default: 20)" },
        offset: { type: "number", description: "Pagination offset" },
      },
    },
  },
  {
    name: "get_order",
    description: "Get full order details by ID",
    inputSchema: {
      type: "object",
      properties: {
        id: { type: "string", description: "Order ID" },
      },
      required: ["id"],
    },
  },

  // Reviews (WRITE)
  {
    name: "submit_review",
    description: "Submit product review/rating (for delivered orders)",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID" },
        rating: {
          type: "number",
          description: "Rating 1-5",
          minimum: 1,
          maximum: 5,
        },
        text: {
          type: "string",
          description: "Review text (optional, max 500 chars)",
        },
      },
      required: ["product_id", "rating", "text"],
    },
  },

  // Analytics (READ)
  {
    name: "get_analytics",
    description: "Get purchase summary (total spent, orders, etc)",
    inputSchema: {
      type: "object",
      properties: {
        period: {
          type: "string",
          enum: ["day", "week", "month", "year"],
          description: "Time period for analytics",
        },
      },
      required: ["period"],
    },
  },
];

// Register tool capability before setting handlers
server.registerCapabilities({
  tools: {},
});

// Setup request handlers
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: TOOLS,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const ctx = Logger.createContext(name);

  try {
    Logger.info(`Calling tool: ${name}`, ctx);

    let result: any;

    // Route to correct tool handler, cast args as needed
    switch (name) {
      case "search_products":
        result = await productsTools.searchProducts(args as any, ctx);
        break;
      case "get_product":
        result = await productsTools.getProduct(args as any, ctx);
        break;

      case "add_to_cart":
        result = await cartTools.addToCart(args as any, ctx);
        break;
      case "get_cart":
        result = await cartTools.getCart(ctx);
        break;
      case "remove_from_cart":
        result = await cartTools.removeFromCart(args as any, ctx);
        break;

      case "create_checkout":
        result = await checkoutTools.createCheckout(args as any, ctx);
        break;

      case "list_orders":
        result = await ordersTools.listOrders(args as any, ctx);
        break;
      case "get_order":
        result = await ordersTools.getOrder(args as any, ctx);
        break;

      case "submit_review":
        result = await reviewsTools.submitReview(args as any, ctx);
        break;

      case "get_analytics":
        result = await analyticsTools.getAnalytics(args as any, ctx);
        break;

      default:
        throw new AppError(`Unknown tool: ${name}`, "INVALID_TOOL", 400);
    }

    Logger.info(`Tool succeeded: ${name}`, ctx);
    return result;
  } catch (error) {
    const appError = error instanceof AppError ? error : new AppError(String(error), "TOOL_ERROR", 500);
    Logger.error(`Tool failed: ${name}`, ctx, error instanceof Error ? error : new Error(String(error)));

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(sanitizeError(appError), null, 2),
          isError: true,
        },
      ],
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  const ctx = Logger.createContext("server", "startup");
  Logger.info("OrignaGTA MCP server started", ctx, { version: "1.0.0" });
}

main().catch((error) => {
  const ctx = Logger.createContext("server", "startup");
  Logger.error("Server startup failed", ctx, error instanceof Error ? error : new Error(String(error)));
  process.exit(1);
});
