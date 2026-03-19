/**
 * Analytics Tool: get_analytics (admin only)
 */

import { GetAnalyticsParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function getAnalytics(params: GetAnalyticsParams, ctx: LogContext) {
  Logger.info("get_analytics called", ctx, { period: params.period });

  const user = AuthService.getCurrentUser(ctx);
  AuthService.requireAdmin(user, ctx);

  const period = Validation.analyticsPeriod(params.period);

  const analytics = await apiClient.getAnalytics(period, ctx);

  Logger.info("get_analytics succeeded", ctx, {
    period,
    totalOrders: analytics.totalOrders,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            period,
            totalRevenueCents: analytics.totalRevenueCents,
            totalOrders: analytics.totalOrders,
            averageOrderValueCents: analytics.averageOrderValueCents,
            topProducts: analytics.topProducts || [],
            ordersByStatus: analytics.ordersByStatus || [],
          },
          null,
          2
        ),
      },
    ],
  };
}
