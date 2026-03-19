/**
 * OrignaGTA MCP Server — Admin Tools (ADMIN ROLE REQUIRED)
 * Analytics and metrics — admin access only
 */

import { Tool } from "../../types.js";
import * as analyticsTools from "../analytics.js";

export const ADMIN_TOOLS: Tool[] = [
  {
    name: "get_analytics",
    description: "Get platform analytics (admin access required)",
    inputSchema: {
      type: "object",
      properties: {
        metric: {
          type: "string",
          enum: ["revenue", "orders", "users", "products"],
          description: "Metric to retrieve",
        },
        period: {
          type: "string",
          enum: ["day", "week", "month"],
          description: "Time period (default: month)",
        },
      },
      required: ["metric"],
    },
  },
];

export const adminToolHandlers: Record<string, Function> = {
  get_analytics: analyticsTools.getAnalytics,
};

export const ADMIN_RATE_LIMITS = {
  get_analytics: { requestsPerMinute: 10 },
};
