import { AgentBrowser } from './lib/agent-browser.ts';

const DESKTOP = '/Users/yuniorrodriguezosorio/Desktop/origna-audit-2026-03-31';
const b = new AgentBrowser({ headed: false });

async function ss(name: string) {
  await b.screenshot(`${DESKTOP}/${name}.png`);
  console.log(`  ✓ ${name}`);
}

try {
  const { mkdirSync } = await import('node:fs');
  mkdirSync(DESKTOP, { recursive: true });

  // Pages that don't require auth
  const pages = [
    ['01-home', 'https://dev.orignagta.ca'],
    ['02-login', 'https://dev.orignagta.ca/#/login'],
    ['03-register', 'https://dev.orignagta.ca/#/register'],
  ];

  for (const [name, url] of pages) {
    await b.open(url);
    await b.waitForFlutter().catch(() => {});
    await new Promise(r => setTimeout(r, 3000));
    // Enable accessibility on first load
    try {
      const snap = await b.snapshot();
      const raw = JSON.parse(snap.raw);
      for (const [ref, info] of Object.entries(raw.data?.refs || {})) {
        if ((info as any).name === 'Enable accessibility') {
          await b.click(ref);
          await new Promise(r => setTimeout(r, 2000));
          break;
        }
      }
    } catch {}
    await ss(name);
  }

  console.log('\nDone!');
} catch (e) {
  console.error('Error:', (e as Error).message);
} finally {
  await b.close();
}
