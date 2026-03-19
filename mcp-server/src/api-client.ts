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
      const params: any = {
        limit: filters?.limit || 10,
        offset: filters?.offset || 0,
        q: query,
      };

      if (filters?.category) params.category = filters.category;
      if (filters?.minPrice !== undefined) params.min_price = filters.minPrice;
      if (filters?.maxPrice !== undefined) params.max_price = filters.maxPrice;
      if (filters?.sort) params.sort = filters.sort;

      const response = await this.http.get("/products", { params });
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
      const response = await this.http.get("/cart");
      return response.data;
    } catch (error) {
      this.handleError(error, "getCart", ctx);
    }
  }

  async addToCart(productId: string, quantity: number, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/cart/add", {
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
      const response = await this.http.delete(`/cart/remove/${productId}`);
      return response.data;
    } catch (error) {
      this.handleError(error, "removeFromCart", ctx);
    }
  }

  async applyCoupon(code: string, ctx?: LogContext): Promise<any> {
    try {
      const response = await this.http.post("/cart/coupon", { code });
      return response.data;
    } catch (error) {
      this.handleError(error, "applyCoupon", ctx);
    }
  }

  async createCheckout(
    shippingAddress: Record<string, any>,
    coupon?: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const response = await this.http.post("/checkout/session", {
        shipping_address: shippingAddress,
        coupon,
      });
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 422) {
        throw new AppError("Invalid checkout data", "VALIDATION_ERROR", 422);
      }
      this.handleError(error, "createCheckout", ctx);
    }
  }

  async listOrders(
    status?: string,
    limit?: number,
    offset?: number,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const params: any = { limit: limit || 20, offset: offset || 0 };
      if (status) params.status = status;

      const response = await this.http.get("/orders", { params });
      return response.data;
    } catch (error) {
      this.handleError(error, "listOrders", ctx);
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

  async requestReturn(
    orderId: string,
    items: Array<{ productId: string; quantity: number }>,
    reason: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const response = await this.http.post(`/orders/${orderId}/returns`, {
        items,
        reason,
      });
      return response.data;
    } catch (error) {
      this.handleError(error, "requestReturn", ctx);
    }
  }

  async submitReview(
    productId: string,
    rating: number,
    text: string,
    ctx?: LogContext
  ): Promise<any> {
    try {
      const response = await this.http.post(`/products/${productId}/reviews`, {
        rating,
        text,
      });
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundError("Product", productId);
      }
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

  private handleError(error: any, method: string, ctx?: LogContext): never {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status || 500;
      const data = error.response?.data;

      Logger.error(`API request failed: ${method}`, ctx || Logger.createContext(method), error);

      switch (status) {
        case 400:
          throw new AppError(
            data?.message || "Invalid request",
            data?.code || "INVALID_REQUEST",
            400
          );
        case 401:
          throw new AppError("Unauthorized", "AUTH_ERROR", 401);
        case 403:
          throw new AppError("Forbidden", "FORBIDDEN", 403);
        case 404:
          throw new NotFoundError("Resource", data?.id || "unknown");
        case 422:
          throw new AppError(
            data?.message || "Validation error",
            data?.code || "VALIDATION_ERROR",
            422
          );
        case 429:
          throw new RateLimitError();
        case 500:
          throw new InternalServerError(data?.message || "Server error");
        case 502:
        case 503:
          throw new InternalServerError(`Service unavailable (${status})`);
        default:
          throw new AppError(`HTTP ${status}: ${data?.message || error.message}`, "API_ERROR", status);
      }
    }

    throw new InternalServerError(String(error));
  }
}

// Singleton instance
export const apiClient = new OrignaBaseClient();
