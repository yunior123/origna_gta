import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_providers.dart';

/// Payment provider names
class PaymentProviders {
  static const String stripe = 'stripe';
  static const String airwallex = 'airwallex';
  static const List<String> all = [stripe, airwallex];
}

/// Admin tab for managing payment providers
class AdminPaymentProvidersTab extends ConsumerStatefulWidget {
  const AdminPaymentProvidersTab({super.key});

  @override
  ConsumerState<AdminPaymentProvidersTab> createState() => _AdminPaymentProvidersTabState();
}

class _AdminPaymentProvidersTabState extends ConsumerState<AdminPaymentProvidersTab> {
  Map<String, dynamic>? _providersData;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProviders,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.red[700])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadProviders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payment, color: Color(0xFF667EEA)),
                                SizedBox(width: 12),
                                Text(
                                  'Payment Provider Management',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Control which payment providers are available in the app. '
                              'Disabling a provider will prevent new payments and captures.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'At least one provider must remain enabled. '
                                      'Changes take effect immediately.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Provider cards
                    if (_providersData != null) ...[
                      _buildProviderCard(
                        provider: PaymentProviders.stripe,
                        name: 'Stripe',
                        icon: Icons.credit_card,
                        description: 'Primary payment processor for credit/debit cards, Apple Pay, Google Pay.',
                        features: ['Credit/Debit Cards', 'Apple Pay', 'Google Pay', 'Connect Payouts'],
                      ),
                      const SizedBox(height: 16),
                      _buildProviderCard(
                        provider: PaymentProviders.airwallex,
                        name: 'Airwallex',
                        icon: Icons.language,
                        description: 'International payment processor with support for Alipay and WeChat Pay.',
                        features: ['Cards', 'Alipay', 'WeChat Pay', 'International'],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Enabled providers summary
                    Card(
                      elevation: 2,
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enabled Providers',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getEnabledProvidersList(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Widget _buildProviderCard({
    required String provider,
    required String name,
    required IconData icon,
    required String description,
    required List<String> features,
  }) {
    final providers = _providersData?['providers'] as Map<String, dynamic>? ?? {};
    final providerData = providers[provider] as Map<String, dynamic>? ?? {};
    final isEnabled = providerData['enabled'] as bool? ?? false;
    final isConfigured = providerData['configured'] as bool? ?? false;
    final missingKeys = (providerData['missingKeys'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled ? const Color(0xFF667EEA).withValues(alpha: 0.1) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isEnabled ? const Color(0xFF667EEA) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isConfigured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Not configured',
                                style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: isConfigured || isEnabled
                      ? (value) => _toggleProvider(provider, name, value, isConfigured)
                      : null, // Disable switch if not configured and not enabled
                  activeTrackColor: const Color(0xFF667EEA),
                ),
              ],
            ),
            
            // Warning if not configured
            if (!isConfigured) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        missingKeys.isNotEmpty 
                            ? 'Missing: ${missingKeys.join(", ")}' 
                            : 'API keys not configured. Set up $name account first.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map(
                    (feature) => Chip(
                      label: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: isEnabled ? const Color(0xFF667EEA) : Colors.grey,
                        ),
                      ),
                      backgroundColor: isEnabled ? const Color(0xFF667EEA).withValues(alpha: 0.1) : Colors.grey[100],
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: isEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'Accepting payments' : 'Not accepting payments',
                  style: TextStyle(
                    fontSize: 13,
                    color: isEnabled ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEnabledProvidersList() {
    final enabledProviders = _providersData?['enabledProviders'] as List<dynamic>? ?? [];
    if (enabledProviders.isEmpty) {
      return 'None';
    }
    return enabledProviders.map((p) => p.toString().toUpperCase()).join(', ');
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final data = await adminRepo.getPaymentProviders();
      
      if (mounted) {
        setState(() {
          _providersData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load providers: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleProvider(String provider, String name, bool enable, bool isConfigured) async {
    // If trying to enable but not configured, show info dialog
    if (enable && !isConfigured) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Text('$name Not Configured'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You need to set up your $name account before enabling it.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Text(
                'Steps to configure $name:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Create a $name account\n'
                '2. Get your API keys from the $name dashboard\n'
                '3. Add the keys to Firebase secrets\n'
                '4. Redeploy the Cloud Functions',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enable ? 'Enable $name?' : 'Disable $name?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              enable
                  ? 'This will allow new payments through $name.'
                  : 'This will prevent new payments and captures through $name. '
                      'Existing authorized payments may fail to capture.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter reason for this change',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _reasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = _reasonController.text;
              _reasonController.clear();
              Navigator.pop(context, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: enable ? const Color(0xFF667EEA) : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(enable ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );

    // If dialog was dismissed without confirmation
    if (reason == null) return;

    // Show loading
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      await adminRepo.updatePaymentProvider(provider, enable, reason: reason);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Reload data
      await _loadProviders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name ${enable ? 'enabled' : 'disabled'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.contains('not configured')) {
        errorMessage = '$name is not configured. Please set up your account first.';
      } else if (errorMessage.contains('Missing API keys')) {
        errorMessage = '$name API keys are missing. Configure them in Firebase secrets.';
      } else if (errorMessage.contains('Cannot disable all')) {
        errorMessage = 'At least one payment provider must remain enabled.';
      } else if (errorMessage.contains('FirebaseFunctionsException')) {
        // Extract the message from FirebaseFunctionsException
        final match = RegExp(r'\[.*?\]\s*(.+)').firstMatch(errorMessage);
        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
