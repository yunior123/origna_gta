import { test } from '@playwright/test';
const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://dev.orignagta.ca';

test.setTimeout(300_000);
test('measure with global setup', async ({ page }) => {
  const t0 = Date.now();
  page.on('console', msg => {
    if (!msg.text().includes('Download the React')) console.log(`APP: ${msg.text()}`);
  });
  
  await page.goto(`${TARGET_URL}/`, { waitUntil: 'domcontentloaded' });
  console.log(`1-domContent: ${Date.now()-t0}ms`);
  
  // Exactly what smoke test does
  const h = await page.waitForFunction(() => !!document.querySelector('flt-glass-pane'), {timeout: 90000});
  console.log(`1-flt-glass-pane: ${Date.now()-t0}ms`);
  
  await page.locator('flt-semantics-placeholder').first().waitFor({state:'attached', timeout: 5000}).catch(() => {});
  const placeholderCount = await page.locator('flt-semantics-placeholder').count();
  console.log(`1-placeholder count: ${placeholderCount} at ${Date.now()-t0}ms`);
  
  const sem1 = await page.locator('flt-semantics').count();
  console.log(`1-flt-semantics count: ${sem1} at ${Date.now()-t0}ms`);
  
  // Navigate to login like ensureLoggedInAsAdmin
  const t1 = Date.now();
  await page.goto(`${TARGET_URL}/login`, { waitUntil: 'domcontentloaded' });
  console.log(`2-domContent: ${Date.now()-t1}ms`);
  
  await page.waitForFunction(() => !!document.querySelector('flt-glass-pane'), {timeout: 90000}).catch(() => {});
  console.log(`2-flt-glass-pane: ${Date.now()-t1}ms`);
  
  await page.locator('flt-semantics-placeholder').first().waitFor({state:'attached', timeout: 5000}).catch(() => {});
  const ph2 = await page.locator('flt-semantics-placeholder').count();
  console.log(`2-placeholder count: ${ph2} at ${Date.now()-t1}ms`);
  
  await page.locator('flt-semantics').first().waitFor({state:'attached', timeout: 30000}).catch(() => {});
  const sem2 = await page.locator('flt-semantics').count();
  console.log(`2-flt-semantics count: ${sem2} at ${Date.now()-t1}ms`);
  
  console.log(`TOTAL: ${Date.now()-t0}ms`);
});
