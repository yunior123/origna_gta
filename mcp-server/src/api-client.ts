/**
 * OrignaGTA MCP Server — OrignaBase API Client
 * HTTP wrapper with auth, retry, rate limit handling
 */

import axios, { AxiosInstance, AxiosError } from "axios";
import {
  NotFoundError,
  RateLimitError,
  StripeError,
  InternalServerError,
  AppError,
} from "./utils/errors.js";
import { AuthService } from "./auth.js";
import { Logger, LogContext } from "./utils/logger.js";

export class OrignaBaseClient {
  private http: AxiosInstance;
  private baseURL: string;

  constructor(baseURL?: string) {
    this.baseURL = baseURL || process.env.ORIGNABASE_URL || "https://api.dev.orignagta.ca";

    const token = AuthService.getJWTToken();

    this.http = axios.create({
      baseURL: this.baseURL,
      timeout: 10000,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    // Axios interceptor for rate limits
    this.http.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 429) {
          const retryAfter = error.response?.headers["retry-after"];
          throw new RateLimitError(retryAfter ? parseInt(retryAfter) : undefined);
        }
        throw error;
      }
    );
  }

  async searchProducts(
    query: string,
    filters?: Record<string, any>,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const response = await this.http.post("/search/products", {
        q: query,
        ...filters,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "searchProducts", ctx);
    }
  }

  async getProduct(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get(`/products/${productId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundError("Product", productId);
      }
      this.handleError(error, "getProduct", ctx);
    }
  }

  async getCart(ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get("/cart");
      return response.data;
    } catch (error) {
      this.handleError(error, "getCart", ctx);
    }
  }

  async addToCart(productId: string, quantity: number, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/cart/items", {
        productId,
        quantity,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "addToCart", ctx);
    }
  }

  async removeFromCart(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.delete(`/cart/items/${productId}`);
      return response.data;
    } catch (error) {
      this.handleError(error, "removeFromCart", ctx);
    }
  }

  async createCheckout(
    cartData: Record<string, any>,
    ctx?: LogContext
  ): Promise<Record<string, any>> {
    try {
      const response = await this.http.post("/checkout", cartData, {
        headers: {
          "Idempotency-Key": ctx?.requestId || this.generateIdempotencyKey(),
        },
      });
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.data?.error?.includes("Stripe")) {
        throw new StripeError(error.response.data.error, error.response.data);
      }
      this.handleError(error, "createCheckout", ctx);
    }
  }

  async getOrder(orderId: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get(`/orders/${orderId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundError("Order", orderId);
      }
      this.handleError(error, "getOrder", ctx);
    }
  }

  async listOrders(filters?: Record<string, any>, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get("/orders", { params: filters });
      return response.data;
    } catch (error) {
      this.handleError(error, "listOrders", ctx);
    }
  }

  async requestReturn(returnData: Record<string, any>, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/return-requests", returnData);
      return response.data;
    } catch (error) {
      this.handleError(error, "requestReturn", ctx);
    }
  }

  async submitReview(reviewData: Record<string, any>, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/reviews", reviewData);
      return response.data;
    } catch (error) {
      this.handleError(error, "submitReview", ctx);
    }
  }

  async getAnalytics(period: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get("/analytics", { params: { period } });
      return response.data;
    } catch (error) {
      this.handleError(error, "getAnalytics", ctx);
    }
  }

  async checkInventory(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.get(`/products/${productId}/inventory`);
      return response.data;
    } catch (error) {
      this.handleError(error, "checkInventory", ctx);
    }
  }

  async applyCoupon(code: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/coupons/apply", { code });
      return response.data;
    } catch (error) {
      this.handleError(error, "applyCoupon", ctx);
    }
  }

  private handleError(error: any, method: string, ctx?: LogContext): never {
    if (error instanceof AppError) {
      throw error;
    }

    if (axios.isAxiosError(error)) {
      if (ctx) {
        Logger.error(`API request failed: ${method}`, ctx, error);
      }

      const status = error.response?.status;
      const data = error.response?.data;

      if (status === 401) {
        throw new Error("Unauthorized - invalid or expired token");
      }
      if (status === 403) {
        throw new Error("Forbidden - insufficient permissions");
      }
      if (status === 404) {
        throw new NotFoundError("Resource");
      }
      if (status === 429) {
        throw new RateLimitError();
      }
      if (status && status >= 500) {
        throw new InternalServerError("OrignaBase API error");
      }

      throw new Error(data?.error || error.message);
    }

    throw new InternalServerError(`Unexpected error in ${method}`);
  }

  private generateIdempotencyKey(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(7)}`;
  }
}

// Export singleton instance
export const apiClient = new OrignaBaseClient();
