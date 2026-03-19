/**
 * Analytics Tools: get_analytics (admin only)
 */

import { GetAnalyticsParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function getAnalytics(params: GetAnalyticsParams, ctx: LogContext) {
  Logger.info("get_analytics called", ctx, { metric: params.metric });

  const user = await AuthService.getCurrentUser(ctx);
  AuthService.requireAdmin(user, ctx);

  const result = await apiClient.getAnalytics(params.metric, params.period || "month", ctx);

  Logger.info("get_analytics succeeded", ctx);

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}
