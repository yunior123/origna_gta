# Widgets Library Reference

> **Purpose**: Shared UI components following the design system. All widgets use `DesignTokens.*` — never hardcoded colors, spacing, or radii.

---

## Design Philosophy

1. **DesignTokens everywhere** — No `Colors.*`, hex literals, or magic numbers
2. **Dark mode first** — All widgets adapt to theme automatically
3. **Accessibility built-in** — Semantics labels for E2E testing
4. **Composability** — Small, focused widgets composed into larger ones
5. **Consistency** — Same widget same behavior across all screens

---

## Widget Catalog

### Buttons

| Widget | File | Use Case |
|--------|------|----------|
| `ModernButton` | `modern_button.dart` | Primary/secondary actions |
| `ModernLoadingIndicator` | `modern_loading_indicator.dart` | Loading states |

### Inputs

| Widget | File | Use Case |
|--------|------|----------|
| `ModernTextField` | `modern_textfield.dart` | Text input forms |

### Containers

| Widget | File | Use Case |
|--------|------|----------|
| `ModernCard` | `modern_card.dart` | Elevated content containers |
| `GlassContainer` | `design_tokens.dart` | Glassmorphism overlays |

### Navigation

| Widget | File | Use Case |
|--------|------|----------|
| `ModernAppBar` | `modern_appbar.dart` | Screen headers |

### Product Widgets

| Widget | File | Use Case |
|--------|------|----------|
| `ModernProductCard` | `modern_product_card.dart` | Product grid/list items |

### Feedback

| Widget | File | Use Case |
|--------|------|----------|
| `ModernSnackbar` | `modern_snackbar.dart` | User notifications |
| `RatingDialog` | `rating_dialog.dart` | Star rating input |
| `RatingHistogram` | `rating_histogram.dart` | 5-star breakdown |

### Layout

| Widget | File | Use Case |
|--------|------|----------|
| `Animations` | `animations.dart` | `AnimatedListItem`, `TapScaleAnimation` |
| `ModernSkeletonLoader` | `modern_skeleton_loader.dart` | Loading placeholders |

### Cart

| Widget | File | Use Case |
|--------|------|----------|
| `FreeShippingBar` | `cart/free_shipping_bar.dart` | Progress to free shipping |
| `CartTotalDisplay` | `cart/cart_total_display.dart` | Cart totals |

### Orders

| Widget | File | Use Case |
|--------|------|----------|
| `OrderStatusChip` | `order_widgets.dart` | Order status badge |
| `PackageTimeline` | `order_widgets.dart` | Shipping timeline |

---

## ModernButton

Primary button widget with gradient, loading state, and semantic labels.

### Properties

```dart
class ModernButton extends StatelessWidget {
  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ModernButtonVariant.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.width,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ModernButtonVariant variant; // primary, secondary, outline, ghost
  final ModernButtonSize size; // small, medium, large
  final IconData? icon;
  final IconPosition iconPosition; // left, right
  final double? width;
  final String? semanticLabel;
}
```

### Variants

| Variant | Use Case | Styling |
|---------|----------|---------|
| `primary` | Main CTA | Gradient background, white text |
| `secondary` | Secondary actions | Solid color, white text |
| `outline` | Tertiary actions | Border only, transparent bg |
| `ghost` | Minimal actions | No border, transparent bg |

### Usage

```dart
// Primary button
ModernButton(
  label: 'Add to Cart',
  onPressed: () => addToCart(),
)

// With icon
ModernButton(
  label: 'Checkout',
  icon: Icons.shopping_cart,
  onPressed: () => navigateToCheckout(),
)

// Loading state
ModernButton(
  label: 'Processing...',
  isLoading: true,
  onPressed: null, // Disabled while loading
)

// Secondary variant
ModernButton(
  label: 'Cancel',
  variant: ModernButtonVariant.secondary,
  onPressed: () => Navigator.pop(context),
)

// Outline variant
ModernButton(
  label: 'View Details',
  variant: ModernButtonVariant.outline,
  onPressed: () => viewDetails(),
)

// Full width
ModernButton(
  label: 'Place Order',
  width: double.infinity,
  onPressed: () => placeOrder(),
)

// With semantic label (for E2E)
ModernButton(
  label: 'Add to Cart',
  semanticLabel: 'btn-add-to-cart',
  onPressed: () => addToCart(),
)
```

### Styling Details

- **Primary**: `DesignTokens.primaryGradient` background
- **Secondary**: `DesignTokens.primary` solid
- **Outline**: `DesignTokens.primary` border, `Colors.transparent` bg
- **Ghost**: `Colors.transparent` bg, `DesignTokens.textPrimary` text

---

## ModernTextField

Dark-themed input field with validation and semantic labels.

### Properties

```dart
class ModernTextField extends StatelessWidget {
  const ModernTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final String? semanticLabel;
}
```

### Usage

```dart
// Basic input
ModernTextField(
  controller: _emailController,
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
)

// Password input
ModernTextField(
  controller: _passwordController,
  label: 'Password',
  obscureText: true,
  suffixIcon: IconButton(
    icon: Icon(Icons.visibility),
    onPressed: () => togglePasswordVisibility(),
  ),
)

// With validation
ModernTextField(
  controller: _nameController,
  label: 'Full Name',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  },
)

// Multiline
ModernTextField(
  controller: _bioController,
  label: 'Bio',
  maxLines: 4,
  maxLength: 500,
)

// With semantic label
ModernTextField(
  controller: _searchController,
  semanticLabel: 'input-search',
  onChanged: (value) => performSearch(value),
)
```

---

## ModernCard

Elevated card container with consistent styling.

### Properties

```dart
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.spacing16),
    this.margin,
    this.color,
    this.borderRadius = DesignTokens.radius16,
    this.elevation = DesignTokens.shadowMd,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow> elevation;
  final VoidCallback? onTap;
  final BoxBorder? border;
}
```

### Usage

```dart
// Basic card
ModernCard(
  child: Text('Card content'),
)

// Interactive card
ModernCard(
  onTap: () => navigateToDetail(),
  child: Column(
    children: [
      Text('Title'),
      Text('Subtitle'),
    ],
  ),
)

// With custom styling
ModernCard(
  padding: const EdgeInsets.all(DesignTokens.spacing24),
  borderRadius: DesignTokens.radius24,
  child: YourContent(),
)

// Dark mode aware
ModernCard(
  color: Theme.of(context).brightness == Brightness.dark
      ? DesignTokens.darkCard
      : DesignTokens.white,
  child: YourContent(),
)
```

---

## ModernAppBar

Screen header with gradient and consistent styling.

### Properties

```dart
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
}
```

### Usage

```dart
// Basic app bar
Scaffold(
  appBar: ModernAppBar(
    title: 'Products',
  ),
  body: ProductList(),
)

// With actions
Scaffold(
  appBar: ModernAppBar(
    title: 'Cart',
    actions: [
      IconButton(
        icon: Badge(
          label: Text('3'),
          child: Icon(Icons.shopping_cart),
        ),
        onPressed: () => navigateToCart(),
      ),
    ],
  ),
  body: ProductList(),
)

// Without back button
Scaffold(
  appBar: ModernAppBar(
    title: 'Home',
    showBackButton: false,
  ),
  body: HomeContent(),
)
```

---

## ModernProductCard

Product display card for grids and lists.

### Properties

```dart
class ModernProductCard extends ConsumerWidget {
  const ModernProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.showSeller = true,
    this.layout = ProductCardLayout.grid,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;
  final bool showSeller;
  final ProductCardLayout layout; // grid, list
}
```

### Usage

```dart
// Grid view
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.7,
  ),
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ModernProductCard(
      product: products[index],
      onTap: () => navigateToDetail(products[index].id),
      onFavorite: () => toggleFavorite(products[index].id),
    );
  },
)

// List view
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ModernProductCard(
      product: products[index],
      layout: ProductCardLayout.list,
      onTap: () => navigateToDetail(products[index].id),
    );
  },
)
```

---

## FreeShippingBar

Progress bar showing progress toward free shipping threshold.

### Properties

```dart
class FreeShippingBar extends StatelessWidget {
  const FreeShippingBar({
    super.key,
    required this.subtotalCents,
    required this.thresholdCents,
  });

  final int subtotalCents;
  final int thresholdCents; // Default: BusinessRules.freeShippingThresholdCents
}
```

### Usage

```dart
// In cart screen
Column(
  children: [
    FreeShippingBar(
      subtotalCents: cartTotal.subtotalCents,
      thresholdCents: BusinessRules.freeShippingThresholdCents,
    ),
    SizedBox(height: DesignTokens.spacing16),
    CartItemsList(),
  ],
)
```

### Display Logic

- If `subtotalCents >= thresholdCents`: "You qualify for FREE shipping! 🎉"
- If `subtotalCents < thresholdCents`: "Add $X more for FREE shipping"
- Progress bar: `subtotalCents / thresholdCents` (capped at 1.0)

---

## RatingDialog

Star rating input dialog for product reviews.

### Usage

```dart
// Show rating dialog
final result = await showDialog<RatingResult>(
  context: context,
  builder: (context) => RatingDialog(
    productId: product.id,
    productName: product.name,
  ),
);

if (result != null) {
  // result.rating: 1-5 stars
  // result.review: Optional text review
  await submitReview(result);
}
```

---

## Animations

### AnimatedListItem

Animates list items on first appearance.

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return AnimatedListItem(
      index: index,
      child: ProductCard(product: items[index]),
    );
  },
)
```

### TapScaleAnimation

Scale animation on tap (button-like feedback).

```dart
TapScaleAnimation(
  onTap: () => handleTap(),
  child: Container(
    child: Text('Tap me'),
  ),
)
```

---

## ModernLoadingIndicator

Animated loading spinner.

### Usage

```dart
// Default
ModernLoadingIndicator()

// Custom size
ModernLoadingIndicator(size: 32.0)

// Custom color
ModernLoadingIndicator(
  color: DesignTokens.primary,
)
```

---

## GlassContainer

Glassmorphism overlay container.

### Usage

```dart
// Over image
Stack(
  children: [
    Image.network('background.jpg'),
    GlassContainer(
      child: Text('Overlay text'),
    ),
  ],
)

// Custom parameters
GlassContainer(
  blur: 20,
  opacity: 0.7,
  borderRadius: BorderRadius.circular(DesignTokens.radius24),
  padding: const EdgeInsets.all(DesignTokens.spacing32),
  child: YourContent(),
)
```

---

## Accessibility (Semantics)

All widgets support semantic labels for E2E testing:

```dart
// Button
ModernButton(
  label: 'Add to Cart',
  semanticLabel: 'btn-add-to-cart',  // E2E: await page.locator('[aria-label="btn-add-to-cart"]')
  onPressed: () {},
)

// Input
ModernTextField(
  controller: _controller,
  semanticLabel: 'input-email',  // E2E: await page.locator('[aria-label="input-email"]')
)

// Product card
ModernProductCard(
  product: product,
  semanticLabel: 'product-card-${product.id}',  // E2E: await page.locator('[aria-label="product-card-123"]')
)
```

### Semantic Naming Convention

| Pattern | Example | E2E Selector |
|---------|---------|--------------|
| `btn-*` | `btn-add-to-cart` | `[aria-label="btn-add-to-cart"]` |
| `input-*` | `input-search` | `[aria-label="input-search"]` |
| `nav-*` | `nav-home` | `[aria-label="nav-home"]` |
| `product-card-*` | `product-card-123` | `[aria-label="product-card-123"]` |

---

## Dark Mode Support

All widgets automatically adapt to theme:

```dart
// In widget build()
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    color: isDark ? DesignTokens.darkCard : DesignTokens.white,
    child: Text(
      'Content',
      style: TextStyle(
        color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
      ),
    ),
  );
}
```

---

## Best Practices

### 1. Always Use DesignTokens

```dart
// ❌ Wrong
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
  ),
)

// ✅ Correct
Container(
  padding: EdgeInsets.all(DesignTokens.spacing16),
  decoration: BoxDecoration(
    color: DesignTokens.primary,
    borderRadius: BorderRadius.circular(DesignTokens.radius12),
  ),
)
```

### 2. Add Semantics for E2E

```dart
// ✅ Always add semantic labels to interactive elements
ModernButton(
  label: 'Submit',
  semanticLabel: 'btn-submit-order',
  onPressed: () {},
)
```

### 3. Support Dark Mode

```dart
// ✅ Check theme and use appropriate tokens
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    color: isDark ? DesignTokens.darkSurface : DesignTokens.surface,
  );
}
```

---

## Quick Reference

| Widget | Use | Key Properties |
|--------|-----|----------------|
| `ModernButton` | Actions | `label`, `variant`, `icon`, `isLoading` |
| `ModernTextField` | Inputs | `controller`, `label`, `validator` |
| `ModernCard` | Containers | `child`, `padding`, `onTap` |
| `ModernAppBar` | Headers | `title`, `actions`, `showBackButton` |
| `ModernProductCard` | Products | `product`, `layout`, `onTap` |
| `FreeShippingBar` | Cart progress | `subtotalCents`, `thresholdCents` |
| `ModernLoadingIndicator` | Loading | `size`, `color` |
| `GlassContainer` | Glassmorphism | `blur`, `opacity`, `child` |

---

*Last updated: 2026-03-25 | Source: `lib/widgets/*.dart`*
