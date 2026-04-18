#!/usr/bin/env bun

import { readFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser, type CapturePersona } from './agent-browser.js';
import { signIn, setOrignaBaseUserTermsVersion } from './api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from './config.js';

const DEFAULT_OUT_DIR = '/tmp/origna-manifest-audit';
const MANIFEST_FILE = process.env.MANIFEST_FILE || 'audit-manifest.json';
const OUT_DIR = process.env.SCREENSHOT_OUT_DIR || DEFAULT_OUT_DIR;
const currentTermsVersion = '1.0';

interface Step {
  action: 'click' | 'fill' | 'scroll' | 'open' | 'wait';
  target?: string;
  value?: string;
}

interface Scenario {
  id: string;
  persona: CapturePersona | 'guest';
  url: string;
  filename?: string;
  viewport?: { width: number; height: number };
  loginFirst?: boolean;
  requiredKeywordCount?: number;
  steps?: Step[];
  anchors: string[];
}

interface Manifest {
  scenarios: Scenario[];
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function settleRoute(browser: AgentBrowser, delayMs = 3000): Promise<void> {
  await browser.waitForFlutter().catch(() => undefined);
  await browser.enableAccessibilityIfPresent();
  await sleep(delayMs);
}

async function loginForScenario(
  browser: AgentBrowser,
  persona: CapturePersona,
  loginFirst: boolean,
): Promise<void> {
  if (!loginFirst) {
    await browser.goHomeAndLogin(persona);
    return;
  }

  const creds = credentialsForPersona(persona);
  try {
    await setOrignaBaseUserTermsVersion(
      creds.email,
      creds.password,
      currentTermsVersion,
    ).catch(() => undefined);
    const auth = await signIn(creds.email, creds.password);
    await browser.installAuthSession(
      creds.email,
      auth.accessToken ?? auth.idToken,
      auth.refreshToken ?? '',
    );
  } catch {
    await browser.goHomeAndLogin(persona);
  }
}

function credentialsForPersona(persona: CapturePersona): { email: string; password: string } {
  switch (persona) {
    case 'buyer':
      return {
        email: TEST_ACCOUNTS.BUYER_EMAIL,
        password: TEST_ACCOUNTS.BUYER_PASS,
      };
    case 'seller':
      return {
        email: TEST_ACCOUNTS.SELLER_EMAIL,
        password: TEST_ACCOUNTS.SELLER_PASS,
      };
    case 'admin':
    default:
      return {
        email: TEST_ACCOUNTS.ADMIN_EMAIL,
        password: TEST_ACCOUNTS.ADMIN_PASS,
      };
  }
}

async function runScenario(browser: AgentBrowser, scenario: Scenario): Promise<boolean> {
  console.log(`\n--- Running scenario: ${scenario.id} (${scenario.persona}) ---`);

  if (scenario.persona !== 'guest') {
    const persona = scenario.persona as CapturePersona;
    await loginForScenario(browser, persona, scenario.loginFirst !== false);
    if (scenario.url !== '/') {
      await browser.open(`${WEB_APP_URL}${scenario.url}`, 60_000);
      await settleRoute(browser);
    }
  } else {
    await browser.clearState();
    await browser.open(`${WEB_APP_URL}${scenario.url}`, 60_000);
    await settleRoute(browser, 4000);
  }

  if (scenario.steps) {
    for (const step of scenario.steps) {
      if (step.action === 'open' && step.target) {
        console.log(`  -> Opening ${step.target}`);
        await browser.open(step.target.startsWith('http') ? step.target : `${WEB_APP_URL}${step.target}`, 60_000);
        await settleRoute(browser);
        continue;
      }

      if (step.action === 'click' && step.target) {
        console.log(`  -> Clicking ${step.target}`);
        const clicked = await browser.safeClick(new RegExp(step.target, 'i'), 3);
        if (!clicked) {
          console.error(`  -> Failed to click ${step.target}`);
        }
        await sleep(3000);
        continue;
      }

      if (step.action === 'fill' && step.target) {
        console.log(`  -> Filling ${step.target}`);
        const filled = await browser.safeFill(new RegExp(step.target, 'i'), step.value ?? '', 3);
        if (!filled) {
          console.error(`  -> Failed to fill ${step.target}`);
        }
        await sleep(1500);
        continue;
      }

      if (step.action === 'scroll') {
        const direction = step.target === 'up' ? 'up' : 'down';
        await browser.scrollAndWait(direction, Number(step.value ?? 2000)).catch(() => undefined);
        await sleep(1500);
        continue;
      }

      if (step.action === 'wait') {
        await sleep(Number(step.value ?? 3000));
      }
    }
  }

  const filepath = join(OUT_DIR, scenario.filename ?? `${scenario.id}.png`);
  console.log(`  -> Verifying anchors: ${scenario.anchors.join(', ')}`);

  const ok = await browser.screenshotWithVerify({
    filepath,
    expectedKeywords: scenario.anchors,
    viewport: scenario.viewport ?? { width: 1440, height: 900 },
    requiredKeywordCount: scenario.requiredKeywordCount ?? 1,
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
  const manifestRaw = readFileSync(join(__dirname, MANIFEST_FILE), 'utf-8');
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
