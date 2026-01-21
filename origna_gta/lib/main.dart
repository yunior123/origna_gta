import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrignaGta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
      ),
      home: const OrignaGtaStore(),
    );
  }
}

class OrignaGtaStore extends StatefulWidget {
  const OrignaGtaStore({super.key});

  @override
  State<OrignaGtaStore> createState() => _OrignaGtaStoreState();
}

class _OrignaGtaStoreState extends State<OrignaGtaStore> {
  String activeTab = 'browse';
  List<Map<String, dynamic>> cart = [];
  bool showSellForm = false;
  String searchQuery = '';
  String selectedCategory = 'all';

  final List<Map<String, dynamic>> initialProducts = [
    {'id': 1, 'name': 'Vintage Leather Jacket', 'price': 89.99, 'seller': 'FashionHub', 'image': '🧥', 'category': 'fashion', 'rating': 4.5, 'sales': 234},
    {'id': 2, 'name': 'Wireless Earbuds Pro', 'price': 129.99, 'seller': 'TechStore', 'image': '🎧', 'category': 'electronics', 'rating': 4.8, 'sales': 567},
    {'id': 3, 'name': 'Handcrafted Ceramic Mug', 'price': 24.99, 'seller': 'ArtisanCrafts', 'image': '☕', 'category': 'home', 'rating': 4.6, 'sales': 123},
    {'id': 4, 'name': 'Running Sneakers', 'price': 79.99, 'seller': 'SportGear', 'image': '👟', 'category': 'fashion', 'rating': 4.7, 'sales': 456},
    {'id': 5, 'name': 'Smart Watch Ultra', 'price': 299.99, 'seller': 'TechStore', 'image': '⌚', 'category': 'electronics', 'rating': 4.9, 'sales': 789},
    {'id': 6, 'name': 'Organic Cotton T-Shirt', 'price': 29.99, 'seller': 'EcoWear', 'image': '👕', 'category': 'fashion', 'rating': 4.4, 'sales': 345},
    {'id': 7, 'name': 'Portable Speaker', 'price': 59.99, 'seller': 'AudioPro', 'image': '🔊', 'category': 'electronics', 'rating': 4.6, 'sales': 234},
    {'id': 8, 'name': 'Yoga Mat Premium', 'price': 39.99, 'seller': 'FitLife', 'image': '🧘', 'category': 'sports', 'rating': 4.7, 'sales': 178},
  ];

  late List<Map<String, dynamic>> products;
  List<int> favorites = [];

  final List<Map<String, dynamic>> categories = [
    {'id': 'all', 'name': 'All Products', 'icon': '🏪'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': '💻'},
    {'id': 'fashion', 'name': 'Fashion', 'icon': '👔'},
    {'id': 'home', 'name': 'Home & Living', 'icon': '🏠'},
    {'id': 'sports', 'name': 'Sports', 'icon': '⚽'},
  ];

  @override
  void initState() {
    super.initState();
    products = List.from(initialProducts);
  }

  void addToCart(Map<String, dynamic> product) {
    final existingIndex = cart.indexWhere((item) => item['id'] == product['id']);
    if (existingIndex != -1) {
      setState(() {
        cart[existingIndex]['quantity']++;
      });
    } else {
      setState(() {
        cart.add({...product, 'quantity': 1});
      });
    }
  }

  void removeFromCart(int productId) {
    setState(() {
      cart.removeWhere((item) => item['id'] == productId);
    });
  }

  void updateQuantity(int productId, int change) {
    setState(() {
      final index = cart.indexWhere((item) => item['id'] == productId);
      if (index != -1) {
        final newQty = cart[index]['quantity'] + change;
        if (newQty > 0) {
          cart[index]['quantity'] = newQty;
        } else {
          cart.removeAt(index);
        }
      }
    });
  }

  void toggleFavorite(int productId) {
    setState(() {
      if (favorites.contains(productId)) {
        favorites.remove(productId);
      } else {
        favorites.add(productId);
      }
    });
  }

  // Sell form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'electronics';

  void handleSellProduct() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) return;

    setState(() {
      products.insert(0, {
        'id': products.length + 1,
        'name': name,
        'price': price,
        'seller': 'You',
        'image': '📦',
        'category': _selectedCategory,
        'rating': 0.0,
        'sales': 0,
      });
    });

    _nameController.clear();
    _priceController.clear();
    _selectedCategory = 'electronics';
    Navigator.pop(context);
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((p) {
      final matchesSearch = p['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'all' || p['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  double get totalCartPrice {
    return cart.fold(0.0, (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = activeTab == 'browse'
        ? filteredProducts
        : filteredProducts.where((p) => favorites.contains(p['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.purple, Colors.blue],
          ).createShader(bounds),
          child: Text(
            'OrignaGta',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text('Shopping Cart'),
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(item['image'], style: const TextStyle(fontSize: 40)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('\$${item['price']}', style: const TextStyle(color: Colors.purple)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => updateQuantity(item['id'], -1),
                                    ),
                                    Text('${item['quantity']}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => updateQuantity(item['id'], 1),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => removeFromCart(item['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (cart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '\$${totalCartPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: Colors.purple,
                      ),
                      onPressed: () {},
                      child: const Text('Checkout', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Browse Products',
                      active: activeTab == 'browse',
                      onTap: () => setState(() => activeTab = 'browse'),
                    ),
                    const SizedBox(width: 12),
                    _TabButton(
                      label: 'Favorites (${favorites.length})',
                      icon: Icons.favorite,
                      active: activeTab == 'favorites',
                      onTap: () => setState(() => activeTab = 'favorites'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Sell Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => _SellProductForm(
                            nameController: _nameController,
                            priceController: _priceController,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (v) => setState(() => _selectedCategory = v!),
                            onSubmit: handleSellProduct,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text('${cat['icon']} ${cat['name']}'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedCategory = cat['id']),
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Products Grid
              if (displayProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text('No products found', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayProducts[index];
                    final isFavorite = favorites.contains(product['id']);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE)],
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                alignment: Alignment.center,
                                child: Text(product['image'], style: const TextStyle(fontSize: 80)),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => toggleFavorite(product['id']),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('by ${product['seller']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('${product['rating']}  •  ${product['sales']} sales', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${product['price']}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => addToCart(product),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? Colors.purple : Colors.white,
        foregroundColor: active ? Colors.white : Colors.black87,
        side: BorderSide(color: active ? Colors.purple : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class _SellProductForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSubmit;

  const _SellProductForm({
    required this.nameController,
    required this.priceController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sell Your Product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price (\$)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
              DropdownMenuItem(value: 'fashion', child: Text('Fashion')),
              DropdownMenuItem(value: 'home', child: Text('Home & Living')),
              DropdownMenuItem(value: 'sports', child: Text('Sports')),
            ],
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: onSubmit,
              child: const Text('List Product', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}