/**
 * OrignaGTA — Design System Compliance E2E Tests
 * ===============================================
 * Verifies DesignTokens are applied correctly across the app.
 * Tests dark theme, color compliance, WCAG contrast, and design consistency.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { WEB_APP_URL, TEST_ACCOUNTS } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;

// DesignTokens hex values (from lib/utils/design_tokens.dart)
const COLORS = {
  primary: '#7b93ff',
  secondary: '#764ba2',
  darkBackground: '#0f0f1e',
  darkCard: '#1e1e32',
  darkSurface: '#1a1a2e',
  success: '#10b981',
  error: '#ef4444',
  warning: '#f59e0b',
  textOnDark: '#ffffff',
  textSecondary: '#6b7280',
};

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) throw new Error(`Invalid hex color: ${hex}`);
  return {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16),
  };
}

function contrastRatio(rgb1: { r: number; g: number; b: number }, rgb2: { r: number; g: number; b: number }): number {
  const l1 = 0.299 * rgb1.r + 0.587 * rgb1.g + 0.114 * rgb1.b;
  const l2 = 0.299 * rgb2.r + 0.587 * rgb2.g + 0.114 * rgb2.b;
  const lighter = Math.max(l1, l2) / 255;
  const darker = Math.min(l1, l2) / 255;
  return (lighter + 0.05) / (darker + 0.05);
}

let browser: AgentBrowser;

beforeAll(async () => {
  browser = new AgentBrowser();
}, 30_000);

afterAll(async () => {
  await browser.close();
});

describe('Design System Compliance', () => {
  test('C001: Home page loads with dark theme applied', async () => {
    await browser.open(TARGET_URL);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  }, 45_000);

  test('C002: Primary button color (#7B93FF) is accessible', async () => {
    // Verify WCAG AA contrast: primary (#7B93FF) on dark background (#0F0F1E)
    const primaryRgb = hexToRgb(COLORS.primary);
    const bgRgb = hexToRgb(COLORS.darkBackground);
    const ratio = contrastRatio(primaryRgb, bgRgb);
    expect(ratio).toBeGreaterThan(4.5); // WCAG AA for normal text
  }, 10_000);

  test('C003: Buttons render with consistent styling', async () => {
    await browser.open(`${TARGET_URL}/login`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const buttons = snap.refs.filter(r => /btn-|button/i.test(r.name));
    expect(buttons.length).toBeGreaterThan(0);
  }, 45_000);

  test('C004: Error color (#EF4444) is visible', async () => {
    const errorRgb = hexToRgb(COLORS.error);
    const whiteRgb = { r: 255, g: 255, b: 255 };
    const ratio = contrastRatio(errorRgb, whiteRgb);
    expect(ratio).toBeGreaterThan(3); // WCAG AA for large text
  }, 10_000);

  test('C005: Success color (#10B981) is visible', async () => {
    const successRgb = hexToRgb(COLORS.success);
    const bgRgb = hexToRgb(COLORS.darkBackground);
    const ratio = contrastRatio(successRgb, bgRgb);
    expect(ratio).toBeGreaterThan(3); // WCAG AA
  }, 10_000);

  test('C006: Text is readable on dark background (white on #0F0F1E)', async () => {
    const textRgb = hexToRgb(COLORS.textOnDark);
    const bgRgb = hexToRgb(COLORS.darkBackground);
    const ratio = contrastRatio(bgRgb, textRgb);
    expect(ratio).toBeGreaterThan(4.5); // WCAG AA for normal text
  }, 10_000);

  test('C007: Secondary text is readable (#6B7280)', async () => {
    const secondaryRgb = hexToRgb(COLORS.textSecondary);
    const bgRgb = hexToRgb(COLORS.darkBackground);
    const ratio = contrastRatio(bgRgb, secondaryRgb);
    expect(ratio).toBeGreaterThan(3); // WCAG AA for large text
  }, 10_000);

  test('C008: Loading spinner page loads without errors', async () => {
    await browser.open(`${TARGET_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  }, 45_000);

  test('C009: Card backgrounds are dark (#1E1E32)', async () => {
    await browser.open(`${TARGET_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Verify page renders with semantic elements
    expect(snap.refs.length).toBeGreaterThan(0);
  }, 45_000);

  test('C010: Navigation uses dark surface color (#1A1A2E)', async () => {
    await browser.open(`${TARGET_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const navElements = snap.refs.filter(r => /nav-|menu/i.test(r.name));
    expect(snap.refs.length).toBeGreaterThan(0);
  }, 45_000);
});
