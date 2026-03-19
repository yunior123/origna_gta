/**
 * OrignaGTA MCP Server — Transactions Tools (AUTH + CONFIRMATION REQUIRED)
 * Financial operations — require authentication and spend limits
 */

import { Tool } from "../../types.js";
import * as checkoutTools from "../checkout.js";
import * as ordersTools from "../orders.js";
import * as reviewsTools from "../reviews.js";

export const TRANSACTIONS_TOOLS: Tool[] = [
  {
    name: "create_checkout",
    description: "Create Stripe checkout session (requires authentication and confirmation for amounts > $250)",
    inputSchema: {
      type: "object",
      properties: {
        shipping_address: {
          type: "object",
          description: "Shipping address",
          properties: {
            street: { type: "string" },
            city: { type: "string" },
            state: { type: "string" },
            postal_code: { type: "string" },
            country: { type: "string" },
          },
          required: ["street", "city", "state", "postal_code", "country"],
        },
        coupon: { type: "string", description: "Optional coupon code" },
        confirmation_token: { type: "string", description: "Required for high-value checkouts (> $250)" },
      },
      required: ["shipping_address"],
    },
  },
  {
    name: "confirm_checkout",
    description: "Confirm a pending high-value checkout (uses confirmation token)",
    inputSchema: {
      type: "object",
      properties: {
        confirmation_token: { type: "string", description: "Confirmation token from create_checkout" },
      },
      required: ["confirmation_token"],
    },
  },
  {
    name: "list_orders",
    description: "List user's orders (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        limit: { type: "number", description: "Limit (default: 20, max: 100)" },
        offset: { type: "number", description: "Offset (default: 0)" },
      },
      required: [],
    },
  },
  {
    name: "get_order",
    description: "Get order details by ID (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        id: { type: "string", description: "Order ID" },
      },
      required: ["id"],
    },
  },
  {
    name: "request_return",
    description: "Request return for an order item (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        order_id: { type: "string", description: "Order ID" },
        reason: { type: "string", description: "Return reason (damaged, wrong_item, etc.)" },
        confirmation_token: { type: "string", description: "Confirmation token (required for full refunds)" },
      },
      required: ["order_id", "reason"],
    },
  },
  {
    name: "submit_review",
    description: "Submit review for a product (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID" },
        rating: { type: "number", description: "Rating 1-5" },
        title: { type: "string", description: "Review title" },
        comment: { type: "string", description: "Review comment" },
      },
      required: ["product_id", "rating", "title"],
    },
  },
];

export const transactionsToolHandlers: Record<string, Function> = {
  create_checkout: checkoutTools.createCheckout,
  confirm_checkout: checkoutTools.confirmCheckout,
  list_orders: ordersTools.listOrders,
  get_order: ordersTools.getOrder,
  request_return: ordersTools.requestReturn,
  submit_review: reviewsTools.submitReview,
};

export const TRANSACTIONS_RATE_LIMITS = {
  create_checkout: { requestsPerMinute: 5 },
  confirm_checkout: { requestsPerMinute: 5 },
  list_orders: { requestsPerMinute: 20 },
  get_order: { requestsPerMinute: 30 },
  request_return: { requestsPerMinute: 5 },
  submit_review: { requestsPerMinute: 10 },
};
