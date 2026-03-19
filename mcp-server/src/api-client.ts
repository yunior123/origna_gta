/**
 * OrignaGTA MCP Server — OrignaBase API Client
 * HTTP wrapper with OAuth auth, retry, rate limit handling
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
  private http: AxiosInstance | null = null;
  private baseURL: string;

  constructor(baseURL?: string) {
    this.baseURL = baseURL || process.env.ORIGNABASE_URL || "https://api.dev.orignagta.ca";
  }

  /**
   * Initialize HTTP client with fresh token
   * Called before each request to ensure token is current
   */
  private async initializeClient(ctx?: LogContext): Promise<AxiosInstance> {
    if (this.http) {
      return this.http;
    }

    const token = await AuthService.getJWTToken(ctx);

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

    return this.http;
  }

  async searchProducts(
    query: string,
    filters?: Record<string, any>,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const params: any = {
        limit: filters?.limit || 10,
        offset: filters?.offset || 0,
        q: query,
      };

      if (filters?.category) params.category = filters.category;
      if (filters?.minPrice !== undefined) params.min_price = filters.minPrice;
      if (filters?.maxPrice !== undefined) params.max_price = filters.maxPrice;
      if (filters?.sort) params.sort = filters.sort;

      const response = await http.get("/products", { params });
      return response.data;
    } catch (error) {
      this.handleError(error, "searchProducts", ctx);
    }
  }

  async getProduct(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.get(`/products/${productId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundError("Product", productId);
      }
      this.handleError(error, "getProduct", ctx);
    }
  }

  async checkInventory(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const product = await this.getProduct(productId, ctx);
      return {
        productId,
        stockQuantity: product.stockQuantity || 0,
        available: (product.stockQuantity || 0) > 0,
      };
    } catch (error) {
      this.handleError(error, "checkInventory", ctx);
    }
  }

  async getCart(ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.get("/cart");
      return response.data;
    } catch (error) {
      this.handleError(error, "getCart", ctx);
    }
  }

  async addToCart(
    productId: string,
    quantity: number,
    idempotencyKey?: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.post("/cart/add", {
        productId,
        quantity,
        idempotency_key: idempotencyKey,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "addToCart", ctx);
    }
  }

  async removeFromCart(productId: string, ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.delete(`/cart/remove/${productId}`);
      return response.data;
    } catch (error) {
      this.handleError(error, "removeFromCart", ctx);
    }
  }

  async applyCoupon(code: string, ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.post("/cart/coupon", { code });
      return response.data;
    } catch (error) {
      this.handleError(error, "applyCoupon", ctx);
    }
  }

  async createCheckout(
    shippingAddress: Record<string, any>,
    coupon?: string,
    idempotencyKey?: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.post("/checkout/session", {
        shipping_address: shippingAddress,
        coupon,
        idempotency_key: idempotencyKey,
      });
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 422) {
        throw new AppError("Invalid checkout data", "VALIDATION_ERROR", 422);
      }
      this.handleError(error, "createCheckout", ctx);
    }
  }

  async listOrders(limit?: number, offset?: number, ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.get("/orders", {
        params: { limit: limit || 20, offset: offset || 0 },
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "listOrders", ctx);
    }
  }

  async getOrder(orderId: string, ctx?: LogContext): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.get(`/orders/${orderId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundError("Order", orderId);
      }
      this.handleError(error, "getOrder", ctx);
    }
  }

  async requestReturn(
    orderId: string,
    reason: string,
    idempotencyKey?: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.post(`/orders/${orderId}/return`, {
        reason,
        idempotency_key: idempotencyKey,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "requestReturn", ctx);
    }
  }

  async submitReview(
    productId: string,
    rating: number,
    title: string,
    comment?: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.post(`/products/${productId}/review`, {
        rating,
        title,
        comment,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "submitReview", ctx);
    }
  }

  async getAnalytics(
    metric: string,
    period: string = "month",
    ctx?: LogContext
  ): Promise<any> {
    try {
      const http = await this.initializeClient(ctx);
      const response = await http.get("/admin/analytics", {
        params: { metric, period },
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "getAnalytics", ctx);
    }
  }

  private handleError(error: any, operation: string, ctx?: LogContext): never {
    Logger.error(`API call failed: ${operation}`, ctx, { error });

    if (error instanceof AppError) {
      throw error;
    }

    if (axios.isAxiosError(error)) {
      const status = error.response?.status;
      const message = error.response?.data?.message || error.message;

      if (status === 400) {
        throw new AppError(message, "INVALID_REQUEST", 400);
      }
      if (status === 401) {
        throw new AppError("Unauthorized", "UNAUTHORIZED", 401);
      }
      if (status === 403) {
        throw new AppError("Forbidden", "FORBIDDEN", 403);
      }
      if (status === 404) {
        throw new NotFoundError("Resource", "unknown");
      }
      if (status === 429) {
        throw new RateLimitError();
      }
      if (status === 500) {
        throw new InternalServerError(message);
      }
      if (status === 402) {
        throw new StripeError(message);
      }

      throw new AppError(message || "API request failed", "NETWORK_ERROR", status);
    }

    throw new InternalServerError("Unknown error");
  }
}

/**
 * Singleton API client instance
 */
export const apiClient = new OrignaBaseClient();
