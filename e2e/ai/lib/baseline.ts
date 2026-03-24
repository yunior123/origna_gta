/**
 * Visual regression baseline management.
 * Stores and retrieves baseline screenshots for comparison.
 */
import { AI_CONFIG } from '../config.js';

const BASELINES_DIR = AI_CONFIG.baselinesDir;

export async function saveBaseline(screenName: string, screenshotPath: string): Promise<string> {
  const destPath = `${BASELINES_DIR}/${screenName}.png`;
  const src = Bun.file(screenshotPath);
  const dest = Bun.file(destPath);
  await Bun.write(dest, await src.arrayBuffer());
  return destPath;
}

export async function loadBaseline(screenName: string): Promise<string | null> {
  const path = `${BASELINES_DIR}/${screenName}.png`;
  const file = Bun.file(path);
  if (await file.exists()) {
    return Buffer.from(await file.arrayBuffer()).toString('base64');
  }
  return null;
}

export async function listBaselines(): Promise<string[]> {
  const { readdirSync, existsSync } = await import('fs');
  if (!existsSync(BASELINES_DIR)) return [];
  return readdirSync(BASELINES_DIR)
    .filter(f => f.endsWith('.png'))
    .map(f => f.replace('.png', ''));
}
