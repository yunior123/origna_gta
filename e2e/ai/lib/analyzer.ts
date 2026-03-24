/**
 * AI analysis orchestration.
 * Sends screenshots + accessibility snapshots to NVIDIA NIM for structured feedback.
 */
import { NvidiaNimClient, type MODELS } from './nvidia-nim.js';
import { AI_CONFIG } from '../config.js';
import type { Snapshot } from '../../lib/types.js';

export interface Issue {
  severity: 'critical' | 'warning' | 'info';
  category: string;
  description: string;
  element?: string;
  location?: string;
}

export interface AiFeedback {
  screen: string;
  type: 'ui-ux' | 'accessibility' | 'user-flow' | 'visual-regression';
  score: number;
  issues: Issue[];
  suggestions: string[];
  rawModel?: string;
  tokensUsed: number;
}

const UI_UX_CRITERIA = `
1. Layout: Elements properly aligned, no overlap, consistent spacing
2. Spacing: Adequate padding/margins, not cramped, visual breathing room
3. Color: Consistent with dark theme (#0F0F1E bg, #7B93FF primary), good contrast
4. Typography: Readable font sizes, clear hierarchy (headings > body > captions)
5. Visual hierarchy: Important actions prominent, secondary elements subdued
6. Consistency: Buttons, cards, inputs follow same style across screen
7. Responsiveness: Content fits viewport, no horizontal scroll
8. Empty states: Graceful handling of empty lists, no broken layouts
`.trim();

const A11Y_CRITERIA = `
1. All interactive elements (buttons, inputs, links) have semantic labels (btn-*, input-*)
2. ARIA roles are correct (button, link, textbox, etc.)
3. Bilingual labels present where needed (EN/FR)
4. No duplicate or ambiguous labels
5. Navigation elements properly labeled (nav-*)
6. Product cards use product-card-<id> convention
7. Form inputs have associated labels
8. Images have alt text or decorative marking
`.trim();

const FLOW_CRITERIA = `
1. Navigation: Clear path between screens, obvious back/forward
2. Feedback: Loading states, success/error messages visible
3. Friction: Minimum steps to complete tasks
4. Discoverability: Key features findable without training
5. Error recovery: Clear error messages with fix suggestions
6. Consistency: Same patterns across different flows
7. Mobile readiness: Touch-friendly targets, scroll behavior
`.trim();

export class AiAnalyzer {
  private client: NvidiaNimClient;

  constructor(client?: NvidiaNimClient) {
    this.client = client ?? new NvidiaNimClient();
  }

  async analyzeUiUx(screenName: string, imageBase64: string): Promise<AiFeedback> {
    const resp = await this.client.analyzeScreenshot(
      imageBase64,
      screenName,
      UI_UX_CRITERIA,
      { model: AI_CONFIG.visionModel, timeout: AI_CONFIG.aiCallTimeout },
    );
    return this.parseFeedback(resp.content, screenName, 'ui-ux', resp.usage.totalTokens);
  }

  async analyzeAccessibility(screenName: string, snapshot: Snapshot): Promise<AiFeedback> {
    const treeText = snapshot.refs
      .map(r => `@${r.ref} [${r.role}] "${r.name}"${r.text ? ` text="${r.text}"` : ''}`)
      .join('\n');

    const resp = await this.client.analyzeAccessibilityTree(
      treeText,
      A11Y_CRITERIA,
      { model: AI_CONFIG.textModel, timeout: AI_CONFIG.aiCallTimeout },
    );
    return this.parseFeedback(resp.content, screenName, 'accessibility', resp.usage.totalTokens);
  }

  async analyzeUserFlow(
    screenName: string,
    imageBase64: string,
    snapshot: Snapshot,
    steps: string[],
  ): Promise<AiFeedback> {
    const treeText = snapshot.refs
      .map(r => `@${r.ref} [${r.role}] "${r.name}"`)
      .join('\n');

    const prompt = `You are a UX expert analyzing a user flow through an e-commerce app.
The user performed these steps:
${steps.map((s, i) => `${i + 1}. ${s}`).join('\n')}

Current screen: "${screenName}"
Accessibility tree:\n${treeText}

Analyze this flow against:
${FLOW_CRITERIA}

Response format (JSON only):
{
  "score": <0-10>,
  "issues": [{"severity": "critical|warning|info", "category": "string", "description": "string"}],
  "suggestions": ["string"]
}`;

    const resp = await this.client.chatWithImage(imageBase64, prompt, {
      model: AI_CONFIG.visionModel,
      timeout: AI_CONFIG.aiCallTimeout,
    });
    return this.parseFeedback(resp.content, screenName, 'user-flow', resp.usage.totalTokens);
  }

  async compareVisualRegression(
    screenName: string,
    currentBase64: string,
    baselineBase64: string,
  ): Promise<AiFeedback> {
    const prompt = `You are a visual regression testing expert.
Compare these two screenshots of the "${screenName}" screen and identify any significant visual differences.
The first image is the BASELINE, the second is the CURRENT version.

Look for:
- Layout shifts or element repositioning
- Color changes
- Missing or added elements
- Font/typography changes
- Broken styling or alignment

Ignore:
- Minor anti-aliasing differences
- Slight color variations (<5% difference)
- Content changes (different product names, etc.)

Response format (JSON only):
{
  "score": <0-10 (10=no changes, 0=completely broken)>,
  "issues": [{"severity": "critical|warning|info", "category": "layout|color|missing|typography", "description": "string"}],
  "suggestions": ["string"]
}`;

    // Send both images in a single message
    const messages = [
      {
        role: 'user' as const,
        content: [
          { type: 'text' as const, text: prompt },
          { type: 'text' as const, text: 'BASELINE:' },
          {
            type: 'image_url' as const,
            image_url: { url: `data:image/png;base64,${baselineBase64}` },
          },
          { type: 'text' as const, text: 'CURRENT:' },
          {
            type: 'image_url' as const,
            image_url: { url: `data:image/png;base64,${currentBase64}` },
          },
        ],
      },
    ];

    const resp = await this.client.chat(messages, {
      model: AI_CONFIG.visionModel,
      timeout: AI_CONFIG.aiCallTimeout,
    });
    return this.parseFeedback(resp.content, screenName, 'visual-regression', resp.usage.totalTokens);
  }

  private parseFeedback(
    raw: string,
    screen: string,
    type: AiFeedback['type'],
    tokensUsed: number,
  ): AiFeedback {
    try {
      const parsed = this.client.parseJsonResponse<{ score: number; issues?: Issue[]; suggestions?: string[] }>({ content: raw, model: '', usage: { promptTokens: 0, completionTokens: 0, totalTokens: 0 } });
      return {
        screen,
        type,
        score: Math.max(0, Math.min(10, parsed.score ?? 0)),
        issues: (parsed.issues ?? []).map(i => ({
          severity: i.severity ?? 'info',
          category: i.category ?? 'unknown',
          description: i.description ?? '',
          element: i.element,
          location: i.location,
        })),
        suggestions: parsed.suggestions ?? [],
        rawModel: raw,
        tokensUsed,
      };
    } catch {
      // JSON parsing failed — return raw as suggestion
      return {
        screen,
        type,
        score: 0,
        issues: [{ severity: 'warning', category: 'parse', description: 'AI response was not valid JSON' }],
        suggestions: [raw.slice(0, 500)],
        rawModel: raw,
        tokensUsed,
      };
    }
  }
}
