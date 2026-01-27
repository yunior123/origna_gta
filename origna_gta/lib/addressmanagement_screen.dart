import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/editaddress_screen.dart';
import 'package:origna_gta/login_screen.dart';
import 'package:origna_gta/utils.dart';

class AddressManagementScreen extends StatelessWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Address', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final address = userData?['address'] != null ? Address.fromMap(userData!['address'] as Map<String, dynamic>) : null;

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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
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
