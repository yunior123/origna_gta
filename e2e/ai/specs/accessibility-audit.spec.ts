/**
 * AI Accessibility Audit — Phase 7
 *
 * Analyzes Flutter Web accessibility semantics tree using NVIDIA NIM (GLM-5).
 * Checks for missing labels, ARIA roles, bilingual coverage, and conventions.
 */
import { test, expect, describe, beforeEach, afterEach } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { SCREEN_FLOWS, navigateToScreen } from '../lib/flows.js';
import { AiAnalyzer } from '../lib/analyzer.js';
import { AiReport } from '../lib/reporter.js';
import { AI_CONFIG } from '../config.js';

const report = new AiReport();

describe('AI Accessibility Audit', () => {
  for (const flow of SCREEN_FLOWS) {
    test(`A11Y: ${flow.name} — semantic tree analysis`, async () => {
      const browser = new AgentBrowser();
      try {
        const snapshot = await navigateToScreen(browser, flow);
        expect(snapshot.refs.length).toBeGreaterThan(0);

        const analyzer = new AiAnalyzer();
        const feedback = await analyzer.analyzeAccessibility(flow.name, snapshot);
        report.addResult(feedback);

        console.log(`  [${flow.name}] score=${feedback.score}/10 issues=${feedback.issues.length}`);

        for (const issue of feedback.issues.filter(i => i.severity === 'critical')) {
          console.log(`    ✗ CRITICAL: ${issue.description}`);
        }
        for (const s of feedback.suggestions) {
          console.log(`    💡 ${s}`);
        }

        // Log score but only fail on very low scores (< 3)
        // Many screens have legitimate a11y gaps — we report them without failing
        if (feedback.score < 3) {
          expect(feedback.score).toBeGreaterThanOrEqual(3);
        }
      } finally {
        await browser.close();
      }
    }, 120_000);
  }

  // Final report summary
  test('REPORT: Save accessibility audit report', async () => {
    if (report.count === 0) return;
    const { mdPath } = await report.save('accessibility-audit');
    console.log(`\n♿ Accessibility report saved: ${mdPath}`);
    console.log(`   Avg score: ${report.averageScore.toFixed(1)}/10 | Tokens: ${report.totalTokens}`);
    expect(report.count).toBeGreaterThan(0);
  }, 10_000);
});
