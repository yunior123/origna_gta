#!/usr/bin/env node
/**
 * OrignaGTA MCP Server — Main Entry Point
 * Model Context Protocol server with OAuth auth, domain separation, and agent safeguards
 * 
 * P0 Improvements:
 * 1. OAuth 2.0 auth with token caching and auto-refresh
 * 2. Domain separation: catalog, shopping, transactions, admin
 * 3. Rate limiting per tool
 * 4. Spend limits + confirmation for financial operations
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { Logger } from "./utils/logger.js";
import { AppError, sanitizeError } from "./utils/errors.js";
import { AuthService } from "./auth.js";
import { RateLimiter } from "./utils/rate-limiter.js";
import { SpendLimiter } from "./utils/spend-limiter.js";

// Import tool domains
import { CATALOG_TOOLS, catalogToolHandlers, CATALOG_RATE_LIMITS } from "./tools/domains/catalog.js";
import { SHOPPING_TOOLS, shoppingToolHandlers, SHOPPING_RATE_LIMITS } from "./tools/domains/shopping.js";
import { TRANSACTIONS_TOOLS, transactionsToolHandlers, TRANSACTIONS_RATE_LIMITS } from "./tools/domains/transactions.js";
import { ADMIN_TOOLS, adminToolHandlers, ADMIN_RATE_LIMITS } from "./tools/domains/admin.js";

const server = new Server({
  name: "orignagta-mcp",
  version: "2.0.0",
  description: "Secure MCP server for AI agents — OAuth auth, domain separation, spend limits",
});

// Combine all tools from domains
const ALL_TOOLS = [
  ...CATALOG_TOOLS,
  ...SHOPPING_TOOLS,
  ...TRANSACTIONS_TOOLS,
  ...ADMIN_TOOLS,
];

// Combine all tool handlers
const toolHandlers = {
  ...catalogToolHandlers,
  ...shoppingToolHandlers,
  ...transactionsToolHandlers,
  ...adminToolHandlers,
};

// Initialize rate limiters for each domain
const catalogRateLimiter = new RateLimiter(CATALOG_RATE_LIMITS);
const shoppingRateLimiter = new RateLimiter(SHOPPING_RATE_LIMITS);
const transactionsRateLimiter = new RateLimiter(TRANSACTIONS_RATE_LIMITS);
const adminRateLimiter = new RateLimiter(ADMIN_RATE_LIMITS);

// Initialize spend limiter (defaults: $500 per checkout, $5000 per day)
const spendLimiter = new SpendLimiter({
  maxCheckoutCents: process.env.MCP_MAX_PURCHASE_CENTS ? parseInt(process.env.MCP_MAX_PURCHASE_CENTS) : 50000,
  maxDailySpendCents: process.env.MCP_MAX_DAILY_CENTS ? parseInt(process.env.MCP_MAX_DAILY_CENTS) : 500000,
});

// Tool domain mapping
const toolDomains: Record<string, "catalog" | "shopping" | "transactions" | "admin"> = {
  // Catalog (public)
  search_products: "catalog",
  get_product: "catalog",
  check_inventory: "catalog",

  // Shopping (auth required)
  add_to_cart: "shopping",
  remove_from_cart: "shopping",
  get_cart: "shopping",
  apply_coupon: "shopping",

  // Transactions (auth + confirmation required)
  create_checkout: "transactions",
  confirm_checkout: "transactions",
  list_orders: "transactions",
  get_order: "transactions",
  request_return: "transactions",
  submit_review: "transactions",

  // Admin (admin role required)
  get_analytics: "admin",
};

// Register tool capability
server.registerCapabilities({
  tools: {},
});

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: ALL_TOOLS,
}));

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const ctx = Logger.createContext(name);

  try {
    Logger.info(`Tool call: ${name}`, ctx, { arguments: args });

    // Check tool exists
    const domain = toolDomains[name];
    if (!domain) {
      throw new AppError(`Unknown tool: ${name}`, "INVALID_TOOL", 400);
    }

    // Get rate limiter for domain
    const getRateLimiter = () => {
      switch (domain) {
        case "catalog":
          return catalogRateLimiter;
        case "shopping":
          return shoppingRateLimiter;
        case "transactions":
          return transactionsRateLimiter;
        case "admin":
          return adminRateLimiter;
      }
    };

    const rateLimiter = getRateLimiter();
    const rateCheck = rateLimiter.isAllowed(name);

    if (!rateCheck.allowed) {
      Logger.warn(`Rate limit exceeded: ${name}`, ctx, { resetIn: rateCheck.resetInSeconds });
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              error: "RATE_LIMIT_EXCEEDED",
              message: `Rate limit exceeded. Retry after ${rateCheck.resetInSeconds} seconds.`,
              retryAfter: rateCheck.resetInSeconds,
            }, null, 2),
            isError: true,
          },
        ],
      };
    }

    // Require auth for non-catalog domains
    let userPayload: any = null;
    if (domain !== "catalog") {
      try {
        userPayload = await AuthService.getCurrentUser(ctx);
      } catch (error) {
        Logger.warn(`Auth required for ${name}`, ctx);
        throw new AppError("Authentication required", "UNAUTHORIZED", 401);
      }

      // Admin tools require admin role
      if (domain === "admin") {
        AuthService.requireAdmin(userPayload, ctx);
      }
    }

    // Handle special cases for financial operations
    if (name === "create_checkout") {
      const args_typed = args as any;
      const cartAmount = args_typed.cart_subtotal_cents || 0;

      const spendCheck = spendLimiter.checkCheckoutLimit(cartAmount);

      if (!spendCheck.allowed) {
        Logger.warn(`Spend limit exceeded`, ctx, { amount: cartAmount });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                error: "SPEND_LIMIT_EXCEEDED",
                message: spendCheck.reason,
              }, null, 2),
              isError: true,
            },
          ],
        };
      }

      // If confirmation required, return prompt instead of executing
      if (spendCheck.requiresConfirmation) {
        const confirmToken = spendLimiter.createConfirmationToken(
          args_typed.checkout_id || `chk_${Date.now()}`,
          cartAmount
        );

        Logger.info(`Confirmation required for checkout`, ctx, { amount: cartAmount });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "confirmation_required",
                message: `Checkout for $${(cartAmount / 100).toFixed(2)} requires confirmation.`,
                confirmation_token: confirmToken,
                amount_cents: cartAmount,
                cart_summary: args_typed.cart_summary,
              }, null, 2),
            },
          ],
        };
      }
    }

    // Handle confirmation
    if (name === "confirm_checkout") {
      const args_typed = args as any;
      const token = args_typed.confirmation_token;

      const verification = spendLimiter.verifyConfirmation(token);
      if (!verification.valid) {
        Logger.warn(`Invalid confirmation token`, ctx);
        throw new AppError(verification.reason || "Invalid token", "INVALID_TOKEN", 400);
      }

      // Record spend and proceed
      spendLimiter.recordSpend(verification.amountCents || 0);
      Logger.info(`Checkout confirmed`, ctx, { amount: verification.amountCents });

      // Continue to actual checkout tool...
      // (remaining code follows)
    }

    // Call tool handler
    const handler = (toolHandlers as any)[name];
    if (!handler) {
      throw new AppError(`No handler for tool: ${name}`, "INVALID_TOOL", 500);
    }

    const result = await handler(args, ctx);

    Logger.info(`Tool succeeded: ${name}`, ctx);
    return result;
  } catch (error) {
    const appError =
      error instanceof AppError ? error : new AppError(String(error), "TOOL_ERROR", 500);

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
  Logger.info("OrignaGTA MCP server started", ctx, {
    version: "2.0.0",
    features: ["OAuth 2.0 auth", "domain separation", "rate limiting", "spend limits"],
  });
}

main().catch((error) => {
  const ctx = Logger.createContext("server", "startup");
  Logger.error("Server startup failed", ctx, error instanceof Error ? error : new Error(String(error)));
  process.exit(1);
});
