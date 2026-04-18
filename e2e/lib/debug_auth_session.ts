#!/usr/bin/env bun

import { AgentBrowser } from './agent-browser.js';
import { signIn } from './api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from './config.js';

async function main() {
  const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
  const browser = new AgentBrowser();

  await browser.clearState();
  await browser.open(WEB_APP_URL, 60_000);
  await browser.waitForFlutter().catch(() => undefined);

  const script = `localStorage.setItem('orignabase_access_token', ${JSON.stringify(auth.idToken)});
    localStorage.setItem('orignabase_refresh_token', ${JSON.stringify(auth.refreshToken ?? '')});
    localStorage.setItem('orignabase_email', ${JSON.stringify(TEST_ACCOUNTS.BUYER_EMAIL)});`;
  browser.run(['eval', script], 15_000);

  await browser.open(`${WEB_APP_URL}/profile`, 60_000);
  await browser.waitForFlutter().catch(() => undefined);
  await new Promise((resolve) => setTimeout(resolve, 5_000));

  const snap = await browser.snapshot({ interactive: true, compact: true });
  console.log(snap.raw);

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
