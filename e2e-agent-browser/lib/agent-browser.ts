/**
 * FIXED AgentBrowser wrapper with robust daemon lifecycle management
 * Key fixes:
 * 1. Increase timeout for browser.close() from 5s to 15s
 * 2. Kill stale Chrome processes between open/close cycles
 * 3. Add explicit cleanup in afterAll to avoid test hangs
 * 4. Use process signals to forcefully terminate daemon if needed
 */
import type { Snapshot, SnapshotRef } from './types.js';

export class AgentBrowser {
  private engine: 'chrome' | 'lightpanda';
  private headed: boolean;
  private wasOnStripe = false;

  constructor(options?: { engine?: 'chrome' | 'lightpanda'; headed?: boolean }) {
    this.engine = options?.engine ?? (process.env.AGENT_BROWSER_ENGINE as any) ?? 'chrome';
    this.headed = options?.headed ?? process.env.HEADED === 'true';
  }

  private run(args: string[], timeoutMs = 30_000): string {
    const fullArgs = [...args];
    if (this.headed) fullArgs.unshift('--headed');
    
    const result = Bun.spawnSync(['agent-browser', ...fullArgs], {
      env: { ...process.env, AGENT_BROWSER_ENGINE: this.engine },
      timeout: timeoutMs,
    });
    
    if (result.exitCode !== 0) {
      const stderr = result.stderr.toString().trim();
      const stdout = result.stdout.toString().trim();
      // If timeout, give better error message
      if (result.exitCode === null) {
        throw new Error(`agent-browser ${args[0]} timed out after ${timeoutMs}ms`);
      }
      throw new Error(`agent-browser ${args[0]} failed (exit ${result.exitCode}): ${stderr || stdout}`);
    }
    return result.stdout.toString();
  }

  async open(url: string): Promise<void> {
    // Clear browser state when navigating to app URLs to prevent Stripe
    // checkout cookies from causing redirects. Check the current browser URL
    // to detect if we were previously on Stripe (handles cross-instance state).
    if (!url.includes('checkout.stripe.com')) {
      let currentUrl = '';
      try { currentUrl = this.run(['eval', 'window.location.href'], 5_000).trim().replace(/^"|"$/g, ''); } catch { /* no page open yet */ }
      if (this.wasOnStripe || currentUrl.includes('checkout.stripe.com')) {
        try { this.run(['cookies', 'clear'], 5_000); } catch { /* ignore */ }
        try { this.run(['storage', 'local', 'clear'], 5_000); } catch { /* ignore */ }
        this.wasOnStripe = false;
      }
    }
    if (url.includes('checkout.stripe.com')) {
      this.wasOnStripe = true;
    }
    this.run(['open', url], 60_000);
  }

  /** Explicitly clear all browser state (cookies, localStorage). Call in beforeAll/beforeEach if needed. */
  async clearState(): Promise<void> {
    try { this.run(['cookies', 'clear'], 5_000); } catch { /* ignore */ }
    try { this.run(['storage', 'local', 'clear'], 5_000); } catch { /* ignore */ }
    this.wasOnStripe = false;
  }

  async snapshot(opts?: { interactive?: boolean; compact?: boolean; depth?: number }): Promise<Snapshot> {
    const args = ['snapshot'];
    if (opts?.interactive) args.push('-i');
    if (opts?.compact) args.push('-c');
    if (opts?.depth) args.push('--depth', String(opts.depth));
    args.push('--json');

    const output = this.run(args);
    const parsed = JSON.parse(output);
    // agent-browser returns { data: { refs: { e1: {...}, e2: {...} }, snapshot: "..." } }
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
    this.run(['click', ref]);
  }

  async fill(ref: string, text: string): Promise<void> {
    this.run(['fill', ref, text]);
  }

  async press(key: string): Promise<void> {
    this.run(['press', key]);
  }

  async type(text: string): Promise<void> {
    this.run(['type', text]);
  }

  async screenshot(path?: string): Promise<string> {
    const args = ['screenshot'];
    if (path) args.push('--path', path);
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
      // CRITICAL FIX: Increase timeout from 5s to 20s and handle graceful + forceful shutdown
      this.run(['close'], 20_000);
    } catch (e) {
      // Browser may already be closed, or daemon is hung
      console.error(`[AgentBrowser] close() failed (likely daemon stuck):`, String(e));
    }
    this.wasOnStripe = false;
    
    // Safety net: kill any stale Chrome/agent-browser processes to prevent leak
    try {
      const killCmd = Bun.spawnSync(['pkill', '-9', '-f', 'chrome|chromium|agent-browser'], {
        timeout: 5_000,
      });
      if (killCmd.exitCode === 0 || killCmd.exitCode === 1) {
        // pkill returns 0 on success, 1 if no process matched (both are OK)
        console.log(`[AgentBrowser] stale processes cleaned up`);
      }
    } catch {
      // Ignore cleanup errors
    }
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

  /** Atomic snapshot+click: takes fresh snapshot, finds element, clicks — retries on stale ref. */
  async safeClick(pattern: RegExp, retries = 3): Promise<boolean> {
    for (let i = 0; i < retries; i++) {
      try {
        const snap = await this.snapshot();
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

  async waitForFlutter(timeout?: number): Promise<void> {
    const ms = timeout ?? (Number(process.env.E2E_FLUTTER_TIMEOUT) || 45_000);
    const start = Date.now();
    while (Date.now() - start < ms) {
      try {
        const snap = await this.snapshot({ interactive: true, compact: true });
        if (snap.refs.length > 0) return;
      } catch {
        // Snapshot may fail while page is loading
      }
      await new Promise(r => setTimeout(r, 1_000));
    }
    throw new Error(`Flutter semantics tree not found within ${ms}ms`);
  }

  /**
   * Wait for the snapshot to change (new elements appear) — replaces hardcoded sleeps.
   * Polls every 200ms, returns as soon as condition is met.
   */
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

  /** Fill + press Enter combo — common for form submission. */
  async fillAndSubmit(ref: string, text: string): Promise<void> {
    await this.fill(ref, text);
    await this.press('Enter');
  }

  /** Scroll down and wait for new content (lazy loading). */
  async scrollAndWait(directionOrDist: 'down' | 'up' | 'left' | 'right' | number = 'down', timeout = 5_000): Promise<void> {
    const dist = typeof directionOrDist === 'number' ? directionOrDist : undefined;
    const dir = typeof directionOrDist === 'string' ? directionOrDist : undefined;

    const before = await this.snapshot({ compact: true });
    if (dir) {
      this.run(['scroll', dir, ...(dist ? [String(dist)] : [])]);
    } else {
      this.run(['scroll', 'down', String(dist ?? 300)]);
    }

    // Wait for content to appear
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
}
