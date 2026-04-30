import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, test } from 'bun:test';

const repoRoot = new URL('../../../', import.meta.url).pathname;
const captureScript = join(repoRoot, 'e2e/lib/capture_investor_deck_desktop.ts');
const screenshotDir = join(
  repoRoot,
  'origna_ventures/output/desktop-screenshots',
);

const requiredCaptureTargets = [
  'gta-buyer-orders',
  'gta-buyer-notifications',
  'gta-buyer-chat',
  'gta-buyer-cart',
  'gta-buyer-support',
  'gta-buyer-security',
  'gta-seller-products',
  'gta-admin-panel',
  'gta-admin-orders',
  'ventures-contact-form',
] as const;

const requiredTranslationKeys = [
  'start_shopping',
  'security.title',
  'security.enable_mfa',
  'admin.security.title',
  'admin.security.enable_mfa',
  'common.go_shopping',
  'orders.no_orders',
  'orders.view_my_orders',
  'payment.check_orders_later',
  'chat.inbox_subtitle',
  'chat.tap_to_chat',
] as const;

const spanishCriticalTranslations: Record<string, string> = {
  'start_shopping': 'Empezar a comprar',
  'security.title': 'Seguridad',
  'security.enable_mfa': 'Activar MFA',
  'admin.security.enable_mfa': 'Activar MFA',
  'admin.users.make_admin': 'Convertir en administrador',
  'admin.users.confirm_grant_admin': 'Conceder acceso de administrador',
  'orders.no_orders': 'Aún no hay pedidos',
  'orders.view_my_orders': 'Ver mis pedidos',
  'payment.check_orders_later': 'Revisa tu página de pedidos en unos minutos.',
  'chat.inbox_subtitle': 'Conversaciones premium',
  'chat.tap_to_chat': 'Toca para abrir la conversación',
};

function flattenTranslations(
  value: Record<string, unknown>,
  prefix = '',
  out: Record<string, string> = {},
): Record<string, string> {
  for (const [key, entry] of Object.entries(value)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (entry && typeof entry === 'object' && !Array.isArray(entry)) {
      flattenTranslations(entry as Record<string, unknown>, path, out);
    } else if (typeof entry === 'string') {
      out[path] = entry;
    }
  }
  return out;
}

describe('Investor deck regression guard', () => {
  test('capture script still targets previously missing buyer/seller/admin views', () => {
    const script = readFileSync(captureScript, 'utf8');
    for (const target of requiredCaptureTargets) {
      expect(script).toContain(`id: '${target}'`);
    }
    expect(script).toContain('seenImageHashes.has(imageHash)');
    expect(script).toContain('skip duplicate');
    expect(script).toContain("process.env.MIN_INVESTOR_SCREENSHOTS || 64");
  });

  test('known raw translation keys are present in every locale', () => {
    const enPath = join(repoRoot, 'origna_gta/assets/translations/en.json');
    const en = flattenTranslations(JSON.parse(readFileSync(enPath, 'utf8')));
    for (const locale of ['en', 'fr', 'es']) {
      const path = join(
        repoRoot,
        `origna_gta/assets/translations/${locale}.json`,
      );
      const translations = flattenTranslations(JSON.parse(readFileSync(path, 'utf8')));
      for (const key of requiredTranslationKeys) {
        expect(translations[key], `${locale} missing ${key}`).toBeTruthy();
        expect(translations[key]).not.toBe(key);
        if (locale !== 'en') {
          expect(translations[key], `${locale} left English for ${key}`).not.toBe(en[key]);
        }
      }
    }

    const esPath = join(repoRoot, 'origna_gta/assets/translations/es.json');
    const es = flattenTranslations(JSON.parse(readFileSync(esPath, 'utf8')));
    for (const [key, expected] of Object.entries(spanishCriticalTranslations)) {
      expect(es[key], `es mismatch for ${key}`).toBe(expected);
    }
  });

  test('current generated screenshot set has required live views and no exact duplicates', () => {
    expect(existsSync(screenshotDir)).toBe(true);

    const files = readdirSync(screenshotDir)
      .filter((name) => name.endsWith('.png'))
      .sort();
    expect(files.length).toBe(64);

    const hashes = new Map<string, string>();
    for (const file of files) {
      const path = join(screenshotDir, file);
      expect(statSync(path).size).toBeGreaterThan(25_000);
      const hash = createHash('sha256').update(readFileSync(path)).digest('hex');
      expect(hashes.get(hash), `${file} duplicates ${hashes.get(hash)}`).toBeUndefined();
      hashes.set(hash, file);
    }

    const names = files.join('\n');
    for (const target of requiredCaptureTargets) {
      expect(names, `missing screenshot for ${target}`).toContain(target);
    }
  });
});
