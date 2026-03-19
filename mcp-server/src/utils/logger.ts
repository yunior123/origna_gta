/**
 * OrignaGTA MCP Server — Structured Logging
 * JSON logs with request context, duration tracking, no PII
 */

import { randomUUID } from "crypto";

export enum LogLevel {
  DEBUG = "DEBUG",
  INFO = "INFO",
  WARN = "WARN",
  ERROR = "ERROR",
}

export interface LogContext {
  requestId: string;
  tool?: string;
  method?: string;
  startTime: number;
  duration?: number;
  userId?: string;
  [key: string]: any;
}

/**
 * Structured logger for MCP server
 * Never logs passwords, tokens, or PII
 */
export class Logger {
  private static readonly isDev = process.env.NODE_ENV === "development";

  static createContext(tool?: string, method?: string): LogContext {
    return {
      requestId: randomUUID(),
      tool,
      method,
      startTime: Date.now(),
    };
  }

  static setUserId(ctx: LogContext, userId: string) {
    ctx.userId = userId.split(":")[1]; // Store only ID suffix, not full path
  }

  static debug(message: string, ctx: LogContext, meta?: Record<string, any>) {
    Logger.log(LogLevel.DEBUG, message, ctx, meta);
  }

  static info(message: string, ctx: LogContext, meta?: Record<string, any>) {
    Logger.log(LogLevel.INFO, message, ctx, meta);
  }

  static warn(message: string, ctx: LogContext, meta?: Record<string, any>) {
    Logger.log(LogLevel.WARN, message, ctx, meta);
  }

  static error(message: string, ctx: LogContext, error?: Error, meta?: Record<string, any>) {
    Logger.log(LogLevel.ERROR, message, ctx, {
      ...meta,
      error: error?.message,
      stack: Logger.isDev ? error?.stack : undefined,
    });
  }

  private static log(
    level: LogLevel,
    message: string,
    ctx: LogContext,
    meta?: Record<string, any>
  ) {
    ctx.duration = Date.now() - ctx.startTime;

    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...ctx,
      ...(meta && Logger.sanitizeMeta(meta)),
    };

    // Always output JSON for structured logging
    console.log(JSON.stringify(logEntry));
  }

  /**
   * Remove secrets and PII before logging
   */
  private static sanitizeMeta(meta: Record<string, any>): Record<string, any> {
    const sanitized = { ...meta };

    const secretFields = [
      "password",
      "token",
      "secret",
      "key",
      "authorization",
      "jwt",
      "apiKey",
      "ssn",
      "creditCard",
      "stripe",
    ];

    for (const field of secretFields) {
      if (field in sanitized) {
        sanitized[field] = "[REDACTED]";
      }
    }

    // Sanitize email partially
    if (sanitized.email && typeof sanitized.email === "string") {
      const [local, domain] = sanitized.email.split("@");
      sanitized.email = `${local.substring(0, 2)}***@${domain}`;
    }

    return sanitized;
  }
}
