/**
 * OrignaGTA MCP Server — Authentication
 * JWT token parsing, validation, and role-based access control
 */

import { AuthenticationError, AuthorizationError } from "./utils/errors.js";
import { Logger, LogContext } from "./utils/logger.js";
import { OAuthProvider } from "./auth/oauth-provider.js";

export interface JWTPayload {
  sub: string; // Full path: "users:abc123"
  uid: string; // Short ID: "abc123"
  email: string;
  role: string; // "buyer", "seller", "admin"
  iat: number;
  exp: number;
  iss?: string;
}

export class AuthService {
  private static oauthProvider = OAuthProvider.getInstance();

  /**
   * Get JWT token — uses OAuth provider with env fallback
   */
  static async getJWTToken(ctx?: LogContext): Promise<string> {
    const _ctx = ctx || Logger.createContext("auth");
    try {
      return await this.oauthProvider.authenticate(_ctx);
    } catch (error) {
      Logger.error("Failed to get JWT token", _ctx, { error });
      throw new AuthenticationError("Authentication failed");
    }
  }

  /**
   * Parse JWT payload (client-side parsing, no verification)
   * Real verification happens server-side in OrignaBase
   */
  static parseJWT(token: string): JWTPayload {
    try {
      const parts = token.split(".");
      if (parts.length !== 3) {
        throw new Error("Invalid token format");
      }

      const decoded = JSON.parse(Buffer.from(parts[1], "base64").toString("utf-8"));
      return decoded as JWTPayload;
    } catch (error) {
      throw new AuthenticationError("Invalid JWT token");
    }
  }

  /**
   * Get current user info from JWT
   */
  static async getCurrentUser(ctx?: LogContext): Promise<JWTPayload> {
    const _ctx = ctx || Logger.createContext("auth");
    try {
      const token = await this.getJWTToken(_ctx);
      const payload = this.parseJWT(token);

      // Check token expiration
      if (payload.exp && payload.exp < Date.now() / 1000) {
        throw new AuthenticationError("JWT token expired");
      }

      Logger.setUserId(_ctx, payload.sub);
      return payload;
    } catch (error) {
      if (error instanceof AuthenticationError) throw error;
      throw new AuthenticationError("Failed to authenticate");
    }
  }

  /**
   * Require admin role
   */
  static requireAdmin(payload: JWTPayload, ctx?: LogContext): void {
    const _ctx = ctx || Logger.createContext("auth");
    if (payload.role !== "admin") {
      Logger.warn("Unauthorized admin access attempt", _ctx, {
        actualRole: payload.role,
      });
      throw new AuthorizationError("Admin access required");
    }
  }

  /**
   * Require seller role
   */
  static requireSeller(payload: JWTPayload, ctx?: LogContext): void {
    if (payload.role !== "seller" && payload.role !== "admin") {
      throw new AuthorizationError("Seller access required");
    }
  }

  /**
   * Require buyer role
   */
  static requireBuyer(payload: JWTPayload, ctx?: LogContext): void {
    if (payload.role !== "buyer" && payload.role !== "admin") {
      throw new AuthorizationError("Buyer access required");
    }
  }

  /**
   * Clear cached authentication
   */
  static logout(ctx?: LogContext): void {
    const _ctx = ctx || Logger.createContext("auth");
    this.oauthProvider.clearToken(_ctx);
    Logger.info("User logged out", _ctx);
  }
}
