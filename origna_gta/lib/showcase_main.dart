import 'package:flutter/material.dart';

void main() => runApp(const OrignaShowcaseApp());

class OrignaShowcaseApp extends StatelessWidget {
  const OrignaShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Origna GTA Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF635BFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const _MarketplaceShowcase(),
    );
  }
}

class _MarketplaceShowcase extends StatelessWidget {
  const _MarketplaceShowcase();

  static const products = [
    _Product(
      name: 'Studio Wireless Headphones',
      category: 'Electronics',
      price: r'$189',
      rating: '4.9',
      icon: Icons.headphones_rounded,
      colors: [Color(0xFF5B63F6), Color(0xFF8B5CF6)],
      badge: 'Bestseller',
    ),
    _Product(
      name: 'North Coast Weekender',
      category: 'Travel',
      price: r'$124',
      rating: '4.8',
      icon: Icons.luggage_rounded,
      colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
      badge: 'Made in Canada',
    ),
    _Product(
      name: 'Minimal Ceramic Set',
      category: 'Home',
      price: r'$68',
      rating: '4.7',
      icon: Icons.coffee_rounded,
      colors: [Color(0xFFC2410C), Color(0xFFFB923C)],
      badge: 'New',
    ),
    _Product(
      name: 'Everyday Smart Watch',
      category: 'Wearables',
      price: r'$249',
      rating: '4.9',
      icon: Icons.watch_rounded,
      colors: [Color(0xFF111827), Color(0xFF4B5563)],
      badge: 'Free shipping',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 18, 40, 44),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Hero(),
                        const SizedBox(height: 28),
                        const _SectionHeader(),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1120
                                ? 4
                                : constraints.maxWidth >= 720
                                ? 2
                                : 1;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 18) /
                                columns;
                            return Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              children: [
                                for (final product in products)
                                  SizedBox(
                                    width: width,
                                    child: _ProductCard(product: product),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF635BFF), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(13)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'ORIGNA',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Color(0xFF171725),
            ),
          ),
          const Spacer(),
          const _NavItem('Discover', selected: true),
          const _NavItem('Categories'),
          const _NavItem('Sell'),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {},
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.label, {this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF635BFF) : const Color(0xFF6B7280),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(44, 36, 44, 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17172F), Color(0xFF403B91)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CANADIAN MARKETPLACE · BUILT FOR EVERYONE',
                  style: TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find your next\nfavourite thing.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search_rounded),
                      hintText: 'Search products, makers, and collections',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 2,
            child: Center(
              child: Icon(
                Icons.storefront_rounded,
                size: 150,
                color: Color(0x66FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending now',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Fresh finds from independent sellers',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Text(
          'View all  →',
          style: TextStyle(
            color: Color(0xFF635BFF),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 174,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: product.colors,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    product.icon,
                    color: const Color(0xEEFFFFFF),
                    size: 92,
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.badge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 12,
                  top: 12,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xDDFFFFFF),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: Color(0xFF171725),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      product.rating,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Product {
  const _Product({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.icon,
    required this.colors,
    required this.badge,
  });

  final String name;
  final String category;
  final String price;
  final String rating;
  final IconData icon;
  final List<Color> colors;
  final String badge;
}
