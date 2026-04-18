/**
 * FIXED AgentBrowser v4 — Reduced clearState timeout + better error messages
 */
import type { Snapshot, SnapshotRef } from './types.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS, WEB_APP_URL } from './config.js';

export type CapturePersona = 'buyer' | 'seller' | 'admin';

export class AgentBrowser {
  private engine: 'chrome' | 'lightpanda';
  private headed: boolean;
  private wasOnStripe = false;

  constructor(options?: { engine?: 'chrome' | 'lightpanda'; headed?: boolean }) {
    this.engine = options?.engine ?? (process.env.AGENT_BROWSER_ENGINE as any) ?? 'chrome';
    this.headed = options?.headed ?? process.env.HEADED === 'true';
  }

  public run(args: string[], timeoutMs = 30_000): string {
    const fullArgs = [...args];
    if (this.headed) fullArgs.unshift('--headed');
    
    const result = Bun.spawnSync(['agent-browser', ...fullArgs], {
      env: { ...process.env, AGENT_BROWSER_ENGINE: this.engine },
      timeout: timeoutMs,
    });
    
    if (result.exitCode !== 0) {
      const stderr = result.stderr.toString().trim();
      const stdout = result.stdout.toString().trim();
      if (result.exitCode === null) {
        throw new Error(`agent-browser ${args[0]} timed out after ${timeoutMs}ms`);
      }
      throw new Error(`agent-browser ${args[0]} failed (exit ${result.exitCode}): ${stderr || stdout}`);
    }
    return result.stdout.toString();
  }

  private normalizeRef(ref: string): string {
    // agent-browser element refs are passed as bare eNN tokens. Prefixing them
    // with '@' makes the CLI treat them like CSS selectors in fill/click flows.
    return ref.startsWith('@') ? ref.slice(1) : ref;
  }

  async open(url: string, timeoutMs = 60_000): Promise<void> {
    if (!url.includes('checkout.stripe.com')) {
      let currentUrl = '';
      try { currentUrl = this.run(['eval', 'window.location.href'], 5_000).trim().replace(/^"|"$/g, ''); } catch { /* no page open yet */ }
      if (this.wasOnStripe || currentUrl.includes('checkout.stripe.com')) {
        try { this.run(['cookies', 'clear'], 2_000); } catch { /* ignore */ }
        try { this.run(['storage', 'local', 'clear'], 2_000); } catch { /* ignore */ }
        this.wasOnStripe = false;
      }
    }
    if (url.includes('checkout.stripe.com')) {
      this.wasOnStripe = true;
    }
    let lastError: unknown = null;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        this.run(['open', url], timeoutMs);
        return;
      } catch (error) {
        lastError = error;
        const message = String(error);
        if (!/Target page, context or browser has been closed|net::ERR_ABORTED/i.test(message) || attempt === 2) {
          throw error;
        }
        await new Promise(r => setTimeout(r, 500 * (attempt + 1)));
      }
    }
    throw lastError instanceof Error ? lastError : new Error(String(lastError));
  }

  async clearState(): Promise<void> {
    // Use very short timeouts — if clearing fails, don't block
    // Tests can work with stale cookies/storage if needed
    try { 
      this.run(['cookies', 'clear'], 500);
    } catch (_e) { 
      // Silently ignore — browser may be busy
    }
    try { 
      this.run(['storage', 'local', 'clear'], 500);
    } catch (_e) { 
      // Silently ignore — browser may be busy
    }
    this.wasOnStripe = false;
    
    // Give browser a moment to stabilize after clearing
    await new Promise(r => setTimeout(r, 100));
  }

  async snapshot(opts?: { interactive?: boolean; compact?: boolean; depth?: number }): Promise<Snapshot> {
    const args = ['snapshot'];
    if (opts?.interactive) args.push('-i');
    if (opts?.compact) args.push('-c');
    if (opts?.depth) args.push('--depth', String(opts.depth));
    args.push('--json');

    const output = this.run(args);
    const parsed = JSON.parse(output);
    const refsObj = parsed.data?.refs ?? parsed.refs ?? {};
    const elements = parsed.elements;
    let refs: SnapshotRef[];
    if (Array.isArray(elements) && elements.length > 0) {
      refs = elements.map((el: any) => ({
        ref: el.ref ?? '',
        role: el.role ?? '',
        name: el.name ?? '',
        text: el.text,
      }));
    } else {
      refs = Object.entries(refsObj).map(([key, val]: [string, any]) => ({
        ref: key,
        role: val.role ?? '',
        name: val.name ?? '',
        text: val.text,
      }));
    }
    return { raw: output, refs };
  }

  async click(ref: string): Promise<void> {
    this.run(['click', this.normalizeRef(ref)]);
  }

  async fill(ref: string, text: string): Promise<void> {
    this.run(['fill', this.normalizeRef(ref), text]);
  }

  async press(key: string): Promise<void> {
    this.run(['press', key]);
  }

  async type(text: string): Promise<void> {
    this.run(['type', text]);
  }

  async screenshot(path?: string): Promise<string> {
    const args = ['screenshot'];
    if (path) args.push(path);
    return this.run(args, 15_000);
  }

  async wait(opts: { text?: string; timeout?: number; networkIdle?: boolean }): Promise<void> {
    const args = ['wait'];
    if (opts.text) args.push('--text', opts.text);
    if (opts.timeout) args.push('--timeout', String(opts.timeout));
    if (opts.networkIdle) args.push('--network-idle');
    this.run(args, (opts.timeout ?? 30_000) + 5_000);
  }

  async close(): Promise<void> {
    try {
      // Keep teardown comfortably under Bun's default 5s hook timeout.
      this.run(['close'], 1_500);
    } catch (e) {
      console.warn(`[close] agent-browser close failed (non-fatal):`, String(e).slice(0, 80));
    }
    this.wasOnStripe = false;
  }

  // High-level helpers built on snapshot
  findByRole(snapshot: Snapshot, role: string, name: string | RegExp): SnapshotRef | null {
    return snapshot.refs.find(r => {
      if (r.role !== role) return false;
      if (typeof name === 'string') return r.name === name;
      return name.test(r.name);
    }) ?? null;
  }

  findByLabel(snapshot: Snapshot, label: string | RegExp): SnapshotRef | null {
    return snapshot.refs.find(r => {
      if (typeof label === 'string') return r.name === label || r.text === label;
      return label.test(r.name) || (r.text != null && label.test(r.text));
    }) ?? null;
  }

  findAllByLabel(snapshot: Snapshot, pattern: RegExp): SnapshotRef[] {
    return snapshot.refs.filter(r => pattern.test(r.name) || (r.text != null && pattern.test(r.text)));
  }

  async safeClick(pattern: RegExp, retries = 3): Promise<boolean> {
    for (let i = 0; i < retries; i++) {
      try {
        const snap = await this.snapshot({ interactive: true, compact: true });
        const target = this.findAllByLabel(snap, pattern)[0];
        if (!target) return false;
        await this.click(target.ref);
        return true;
      } catch (e) {
        if (i === retries - 1) throw e;
        await new Promise(r => setTimeout(r, 500));
      }
    }
    return false;
  }

  async safeFill(pattern: RegExp, text: string, retries = 3): Promise<boolean> {
    for (let i = 0; i < retries; i++) {
      try {
        const snap = await this.snapshot({ interactive: true, compact: true });
        const target = this.findAllByLabel(snap, pattern)[0];
        if (!target) return false;
        await this.fill(target.ref, text);
        return true;
      } catch (e) {
        if (i === retries - 1) throw e;
        await new Promise(r => setTimeout(r, 500));
      }
    }
    return false;
  }

  private hasFlutterAppRefs(snap: Snapshot): boolean {
    return snap.refs.some(ref => {
      const name = `${ref.name ?? ''} ${ref.text ?? ''}`.trim();
      return !!name && !/^(Enable accessibility|Privacy Policy|Terms of Service)$/i.test(name);
    });
  }

  async waitForFlutter(timeout?: number): Promise<void> {
    const ms = timeout ?? (Number(process.env.E2E_FLUTTER_TIMEOUT) || 45_000);
    const start = Date.now();
    let lastError = '';
    while (Date.now() - start < ms) {
      try {
        const snap = await this.snapshot({ interactive: true, compact: true });
        if (this.hasFlutterAppRefs(snap)) return;
        lastError = `only bootstrap/html refs visible (${snap.refs.map(ref => ref.name).join(', ').slice(0, 120)})`;
      } catch (e) {
        // Snapshot may fail while page is loading
        lastError = String(e).slice(0, 60);
      }
      await new Promise(r => setTimeout(r, 1_000));
    }
    throw new Error(`Flutter semantics tree not found within ${ms}ms (last: ${lastError})`);
  }

  async waitForChange(opts?: { minRefs?: number; text?: string | RegExp; timeout?: number }): Promise<Snapshot> {
    const timeout = opts?.timeout ?? 10_000;
    const start = Date.now();
    while (Date.now() - start < timeout) {
      try {
        const snap = await this.snapshot({ interactive: true, compact: true });
        if (opts?.text) {
          const pattern = typeof opts.text === 'string' ? new RegExp(opts.text, 'i') : opts.text;
          if (snap.refs.some(r => pattern.test(r.name) || (r.text && pattern.test(r.text)))) return snap;
        } else if (opts?.minRefs) {
          if (snap.refs.length >= opts.minRefs) return snap;
        } else {
          return snap;
        }
      } catch {
        // Transient snapshot failures OK
      }
      await new Promise(r => setTimeout(r, 200));
    }
    throw new Error(`waitForChange timeout: condition not met after ${timeout}ms`);
  }

  async enableAccessibilityIfPresent(): Promise<boolean> {
    try {
      const snap = await this.snapshot({ interactive: true, compact: true });
      const button = this.findByLabel(snap, /Enable accessibility/i);
      if (!button) return false;

      await this.click(button.ref);
      await new Promise(r => setTimeout(r, 2_000));
      await this.waitForFlutter().catch(() => undefined);
      await new Promise(r => setTimeout(r, 1_000));
      return true;
    } catch {
      return false;
    }
  }

  async fillAndSubmit(ref: string, text: string): Promise<void> {
    await this.fill(ref, text);
    await this.press('Enter');
  }

  async scrollAndWait(directionOrDist: 'down' | 'up' | 'left' | 'right' | number = 'down', timeout = 5_000): Promise<void> {
    const dist = typeof directionOrDist === 'number' ? directionOrDist : undefined;
    const dir = typeof directionOrDist === 'string' ? directionOrDist : undefined;

    const before = await this.snapshot({ compact: true });
    if (dir) {
      this.run(['scroll', dir, ...(dist ? [String(dist)] : [])]);
    } else {
      this.run(['scroll', 'down', String(dist ?? 300)]);
    }

    const start = Date.now();
    while (Date.now() - start < timeout) {
      try {
        const after = await this.snapshot({ compact: true });
        if (after.refs.length !== before.refs.length) return;
      } catch {
        // Ignore snapshot errors during scroll
      }
      await new Promise(r => setTimeout(r, 200));
    }
  }

  async navigateAndVerify(options: {
    clickRef: string;
    expectedKeywords: string[];
    scrollIntoView?: boolean;
    retries?: number;
    waitMs?: number;
  }): Promise<{ success: boolean; snapshot: string; error?: string }> {
    const { clickRef, expectedKeywords, scrollIntoView = false, retries = 1, waitMs = 3000 } = options;

    for (let attempt = 0; attempt <= retries; attempt++) {
      const before = await this.snapshot({ compact: true });
      const beforeRaw = before.raw;

      let actualRef = clickRef;
      if (!/^@?e\d+$/i.test(clickRef)) {
        const match = this.findByLabel(before, new RegExp(clickRef, 'i'))?.ref;
        if (match) {
          actualRef = match;
        } else {
          const m = beforeRaw.match(new RegExp(`"ref":"(@?e\\\\d+)".*?"name":".*?${clickRef}.*?"`, 'i')) || 
                    beforeRaw.match(new RegExp(`${clickRef}.*?ref=(e\\\\d+)`, 'i'));
          if (m) actualRef = m[1];
          else {
            if (attempt < retries) { await new Promise(r => setTimeout(r, 1000)); continue; }
            return { success: false, snapshot: beforeRaw, error: `Ref not found for label: ${clickRef}` };
          }
        }
      }

      if (scrollIntoView) {
        try { this.run(['scrollintoview', this.normalizeRef(actualRef)]); } catch(e) {}
        await new Promise(r => setTimeout(r, 500));
      }

      try {
        await this.click(actualRef);
      } catch (e) {
        if (attempt < retries) { await new Promise(r => setTimeout(r, 1000)); continue; }
        return { success: false, snapshot: beforeRaw, error: `Click failed on ${actualRef}` };
      }
      await new Promise(r => setTimeout(r, waitMs));

      const after = await this.snapshot({ compact: true });
      const afterRaw = after.raw;

      if (afterRaw === beforeRaw) {
        console.warn(`[navigateAndVerify] Page didn't change after clicking ${clickRef} (attempt ${attempt + 1})`);
        if (attempt < retries) {
          await new Promise(r => setTimeout(r, 1000));
          continue;
        }
        return { success: false, snapshot: afterRaw, error: 'Page unchanged after click' };
      }

      const hasExpected = expectedKeywords.some(kw => afterRaw.toLowerCase().includes(kw.toLowerCase()));
      if (!hasExpected) {
        console.warn(`[navigateAndVerify] Page changed but expected keywords [${expectedKeywords.join(', ')}] not found (attempt ${attempt + 1})`);
        if (attempt < retries) continue;
        return { success: false, snapshot: afterRaw, error: `Keywords not found: ${expectedKeywords.join(', ')}` };
      }

      return { success: true, snapshot: afterRaw };
    }

    return { success: false, snapshot: '', error: 'All retries exhausted' };
  }

  async screenshotWithVerify(options: {
    filepath: string;
    expectedKeywords: string[];
    viewport?: { width: number; height: number };
    requiredKeywordCount?: number;
  }): Promise<boolean> {
    const { filepath, expectedKeywords, viewport } = options;
    const requiredKeywordCount = Math.max(1, options.requiredKeywordCount ?? 1);

    if (viewport) {
      this.run(['set', 'viewport', String(viewport.width), String(viewport.height)]);
      await new Promise(r => setTimeout(r, 500));
    }

    const snap = await this.snapshot({ compact: true });
    const snapRaw = snap.raw;
    const matchedKeywords = expectedKeywords.filter((kw) =>
      snapRaw.toLowerCase().includes(kw.toLowerCase()),
    );
    const hasExpected = matchedKeywords.length >= requiredKeywordCount;

    if (!hasExpected) {
      console.error(
        `[screenshotWithVerify] SKIPPING ${filepath} — matched ${matchedKeywords.length}/${requiredKeywordCount} keywords [${expectedKeywords.join(', ')}]`,
      );
      return false;
    }

    await this.screenshot(filepath);
    console.log(`[screenshotWithVerify] OK: ${filepath}`);
    return true;
  }

  private credentialsForPersona(persona: CapturePersona): {
    email: string;
    password: string;
    successMarkers: string[];
  } {
    switch (persona) {
      case 'buyer':
        return {
          email: TEST_ACCOUNTS.BUYER_EMAIL,
          password: TEST_ACCOUNTS.BUYER_PASS,
          successMarkers: ['btn-home-settings', 'btn-cart'],
        };
      case 'seller':
        return {
          email: TEST_ACCOUNTS.SELLER_EMAIL,
          password: TEST_ACCOUNTS.SELLER_PASS,
          successMarkers: ['btn-home-settings', 'btn-add-product'],
        };
      case 'admin':
      default:
        return {
          email: TEST_ACCOUNTS.ADMIN_EMAIL,
          password: TEST_ACCOUNTS.ADMIN_PASS,
          successMarkers: ['btn-home-settings', 'btn-add-product', 'menu-admin-panel'],
        };
    }
  }

  private hasAnyMarker(raw: string, successMarkers: string[]): boolean {
    return successMarkers.some((marker) => raw.includes(marker));
  }

  async goHomeAndLogin(persona: CapturePersona = 'admin'): Promise<string> {
    await this.clearState();
    await this.open(WEB_APP_URL, 60_000);
    await this.waitForFlutter();
    await this.enableAccessibilityIfPresent();
    await new Promise(r => setTimeout(r, 2000));

    let snap = await this.snapshot({ compact: true });
    const { email, password, successMarkers } = this.credentialsForPersona(persona);
    if (!this.hasAnyMarker(snap.raw, successMarkers)) {
      await this.open(`${WEB_APP_URL}/login`, 60_000);
      await this.waitForFlutter();
      await this.enableAccessibilityIfPresent();
      await new Promise(r => setTimeout(r, 2000));
      await this.safeFill(/email|you@example|login_email/i, email);
      await this.safeFill(/password|login_password|••••••••/i, password);
      await this.press('Enter');
      
      // Wait for login to complete and navigate home
      await new Promise(r => setTimeout(r, 5000));
      await this.waitForFlutter();
      
      // Double check we are home, if not navigate
      await this.open(WEB_APP_URL, 60_000);
      await this.waitForFlutter();
      await this.enableAccessibilityIfPresent();
      await new Promise(r => setTimeout(r, 3000));
      snap = await this.snapshot({ compact: true });
    }

    if (!this.hasAnyMarker(snap.raw, successMarkers)) {
      throw new Error(
        `Login failed for ${persona} — none of [${successMarkers.join(', ')}] were found after login`,
      );
    }

    return snap.raw;
  }

  async loginViaApi(email: string, password: string): Promise<void> {
    await this.clearState();
    await this.open(WEB_APP_URL, 60_000);
    await this.waitForFlutter();
    await this.enableAccessibilityIfPresent();
    await new Promise(r => setTimeout(r, 1000));

    const script = `(async()=>{const r=await fetch(${JSON.stringify(`${ORIGNABASE_URL}/auth/login`)},{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:${JSON.stringify(email)},password:${JSON.stringify(password)}})});const d=await r.json().catch(()=>({}));if(!r.ok||!d.access_token||!d.refresh_token){throw new Error('login failed: '+JSON.stringify({status:r.status,body:d}));}localStorage.setItem('orignabase_access_token',d.access_token);localStorage.setItem('orignabase_refresh_token',d.refresh_token);localStorage.setItem('orignabase_email',${JSON.stringify(email)});return JSON.stringify({ok:true,userId:d.user?.id||null});})()`;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        this.run(['eval', script], 45_000);
        await this.open(WEB_APP_URL, 60_000);
        await this.waitForFlutter();
        await this.enableAccessibilityIfPresent();
        await new Promise(r => setTimeout(r, 1500));
        return;
      } catch (error) {
        const message = String(error);
        if (
          !/Execution context was destroyed|navigation|Failed to fetch|ERR_|NetworkError|net::/i.test(
            message,
          ) ||
          attempt === 2
        ) {
          throw error;
        }
        await this.clearState();
        await this.open(WEB_APP_URL, 60_000);
        await this.waitForFlutter();
        await this.enableAccessibilityIfPresent();
        await new Promise(r => setTimeout(r, 1000 + attempt * 500));
      }
    }
  }

  async installAuthSession(email: string, accessToken: string, refreshToken = ''): Promise<void> {
    await this.clearState();
    await this.open(WEB_APP_URL, 60_000);
    await this.waitForFlutter().catch(() => undefined);

    const script = `(function(){localStorage.setItem('orignabase_access_token',${JSON.stringify(accessToken)});localStorage.setItem('orignabase_refresh_token',${JSON.stringify(refreshToken)});localStorage.setItem('orignabase_email',${JSON.stringify(email)});return JSON.stringify({ok:true});})()`;
    this.run(['eval', script], 15_000);

    await this.open(WEB_APP_URL, 60_000);
    await this.waitForFlutter().catch(() => undefined);
    try {
      await this.waitForChange({
        text: /btn-home-settings|product-card-|input-home-search|search|home/i,
        timeout: 20_000,
      });
    } catch {
      await new Promise(r => setTimeout(r, 1_500));
    }
  }

  async navigateToProfileMenu(
    menuName: string,
    expectedKeywords: string[],
    persona: CapturePersona = 'admin',
  ): Promise<{ success: boolean; snapshot: string; error?: string }> {
    const homeSnapRaw = await this.goHomeAndLogin(persona);
    const homeSnapObj = await this.snapshot({ compact: true });
    
    let settingsRef = this.findByLabel(homeSnapObj, /btn-home-settings/i)?.ref;
    if (!settingsRef) {
       // try fallback with text
       const m = homeSnapRaw.match(/btn-home-settings.*?ref=(e\d+)/i) || homeSnapRaw.match(/"ref":"(@?e\d+)".*?"name":"btn-home-settings"/i);
       if (m) settingsRef = m[1];
    }
    
    if (!settingsRef) return { success: false, snapshot: homeSnapRaw, error: 'btn-home-settings not found' };

    await this.click(settingsRef);
    await new Promise(r => setTimeout(r, 2000));

    const profileSnapObj = await this.snapshot({ compact: true });
    let menuRef = this.findByLabel(profileSnapObj, new RegExp(menuName, 'i'))?.ref;
    
    if (!menuRef) {
      const m = profileSnapObj.raw.match(new RegExp(`${menuName}.*?ref=(e\\d+)`, 'i')) || profileSnapObj.raw.match(new RegExp(`"ref":"(@?e\\d+)".*?"name":"${menuName}"`, 'i'));
      if (m) menuRef = m[1];
    }

    if (!menuRef) {
      console.error(`Menu item ${menuName} not found in profile snapshot`);
      return { success: false, snapshot: profileSnapObj.raw, error: `Menu item ${menuName} not found` };
    }

    return this.navigateAndVerify({
      clickRef: menuRef,
      expectedKeywords,
      scrollIntoView: true,
      waitMs: 3000,
    });
  }

}
