

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/addproduct_screen.dart';
import 'package:origna_gta/cart_screen.dart';
import 'package:origna_gta/productcard_screen.dart';
import 'package:origna_gta/profile_screen.dart';
import 'package:origna_gta/utils.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? userModel;

  const HomeScreen({super.key, this.userModel});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  //static const int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();
  //DocumentSnapshot? _lastDocument;
  final List<ProductModel> _products = [];
  // bool _isLoadingMore = false;
  // bool _hasMore = true;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((doc) {
      final name = doc.name.toString().toLowerCase() ;
      final categoryId = doc.categoryId.toString() ;

      bool matchesSearch = name.contains(_searchQuery.toLowerCase());
      bool matchesCategory = _selectedCategoryId == null || categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Replace the existing AppBar in _HomeScreenState's build method with:
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'OrignaGta',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.settings_outlined,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                      ),
                      if (widget.userModel?.roles.contains('seller') ?? false)
                        _buildIconButton(
                          icon: Icons.add_box_outlined,
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                          },
                        ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() : null,
                        builder: (context, snapshot) {
                          int itemCount = 0;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null && data.containsKey('cart')) {
                              final List<dynamic> cartList = data['cart'] ?? [];
                              itemCount = cartList.fold(0, (sum, item) => sum + (item['quantity'] as int));
                            }
                          }
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildIconButton(
                                icon: Icons.shopping_cart_outlined,
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                                },
                              ),
                              if (itemCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    child: Text(
                                      itemCount > 99 ? '99+' : '$itemCount',
                                      style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          // Category Chips
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productCategories.length + 1, // +1 for "All" chip
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                        selectedColor: const Color(0xFFFF6B35),
                        labelStyle: TextStyle(color: _selectedCategoryId == null ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    );
                  }

                  final category = productCategories[index - 1];
                  final isSelected = _selectedCategoryId == category.categoryId.toString();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(category.icon, size: 18, color: isSelected ? Colors.white : const Color(0xFFFF6B35)),
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category.categoryId.toString() : null;
                        });
                      },
                      selectedColor: const Color(0xFFFF6B35),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Rest of the products grid remains the same
          if (filteredProducts.isEmpty && _products.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No products found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredProducts.isEmpty && _products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No products available', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(productId: filteredProducts[index].id, product: product, userModel: widget.userModel);
                }, childCount: filteredProducts.length),
              ),
            ),
          // if (_isLoadingMore)
          //   const SliverToBoxAdapter(
          //     child: Padding(
          //       padding: EdgeInsets.all(16),
          //       child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
          //     ),
          //   ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (mounted) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  // Add this helper method in _HomeScreenState class:
  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }

  Future<void> _loadProducts() async {
    // if (_isLoadingMore || !_hasMore) return;

    // setState(() => _isLoadingMore = true);

    try {
      final query = FirebaseFirestore.instance.collection('products');

      // if (_lastDocument != null) {
      //   query = query.startAfterDocument(_lastDocument!);
      // }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        // setState(() => _hasMore = false);
      } else {
        setState(() {
          // _lastDocument = snapshot.docs.last;
          final prod = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
          _products.addAll(prod);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }

    // finally {
    //   //if (mounted) setState(() => _isLoadingMore = false);
    // }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      //_loadProducts();
    }
  }
}