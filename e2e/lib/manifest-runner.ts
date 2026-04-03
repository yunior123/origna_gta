#!/usr/bin/env bun

import { readFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser, type CapturePersona } from './agent-browser.js';

const OUT_DIR = '/tmp/origna-manifest-audit';

interface Step {
  action: 'click' | 'fill' | 'scroll';
  target?: string;
  value?: string;
}

interface Scenario {
  id: string;
  persona: CapturePersona | 'guest';
  url: string;
  steps?: Step[];
  anchors: string[];
}

interface Manifest {
  scenarios: Scenario[];
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function runScenario(browser: AgentBrowser, scenario: Scenario): Promise<boolean> {
  console.log(`\n--- Running scenario: ${scenario.id} (${scenario.persona}) ---`);
  
  if (scenario.persona !== 'guest') {
    await browser.goHomeAndLogin(scenario.persona as CapturePersona);
  } else {
    await browser.clearState();
    await browser.open(`https://dev.orignagta.ca${scenario.url}`, 60_000);
    await sleep(4000);
  }

  if (scenario.steps) {
    for (const step of scenario.steps) {
      if (step.action === 'click' && step.target) {
        console.log(`  -> Clicking ${step.target}`);
        const clicked = await browser.safeClick(new RegExp(step.target, 'i'), 3);
        if (!clicked) {
            console.error(`  -> Failed to click ${step.target}`);
        }
        await sleep(3000);
      }
    }
  }

  const filepath = join(OUT_DIR, `${scenario.id}.png`);
  console.log(`  -> Verifying anchors: ${scenario.anchors.join(', ')}`);
  
  const ok = await browser.screenshotWithVerify({
    filepath,
    expectedKeywords: scenario.anchors,
    viewport: { width: 1440, height: 900 },
    requiredKeywordCount: 1,
  });

  if (ok) {
    console.log(`  -> SUCCESS: ${scenario.id}`);
    return true;
  } else {
    console.error(`  -> FAILED: ${scenario.id}`);
    return false;
  }
}

async function main() {
  const manifestRaw = readFileSync(join(__dirname, 'audit-manifest.json'), 'utf-8');
  const manifest: Manifest = JSON.parse(manifestRaw);
  
  mkdirSync(OUT_DIR, { recursive: true });
  
  const browser = new AgentBrowser();
  let passed = 0;
  
  for (const scenario of manifest.scenarios) {
    try {
      const success = await runScenario(browser, scenario);
      if (success) passed++;
    } catch (e) {
      console.error(`Error running scenario ${scenario.id}:`, e);
    }
  }
  
  console.log(`\n=== Audit Complete: ${passed}/${manifest.scenarios.length} passed ===`);
  try {
      await browser.close();
  } catch (e) {}
}

main().catch(console.error);
