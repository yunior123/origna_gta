import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'My Address'),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (userModel) {
          if (userModel == null) return const Center(child: Text('Log in to view address'));
          
          final address = userModel.address;

          if (address == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No address saved'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Address'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (address.label != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              address.label!,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(address.formattedAddress, style: const TextStyle(fontSize: 14, height: 1.5)),
                    if (address.phoneNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.phone_outlined, size: 16), const SizedBox(width: 8), Text(address.phoneNumber!)]),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
