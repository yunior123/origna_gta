/**
 * OrignaGTA MCP Server — OAuth 2.0 Provider
 * Handles JWT token caching, refresh, and API key fallback
 */

import axios, { AxiosInstance } from "axios";
import { AuthenticationError } from "../utils/errors.js";
import { Logger, LogContext } from "../utils/logger.js";

export interface OAuthToken {
  access_token: string;
  token_type: "Bearer";
  expires_in: number; // seconds
  expires_at: number; // unix timestamp
}

export class OAuthProvider {
  private static instance: OAuthProvider;
  private token: OAuthToken | null = null;
  private http: AxiosInstance;
  private baseURL: string;
  private authMethod: "credentials" | "api_key";
  private refreshTimer: NodeJS.Timeout | null = null;

  private constructor() {
    this.baseURL = process.env.ORIGNABASE_URL || "https://api.dev.orignagta.ca";
    this.authMethod = (process.env.MCP_AUTH_METHOD as "credentials" | "api_key") || "credentials";

    this.http = axios.create({
      baseURL: this.baseURL,
      timeout: 10000,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  static getInstance(): OAuthProvider {
    if (!OAuthProvider.instance) {
      OAuthProvider.instance = new OAuthProvider();
    }
    return OAuthProvider.instance;
  }

  /**
   * Authenticate and get JWT token
   * Caches token and auto-refreshes before expiry
   */
  async authenticate(ctx?: LogContext): Promise<string> {
    const _ctx = ctx || Logger.createContext("auth");

    // Return cached token if still valid (with 1min buffer)
    if (this.token && this.token.expires_at > Date.now() / 1000 + 60) {
      Logger.debug("Using cached token", _ctx, { expiresIn: this.token.expires_at - Date.now() / 1000 });
      return this.token.access_token;
    }

    // Fallback: env JWT token (dev mode)
    const envToken = process.env.ORIGNABASE_JWT_TOKEN;
    if (envToken) {
      Logger.debug("Using env JWT token (fallback)", _ctx);
      return envToken;
    }

    if (this.authMethod === "api_key") {
      return this.authenticateViaApiKey(_ctx);
    }

    return this.authenticateViaCredentials(_ctx);
  }

  /**
   * Authenticate via email/password
   */
  private async authenticateViaCredentials(ctx: LogContext): Promise<string> {
    const email = process.env.MCP_AUTH_EMAIL;
    const password = process.env.MCP_AUTH_PASSWORD;

    if (!email || !password) {
      throw new AuthenticationError(
        "MCP_AUTH_EMAIL and MCP_AUTH_PASSWORD required for credentials auth. " +
        "Or set ORIGNABASE_JWT_TOKEN for env-based auth."
      );
    }

    try {
      Logger.debug("Authenticating via credentials", ctx, { email });

      const response = await this.http.post("/auth/login", {
        email,
        password,
      });

      const { jwt, expiresIn } = response.data;
      if (!jwt) {
        throw new AuthenticationError("No JWT returned from auth endpoint");
      }

      this.token = {
        access_token: jwt,
        token_type: "Bearer",
        expires_in: expiresIn || 900, // default 15 mins
        expires_at: Date.now() / 1000 + (expiresIn || 900),
      };

      // Schedule auto-refresh (refresh at 80% of TTL)
      this.scheduleRefresh(ctx);

      Logger.info("Successfully authenticated via credentials", ctx, { expiresIn: this.token.expires_in });

      return this.token.access_token;
    } catch (error) {
      Logger.error("Auth failed", ctx, error instanceof Error ? error : new Error(String(error)));
      throw new AuthenticationError("Failed to authenticate with OrignaBase");
    }
  }

  /**
   * Authenticate via API key
   */
  private async authenticateViaApiKey(ctx: LogContext): Promise<string> {
    const apiKey = process.env.MCP_API_KEY;

    if (!apiKey) {
      throw new AuthenticationError("MCP_API_KEY required for API key auth");
    }

    try {
      Logger.debug("Authenticating via API key", ctx);

      const response = await this.http.post("/auth/api-key", {
        api_key: apiKey,
      });

      const { jwt, expiresIn } = response.data;
      if (!jwt) {
        throw new AuthenticationError("No JWT returned from auth endpoint");
      }

      this.token = {
        access_token: jwt,
        token_type: "Bearer",
        expires_in: expiresIn || 900,
        expires_at: Date.now() / 1000 + (expiresIn || 900),
      };

      this.scheduleRefresh(ctx);

      Logger.info("Successfully authenticated via API key", ctx, { expiresIn: this.token.expires_in });

      return this.token.access_token;
    } catch (error) {
      Logger.error("API key auth failed", ctx, error instanceof Error ? error : new Error(String(error)));
      throw new AuthenticationError("Failed to authenticate with API key");
    }
  }

  /**
   * Refresh token before expiry
   */
  async refreshToken(ctx?: LogContext): Promise<string> {
    const _ctx = ctx || Logger.createContext("auth");

    if (!this.token) {
      return this.authenticate(_ctx);
    }

    try {
      Logger.debug("Refreshing token", _ctx);

      // Most OAuth/JWT systems use refresh_token, but OrignaBase may use a different flow
      // For now, re-authenticate; this can be optimized later
      this.token = null;
      this.clearRefreshTimer();

      return this.authenticate(_ctx);
    } catch (error) {
      Logger.error("Token refresh failed", _ctx, error instanceof Error ? error : new Error(String(error)));
      throw new AuthenticationError("Failed to refresh token");
    }
  }

  /**
   * Clear token cache (for logout)
   */
  clearToken(ctx?: LogContext): void {
    const _ctx = ctx || Logger.createContext("auth");
    Logger.debug("Clearing cached token", _ctx);
    this.token = null;
    this.clearRefreshTimer();
  }

  /**
   * Schedule auto-refresh before token expires
   */
  private scheduleRefresh(ctx: LogContext): void {
    this.clearRefreshTimer();

    if (!this.token) return;

    // Refresh at 80% of TTL
    const refreshIn = Math.floor(this.token.expires_in * 0.8 * 1000);

    this.refreshTimer = setTimeout(() => {
      this.refreshToken(ctx).catch((err) => {
        Logger.error("Auto-refresh failed", ctx, err instanceof Error ? err : new Error(String(err)));
      });
    }, refreshIn);
  }

  private clearRefreshTimer(): void {
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
      this.refreshTimer = null;
    }
  }

  /**
   * Get current token (for HTTP client)
   */
  getToken(): string | null {
    return this.token?.access_token || null;
  }

  /**
   * Check if authenticated
   */
  isAuthenticated(): boolean {
    return !!this.token || !!process.env.ORIGNABASE_JWT_TOKEN;
  }
}
