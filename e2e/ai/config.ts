/**
 * AI E2E Test Configuration
 */
import { WEB_APP_URL, TEST_ACCOUNTS } from '../lib/config.js';
import { MODELS } from './lib/nvidia-nim.js';

export const AI_CONFIG = {
  /** Models */
  textModel: process.env.AI_TEXT_MODEL ?? MODELS.TEXT_REASONING,
  visionModel: process.env.AI_VISION_MODEL ?? MODELS.VISION,

  /** Score thresholds (0-10). Tests fail below these. */
  minUiScore: Number(process.env.AI_MIN_UI_SCORE) || 6,
  minA11yScore: Number(process.env.AI_MIN_A11Y_SCORE) || 7,
  minFlowScore: Number(process.env.AI_MIN_FLOW_SCORE) || 5,

  /** Visual regression: max allowed score drop vs baseline */
  maxRegressionDrop: Number(process.env.AI_MAX_REGRESSION) || 2,

  /** Timeouts */
  aiCallTimeout: Number(process.env.AI_CALL_TIMEOUT) || 90_000,
  screenTimeout: Number(process.env.AI_SCREEN_TIMEOUT) || 60_000,

  /** Output */
  reportsDir: new URL('./reports/', import.meta.url).pathname,
  baselinesDir: new URL('./baselines/', import.meta.url).pathname,

  /** Screenshot quality (0-100) */
  screenshotQuality: Number(process.env.AI_SCREENSHOT_QUALITY) || 80,

  /** Screens to analyze */
  targetUrl: WEB_APP_URL,
  accounts: {
    admin: { email: TEST_ACCOUNTS.ADMIN_EMAIL, pass: TEST_ACCOUNTS.ADMIN_PASS },
    seller: { email: TEST_ACCOUNTS.SELLER_EMAIL, pass: TEST_ACCOUNTS.SELLER_PASS },
    buyer: { email: TEST_ACCOUNTS.BUYER_EMAIL, pass: TEST_ACCOUNTS.BUYER_PASS },
  },
} as const;
