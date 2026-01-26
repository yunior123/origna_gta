import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// Initialize config
// Initialize the singleton instance
  await ConfigService().initialize();
  runApp(const OrignaApp());
}


//Version 1.0
//TODO: Cart view rebuilding when adding products, fix
//TODO: check google sign in, make sure it works
//TODO: when users visits website no need to sign in, just browse products, only sign in when adding to cart, tapping settings or cart icon
//TODO: seller should be able to edit their products, and mark them as sold out
//TODO: Terms and conditions screen needs to be added, link it in the signup screen, user must accept terms and conditions before signing up
//TODO: splash and launch icons need to be added later
//TODO: later on, move api keys to secure storage or similar, do not keep them hardcoded in the project

// -cloudflare r2 keys are also hardcoded in the project, that is ok for now








































// class _HomeScreenWidgetState extends State<HomeScreenWidget> {
//   @override
//   Widget build(BuildContext context) {
//     // Add your widget build logic here
//     return Container(); // Placeholder for the actual UI
//   }
// }




// class CategoriesScreen extends StatelessWidget {
//   const CategoriesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(8),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, crossAxisSpacing: 6, mainAxisSpacing: 6),
//         itemCount: productCategories.length,
//         itemBuilder: (context, index) {
//           final category = productCategories[index];
//           return CategoryCard(categoryId: category.categoryId.toString(), name: category.name, icon: category.icon);
//         },
//       ),
//     );
//   }
// }

// class CategoryCard extends StatelessWidget {
//   final String categoryId;
//   final String name;
//   final IconData icon;

//   const CategoryCard({super.key, required this.categoryId, required this.name, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
//       builder: (context, asyncSnapshot) {
//         UserModel? userModel;
//         if (asyncSnapshot.hasData && asyncSnapshot.data!.exists) {
//           final userData = asyncSnapshot.data!.data();
//           userModel = UserModel.fromMap(userData ?? {});
//         }

//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => CategoryProductsScreen(categoryId: categoryId, categoryName: name, userModel: userModel),
//               ),
//             );
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               gradient: LinearGradient(
//                 colors: [const Color(0xFFFF6B35).withOpacity(0.8), const Color(0xFFFF8E53).withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
//             ),
//             child: Stack(
//               children: [
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(icon, size: 50, color: Colors.white),
//                       const SizedBox(height: 12),
//                       Text(
//                         name,
//                         style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class CategoryProductsScreen extends StatelessWidget {
//   final String categoryId;
//   final String categoryName;
//   final UserModel? userModel;

//   const CategoryProductsScreen({super.key, required this.categoryId, required this.categoryName, required this.userModel});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: categoryId).snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
//                   const SizedBox(height: 16),
//                   const Text('No products in this category'),
//                 ],
//               ),
//             );
//           }

//           return GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1, crossAxisSpacing: 12, mainAxisSpacing: 12),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final product = snapshot.data!.docs[index];
//               return ProductCard(productId: product.id, product: product.data() as Map<String, dynamic>, userModel: userModel);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// CheckoutScreen
