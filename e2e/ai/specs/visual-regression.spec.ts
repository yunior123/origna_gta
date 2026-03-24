/**
 * AI Visual Regression — Phase 7
 *
 * Compares current screenshots against saved baselines using AI analysis.
 * First run saves baselines. Subsequent runs detect visual regressions.
 *
 * Update baselines: UPDATE_BASELINES=true bun test ai/specs/visual-regression.spec.ts
 */
import { test, expect, describe } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { SCREEN_FLOWS, navigateToScreen } from '../lib/flows.js';
import { AiAnalyzer } from '../lib/analyzer.js';
import { AiReport } from '../lib/reporter.js';
import { saveBaseline, loadBaseline } from '../lib/baseline.js';
import { AI_CONFIG } from '../config.js';

const UPDATE_BASELINES = process.env.UPDATE_BASELINES === 'true';
const report = new AiReport();

if (UPDATE_BASELINES) console.log('\n📸 UPDATE_BASELINES=true — saving new baselines\n');

describe('AI Visual Regression', () => {
  for (const flow of SCREEN_FLOWS) {
    test(`Regression: ${flow.name}`, async () => {
      const browser = new AgentBrowser();
      try {
        await navigateToScreen(browser, flow);
        await new Promise(r => setTimeout(r, 1_000));

        const screenshotPath = `/tmp/ai-regression-${flow.name}-${Date.now()}.png`;
        await browser.screenshot(screenshotPath);
        const currentBase64 = await Bun.file(screenshotPath).arrayBuffer()
          .then(buf => Buffer.from(buf).toString('base64'));

        if (UPDATE_BASELINES) {
          await saveBaseline(flow.name, screenshotPath);
          console.log(`  📸 Saved baseline: ${flow.name}`);
          return;
        }

        const baselineBase64 = await loadBaseline(flow.name);
        if (!baselineBase64) {
          console.log(`  ⚠ No baseline for ${flow.name} — run with UPDATE_BASELINES=true first`);
          await saveBaseline(flow.name, screenshotPath);
          return;
        }

        const analyzer = new AiAnalyzer();
        const feedback = await analyzer.compareVisualRegression(flow.name, currentBase64, baselineBase64);
        report.addResult(feedback);

        console.log(`  [${flow.name}] regression score=${feedback.score}/10`);
        for (const issue of feedback.issues) {
          const icon = issue.severity === 'critical' ? '✗' : '⚠';
          console.log(`    ${icon} [${issue.category}] ${issue.description}`);
        }

        if (feedback.score < 5) {
          expect(feedback.score).toBeGreaterThanOrEqual(5);
        }
      } finally {
        await browser.close();
      }
    }, 120_000);
  }

  test('REPORT: Save visual regression report', async () => {
    if (!UPDATE_BASELINES && report.count > 0) {
      const { mdPath } = await report.save('visual-regression');
      console.log(`\n📊 Visual regression report saved: ${mdPath}`);
      console.log(`   Avg score: ${report.averageScore.toFixed(1)}/10 | Tokens: ${report.totalTokens}`);
    }
    expect(true).toBe(true);
  }, 10_000);
});
