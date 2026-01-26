
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/productcard_screen.dart';
import 'package:origna_gta/utils.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view favorites')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Error loading favorites'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final favorites = List<String>.from(userData?['favorites'] ?? []);
          final userModel = UserModel.fromMap(userData ?? {});
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').where(FieldPath.documentId, whereIn: favorites).snapshots(),
            builder: (context, productsSnapshot) {
              if (!productsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: productsSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final productD = productsSnapshot.data!.docs[index];

                  final product = ProductModel.fromDocument(productD);
                  return ProductCard(productId: product.id, product: product, userModel: userModel);
                },
              );
            },
          );
        },
      ),
    );
  }
}