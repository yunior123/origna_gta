/**
 * AI test report generation.
 * Produces Markdown and JSON reports from AI analysis results.
 */
import type { AiFeedback, Issue } from './analyzer.js';
import { AI_CONFIG } from '../config.js';

export class AiReport {
  results: AiFeedback[] = [];
  private startTime = Date.now();

  addResult(feedback: AiFeedback): void {
    this.results.push(feedback);
  }

  get count(): number {
    return this.results.length;
  }

  get totalTokens(): number {
    return this.results.reduce((sum, r) => sum + r.tokensUsed, 0);
  }

  get averageScore(): number {
    if (this.results.length === 0) return 0;
    return this.results.reduce((sum, r) => sum + r.score, 0) / this.results.length;
  }

  get criticalIssues(): Issue[] {
    return this.results.flatMap(r => r.issues.filter(i => i.severity === 'critical'));
  }

  get allIssues(): Issue[] {
    return this.results.flatMap(r => r.issues);
  }

  toMarkdown(): string {
    const elapsed = ((Date.now() - this.startTime) / 1000).toFixed(1);
    const lines: string[] = [
      '# AI E2E Analysis Report',
      '',
      `**Generated**: ${new Date().toISOString()}`,
      `**Duration**: ${elapsed}s`,
      `**Total tokens**: ${this.totalTokens.toLocaleString()}`,
      `**Average score**: ${this.averageScore.toFixed(1)}/10`,
      '',
      '## Summary',
      '',
      '| Screen | Type | Score | Issues |',
      '|--------|------|-------|--------|',
    ];

    for (const r of this.results) {
      const critical = r.issues.filter(i => i.severity === 'critical').length;
      const warnings = r.issues.filter(i => i.severity === 'warning').length;
      const icon = r.score >= 7 ? '✓' : r.score >= 5 ? '⚠' : '✗';
      lines.push(`| ${r.screen} | ${r.type} | ${icon} ${r.score}/10 | ${critical}C ${warnings}W |`);
    }

    lines.push('');

    if (this.criticalIssues.length > 0) {
      lines.push('## Critical Issues');
      lines.push('');
      for (const issue of this.criticalIssues) {
        lines.push(`- **[${issue.category}]** ${issue.description}${issue.element ? ` (${issue.element})` : ''}`);
      }
      lines.push('');
    }

    // Per-screen details
    for (const r of this.results) {
      lines.push(`## ${r.screen} (${r.type})`);
      lines.push('');
      lines.push(`**Score**: ${r.score}/10`);
      lines.push('');

      if (r.issues.length > 0) {
        lines.push('| Severity | Category | Description |');
        lines.push('|----------|----------|-------------|');
        for (const issue of r.issues) {
          lines.push(`| ${issue.severity} | ${issue.category} | ${issue.description} |`);
        }
        lines.push('');
      }

      if (r.suggestions.length > 0) {
        lines.push('**Suggestions:**');
        for (const s of r.suggestions) {
          lines.push(`- ${s}`);
        }
        lines.push('');
      }
    }

    return lines.join('\n');
  }

  toJson(): string {
    return JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        totalTokens: this.totalTokens,
        averageScore: this.averageScore,
        criticalIssues: this.criticalIssues.length,
        results: this.results,
      },
      null,
      2,
    );
  }

  async save(prefix = 'ai-report'): Promise<{ mdPath: string; jsonPath: string }> {
    const dir = AI_CONFIG.reportsDir;
    const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const mdPath = `${dir}/${prefix}-${ts}.md`;
    const jsonPath = `${dir}/${prefix}-${ts}.json`;

    await Bun.write(mdPath, this.toMarkdown());
    await Bun.write(jsonPath, this.toJson());

    return { mdPath, jsonPath };
  }
}
