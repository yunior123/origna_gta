/**
 * OrignaGTA MCP Server — Rate Limiter
 * Per-tool request budgets with sliding window
 */

export interface RateLimitConfig {
  requestsPerMinute: number;
  burstSize?: number; // peak concurrent requests
}

interface TokenBucket {
  tokens: number;
  lastRefill: number;
}

export class RateLimiter {
  private buckets = new Map<string, TokenBucket>();
  private readonly configs: Map<string, RateLimitConfig>;

  constructor(toolConfigs: Record<string, RateLimitConfig>) {
    this.configs = new Map(Object.entries(toolConfigs));
  }

  /**
   * Check if a request is allowed
   */
  isAllowed(toolName: string): { allowed: boolean; resetInSeconds: number } {
    const config = this.configs.get(toolName);
    if (!config) {
      // Unknown tool — allow but log warning
      return { allowed: true, resetInSeconds: 60 };
    }

    const now = Date.now();
    const bucket = this.buckets.get(toolName) || {
      tokens: config.requestsPerMinute,
      lastRefill: now,
    };

    // Refill tokens based on elapsed time
    const elapsedSeconds = (now - bucket.lastRefill) / 1000;
    const tokensToAdd = (config.requestsPerMinute / 60) * elapsedSeconds;
    bucket.tokens = Math.min(config.requestsPerMinute, bucket.tokens + tokensToAdd);
    bucket.lastRefill = now;

    const allowed = bucket.tokens >= 1;
    if (allowed) {
      bucket.tokens -= 1;
    }

    this.buckets.set(toolName, bucket);

    // Calculate seconds until next request is allowed
    const resetIn = allowed ? 0 : Math.ceil((1 - bucket.tokens) / (config.requestsPerMinute / 60));

    return { allowed, resetInSeconds: resetIn };
  }

  /**
   * Get current bucket state (for monitoring)
   */
  getMetrics(toolName: string): { tokensRemaining: number; capacity: number; nextRequestInSeconds: number } | null {
    const config = this.configs.get(toolName);
    const bucket = this.buckets.get(toolName);

    if (!config || !bucket) return null;

    const resetIn = bucket.tokens >= 1 ? 0 : Math.ceil((1 - bucket.tokens) / (config.requestsPerMinute / 60));

    return {
      tokensRemaining: Math.floor(bucket.tokens),
      capacity: config.requestsPerMinute,
      nextRequestInSeconds: resetIn,
    };
  }

  /**
   * Reset specific tool bucket
   */
  reset(toolName: string): void {
    this.buckets.delete(toolName);
  }

  /**
   * Reset all buckets
   */
  resetAll(): void {
    this.buckets.clear();
  }
}
