// /// Aurora Home Demo — Standalone mockup screen
// /// Temporary file to preview the Aurora UI design.
// /// No providers, no Firebase, no external deps — pure Flutter.
// library;

// import 'dart:ui';
// import 'package:flutter/material.dart';

// // =============================================================================
// // DESIGN TOKENS (local copy to keep demo self-contained)
// // =============================================================================
// class _C {
//   static const background = Color(0xFF0F0F1E);
//   static const surface = Color(0xFF1E1E32);
//   static const surfaceLight = Color(0xFF252542);
//   static const blue = Color(0xFF667EEA);
//   static const violet = Color(0xFF764BA2);
//   static const cyan = Color(0xFF5CE1E6);
//   static const coral = Color(0xFFFF6B6B);
//   static const textPrimary = Colors.white;
//   static const textSecondary = Color(0xFFAAB2C8);
//   static const textTertiary = Color(0xFF6B7280);
// }

// // =============================================================================
// // MOCK DATA
// // =============================================================================
// class _MockProduct {
//   final String name;
//   final String price;
//   final double rating;
//   final int reviews;
//   final IconData icon;
//   final Color iconColor;
//   final bool isFavorite;
//   final String badge;

//   const _MockProduct({
//     required this.name,
//     required this.price,
//     required this.rating,
//     required this.reviews,
//     required this.icon,
//     this.iconColor = Colors.white,
//     this.isFavorite = false,
//     this.badge = '',
//   });
// }

// const _mockProducts = [
//   _MockProduct(
//     name: 'Nike Air Max 90',
//     price: '\$189.99',
//     rating: 4.5,
//     reviews: 128,
//     icon: Icons.directions_run,
//     iconColor: Color(0xFF64B5F6),
//     isFavorite: true,
//     badge: 'Popular',
//   ),
//   _MockProduct(
//     name: 'Samsung Galaxy S25',
//     price: '\$1,299.99',
//     rating: 4.8,
//     reviews: 256,
//     icon: Icons.phone_android,
//     iconColor: Color(0xFFCE93D8),
//     isFavorite: false,
//     badge: 'New',
//   ),
//   _MockProduct(
//     name: 'Canada Goose Parka',
//     price: '\$899.00',
//     rating: 4.9,
//     reviews: 89,
//     icon: Icons.ac_unit,
//     iconColor: Color(0xFF4FC3F7),
//     isFavorite: true,
//   ),
//   _MockProduct(
//     name: 'MacBook Pro M4',
//     price: '\$2,499.00',
//     rating: 4.7,
//     reviews: 342,
//     icon: Icons.laptop_mac,
//     iconColor: Color(0xFFB0BEC5),
//     isFavorite: true,
//     badge: 'Best Seller',
//   ),
//   _MockProduct(
//     name: 'Sony WH-1000XM5',
//     price: '\$449.99',
//     rating: 4.6,
//     reviews: 201,
//     icon: Icons.headphones,
//     iconColor: Color(0xFFFFCC80),
//     isFavorite: false,
//   ),
//   _MockProduct(
//     name: 'iPad Pro 13"',
//     price: '\$1,599.00',
//     rating: 4.8,
//     reviews: 178,
//     icon: Icons.tablet_mac,
//     iconColor: Color(0xFFA5D6A7),
//     isFavorite: false,
//     badge: 'Hot',
//   ),
// ];

// const _categories = ['All', 'Electronics', 'Fashion', 'Tech', 'Sports', 'Home', 'Gaming'];

// // =============================================================================
// // MAIN DEMO SCREEN
// // =============================================================================
// class AuroraHomeDemo extends StatefulWidget {
//   const AuroraHomeDemo({super.key});

//   @override
//   State<AuroraHomeDemo> createState() => _AuroraHomeDemoState();
// }

// class _AuroraHomeDemoState extends State<AuroraHomeDemo> {
//   int _selectedCategory = 0;
//   bool _showSearch = false;
//   final _searchController = TextEditingController();
//   final _searchFocus = FocusNode();

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocus.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _C.background,
//       body: Stack(
//         children: [
//           // Layer 0: Aurora animated background
//           const _AnimatedAuroraBackground(),

//           // Layer 1: Content
//           SafeArea(
//             child: Column(
//               children: [
//                 const _GlassAppBar(),
//                 Expanded(
//                   child: CustomScrollView(
//                     slivers: [
//                       // Tagline
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//                           child: Text(
//                             'Your marketplace for buying and selling across the GTA and all of Canada.',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: _C.textSecondary,
//                               fontWeight: FontWeight.w400,
//                               height: 1.4,
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Search Bar
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: GestureDetector(
//                             onTap: () => setState(() {
//                               _showSearch = true;
//                               Future.delayed(const Duration(milliseconds: 100), () {
//                                 _searchFocus.requestFocus();
//                               });
//                             }),
//                             child: const _GlassSearchBar(),
//                           ),
//                         ),
//                       ),

//                       // Category Chips
//                       SliverToBoxAdapter(
//                         child: SizedBox(
//                           height: 48,
//                           child: ListView.separated(
//                             scrollDirection: Axis.horizontal,
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: _categories.length,
//                             separatorBuilder: (_, __) => const SizedBox(width: 10),
//                             itemBuilder: (context, i) {
//                               final active = _selectedCategory == i;
//                               return GestureDetector(
//                                 onTap: () => setState(() => _selectedCategory = i),
//                                 child: _CategoryChip(label: _categories[i], active: active),
//                               );
//                             },
//                           ),
//                         ),
//                       ),

//                       const SliverToBoxAdapter(child: SizedBox(height: 16)),

//                       // Product Grid
//                       SliverPadding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         sliver: SliverGrid(
//                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             crossAxisSpacing: 14,
//                             mainAxisSpacing: 14,
//                             childAspectRatio: 0.62,
//                           ),
//                           delegate: SliverChildBuilderDelegate(
//                             (context, index) {
//                               final product = _mockProducts[index];
//                               return _AuroraProductCard(product: product);
//                             },
//                             childCount: _mockProducts.length,
//                           ),
//                         ),
//                       ),

//                       // Loading More
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 32),
//                           child: Center(
//                             child: _GradientText(
//                               text: 'Loading more...',
//                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                               gradient: const LinearGradient(colors: [_C.blue, _C.violet, _C.cyan]),
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Gradient divider
//                       SliverToBoxAdapter(
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 40),
//                           height: 2,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(1),
//                             gradient: LinearGradient(
//                               colors: [
//                                 _C.blue.withValues(alpha: 0.0),
//                                 _C.blue.withValues(alpha: 0.8),
//                                 _C.violet.withValues(alpha: 0.8),
//                                 _C.cyan.withValues(alpha: 0.8),
//                                 _C.cyan.withValues(alpha: 0.0),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Footer
//                       SliverToBoxAdapter(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
//                           child: Column(
//                             children: [
//                               const SizedBox(height: 12),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   _GradientText(
//                                     text: 'Privacy Policy',
//                                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                                     gradient: const LinearGradient(colors: [_C.blue, _C.violet]),
//                                   ),
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                                     child: Text('|', style: TextStyle(color: _C.textTertiary, fontSize: 13)),
//                                   ),
//                                   _GradientText(
//                                     text: 'Terms of Service',
//                                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                                     gradient: const LinearGradient(colors: [_C.violet, _C.cyan]),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 '© 2026 Origna GTA. All rights reserved.',
//                                 style: TextStyle(color: _C.textTertiary, fontSize: 11),
//                               ),
//                               const SizedBox(height: 24),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Layer 2: Search Overlay
//           if (_showSearch)
//             _AuroraSearchOverlay(
//               controller: _searchController,
//               focusNode: _searchFocus,
//               onClose: () => setState(() {
//                 _showSearch = false;
//                 _searchController.clear();
//               }),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // =============================================================================
// // ANIMATED AURORA BACKGROUND
// // =============================================================================
// class _AnimatedAuroraBackground extends StatefulWidget {
//   const _AnimatedAuroraBackground();

//   @override
//   State<_AnimatedAuroraBackground> createState() => _AnimatedAuroraBackgroundState();
// }

// class _AnimatedAuroraBackgroundState extends State<_AnimatedAuroraBackground>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 30),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (_, __) {
//         final t = _controller.value;
//         return SizedBox.expand(
//           child: Stack(
//             children: [
//               Container(color: _C.background),
//               // Blue orb — top left, drifts right
//               _buildOrb(
//                 alignment: Alignment(-1.0 + t * 0.6, -1.0 + t * 0.3),
//                 color: _C.blue,
//                 size: 380,
//                 blur: 120,
//                 opacity: 0.40,
//               ),
//               // Violet orb — top right, drifts left
//               _buildOrb(
//                 alignment: Alignment(1.0 - t * 0.5, -0.6 + t * 0.2),
//                 color: _C.violet,
//                 size: 320,
//                 blur: 100,
//                 opacity: 0.35,
//               ),
//               // Cyan orb — bottom center, drifts up
//               _buildOrb(
//                 alignment: Alignment(0.2 - t * 0.4, 1.0 - t * 0.4),
//                 color: _C.cyan,
//                 size: 280,
//                 blur: 90,
//                 opacity: 0.25,
//               ),
//               // Small coral accent orb
//               _buildOrb(
//                 alignment: Alignment(-0.5 + t * 0.8, 0.3 - t * 0.2),
//                 color: _C.coral,
//                 size: 150,
//                 blur: 70,
//                 opacity: 0.15,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildOrb({
//     required Alignment alignment,
//     required Color color,
//     required double size,
//     required double blur,
//     required double opacity,
//   }) {
//     return Align(
//       alignment: alignment,
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: color.withValues(alpha: opacity),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//           child: const SizedBox(),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // GLASS APP BAR
// // =============================================================================
// class _GlassAppBar extends StatelessWidget {
//   const _GlassAppBar();

//   @override
//   Widget build(BuildContext context) {
//     return ClipRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//         child: Container(
//           height: 64,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             color: _C.surface.withValues(alpha: 0.15),
//             border: Border(
//               bottom: BorderSide(
//                 width: 1.5,
//                 color: _C.blue.withValues(alpha: 0.4),
//               ),
//             ),
//           ),
//           child: Row(
//             children: [
//               // Animated logo
//               TweenAnimationBuilder<double>(
//                 tween: Tween(begin: 0.0, end: 1.0),
//                 duration: const Duration(milliseconds: 800),
//                 curve: Curves.elasticOut,
//                 builder: (context, value, child) {
//                   return Transform.scale(
//                     scale: value,
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             _C.blue.withValues(alpha: 0.3),
//                             _C.violet.withValues(alpha: 0.3),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: _C.blue.withValues(alpha: 0.4),
//                           width: 1,
//                         ),
//                       ),
//                       child: const Icon(Icons.shopping_bag, color: _C.blue, size: 24),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(width: 12),
//               // Gradient title
//               ShaderMask(
//                 shaderCallback: (bounds) => const LinearGradient(
//                   colors: [Colors.white, Color(0xFFAAB2C8)],
//                 ).createShader(bounds),
//                 child: const Text(
//                   'Origna GTA',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w800,
//                     color: Colors.white,
//                     fontSize: 22,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               // Settings
//               _GlowIcon(icon: Icons.settings_outlined, onTap: () {}),
//               const SizedBox(width: 8),
//               // Add product
//               _GlowIcon(icon: Icons.add_box_outlined, onTap: () {}),
//               const SizedBox(width: 8),
//               // Cart with badge
//               Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   _GlowIcon(icon: Icons.shopping_cart_outlined, onTap: () {}),
//                   Positioned(
//                     right: -4,
//                     top: -4,
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(colors: [_C.coral, Color(0xFFFF4757)]),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: _C.coral.withValues(alpha: 0.6),
//                             blurRadius: 8,
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                       constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
//                       child: const Text(
//                         '3',
//                         style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // GLOW ICON BUTTON
// // =============================================================================
// class _GlowIcon extends StatefulWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _GlowIcon({required this.icon, required this.onTap});

//   @override
//   State<_GlowIcon> createState() => _GlowIconState();
// }

// class _GlowIconState extends State<_GlowIcon> {
//   bool _hovering = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             color: _hovering ? _C.blue.withValues(alpha: 0.15) : Colors.transparent,
//           ),
//           child: Icon(
//             widget.icon,
//             color: _hovering ? _C.cyan : Colors.white,
//             size: 22,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // GLASS SEARCH BAR (static, tappable)
// // =============================================================================
// class _GlassSearchBar extends StatelessWidget {
//   const _GlassSearchBar();

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 52,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             color: _C.surface.withValues(alpha: 0.12),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: _C.blue.withValues(alpha: 0.25), width: 1),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.search, color: _C.blue.withValues(alpha: 0.8), size: 22),
//               const SizedBox(width: 12),
//               Text(
//                 'Search products...',
//                 style: TextStyle(color: _C.textSecondary, fontSize: 15),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // CATEGORY CHIP
// // =============================================================================
// class _CategoryChip extends StatefulWidget {
//   final String label;
//   final bool active;
//   const _CategoryChip({required this.label, required this.active});

//   @override
//   State<_CategoryChip> createState() => _CategoryChipState();
// }

// class _CategoryChipState extends State<_CategoryChip> {
//   bool _hovering = false;

//   @override
//   Widget build(BuildContext context) {
//     final active = widget.active;
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOutCubic,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(24),
//           gradient: active
//               ? const LinearGradient(colors: [_C.blue, _C.violet])
//               : null,
//           color: active
//               ? null
//               : (_hovering ? _C.surfaceLight : _C.surface),
//           border: Border.all(
//             color: active
//                 ? Colors.transparent
//                 : _C.blue.withValues(alpha: _hovering ? 0.3 : 0.1),
//             width: 1,
//           ),
//           boxShadow: active
//               ? [
//                   BoxShadow(
//                     color: _C.blue.withValues(alpha: 0.5),
//                     blurRadius: 16,
//                     spreadRadius: -2,
//                   ),
//                 ]
//               : [],
//         ),
//         child: Text(
//           widget.label,
//           style: TextStyle(
//             color: active ? Colors.white : _C.textSecondary,
//             fontWeight: active ? FontWeight.w600 : FontWeight.w500,
//             fontSize: 13,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // AURORA PRODUCT CARD
// // =============================================================================
// class _AuroraProductCard extends StatefulWidget {
//   final _MockProduct product;
//   const _AuroraProductCard({required this.product});

//   @override
//   State<_AuroraProductCard> createState() => _AuroraProductCardState();
// }

// class _AuroraProductCardState extends State<_AuroraProductCard> {
//   bool _hovering = false;
//   bool _pressing = false;

//   double get _scale {
//     if (_pressing) return 0.97;
//     if (_hovering) return 1.03;
//     return 1.0;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final p = widget.product;

//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: GestureDetector(
//         onTapDown: (_) => setState(() => _pressing = true),
//         onTapUp: (_) => setState(() => _pressing = false),
//         onTapCancel: () => setState(() => _pressing = false),
//         child: AnimatedScale(
//           scale: _scale,
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeOutCubic,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             decoration: BoxDecoration(
//               color: _C.surface,
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(
//                 color: _hovering
//                     ? _C.blue.withValues(alpha: 0.4)
//                     : Colors.white.withValues(alpha: 0.06),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: _hovering
//                       ? _C.blue.withValues(alpha: 0.3)
//                       : _C.violet.withValues(alpha: 0.12),
//                   blurRadius: _hovering ? 32 : 20,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Image area
//                 Expanded(
//                   flex: 5,
//                   child: Stack(
//                     children: [
//                       // Product icon placeholder
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               _C.surface,
//                               p.iconColor.withValues(alpha: 0.08),
//                             ],
//                           ),
//                         ),
//                         child: Center(
//                           child: Icon(p.icon, size: 64, color: p.iconColor.withValues(alpha: 0.9)),
//                         ),
//                       ),
//                       // Badge
//                       if (p.badge.isNotEmpty)
//                         Positioned(
//                           top: 8,
//                           left: 8,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(colors: [_C.blue, _C.violet]),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               p.badge,
//                               style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                         ),
//                       // Favorite button
//                       Positioned(
//                         top: 8,
//                         right: 8,
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: BoxDecoration(
//                             color: _C.background.withValues(alpha: 0.6),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
//                           ),
//                           child: Icon(
//                             p.isFavorite ? Icons.favorite : Icons.favorite_border,
//                             color: p.isFavorite ? _C.coral : _C.textSecondary,
//                             size: 16,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Info area
//                 Expanded(
//                   flex: 4,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Title
//                         Text(
//                           p.name,
//                           style: const TextStyle(
//                             color: _C.textPrimary,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 13,
//                             height: 1.2,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         // Rating
//                         Row(
//                           children: [
//                             ...List.generate(5, (i) {
//                               final full = i < p.rating.floor();
//                               final half = i == p.rating.floor() && p.rating % 1 >= 0.5;
//                               return Icon(
//                                 full ? Icons.star : (half ? Icons.star_half : Icons.star_border),
//                                 size: 13,
//                                 color: const Color(0xFFFFC107),
//                               );
//                             }),
//                             const SizedBox(width: 4),
//                             Text(
//                               p.rating.toStringAsFixed(1),
//                               style: const TextStyle(color: _C.textSecondary, fontSize: 11),
//                             ),
//                           ],
//                         ),
//                         // Price + Cart
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Flexible(
//                               child: _GradientText(
//                                 text: p.price,
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                                 gradient: const LinearGradient(colors: [_C.blue, _C.violet]),
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                               decoration: BoxDecoration(
//                                 gradient: const LinearGradient(colors: [_C.blue, _C.violet]),
//                                 borderRadius: BorderRadius.circular(10),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: _C.blue.withValues(alpha: 0.4),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // GRADIENT TEXT HELPER
// // =============================================================================
// class _GradientText extends StatelessWidget {
//   final String text;
//   final TextStyle style;
//   final Gradient gradient;

//   const _GradientText({
//     required this.text,
//     required this.style,
//     required this.gradient,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ShaderMask(
//       blendMode: BlendMode.srcIn,
//       shaderCallback: (bounds) => gradient.createShader(
//         Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//       ),
//       child: Text(text, style: style.copyWith(color: Colors.white)),
//     );
//   }
// }

// // =============================================================================
// // AURORA SEARCH OVERLAY
// // =============================================================================
// class _AuroraSearchOverlay extends StatefulWidget {
//   final TextEditingController controller;
//   final FocusNode focusNode;
//   final VoidCallback onClose;

//   const _AuroraSearchOverlay({
//     required this.controller,
//     required this.focusNode,
//     required this.onClose,
//   });

//   @override
//   State<_AuroraSearchOverlay> createState() => _AuroraSearchOverlayState();
// }

// class _AuroraSearchOverlayState extends State<_AuroraSearchOverlay>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//   String _query = '';

//   List<_MockProduct> get _filteredProducts {
//     if (_query.isEmpty) return [];
//     return _mockProducts
//         .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
//         .toList();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//     )..forward();
//     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   void _close() async {
//     await _fadeController.reverse();
//     widget.onClose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: GestureDetector(
//         onTap: _close,
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
//           child: Container(
//             color: _C.background.withValues(alpha: 0.85),
//             child: SafeArea(
//               child: GestureDetector(
//                 onTap: () {}, // prevent close on content tap
//                 child: Column(
//                   children: [
//                     // Search field
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: _C.surface.withValues(alpha: 0.4),
//                           borderRadius: BorderRadius.circular(18),
//                           border: Border.all(color: _C.blue.withValues(alpha: 0.4)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: _C.blue.withValues(alpha: 0.2),
//                               blurRadius: 20,
//                             ),
//                           ],
//                         ),
//                         child: TextField(
//                           controller: widget.controller,
//                           focusNode: widget.focusNode,
//                           onChanged: (v) => setState(() => _query = v),
//                           style: const TextStyle(color: Colors.white, fontSize: 17),
//                           cursorColor: _C.cyan,
//                           decoration: InputDecoration(
//                             hintText: 'Search products, brands, categories...',
//                             hintStyle: TextStyle(color: _C.textSecondary),
//                             prefixIcon: const Icon(Icons.search, color: _C.blue),
//                             suffixIcon: IconButton(
//                               icon: const Icon(Icons.close, color: _C.textSecondary),
//                               onPressed: _close,
//                               tooltip: 'Close search',
//                             ),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(vertical: 16),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // Results
//                     Expanded(
//                       child: _query.isEmpty
//                           ? Center(
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.search, size: 48, color: _C.textTertiary),
//                                   const SizedBox(height: 12),
//                                   Text(
//                                     'Type to search products...',
//                                     style: TextStyle(color: _C.textSecondary, fontSize: 15),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           : _filteredProducts.isEmpty
//                               ? Center(
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(Icons.search_off, size: 48, color: _C.textTertiary),
//                                       const SizedBox(height: 12),
//                                       Text(
//                                         'No results for "$_query"',
//                                         style: TextStyle(color: _C.textSecondary, fontSize: 15),
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               : ListView.separated(
//                                   padding: const EdgeInsets.all(16),
//                                   itemCount: _filteredProducts.length,
//                                   separatorBuilder: (_, __) => const SizedBox(height: 10),
//                                   itemBuilder: (_, i) {
//                                     final p = _filteredProducts[i];
//                                     return _SearchResultTile(product: p);
//                                   },
//                                 ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // SEARCH RESULT TILE
// // =============================================================================
// class _SearchResultTile extends StatefulWidget {
//   final _MockProduct product;
//   const _SearchResultTile({required this.product});

//   @override
//   State<_SearchResultTile> createState() => _SearchResultTileState();
// }

// class _SearchResultTileState extends State<_SearchResultTile> {
//   bool _hovering = false;

//   @override
//   Widget build(BuildContext context) {
//     final p = widget.product;
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: _hovering ? _C.surfaceLight : _C.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: _hovering ? _C.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: p.iconColor.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(p.icon, color: p.iconColor, size: 24),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     p.name,
//                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${p.rating} · ${p.reviews} reviews',
//                         style: TextStyle(color: _C.textSecondary, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             _GradientText(
//               text: p.price,
//               style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
//               gradient: const LinearGradient(colors: [_C.blue, _C.violet]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
