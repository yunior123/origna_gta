#!/usr/bin/env bun

import { AgentBrowser } from './agent-browser.js';

function runAgentBrowser(args: string[], timeout = 30_000): string {
  const result = Bun.spawnSync(['agent-browser', ...args], {
    env: process.env,
    timeout,
  });
  if (result.exitCode !== 0) {
    throw new Error(
      `agent-browser ${args[0]} failed: ${
        result.stderr.toString().trim() || result.stdout.toString().trim()
      }`,
    );
  }
  return result.stdout.toString();
}

async function main() {
  const browser = new AgentBrowser();

  await browser.open('https://dev.orignagta.ca', 60_000);
  await new Promise((resolve) => setTimeout(resolve, 4_000));

  runAgentBrowser([
    'eval',
    `(async()=>{const r=await fetch('https://api.dev.orignagta.ca/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'e2e-admin@test.origna.ca',password:'REDACTED_TEST_PASSWORD'})});const d=await r.json();localStorage.setItem('orignabase_access_token',d.access_token);localStorage.setItem('orignabase_refresh_token',d.refresh_token);localStorage.setItem('orignabase_email','e2e-admin@test.origna.ca');return JSON.stringify({ok:!!d.access_token,userId:d.user?.id})})()`,
  ]);

  await browser.open('https://dev.orignagta.ca', 60_000);
  await new Promise((resolve) => setTimeout(resolve, 6_000));
  const home = await browser.snapshot({ interactive: true, compact: true });
  console.log('HOME', JSON.stringify(home.refs.slice(0, 20), null, 2));

  await browser.safeClick(/btn-home-settings/i);
  await new Promise((resolve) => setTimeout(resolve, 3_000));
  const profile = await browser.snapshot({ interactive: true, compact: true });
  console.log('PROFILE', JSON.stringify(profile.refs.slice(0, 30), null, 2));

  await browser.safeClick(/menu-my-orders/i);
  await new Promise((resolve) => setTimeout(resolve, 5_000));
  const orders = await browser.snapshot({ interactive: true, compact: true });
  console.log('ORDERS', JSON.stringify(orders.refs.slice(0, 80), null, 2));
}

await main();
