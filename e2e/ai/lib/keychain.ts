/**
 * macOS Keychain wrapper for NVIDIA NIM API key retrieval.
 *
 * Keychain entry: service="NVIDIA_NIM", account=$USER
 * Fallback: NVIDIA_API_KEY env var
 */
const KEYCHAIN_SERVICE = 'NVIDIA_NIM';

export function getNvidiaApiKey(): string {
  // 1. Try env var first (CI-friendly)
  const envKey = process.env.NVIDIA_API_KEY?.trim();
  if (envKey) return envKey;

  // 2. Try macOS keychain
  try {
    const result = Bun.spawnSync(
      ['security', 'find-generic-password', '-s', KEYCHAIN_SERVICE, '-a', process.env.USER ?? '', '-w'],
      { timeout: 5_000 },
    );
    if (result.exitCode === 0) {
      const key = result.stdout.toString().trim();
      if (key) return key;
    }
  } catch {
    // security command not available (non-macOS)
  }

  throw new Error(
    `NVIDIA API key not found. Either:\n` +
    `  1. Set NVIDIA_API_KEY env var, or\n` +
    `  2. Save to keychain: security add-generic-password -s "${KEYCHAIN_SERVICE}" -a "$USER" -w "<your-key>"`,
  );
}
