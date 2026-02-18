import { test } from '@playwright/test';
import { waitForFlutter } from './flutter-helpers';

test('inspect DOM structure', async ({ page }) => {
  test.setTimeout(120_000);

  // Disable caching to ensure fresh build is loaded
  await page.route('**/*', (route) => {
    route.continue({ headers: { ...route.request().headers(), 'Cache-Control': 'no-cache' } });
  });

  // Unregister service workers to avoid stale cache
  await page.goto('http://localhost:5005');
  await page.evaluate(async () => {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      for (const reg of registrations) await reg.unregister();
    }
    // Clear all caches
    if ('caches' in window) {
      const names = await caches.keys();
      for (const name of names) await caches.delete(name);
    }
  });

  // Reload fresh
  await page.reload({ waitUntil: 'networkidle' });

  // Use the project's waitForFlutter which handles canvas + semantics
  await waitForFlutter(page, 90_000);

  // Activate semantics: try multiple methods
  // Method 1: Force-click placeholder
  const placeholder = page.locator('flt-semantics-placeholder');
  const placeholderCount = await placeholder.count();
  console.log('Placeholder count before activation:', placeholderCount);
  if (placeholderCount > 0) {
    await placeholder.first().click({ force: true }).catch(() => {});
    await page.waitForTimeout(2000);
  }
  // Method 2: Dispatch click event directly via JS
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) {
      ph.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      ph.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      ph.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
    }
  });
  await page.waitForTimeout(2000);
  // Method 3: Focus the page and press Tab (Flutter intercepts this)
  await page.keyboard.press('Tab');
  await page.waitForTimeout(2000);
  // Method 4: Click the body to focus, then Tab
  await page.click('body', { force: true }).catch(() => {});
  await page.keyboard.press('Tab');
  await page.waitForTimeout(3000);
  console.log('Completed all semantics activation methods');

  const domInfo = await page.evaluate(() => {
    // Deep-dive: look inside glass-pane shadow DOM for semantic elements
    const gp = document.querySelector('flt-glass-pane');
    let gpShadow: any = 'no shadow';
    if (gp && (gp as any).shadowRoot) {
      const sr = (gp as any).shadowRoot;
      const allEls = sr.querySelectorAll('*');
      const tags: string[] = [];
      const ariaEls: string[] = [];
      allEls.forEach((el: Element) => {
        const t = el.tagName.toLowerCase();
        if (!tags.includes(t)) tags.push(t);
        const r = el.getAttribute('role');
        const l = el.getAttribute('aria-label');
        if (r || l) ariaEls.push(t + ' role=' + r + ' label=' + l);
        // Check nested shadow roots
        if ((el as any).shadowRoot) {
          const nsr = (el as any).shadowRoot;
          const nels = nsr.querySelectorAll('*');
          nels.forEach((nel: Element) => {
            const nt = nel.tagName.toLowerCase();
            if (!tags.includes('N:' + nt)) tags.push('N:' + nt);
            const nr = nel.getAttribute('role');
            const nl = nel.getAttribute('aria-label');
            if (nr || nl) ariaEls.push('N:' + nt + ' role=' + nr + ' label=' + nl);
          });
        }
      });
      gpShadow = { count: allEls.length, tags, aria: ariaEls.slice(0, 50) };
    }

    // Check flt-semantics-host
    const semHost = document.querySelector('flt-semantics-host');
    const semInfo = semHost ? {
      children: semHost.childElementCount,
      display: getComputedStyle(semHost).display,
      position: getComputedStyle(semHost).position,
      rect: semHost.getBoundingClientRect(),
    } : 'not found';

    // Check getByRole accessibility — what does the browser think is accessible?
    const allRoles = document.querySelectorAll('[role]');
    const roleList: string[] = [];
    allRoles.forEach(el => {
      roleList.push(el.tagName.toLowerCase() + '=' + el.getAttribute('role') + ':' + el.getAttribute('aria-label'));
    });

    // Check flutter-view details
    const fv = document.querySelector('flutter-view');
    const fvInfo = fv ? {
      role: fv.getAttribute('role'),
      ariaLabel: fv.getAttribute('aria-label'),
      children: fv.childElementCount,
      childTags: Array.from(fv.children).map(c => c.tagName.toLowerCase()),
    } : 'not found';

    return { gpShadow, semInfo, roleList, fvInfo };
  });

  console.log('DOM_INFO_START');
  console.log(JSON.stringify(domInfo, null, 2));
  console.log('DOM_INFO_END');
});
