/**
 * OrignaGTA MCP Server — Authentication
 * JWT token parsing and validation
 */

import { AuthenticationError, AuthorizationError } from "./utils/errors.js";
import { Logger, LogContext } from "./utils/logger.js";

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
  static getJWTToken(): string {
    const token = process.env.ORIGNABASE_JWT_TOKEN;
    if (!token) {
      throw new AuthenticationError("ORIGNABASE_JWT_TOKEN not set");
    }
    return token;
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
  static getCurrentUser(ctx: LogContext): JWTPayload {
    try {
      const token = AuthService.getJWTToken();
      const payload = AuthService.parseJWT(token);

      // Check token expiration
      if (payload.exp && payload.exp < Date.now() / 1000) {
        throw new AuthenticationError("JWT token expired");
      }

      Logger.setUserId(ctx, payload.sub);
      return payload;
    } catch (error) {
      if (error instanceof AuthenticationError) throw error;
      throw new AuthenticationError("Failed to authenticate");
    }
  }

  /**
   * Require admin role
   */
  static requireAdmin(payload: JWTPayload, ctx: LogContext) {
    if (payload.role !== "admin") {
      Logger.warn("Unauthorized admin access attempt", ctx, {
        actualRole: payload.role,
      });
      throw new AuthorizationError("Admin access required");
    }
  }

  /**
   * Require seller role
   */
  static requireSeller(payload: JWTPayload, ctx: LogContext) {
    if (payload.role !== "seller" && payload.role !== "admin") {
      throw new AuthorizationError("Seller access required");
    }
  }

  /**
   * Require buyer role
   */
  static requireBuyer(payload: JWTPayload, ctx: LogContext) {
    if (payload.role !== "buyer" && payload.role !== "admin") {
      throw new AuthorizationError("Buyer access required");
    }
  }
}
