import { test } from '@playwright/test';
import { waitForFlutter, requireWebApp, checkSemantics, ensureLoggedInAsAdmin } from './flutter-helpers';
import { TEST_ACCOUNTS, WEB_APP_URL } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const BTN_SETTINGS_LABEL = 'btn-home-settings';

test('Debug: Inspect profile page semantics', async ({ page }) => {
  test.setTimeout(300_000);
  await requireWebApp(page, TARGET_URL);
  page.setDefaultTimeout(60_000);
  await page.goto(`${TARGET_URL}/`);
  await waitForFlutter(page);
  await checkSemantics(page);

  // Log home page semantics
  const homeSemsCount = await page.locator('flt-semantics').count();
  console.log(`\n=== HOME PAGE: ${homeSemsCount} flt-semantics elements ===`);
  const homeLabels = await page.evaluate(() => {
    const els = document.querySelectorAll('[aria-label]');
    return Array.from(els).slice(0, 30).map(el => ({
      tag: el.tagName.toLowerCase(),
      role: el.getAttribute('role'),
      label: el.getAttribute('aria-label'),
    }));
  });
  for (const el of homeLabels) {
    console.log(`  <${el.tag}> role="${el.role}" aria-label="${el.label}"`);
  }

  // Login
  await ensureLoggedInAsAdmin(page, TARGET_URL, TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
  console.log('\n=== LOGGED IN — navigating to profile ===');

  // Click settings to go to profile
  const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
  await settingsBtn.click();
  await page.waitForTimeout(5000);
  await waitForFlutter(page);

  console.log(`Profile URL: ${page.url()}`);

  // Dump ALL flt-semantics elements on profile page
  const profileSemsCount = await page.locator('flt-semantics').count();
  console.log(`\n=== PROFILE PAGE: ${profileSemsCount} flt-semantics elements ===`);

  // Check ALL elements with aria-label (including inside shadow DOM)
  const profileLabels = await page.evaluate(() => {
    const result: string[] = [];

    // Regular DOM
    document.querySelectorAll('[aria-label]').forEach(el => {
      result.push(`DOM: <${el.tagName.toLowerCase()}> role="${el.getAttribute('role')}" label="${el.getAttribute('aria-label')}"`);
    });

    // Shadow DOM traversal
    function walkShadow(root: Element | ShadowRoot, path: string) {
      const children = root instanceof ShadowRoot ? root.children : (root.shadowRoot?.children ?? []);
      for (const child of children) {
        const tag = child.tagName.toLowerCase();
        const label = child.getAttribute('aria-label');
        const role = child.getAttribute('role');
        if (label || role) {
          result.push(`SHADOW(${path}): <${tag}> role="${role}" label="${label}"`);
        }
        if (child.shadowRoot) {
          walkShadow(child.shadowRoot, `${path}>${tag}>shadow`);
        }
        walkShadow(child, `${path}>${tag}`);
      }
    }
    document.querySelectorAll('*').forEach(el => {
      if (el.shadowRoot) {
        walkShadow(el.shadowRoot, el.tagName.toLowerCase() + '>shadow');
      }
    });

    return result;
  });

  for (const line of profileLabels.slice(0, 80)) {
    console.log(`  ${line}`);
  }
  console.log(`  ... total: ${profileLabels.length} elements with aria-label/role`);

  // Specifically check for menu-* patterns
  const menuElements = profileLabels.filter(l => l.includes('menu-'));
  console.log(`\n=== MENU ELEMENTS: ${menuElements.length} ===`);
  for (const m of menuElements) {
    console.log(`  ${m}`);
  }

  // Check Playwright locator counts
  console.log('\n=== PLAYWRIGHT LOCATOR COUNTS ===');
  console.log('  [aria-label^="menu-"]:', await page.locator('[aria-label^="menu-"]').count());
  console.log('  [aria-label^="menu-my-orders"]:', await page.locator('[aria-label^="menu-my-orders"]').count());
  console.log('  role=button:', await page.getByRole('button').count());
  console.log('  flt-semantics:', await page.locator('flt-semantics').count());
  console.log('  flt-semantics[role="button"]:', await page.locator('flt-semantics[role="button"]').count());

  // Also dump all button roles to see what's accessible
  const buttons = await page.getByRole('button').all();
  console.log(`\n=== ALL BUTTONS (${buttons.length}) ===`);
  for (let i = 0; i < Math.min(buttons.length, 30); i++) {
    const name = await buttons[i].getAttribute('aria-label').catch(() => '(no label)');
    const html = await buttons[i].evaluate(el => el.outerHTML.slice(0, 300)).catch(() => '(error)');
    console.log(`  button[${i}]: aria-label="${name}" → ${html}`);
  }

  // Dump ALL flt-semantics with any attributes
  const allSems = await page.evaluate(() => {
    const result: string[] = [];
    document.querySelectorAll('flt-semantics').forEach(el => {
      const attrs: string[] = [];
      for (const attr of (el as any).attributes) {
        attrs.push(`${attr.name}="${attr.value}"`);
      }
      result.push(`<flt-semantics ${attrs.join(' ')}>`);
    });
    return result;
  });
  console.log(`\n=== ALL FLT-SEMANTICS FULL ATTRIBUTES (${allSems.length}) ===`);
  for (const s of allSems) {
    console.log(`  ${s}`);
  }
});
