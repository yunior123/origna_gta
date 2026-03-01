import { test, expect } from '@playwright/test';
import { waitForFlutter, requireWebApp } from './flutter-helpers';
import { WEB_APP_URL } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;

test('Inspect DOM for semantics elements', async ({ page }) => {
  test.setTimeout(300_000);
  await requireWebApp(page, TARGET_URL);
  page.setDefaultTimeout(180_000);

  // Capture console errors with FULL stack traces
  const consoleErrors: string[] = [];
  const consoleLogs: string[] = [];
  page.on('console', msg => {
    const text = msg.text();
    if (msg.type() === 'error') consoleErrors.push(text);
    else consoleLogs.push(text);
  });
  page.on('pageerror', err => {
    consoleErrors.push(`PAGE ERROR: ${err.message}\nSTACK: ${err.stack}`);
  });

  await page.goto(`${TARGET_URL}/`);

  // Wait 60s then check intermediate state
  console.log('Waiting 60s for Flutter...');
  await page.waitForTimeout(60000);
  const midState = await page.evaluate(() => ({
    glasspane: !!document.querySelector('flt-glass-pane'),
    flutterView: !!document.querySelector('flutter-view'),
    canvas: !!document.querySelector('canvas'),
    bodyChildren: Array.from(document.body.children).map(c => c.tagName.toLowerCase()),
  }));
  console.log('60s state:', JSON.stringify(midState));

  await waitForFlutter(page);

  // Print console errors
  if (consoleErrors.length > 0) {
    console.log('\n--- Console Errors ---');
    for (const e of consoleErrors.slice(0, 20)) console.log('  ERROR:', e);
  }
  if (consoleLogs.length > 0) {
    console.log('\n--- Console Logs (last 20) ---');
    for (const l of consoleLogs.slice(-20)) console.log('  LOG:', l);
  }

  // Check top-level DOM
  const topLevelInfo = await page.evaluate(() => {
    const result: Record<string, unknown> = {};
    const fltTags = new Set<string>();
    document.querySelectorAll('*').forEach(el => {
      const tag = el.tagName.toLowerCase();
      if (tag.startsWith('flt-') || tag.startsWith('flutter-')) fltTags.add(tag);
    });
    result.topLevelFltTags = Array.from(fltTags).sort();
    result.fltSemanticsCount = document.querySelectorAll('flt-semantics').length;
    result.ariaLabelCount = document.querySelectorAll('[aria-label]').length;

    // Check ALL shadow roots recursively
    const shadowInfo: string[] = [];
    function walkShadow(root: Element | ShadowRoot, depth: number, path: string) {
      const children = root instanceof ShadowRoot ? root.children : root.shadowRoot?.children;
      if (!children) return;
      for (const child of children) {
        const tag = child.tagName.toLowerCase();
        if (tag.startsWith('flt-') || tag.startsWith('flutter-') || child.hasAttribute('role') || child.hasAttribute('aria-label')) {
          const role = child.getAttribute('role') || '';
          const label = child.getAttribute('aria-label') || '';
          shadowInfo.push(`${'  '.repeat(depth)}${path}>${tag} role=${role} label=${label}`);
        }
        if (child.shadowRoot) {
          shadowInfo.push(`${'  '.repeat(depth)}${path}>${tag} [HAS SHADOW ROOT]`);
          walkShadow(child.shadowRoot, depth + 1, `${path}>${tag}>shadow`);
        }
        // Also walk regular children
        walkShadow(child, depth + 1, `${path}>${tag}`);
      }
    }
    document.querySelectorAll('*').forEach(el => {
      if (el.shadowRoot) {
        shadowInfo.push(`${el.tagName.toLowerCase()} [HAS SHADOW ROOT]`);
        walkShadow(el.shadowRoot, 1, el.tagName.toLowerCase() + '>shadow');
      }
    });
    result.shadowInfo = shadowInfo.slice(0, 50);
    return result;
  });

  console.log('Top-level flt tags:', JSON.stringify(topLevelInfo.topLevelFltTags));
  console.log('flt-semantics count:', topLevelInfo.fltSemanticsCount);
  console.log('aria-label count:', topLevelInfo.ariaLabelCount);
  console.log('Shadow DOM info:');
  for (const line of (topLevelInfo.shadowInfo as string[])) {
    console.log('  ', line);
  }

  // Also try Playwright's pierce locator
  const pierceCount = await page.locator('flt-semantics').count();
  console.log('Playwright flt-semantics count:', pierceCount);

  // Try evaluating inside each shadow root for semantics
  const deepSemanticsInfo = await page.evaluate(() => {
    const result: string[] = [];
    function findInShadow(root: Element | ShadowRoot, path: string): number {
      let count = 0;
      const children = root instanceof ShadowRoot ? Array.from(root.querySelectorAll('*')) : (root.shadowRoot ? Array.from(root.shadowRoot.querySelectorAll('*')) : []);
      for (const child of children) {
        const tag = child.tagName.toLowerCase();
        if (tag === 'flt-semantics' || tag.includes('semantic')) {
          count++;
          result.push(`${path} > ${tag} role=${child.getAttribute('role')} label=${child.getAttribute('aria-label')}`);
        }
        if (child.shadowRoot) {
          count += findInShadow(child.shadowRoot, `${path}>${tag}>shadow`);
        }
      }
      return count;
    }

    let total = 0;
    document.querySelectorAll('*').forEach(el => {
      if (el.shadowRoot) {
        total += findInShadow(el.shadowRoot, el.tagName.toLowerCase() + '>shadow');
      }
    });
    return { total, locations: result.slice(0, 30) };
  });

  console.log('\nDeep semantics search:', deepSemanticsInfo.total, 'elements found');
  for (const loc of deepSemanticsInfo.locations) {
    console.log('  ', loc);
  }

  // Check what the Flutter view looks like
  const flutterViewInfo = await page.evaluate(() => {
    const fv = document.querySelector('flutter-view');
    const gp = document.querySelector('flt-glass-pane');
    return {
      hasFlutterView: !!fv,
      hasGlassPane: !!gp,
      flutterViewShadow: fv?.shadowRoot ? 'yes' : 'no',
      glassPaneShadow: gp?.shadowRoot ? 'yes' : 'no',
      flutterViewChildren: fv ? Array.from(fv.children).map(c => c.tagName.toLowerCase()).join(', ') : 'N/A',
      glassPaneChildren: gp ? Array.from(gp.children).map(c => c.tagName.toLowerCase()).join(', ') : 'N/A',
    };
  });
  console.log('\nFlutter view info:', JSON.stringify(flutterViewInfo, null, 2));
});
