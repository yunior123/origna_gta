import { test, expect } from '@playwright/test';

test('debug login: trace each step', async ({ browser }) => {
    test.setTimeout(120000);
    const context = await browser.newContext();
    const page = await context.newPage();
    
    await page.goto('http://127.0.0.1:5005/');
    await page.waitForFunction(() => !!document.querySelector('flt-semantics'), { timeout: 30000 }).catch(() => {});
    const placeholder = page.locator('flt-semantics-placeholder');
    if (await placeholder.count() > 0) { await placeholder.first().click({ force: true }); await page.keyboard.press('Tab'); }
    await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(2000);
    
    await page.getByRole('button', { name: /settings/i }).first().click();
    const signInBtn = page.getByRole('button', { name: /sign\s*in/i }).first();
    await expect(signInBtn).toBeVisible({ timeout: 20000 });
    console.log('Sign-in button visible');
    await signInBtn.click();
    await expect(page).toHaveURL(/\/login/i, { timeout: 20000 });
    console.log('Navigated to /login');
    
    // waitForFlutter like the helper does
    await page.waitForFunction(() => {
        const glasspane = document.querySelector('flt-glass-pane');
        const flutterView = document.querySelector('flutter-view');
        const canvas = document.querySelector('canvas');
        return !!glasspane || !!flutterView || (canvas instanceof HTMLCanvasElement && canvas.getBoundingClientRect().width > 0);
    }, { timeout: 120000 }).catch(() => {});
    
    // Enable a11y
    const enableA11yBtn = page.locator('button:has-text("Enable accessibility")');
    const placeholder2 = page.locator('flt-semantics-placeholder');
    if (await enableA11yBtn.count() > 0) {
        await enableA11yBtn.first().click({ force: true }).catch(() => {});
    } else if (await placeholder2.count() > 0) {
        await placeholder2.first().click({ force: true }).catch(() => {});
        await page.keyboard.press('Tab');
    }
    await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 30000 }).catch(() => {});
    console.log('Flutter initialized on login page');
    
    // Check email label
    const emailLabel = page.locator('flt-semantics').filter({ hasText: 'Email Address' }).first();
    const labelCount = await emailLabel.count();
    console.log('emailLabel count:', labelCount);
    const labelVisible = await emailLabel.isVisible().catch(() => false);
    console.log('emailLabel visible:', labelVisible);
    
    await expect(emailLabel).toBeVisible({ timeout: 30000 });
    
    // Click email label
    await emailLabel.click();
    await page.waitForTimeout(300);
    
    // Check active element after click
    const activeEl = await page.evaluate(() => {
        const el = document.activeElement;
        return el ? { tag: el.tagName, label: el.getAttribute('aria-label'), disabled: (el as HTMLInputElement).disabled } : null;
    });
    console.log('Active element after emailLabel click:', JSON.stringify(activeEl));
    
    // Type email
    await page.keyboard.type('yr62813@gmail.com', { delay: 50 });
    await page.waitForTimeout(300);
    
    // Check input values
    const inputVals = await page.evaluate(() => {
        return Array.from(document.querySelectorAll('input')).map(i => ({
            label: i.getAttribute('aria-label'),
            value: i.value,
            disabled: i.disabled,
        }));
    });
    console.log('Input values after typing email:', JSON.stringify(inputVals));
    
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    
    await page.keyboard.type('REDACTED_TEST_PASSWORD', { delay: 50 });
    await page.waitForTimeout(300);
    
    const inputVals2 = await page.evaluate(() => {
        return Array.from(document.querySelectorAll('input')).map(i => ({
            label: i.getAttribute('aria-label'),
            value: i.value,
            disabled: i.disabled,
        }));
    });
    console.log('Input values after typing password:', JSON.stringify(inputVals2));
    
    // Find and click submit
    const submitBtns = await page.locator('flt-semantics[role="button"]').all();
    console.log('Button count:', submitBtns.length);
    for (const btn of submitBtns.slice(0, 5)) {
        const label = await btn.getAttribute('aria-label');
        const text = (await btn.textContent())?.trim().slice(0, 30);
        console.log('Button:', label, '|', text);
    }
    
    const submitBtn = page.getByRole('button', { name: /sign\s*in/i }).first();
    await submitBtn.click({ force: true });
    console.log('Submit clicked');
    
    await page.waitForTimeout(5000);
    console.log('URL after submit:', page.url());
    
    await context.close();
});
