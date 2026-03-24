/**
 * AI UI/UX Visual Review — Phase 7
 *
 * Takes screenshots of each screen and sends to NVIDIA NIM (Llama 3.2 90B Vision)
 * for visual quality analysis: layout, spacing, color, typography, hierarchy.
 */
import { test, expect, describe } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { SCREEN_FLOWS, navigateToScreen, captureScreenshot } from '../lib/flows.js';
import { AiAnalyzer } from '../lib/analyzer.js';
import { AiReport } from '../lib/reporter.js';
import { AI_CONFIG } from '../config.js';

const report = new AiReport();

describe('AI UI/UX Visual Review', () => {
  for (const flow of SCREEN_FLOWS) {
    test(`UI/UX: ${flow.name} — visual quality analysis`, async () => {
      const browser = new AgentBrowser();
      try {
        await navigateToScreen(browser, flow);
        await new Promise(r => setTimeout(r, 1_000));

        const screenshotBase64 = await captureScreenshot(browser, flow.name);
        const analyzer = new AiAnalyzer();
        const feedback = await analyzer.analyzeUiUx(flow.name, screenshotBase64);
        report.addResult(feedback);

        console.log(`  [${flow.name}] score=${feedback.score}/10 issues=${feedback.issues.length}`);
        for (const issue of feedback.issues) {
          const icon = issue.severity === 'critical' ? '✗' : issue.severity === 'warning' ? '⚠' : 'ℹ';
          console.log(`    ${icon} [${issue.category}] ${issue.description}`);
        }

        // Log but don't fail on low UI scores — many are informational
        if (feedback.score < 3) {
          expect(feedback.score).toBeGreaterThanOrEqual(3);
        }
      } finally {
        await browser.close();
      }
    }, 120_000);
  }

  test('REPORT: Save UI/UX review report', async () => {
    if (report.count === 0) return;
    const { mdPath } = await report.save('ui-ux-review');
    console.log(`\n🎨 UI/UX report saved: ${mdPath}`);
    console.log(`   Avg score: ${report.averageScore.toFixed(1)}/10 | Tokens: ${report.totalTokens}`);
    if (report.criticalIssues.length > 0) {
      console.log(`   ⚠ ${report.criticalIssues.length} critical issues found`);
    }
    expect(report.count).toBeGreaterThan(0);
  }, 10_000);
});
