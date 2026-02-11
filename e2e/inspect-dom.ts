import { chromium } from '@playwright/test';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:5005/#/login', { waitUntil: 'networkidle', timeout: 60000 });

  console.log('Waiting for Flutter host element...');
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  console.log('Host found. Waiting for canvas...');
  await page.waitForSelector('canvas', { timeout: 60000 });
  console.log('Canvas found. Waiting 20s for semantics...');
  await page.waitForTimeout(20000);

  const info = await page.evaluate(() => {
    const lines: string[] = [];
    const sems = document.querySelectorAll('flt-semantics');
    lines.push('flt-semantics count: ' + sems.length);

    const inputs = document.querySelectorAll('input');
    lines.push('input count: ' + inputs.length);
    inputs.forEach((inp, i) => {
      lines.push('  input[' + i + ']: type=' + inp.type + ' role=' + inp.getAttribute('role') + ' aria-label=' + inp.getAttribute('aria-label') + ' parent=' + (inp.parentElement?.tagName || ''));
    });

    const tas = document.querySelectorAll('textarea');
    lines.push('textarea count: ' + tas.length);

    const edits = document.querySelectorAll('[contenteditable]');
    lines.push('contenteditable count: ' + edits.length);

    const tbx = document.querySelectorAll('[role="textbox"]');
    lines.push('role=textbox count: ' + tbx.length);
    tbx.forEach((t, i) => {
      lines.push('  tb[' + i + ']: tag=' + t.tagName + ' label=' + t.getAttribute('aria-label'));
    });

    const cbx = document.querySelectorAll('[role="combobox"]');
    lines.push('role=combobox count: ' + cbx.length);

    const labeled = document.querySelectorAll('[aria-label]');
    lines.push('aria-label elements: ' + labeled.length);
    labeled.forEach((el, i) => {
      if (i < 80) {
        lines.push('  [' + i + '] <' + el.tagName.toLowerCase() + '> role=' + el.getAttribute('role') + ' label="' + el.getAttribute('aria-label') + '"');
      }
    });

    const semRoles = document.querySelectorAll('flt-semantics[role]');
    lines.push('flt-semantics with role: ' + semRoles.length);
    semRoles.forEach((el, i) => {
      if (i < 40) {
        lines.push('  sem[' + i + ']: role=' + el.getAttribute('role') + ' label=' + el.getAttribute('aria-label'));
      }
    });

    return lines.join('\n');
  });

  console.log('\n=== FLUTTER DOM INSPECTION ===');
  console.log(info);

  console.log('\n=== PLAYWRIGHT LOCATOR COUNTS ===');
  const tbCount = await page.getByRole('textbox').count();
  console.log('getByRole textbox: ' + tbCount);
  const cbCount = await page.getByRole('combobox').count();
  console.log('getByRole combobox: ' + cbCount);
  const inpCount = await page.locator('input').count();
  console.log('locator input: ' + inpCount);
  const taCount = await page.locator('textarea').count();
  console.log('locator textarea: ' + taCount);
  const ceCount = await page.locator('[contenteditable]').count();
  console.log('locator contenteditable: ' + ceCount);
  const semCount = await page.locator('flt-semantics').count();
  console.log('locator flt-semantics: ' + semCount);

  await browser.close();
  console.log('\nDone.');
})();
