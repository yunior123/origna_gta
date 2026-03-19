/**
 * Review Tool: submit_review
 */

import { SubmitReviewParams } from "../types.js";
import { apiClient } from "../api-client.js";
import { AuthService } from "../auth.js";
import { Validation } from "../utils/validation.js";
import { Logger, LogContext } from "../utils/logger.js";

export async function submitReview(params: SubmitReviewParams, ctx: LogContext) {
  Logger.info("submit_review called", ctx, {
    productId: params.product_id,
    rating: params.rating,
  });

  const user = AuthService.getCurrentUser(ctx);
  AuthService.requireBuyer(user, ctx);

  const productId = Validation.surrealId(params.product_id, "product_id");
  const rating = Validation.rating(params.rating);
  const text = Validation.reviewText(params.text);

  const review = await apiClient.submitReview(
    {
      productId,
      userId: user.sub,
      rating,
      text,
    },
    ctx
  );

  Logger.info("submit_review succeeded", ctx, {
    reviewId: review.id,
  });

  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            reviewId: review.id,
            productId,
            rating,
            text: text.substring(0, 100) + (text.length > 100 ? "..." : ""),
            status: "published",
            createdAt: new Date().toISOString(),
          },
          null,
          2
        ),
      },
    ],
  };
}
