/**
 * OrignaGTA MCP Server — Shopping Tools (AUTH REQUIRED)
 * Cart management — requires valid JWT token
 */

import { Tool } from "../../types.js";
import * as cartTools from "../cart.js";
import * as checkoutTools from "../checkout.js";

export const SHOPPING_TOOLS: Tool[] = [
  {
    name: "add_to_cart",
    description: "Add product to cart (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID" },
        quantity: { type: "number", description: "Quantity (default: 1)" },
        idempotency_key: { type: "string", description: "Optional idempotency key to prevent duplicate cart entries" },
      },
      required: ["product_id", "quantity"],
    },
  },
  {
    name: "remove_from_cart",
    description: "Remove product from cart (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        product_id: { type: "string", description: "Product ID" },
      },
      required: ["product_id"],
    },
  },
  {
    name: "get_cart",
    description: "Get current cart contents (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
  },
  {
    name: "apply_coupon",
    description: "Apply coupon code to cart (requires authentication)",
    inputSchema: {
      type: "object",
      properties: {
        code: { type: "string", description: "Coupon code" },
      },
      required: ["code"],
    },
  },
];

export const shoppingToolHandlers: Record<string, Function> = {
  add_to_cart: cartTools.addToCart,
  remove_from_cart: cartTools.removeFromCart,
  get_cart: cartTools.getCart,
  apply_coupon: checkoutTools.applyCoupon,
};

export const SHOPPING_RATE_LIMITS = {
  add_to_cart: { requestsPerMinute: 20 },
  remove_from_cart: { requestsPerMinute: 20 },
  get_cart: { requestsPerMinute: 30 },
  apply_coupon: { requestsPerMinute: 20 },
};
