import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/addproduct_screen.dart';
import 'package:origna_gta/cart_screen.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/productcard_screen.dart';
import 'package:origna_gta/profile_screen.dart';
import 'package:origna_gta/utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel? userModel;
  const HomeScreen({super.key, this.userModel});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination variables
  final List<ProductModel> _products = [];
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
    _debounce?.cancel();
    super.dispose();
  }

  void _refreshProducts() {
    setState(() {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _loadProducts();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value;
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
      final searchQuery = ref.read(searchQueryProvider);
      final selectedCategoryId = ref.read(selectedCategoryProvider);

      Query query = FirebaseFirestore.instance.collection('products');

      if (searchQuery.isNotEmpty) {
        query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase().trim());
      }

      if (selectedCategoryId != null) {
        query = query.where('categoryId', isEqualTo: selectedCategoryId);
      }

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
    // Only watch userProfile for ProductCard - no longer causes full rebuilds
    // since cart badge and other buttons are extracted to separate widgets
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: _buildAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
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

          // Product Grid
          if (_products.isEmpty && !_isLoadingMore)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getCrossAxisCount(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return ProductCard(productId: product.id, product: product, userModel: userProfile ?? widget.userModel);
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
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
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(15)),
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
                const Row(
                  children: [
                    _SettingsButton(),
                    _AddProductButton(),
                    _CartBadge(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll ? selectedCategoryId == null : selectedCategoryId == category?.categoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(isAll ? 'All' : category!.name),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(selectedCategoryProvider.notifier).state = isAll ? null : category!.categoryId;
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
}

// ============================================================================
// EXTRACTED WIDGETS - Each only rebuilds when its specific data changes
// ============================================================================

/// Settings button - only rebuilds when auth state changes
class _SettingsButton extends ConsumerWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return IconButton(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      onPressed: () {
        if (user == null) {
          showLoginPrompt(context, text: "You need to sign in to access settings");
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
    );
  }
}

/// Add product button - only rebuilds when user profile changes
class _AddProductButton extends ConsumerWidget {
  const _AddProductButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    // Only show for sellers or admins
    final isSeller = userProfile?.roles.contains(UserRoles.seller) ?? false;
    final isAdmin = userProfile?.roles.contains(UserRoles.admin) ?? false;

    if (!isSeller && !isAdmin) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
      },
    );
  }
}

/// Cart badge - only rebuilds when cart count or auth state changes
class _CartBadge extends ConsumerWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {
            if (user == null) {
              showLoginPrompt(context);
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        if (cartCount > 0)
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
                cartCount > 99 ? '99+' : '$cartCount',
                style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
