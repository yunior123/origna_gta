/**
 * NVIDIA NIM OpenAI-compatible client.
 *
 * Uses free endpoints at https://integrate.api.nvidia.com/v1
 * Supports text-only and multimodal (vision) completions.
 */
import { getNvidiaApiKey } from './keychain.js';

const NIM_BASE_URL = 'https://integrate.api.nvidia.com/v1';

export const MODELS = {
  // Text reasoning — preferred order (all verified working)
  GLM5: 'z-ai/glm5',                          // 744B MoE, Feb 2026 — primary
  MINIMAX_M25: 'minimaxai/minimax-m2.5',       // 230B, Mar 2026 — alt
  KIMI_K25: 'moonshotai/kimi-k2.5',            // Mar 2026 — thinking model, needs high maxTokens
  QWEN35: 'qwen/qwen3.5-122b-a10b',           // Mar 2026 — recent alt
  MISTRAL_SMALL4: 'mistralai/mistral-small-4-119b-2603', // Mar 2026 — recent alt
  // Vision — best free multimodal
  VISION: 'moonshotai/kimi-k2.5',              // Kimi K2.5 — multimodal, best JSON compliance
  LLAMA_VISION_90B: 'meta/llama-3.2-90b-vision-instruct', // fallback vision
  LLAMA_VISION_11B: 'meta/llama-3.2-11b-vision-instruct', // lighter fallback
  // Aliases
  TEXT_REASONING: 'z-ai/glm5',
  TEXT_ALT: 'minimaxai/minimax-m2.5',
  VISION_ALT: 'meta/llama-3.2-90b-vision-instruct',
} as const;

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string | ContentPart[];
}

interface ContentPart {
  type: 'text' | 'image_url';
  text?: string;
  image_url?: { url: string };
}

interface ChatOptions {
  model?: string;
  temperature?: number;
  maxTokens?: number;
  timeout?: number;
}

interface ChatResponse {
  content: string;
  model: string;
  usage: { promptTokens: number; completionTokens: number; totalTokens: number };
}

export class NvidiaNimClient {
  private apiKey: string;
  private baseUrl: string;

  constructor(opts?: { apiKey?: string; baseUrl?: string }) {
    this.apiKey = opts?.apiKey ?? getNvidiaApiKey();
    this.baseUrl = opts?.baseUrl ?? NIM_BASE_URL;
  }

  async chat(messages: ChatMessage[], opts?: ChatOptions): Promise<ChatResponse> {
    const model = opts?.model ?? MODELS.TEXT_REASONING;
    const timeout = opts?.timeout ?? 90_000;

    const body = {
      model,
      messages,
      temperature: opts?.temperature ?? 0.3,
      max_tokens: opts?.maxTokens ?? 4096,
      stream: false,
    };

    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeout),
    });

    if (!response.ok) {
      const errText = await response.text().catch(() => '');
      throw new Error(`NIM API error ${response.status}: ${errText.slice(0, 300)}`);
    }

    const data = await response.json() as any;
    const choice = data.choices?.[0];
    if (!choice?.message) {
      throw new Error(`NIM API returned no message: ${JSON.stringify(data).slice(0, 200)}`);
    }

    // Thinking models (Kimi K2.5, etc.) may put content in reasoning_content
    // or return null content when max_tokens is too low
    let content = choice.message.content;
    if (!content && choice.message.reasoning_content) {
      content = choice.message.reasoning_content;
    }
    if (!content) {
      throw new Error(
        `NIM API returned empty content (model=${model}, finish=${choice.finish_reason}). ` +
        `Try increasing maxTokens. Response: ${JSON.stringify(data).slice(0, 200)}`,
      );
    }

    return {
      content,
      model: data.model ?? model,
      usage: {
        promptTokens: data.usage?.prompt_tokens ?? 0,
        completionTokens: data.usage?.completion_tokens ?? 0,
        totalTokens: data.usage?.total_tokens ?? 0,
      },
    };
  }

  async chatWithImage(
    imageBase64: string,
    prompt: string,
    opts?: ChatOptions,
  ): Promise<ChatResponse> {
    const model = opts?.model ?? MODELS.VISION;

    const messages: ChatMessage[] = [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          {
            type: 'image_url',
            image_url: { url: `data:image/png;base64,${imageBase64}` },
          },
        ],
      },
    ];

    return this.chat(messages, { ...opts, model });
  }

  async analyzeAccessibilityTree(
    treeText: string,
    criteria: string,
    opts?: ChatOptions,
  ): Promise<ChatResponse> {
    const systemPrompt = `You are an accessibility and UX expert analyzing a Flutter Web application's accessibility semantics tree.
The tree is produced by agent-browser snapshot and uses ref-based element identification.
Analyze the tree against the given criteria and return a JSON response.

Response format (JSON only, no markdown):
{
  "score": <0-10>,
  "issues": [
    {
      "severity": "critical|warning|info",
      "category": "string",
      "description": "string",
      "element": "string (ref or label, optional)"
    }
  ],
  "suggestions": ["string"]
}`;

    return this.chat(
      [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `## Criteria\n${criteria}\n\n## Accessibility Tree\n${treeText}` },
      ],
      { ...opts, model: opts?.model ?? MODELS.TEXT_REASONING },
    );
  }

  async analyzeScreenshot(
    imageBase64: string,
    screenName: string,
    criteria: string,
    opts?: ChatOptions,
  ): Promise<ChatResponse> {
    const prompt = `Analyze this UI screenshot of the "${screenName}" screen.

App: Flutter Web e-commerce, dark theme (#0F0F1E bg, #7B93FF primary).
Criteria to check: ${criteria}

IMPORTANT: Respond with ONLY a JSON object. No explanation, no markdown, no code blocks.

{"score":7,"issues":[{"severity":"warning","category":"layout","description":"example issue","location":"top"}],"suggestions":["example suggestion"]}`;

    return this.chatWithImage(imageBase64, prompt, { ...opts, model: opts?.model ?? MODELS.VISION });
  }

  parseJsonResponse<T = any>(response: ChatResponse): T {
    let text = response.content.trim();
    // Strip markdown code blocks if present
    if (text.startsWith('```')) {
      text = text.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    }
    // Try to find a complete JSON object
    const jsonMatch = text.match(/\{[\s\S]*?\}/);
    if (!jsonMatch) {
      throw new Error(`No JSON found in AI response: ${text.slice(0, 300)}`);
    }
    // Clean common JSON issues from LLM output
    let jsonStr = jsonMatch[0]
      .replace(/,\s*}/g, '}')     // trailing commas
      .replace(/,\s*]/g, ']')     // trailing commas in arrays
      .replace(/\n/g, ' ');       // newlines that may break JSON
    try {
      return JSON.parse(jsonStr);
    } catch (e) {
      // Last resort: try to extract score from text
      const scoreMatch = text.match(/"score"\s*:\s*(\d+)/);
      if (scoreMatch) {
        return { score: parseInt(scoreMatch[1]), issues: [], suggestions: [] } as T;
      }
      throw new Error(`Failed to parse JSON: ${(e as Error).message}. Raw: ${text.slice(0, 300)}`);
    }
  }
}
