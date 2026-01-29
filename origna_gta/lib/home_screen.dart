import 'dart:async'; // Required for Timer (Debouncer)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/addproduct_screen.dart';
import 'package:origna_gta/cart_screen.dart';
import 'package:origna_gta/constants.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  String _searchQuery = '';
  String? _selectedCategoryId;
  final List<ProductModel> _products = [];

  // Pagination variables
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Debouncer timer
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel(); // Important: cancel timer on dispose
    super.dispose();
  }

  // Logic: Reset list and fetch fresh from server
  void _refreshProducts() {
    setState(() {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _loadProducts();
  }

  // Logic: Debounce search to prevent excessive Firestore reads
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
      _refreshProducts();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _loadProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance.collection('products');

      // 1. SERVER-SIDE SEARCH (Free Way)
      if (_searchQuery.isNotEmpty) {
        query = query.where('searchKeywords', arrayContains: _searchQuery.toLowerCase().trim());
      }

      // 2. SERVER-SIDE CATEGORY FILTER
      if (_selectedCategoryId != null) {
        query = query.where('categoryId', isEqualTo: int.parse(_selectedCategoryId!));
      }

      // 3. ORDERING & PAGINATION
      // Note: You must click the error link in console to create composite index!
      query = query.orderBy('dateCreated', descending: true).limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newProducts = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

        setState(() {
          _products.addAll(newProducts);
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: _buildAppBar(user),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged, // Used debouncer here
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
          SliverToBoxAdapter(child: _buildCategoryList()),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Product Grid (Directly using _products from server)
          if (_products.isEmpty && !_isLoadingMore)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: getCrossAxisCount(context), crossAxisSpacing: 12, mainAxisSpacing: 12),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return ProductCard(productId: product.id, product: product, userModel: widget.userModel);
                }, childCount: _products.length),
              ),
            ),

          // Pagination Loader
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  //   // --- UI Helper Methods ---
  PreferredSizeWidget _buildAppBar(User? user) {
    return PreferredSize(
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
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          showLoginPrompt(context, text: "You need to sign in to access settings");
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                    ),
                    if ((widget.userModel?.roles.contains(UserRoles.seller) ?? false) ||
                        (widget.userModel?.roles.contains(UserRoles.admin) ?? false))
                      _buildIconButton(
                        icon: Icons.add_box_outlined,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                        },
                      ),
                    StreamBuilder<QuerySnapshot>(
                      stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').snapshots() : null,
                      builder: (context, snapshot) {
                        int count = 0;
                        if (snapshot.hasData) {
                          count = snapshot.data!.docs.fold(0, (sum, doc) => sum + (doc.get('quantity') as int));
                        }
                        return _buildCartBadge(context, count);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stack _buildCartBadge(BuildContext context, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconButton(
          icon: Icons.shopping_cart_outlined,
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              showLoginPrompt(context);
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        if (count > 0)
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
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == category?.categoryId.toString();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(isAll ? 'All' : category!.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategoryId = isAll ? null : category!.categoryId.toString());
                _refreshProducts();
              },
              selectedColor: const Color(0xFFFF6B35),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('No products matching your filters'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }
}
