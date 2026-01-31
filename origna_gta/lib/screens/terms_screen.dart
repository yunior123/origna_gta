import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import '../features/terms/terms_provider.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Terms & Conditions'),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildContent(context, 'Error loading terms. Please try again later.'),
        data: (content) => _buildContent(context, content),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms and Conditions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
