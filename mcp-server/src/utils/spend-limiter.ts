/**
 * OrignaGTA MCP Server — Spend Limiter
 * Enforces maximum spend per operation and optional confirmation requirement
 */

import { AppError } from "./errors.js";

export interface SpendLimitConfig {
  maxCheckoutCents: number; // max amount for a single checkout without confirmation
  maxDailySpendCents: number; // max total spending per calendar day
}

interface ConfirmationToken {
  token: string;
  checkoutId: string;
  amountCents: number;
  expiresAt: number; // unix timestamp
}

export class SpendLimiter {
  private config: SpendLimitConfig;
  private dailySpend = new Map<string, number>(); // date -> total cents
  private pendingConfirmations = new Map<string, ConfirmationToken>();

  private readonly CONFIRMATION_EXPIRY_MS = 5 * 60 * 1000; // 5 minutes

  constructor(config: SpendLimitConfig) {
    this.config = config;
  }

  /**
   * Check if checkout amount is within limits
   */
  checkCheckoutLimit(amountCents: number, date: string = this.getTodayDate()): {
    allowed: boolean;
    requiresConfirmation: boolean;
    reason?: string;
  } {
    // Check per-transaction limit
    if (amountCents > this.config.maxCheckoutCents) {
      return {
        allowed: false,
        requiresConfirmation: false,
        reason: `Checkout amount $${(amountCents / 100).toFixed(2)} exceeds maximum $${(this.config.maxCheckoutCents / 100).toFixed(2)}`,
      };
    }

    // Check daily spend limit
    const todaySpend = this.dailySpend.get(date) || 0;
    if (todaySpend + amountCents > this.config.maxDailySpendCents) {
      return {
        allowed: false,
        requiresConfirmation: false,
        reason: `Daily spend limit exceeded. Current: $${(todaySpend / 100).toFixed(2)}, Remaining: $${((this.config.maxDailySpendCents - todaySpend) / 100).toFixed(2)}`,
      };
    }

    // Check if confirmation is required
    const requiresConfirmation = amountCents > (this.config.maxCheckoutCents * 0.5); // 50% of limit

    return { allowed: true, requiresConfirmation };
  }

  /**
   * Create a confirmation token for a checkout
   * Returns token that must be provided to confirm
   */
  createConfirmationToken(checkoutId: string, amountCents: number): string {
    const token = `confirm_${checkoutId}_${Date.now()}`;

    this.pendingConfirmations.set(token, {
      token,
      checkoutId,
      amountCents,
      expiresAt: Date.now() + this.CONFIRMATION_EXPIRY_MS,
    });

    return token;
  }

  /**
   * Verify and consume a confirmation token
   */
  verifyConfirmation(token: string): { valid: boolean; checkoutId?: string; amountCents?: number; reason?: string } {
    const confirmation = this.pendingConfirmations.get(token);

    if (!confirmation) {
      return { valid: false, reason: "Confirmation token not found" };
    }

    if (confirmation.expiresAt < Date.now()) {
      this.pendingConfirmations.delete(token);
      return { valid: false, reason: "Confirmation token expired" };
    }

    // Token is valid — remove it (one-time use)
    this.pendingConfirmations.delete(token);

    return {
      valid: true,
      checkoutId: confirmation.checkoutId,
      amountCents: confirmation.amountCents,
    };
  }

  /**
   * Record a confirmed spend
   */
  recordSpend(amountCents: number, date: string = this.getTodayDate()): void {
    const current = this.dailySpend.get(date) || 0;
    this.dailySpend.set(date, current + amountCents);
  }

  /**
   * Get daily spend for a date
   */
  getDailySpend(date: string = this.getTodayDate()): number {
    return this.dailySpend.get(date) || 0;
  }

  /**
   * Reset daily spend (call at midnight or for testing)
   */
  resetDaily(date?: string): void {
    if (date) {
      this.dailySpend.delete(date);
    } else {
      this.dailySpend.clear();
    }
  }

  private getTodayDate(): string {
    return new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  }
}
