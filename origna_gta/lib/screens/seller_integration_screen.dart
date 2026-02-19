import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

/// Seller Integration Guide — shows the public API endpoints, seller's product IDs,
/// and ready-to-use code snippets for activating licenses from their software.
class SellerIntegrationScreen extends ConsumerWidget {
  const SellerIntegrationScreen({super.key});

  static const _activateEndpointProd =
      'https://us-central1-orignagta.cloudfunctions.net/activate_license';
  static const _verifyEndpointProd =
      'https://us-central1-orignagta.cloudfunctions.net/verify_license';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CustomAppBar(
              title: 'Developer Integration Guide',
              subtitle: 'Connect your software to Origna license validation',
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _IntroCard(),
                  const SizedBox(height: 20),
                  _HowItWorksCard(),
                  const SizedBox(height: 20),
                  _EndpointsCard(),
                  const SizedBox(height: 20),
                  _SwiftSnippetCard(),
                  const SizedBox(height: 20),
                  _PythonSnippetCard(),
                  const SizedBox(height: 20),
                  _BookIntegrationCard(),
                  const SizedBox(height: 20),
                  _ErrorCodesCard(),
                  const SizedBox(height: 20),
                  _SecurityCard(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Intro ────────────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.integration_instructions_outlined,
      title: 'How licensing works on Origna',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText(
            'When a buyer purchases your software on Origna, a unique license key '
            '(format: XXXX-XXXX-XXXX-XXXX) is automatically generated and emailed to them.',
          ),
          const SizedBox(height: 8),
          _BodyText(
            'Your app calls two public endpoints — no API key, no Firebase SDK, no login '
            'required. Just a plain HTTPS POST from anywhere: Swift, Python, Electron, Unity.',
          ),
          const SizedBox(height: 12),
          _StepRow(number: '1', text: 'Buyer enters their license key in your app'),
          _StepRow(number: '2', text: 'Your app calls POST /activate_license'),
          _StepRow(number: '3', text: 'Origna verifies key, registers the device, returns product info'),
          _StepRow(number: '4', text: 'Your app unlocks Pro features'),
        ],
      ),
    );
  }
}

// ── How it works detail ──────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.lock_open_outlined,
      title: 'Activation vs Verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeading('activate_license — call on first run or when user enters key'),
          _BodyText(
            'Registers the device (deviceId) against the license. '
            'Respects the device limit the seller configured. '
            'Idempotent — safe to call multiple times from the same device.',
          ),
          const SizedBox(height: 12),
          _SubHeading('verify_license — call periodically (e.g. on app launch)'),
          _BodyText(
            'Re-validates that the license is still active and not revoked (e.g. after a refund). '
            'Same request/response shape as activate. '
            'Recommended: call once per app launch, cache result for 24 h offline grace.',
          ),
        ],
      ),
    );
  }
}

// ── Endpoints ────────────────────────────────────────────────────────────────

class _EndpointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.cloud_outlined,
      title: 'API Endpoints',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EndpointRow(
            method: 'POST',
            url: SellerIntegrationScreen._activateEndpointProd,
            label: 'Activate / register device',
          ),
          const SizedBox(height: 8),
          _EndpointRow(
            method: 'POST',
            url: SellerIntegrationScreen._verifyEndpointProd,
            label: 'Verify on app launch',
          ),
          const SizedBox(height: 12),
          _SubHeading('Request body (JSON)'),
          _CodeBlock('''
{
  "licenseKey": "XXXX-XXXX-XXXX-XXXX",
  "deviceId":   "<unique device identifier>",
  "platform":   "macos" | "windows" | "linux"
}'''),
          const SizedBox(height: 12),
          _SubHeading('Success response (HTTP 200)'),
          _CodeBlock('''
{
  "activated": true,
  "productName": "FXCleaner",
  "licenseKey": "XXXX-XXXX-XXXX-XXXX",
  "activatedAt": "2025-03-01T12:00:00Z"
}'''),
        ],
      ),
    );
  }
}

// ── Swift snippet ────────────────────────────────────────────────────────────

class _SwiftSnippetCard extends StatelessWidget {
  static const _code = r'''
import Foundation
import IOKit

/// Returns the hardware UUID of this Mac — stable across reboots.
func deviceID() -> String {
    let service = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching("IOPlatformExpertDevice")
    )
    defer { IOObjectRelease(service) }
    return IORegistryEntryCreateCFProperty(
        service,
        "IOPlatformUUID" as CFString,
        kCFAllocatorDefault, 0
    )?.takeRetainedValue() as? String ?? UUID().uuidString
}

/// Activate a license key against the Origna backend.
func activateLicense(key: String, platform: String = "macos") async throws -> Bool {
    let url = URL(string:
        "https://us-central1-orignagta.cloudfunctions.net/activate_license")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONSerialization.data(withJSONObject: [
        "licenseKey": key,
        "deviceId":   deviceID(),
        "platform":   platform,
    ])
    let (data, resp) = try await URLSession.shared.data(for: req)
    guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
        let body = try? JSONDecoder().decode([String: String].self, from: data)
        throw LicenseError(body?["error"] ?? "unknown_error")
    }
    return true
}''';

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.apple,
      title: 'Swift / macOS Integration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText('Paste this into your app. Uses IOKit to get the hardware UUID as a stable device identifier.'),
          const SizedBox(height: 10),
          _CodeBlock(_code),
          const SizedBox(height: 8),
          _InfoChip('No Firebase SDK or CocoaPods required — plain URLSession'),
        ],
      ),
    );
  }
}

// ── Python snippet ───────────────────────────────────────────────────────────

class _PythonSnippetCard extends StatelessWidget {
  static const _code = r'''
import requests, subprocess, platform

def device_id() -> str:
    """Returns a stable hardware identifier."""
    if platform.system() == "Darwin":
        out = subprocess.check_output(
            ["ioreg", "-rd1", "-c", "IOPlatformExpertDevice"],
            text=True
        )
        for line in out.splitlines():
            if "IOPlatformUUID" in line:
                return line.split('"')[-2]
    elif platform.system() == "Windows":
        import winreg
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Cryptography")
        return winreg.QueryValueEx(key, "MachineGuid")[0]
    import uuid
    return str(uuid.getnode())

def activate_license(key: str, plat: str = "windows") -> dict:
    resp = requests.post(
        "https://us-central1-orignagta.cloudfunctions.net/activate_license",
        json={"licenseKey": key, "deviceId": device_id(), "platform": plat},
        timeout=10,
    )
    resp.raise_for_status()
    return resp.json()  # {"activated": True, "productName": "..."}''';

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.code,
      title: 'Python / Windows / Linux Integration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText('Works for any Python app on macOS, Windows, or Linux.'),
          const SizedBox(height: 10),
          _CodeBlock(_code),
          const SizedBox(height: 8),
          _InfoChip('Only dependency: requests  (pip install requests)'),
        ],
      ),
    );
  }
}

// ── Book integration ─────────────────────────────────────────────────────────

class _BookIntegrationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.menu_book_outlined,
      title: 'Books — no integration needed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText(
            'Book downloads are fully managed by Origna. When a buyer taps "Download" '
            'in the app, Origna generates a 15-minute single-use secure link and '
            'redirects them to your PDF/EPUB URL — your URL is never exposed to the buyer.',
          ),
          const SizedBox(height: 8),
          _BodyText(
            'As a book seller, you only need to provide your download URL when listing '
            'the product. Origna handles access control, token expiry, and single-use enforcement.',
          ),
          const SizedBox(height: 12),
          _StepRow(number: '✓', text: 'Buyer taps Download in their Origna order'),
          _StepRow(number: '✓', text: 'Origna backend creates a 15-min token, URL stays server-side'),
          _StepRow(number: '✓', text: 'Browser is redirected — buyer downloads directly'),
          _StepRow(number: '✓', text: 'Link expires and cannot be reused'),
        ],
      ),
    );
  }
}

// ── Error codes ──────────────────────────────────────────────────────────────

class _ErrorCodesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.error_outline,
      title: 'Error codes',
      child: Column(
        children: const [
          _ErrorRow('not_found', 404, 'Key does not exist — buyer entered wrong key'),
          _ErrorRow('revoked', 403, 'License revoked (refund issued)'),
          _ErrorRow('device_limit_exceeded', 403, 'Too many devices activated for this key'),
          _ErrorRow('platform_not_supported', 403, 'Platform not included in this product'),
          _ErrorRow('invalid_key_format', 400, 'Key format wrong — validate before calling'),
        ],
      ),
    );
  }
}

// ── Security ─────────────────────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      icon: Icons.shield_outlined,
      title: 'Security recommendations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepRow(number: '1', text: 'Use hardware UUID (IOKit / WMI) as deviceId — not a random UUID stored on disk'),
          _StepRow(number: '2', text: 'Cache the activation result locally; re-verify on launch, not on every action'),
          _StepRow(number: '3', text: 'If verify_license returns "revoked", disable Pro features immediately'),
          _StepRow(number: '4', text: 'Set your device limit to 2–3 in the product listing to limit key sharing'),
          _StepRow(number: '5', text: 'Never hardcode keys in your source — the buyer provides their own at runtime'),
        ],
      ),
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _GuideCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.surface.withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.outline.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: DesignTokens.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final String method;
  final String url;
  final String label;
  const _EndpointRow({required this.method, required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DesignTokens.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(method,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(url,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: DesignTokens.primary)),
          ),
          Tooltip(
            message: 'Copy URL',
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied'), duration: Duration(seconds: 2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock(this.code);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 44, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F4F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Tooltip(
            message: 'Copy code',
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied'), duration: Duration(seconds: 2)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.primary)),
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(fontSize: 14, height: 1.6, color: DesignTokens.textSecondary));
  }
}

class _SubHeading extends StatelessWidget {
  final String text;
  const _SubHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DesignTokens.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              color: DesignTokens.secondary,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String code;
  final int status;
  final String description;
  const _ErrorRow(this.code, this.status, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: DesignTokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('$status',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.error)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(description,
                    style: TextStyle(
                        fontSize: 13, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
