const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', error => console.log('PAGE ERROR:', error.message));
  await page.goto('https://orignagta-dev.web.app');
  await page.waitForTimeout(10000);
  console.log('DOM:', await page.content());
  await browser.close();
})();
