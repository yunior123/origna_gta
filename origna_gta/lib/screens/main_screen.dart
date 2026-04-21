import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/models.dart' show UserModel, UserRole;
import 'package:origna_gta/screens/home_screen.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

/// Root scaffold with bottom navigation: Home, Orders, Cart, Profile tabs.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

/// Private provider for MainScreen timeout state
final _mainScreenTimedOutProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _timeoutTimer;
  ProviderSubscription<AsyncValue<UserModel?>>? _userProfileSubscription;

  @override
  Widget build(BuildContext context) {
    final timedOut = ref.watch(_mainScreenTimedOutProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    // If profile loading takes too long, show HomeScreen without profile data
    // User remains logged in (auth session active), just without database profile
    if (timedOut && userProfileAsync.isLoading) {
      return const HomeScreen(userModel: null);
    }

    return userProfileAsync.when(
      // Show HomeScreen immediately - no loading indicator to avoid flash after splash
      loading: () => const HomeScreen(userModel: null),
      error: (error, stack) => const HomeScreen(userModel: null),
      data: (userModel) => HomeScreen(userModel: userModel),
    );
  }

  @override
  void dispose() {
    _userProfileSubscription?.close();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _userProfileSubscription = ref.listenManual(userProfileProvider, (_, next) {
      if ((next.hasValue || next.hasError) &&
          ref.read(_mainScreenTimedOutProvider) &&
          mounted) {
        ref.read(_mainScreenTimedOutProvider.notifier).state = false;
      }
    });
    // Safety timeout: if user profile takes more than 3 seconds, show home anyway
    // This prevents infinite loading if the database is slow or unresponsive
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final userProfileAsync = ref.read(userProfileProvider);
        if (userProfileAsync.isLoading) {
          ref.read(_mainScreenTimedOutProvider.notifier).state = true;
        }
      }
    });
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

const _previewMainImageBase = 'https://fastly.picsum.photos/id';

String _previewMainImage(int id, {int width = 900, int height = 900}) =>
    '$_previewMainImageBase/$id/$width/$height.jpg';

class _PreviewMainHomeRef extends Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PreviewMainHomeViewModel extends HomeViewModel {
  _PreviewMainHomeViewModel() : super(_PreviewMainHomeRef()) {
    state = HomeState(
      products: [
        Product(
          productId: 'main-preview-1',
          sellerId: 'main-preview-seller',
          name: 'Ontario Maple Breakfast Box',
          description:
              'Curated breakfast staples from independent Canadian makers.',
          priceCents: 7400,
          stockQuantity: 12,
          imageUrls: [_previewMainImage(431)],
          categoryId: 1,
          createdAt: DateTime(2026, 3, 12),
          rating: 4.9,
          ratingCount: 132,
          freeShipping: true,
          shipFromCountry: 'CA',
          shipFromCity: 'Toronto',
          shipFromProvince: 'ON',
        ),
        Product(
          productId: 'main-preview-2',
          sellerId: 'main-preview-seller',
          name: 'Montreal Atelier Leather Wallet',
          description:
              'Vegetable-tanned leather wallet with hand-stitched edges.',
          priceCents: 9800,
          stockQuantity: 6,
          imageUrls: [_previewMainImage(1062)],
          categoryId: 5,
          createdAt: DateTime(2026, 3, 22),
          rating: 4.7,
          ratingCount: 41,
          shipFromCountry: 'CA',
          shipFromCity: 'Montreal',
          shipFromProvince: 'QC',
        ),
      ],
      isLoading: false,
      hasMore: false,
      recentSearches: const ['maple syrup', 'gift box', 'artisan wallet'],
    );
  }
}

final _previewMainUser = UserModel(
  uid: 'main-preview-user',
  email: 'main.preview@origna.ca',
  name: 'Jordan Lee',
  roles: const [UserRole.buyer],
  createdAt: DateTime(2026, 1, 5),
  verified: true,
);

Widget _mainScreenPreview({bool loggedIn = false}) {
  final child = const MainScreen();
  final overrides = [
    homeViewModelProvider.overrideWith((ref) => _PreviewMainHomeViewModel()),
  ];
  if (!loggedIn) {
    return previewScope(extraOverrides: overrides, child: child);
  }
  return previewScopeLoggedIn(
    uid: _previewMainUser.uid,
    extraOverrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(_previewMainUser)),
      ...overrides,
    ],
    child: child,
  );
}

@Preview(
  name: 'Main Screen — Mobile',
  group: 'Home Screens',
  size: Size(390, 844),
)
Widget previewMainScreenMobile() => previewMobile(child: _mainScreenPreview());

@Preview(
  name: 'Main Screen — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewMainScreenDesktop() =>
    previewDesktop(child: _mainScreenPreview(loggedIn: true));

@Preview(
  name: 'Main Screen Light — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewMainScreenLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _mainScreenPreview(loggedIn: true),
);
