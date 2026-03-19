/**
 * Review Tools: submit_review
 */

import { SubmitReviewParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function submitReview(params: SubmitReviewParams, ctx: LogContext) {
  Logger.info("submit_review called", ctx, { productId: params.product_id });

  const user = await AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  const productId = Validation.surrealId(params.product_id, "product_id");
  const rating = Validation.rating(params.rating);
  const title = Validation.string(params.title, 5, 100, "title");
  const comment = params.comment ? Validation.string(params.comment, 10, 1000, "comment") : undefined;

  const result = await apiClient.submitReview(productId, rating, title, comment, ctx);

  Logger.info("submit_review succeeded", ctx, { reviewId: result.id });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(result, null, 2),
      },
    ],
  };
}
