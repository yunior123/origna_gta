/**
 * OrignaGTA MCP Server — Custom Error Classes
 */

export class AppError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number = 400,
    public details?: Record<string, any>
  ) {
    super(message);
    this.name = "AppError";
  }

  toJSON() {
    return {
      error: this.message,
      code: this.code,
      details: this.details,
      statusCode: this.statusCode,
    };
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, any>) {
    super("VALIDATION_ERROR", message, 400, details);
  }
}

export class AuthenticationError extends AppError {
  constructor(message: string = "Authentication required") {
    super("AUTH_ERROR", message, 401);
  }
}

export class AuthorizationError extends AppError {
  constructor(message: string = "Insufficient permissions") {
    super("AUTHZ_ERROR", message, 403);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    const msg = id ? `${resource} '${id}' not found` : `${resource} not found`;
    super("NOT_FOUND", msg, 404);
  }
}

export class ConflictError extends AppError {
  constructor(message: string, details?: Record<string, any>) {
    super("CONFLICT", message, 409, details);
  }
}

export class RateLimitError extends AppError {
  constructor(retryAfter?: number) {
    super("RATE_LIMIT", "Too many requests", 429, retryAfter ? { retryAfter } : undefined);
  }
}

export class StripeError extends AppError {
  constructor(message: string, details?: Record<string, any>) {
    super("STRIPE_ERROR", message, 400, details);
  }
}

export class InternalServerError extends AppError {
  constructor(message: string = "Internal error") {
    super("INTERNAL_ERROR", message, 500);
  }
}

export function isAppError(error: any): error is AppError {
  return error instanceof AppError;
}

export function sanitizeError(error: any) {
  if (isAppError(error)) {
    return { message: error.message, code: error.code };
  }
  return { message: "An unexpected error occurred", code: "UNKNOWN_ERROR" };
}
