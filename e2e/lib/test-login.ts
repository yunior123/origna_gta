import { AgentBrowser } from './agent-browser.js';
import { WEB_APP_URL } from './config.js';

async function main() {
  const browser = new AgentBrowser();
  
  await browser.open(WEB_APP_URL, 60000);
  await browser.waitForFlutter();
  
  console.log("Navigating to login...");
  await browser.open(`${WEB_APP_URL}/login`, 60000);
  await browser.waitForFlutter();
  
  console.log("Clicking enable accessibility...");
  const snap = await browser.snapshot({ compact: true });
  const a11yRef = browser.findByLabel(snap, /Enable accessibility/i);
  if (a11yRef) {
      await browser.click(a11yRef.ref);
      console.log("Clicked.");
  } else {
      console.log("Not found.");
  }
  
  await new Promise(r => setTimeout(r, 5000));
  await browser.waitForFlutter();
  
  const snap2 = await browser.snapshot({ compact: true });
  console.log("Snapshot after accessibility click:", JSON.stringify(snap2.refs.slice(0, 10), null, 2));
}

main().catch(console.error);
