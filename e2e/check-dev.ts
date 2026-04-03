import { AgentBrowser } from './lib/agent-browser.ts';

const b = new AgentBrowser({ headed: false });
await b.clearState(); // Clear cookies/cache
await b.open('https://dev.orignagta.ca');
await b.waitForFlutter();
await b.click('e1'); // Enable accessibility
await new Promise(r => setTimeout(r, 4000));
await b.screenshot('/Users/yuniorrodriguezosorio/Desktop/dev-home-fresh.png');
await b.close();
console.log('DONE');
