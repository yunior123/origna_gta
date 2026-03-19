/**
 * OrignaGTA MCP Server — Input Validation
 * Schema validation, business rule checks
 */

import { ValidationError } from "./errors.js";

const CANADIAN_POSTAL_REGEX = /^[A-Z]\d[A-Z] \d[A-Z]\d$/;
const E164_PHONE_REGEX = /^\+1\d{10}$/; // Canada only
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const Validation = {
  /**
   * Validate price in cents (0 - $100,000 CAD)
   */
  priceCents(value: any, fieldName = "price"): number {
    if (typeof value !== "number" || value < 0 || value > 10000000) {
      throw new ValidationError(`${fieldName} must be between 0 and 10000000 cents`);
    }
    if (!Number.isInteger(value)) {
      throw new ValidationError(`${fieldName} must be an integer`);
    }
    return value;
  },

  /**
   * Validate quantity
   */
  quantity(value: any): number {
    if (typeof value !== "number" || value < 1 || value > 10000) {
      throw new ValidationError("Quantity must be between 1 and 10000");
    }
    if (!Number.isInteger(value)) {
      throw new ValidationError("Quantity must be an integer");
    }
    return value;
  },

  /**
   * Validate product rating (1-5)
   */
  rating(value: any): number {
    if (typeof value !== "number" || value < 1 || value > 5) {
      throw new ValidationError("Rating must be between 1 and 5");
    }
    if (!Number.isInteger(value)) {
      throw new ValidationError("Rating must be an integer");
    }
    return value;
  },

  /**
   * Validate Canadian postal code
   */
  postalCode(value: any): string {
    if (typeof value !== "string") {
      throw new ValidationError("Postal code must be a string");
    }
    if (!CANADIAN_POSTAL_REGEX.test(value)) {
      throw new ValidationError("Postal code must be in format: A1A 1A1");
    }
    return value.toUpperCase();
  },

  /**
   * Validate phone number (E.164 for Canada)
   */
  phone(value: any): string {
    if (typeof value !== "string") {
      throw new ValidationError("Phone must be a string");
    }
    const cleaned = value.replace(/[^\d+]/g, "");
    if (!E164_PHONE_REGEX.test(cleaned)) {
      throw new ValidationError("Phone must be in format: +1XXXXXXXXXX");
    }
    return cleaned;
  },

  /**
   * Validate email
   */
  email(value: any): string {
    if (typeof value !== "string" || !EMAIL_REGEX.test(value)) {
      throw new ValidationError("Invalid email format");
    }
    return value.toLowerCase();
  },

  /**
   * Validate string length
   */
  string(value: any, minLen = 1, maxLen = 1000, fieldName = "field"): string {
    if (typeof value !== "string") {
      throw new ValidationError(`${fieldName} must be a string`);
    }
    const len = value.trim().length;
    if (len < minLen || len > maxLen) {
      throw new ValidationError(
        `${fieldName} must be between ${minLen} and ${maxLen} characters`
      );
    }
    return value.trim();
  },

  /**
   * Validate SurrealDB ID format
   */
  surrealId(value: any, fieldName = "id"): string {
    if (typeof value !== "string" || !value.includes(":")) {
      throw new ValidationError(`${fieldName} must be a valid SurrealDB ID (e.g., products:abc123)`);
    }
    return value;
  },

  /**
   * Validate pagination parameters
   */
  pagination(limit?: number, offset?: number) {
    const validLimit = !limit ? 20 : Math.min(Math.max(limit, 1), 100);
    const validOffset = !offset ? 0 : Math.max(offset, 0);
    return { limit: validLimit, offset: validOffset };
  },

  /**
   * Validate period for analytics
   */
  analyticsPeriod(value: any): "day" | "week" | "month" | "year" {
    if (!["day", "week", "month", "year"].includes(value)) {
      throw new ValidationError("Period must be: day, week, month, or year");
    }
    return value;
  },

  /**
   * Validate order status
   */
  orderStatus(value: any): "pending" | "confirmed" | "shipped" | "delivered" | "cancelled" {
    if (!["pending", "confirmed", "shipped", "delivered", "cancelled"].includes(value)) {
      throw new ValidationError(
        "Status must be: pending, confirmed, shipped, delivered, or cancelled"
      );
    }
    return value;
  },

  /**
   * Validate coupon code
   */
  couponCode(value: any): string {
    const code = Validation.string(value, 1, 50, "Coupon code");
    return code.toUpperCase();
  },

  /**
   * Validate return reason
   */
  returnReason(value: any): string {
    return Validation.string(value, 10, 500, "Return reason");
  },

  /**
   * Validate review text
   */
  reviewText(value: any): string {
    return Validation.string(value, 5, 2000, "Review text");
  },
};
