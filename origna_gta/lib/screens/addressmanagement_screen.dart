import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/profile/address_management_viewmodel.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Address book manager: add, edit, delete, set default shipping address.
class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesProvider);
    final viewModelIsLoading = ref.watch(
      addressManagementViewModelProvider.select((a) => a.isLoading),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(addressManagementViewModelProvider, (
      _,
      state,
    ) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.error.toString(),
              style: const TextStyle(color: DesignTokens.white),
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // ADDR-L1: disable add button client-side when at the 10-address limit
    final addressCount = addressesAsync.valueOrNull?.length ?? 0;
    final atAddressLimit = addressCount >= 10;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.custom(
          title: 'profile.addresses'.tr(),
          subtitle: 'address.count_subtitle'.tr(
            namedArgs: {'count': addressCount.toString(), 'max': '10'},
          ),
          actions: [
            Semantics(
              button: true,
              label: 'btn-add-address',
              child: IconButton(
                icon: const Icon(Icons.add, color: DesignTokens.white),
                tooltip: atAddressLimit
                    ? 'address.limit_reached'.tr()
                    : 'address.add_address'.tr(),
                onPressed: atAddressLimit
                    ? null
                    : () => appPushNamed(context,
                        AppRoutes.addEditAddress,
                      ),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.transparent,
        body: Stack(
          children: [
            addressesAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          DesignTokens.primaryGradient.createShader(bounds),
                      child: const ModernLoadingIndicator(
                        strokeWidth: 3,
                        color: DesignTokens.white,
                        centered: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'address.loading'.tr(),
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => AnimatedEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'address.error_loading'.tr(),
                subtitle: '$error',
              ),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return AnimatedEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'address.no_address'.tr(),
                    subtitle: 'address.add_to_speed_up'.tr(),
                    action: SizedBox(
                      width: 220,
                      child: Semantics(
                        button: true,
                        label: 'btn-add-address',
                        child: ModernButton(
                          key: const Key('btn_add_address'),
                          label: 'address.add_address'.tr(),
                          icon: Icons.add_location_alt_outlined,
                          onPressed: () {
                            appPushNamed(context,
                              AppRoutes.addEditAddress,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(DesignTokens.spacing20),
                      itemCount: addresses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: index * 100),
                          child: _buildAddressCard(
                            context,
                            ref,
                            addresses[index],
                            isDark,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            if (viewModelIsLoading)
              Container(
                color: DesignTokens.black.withValues(alpha: 0.3),
                child: const Center(
                  child: ModernLoadingIndicator(
                    strokeWidth: 4,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    WidgetRef ref,
    Address address,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5)
            : DesignTokens.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(
          color: address.isDefault
              ? DesignTokens.primary
              : isDark
              ? DesignTokens.white.withValues(alpha: 0.08)
              : DesignTokens.primary.withValues(alpha: 0.15),
          width: address.isDefault ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (address.label != null && address.label!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.primary.withValues(alpha: 0.15),
                            DesignTokens.secondary.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radius12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            address.label == AddressLabelValues.home
                                ? Icons.home_outlined
                                : address.label == AddressLabelValues.work
                                ? Icons.business_outlined
                                : Icons.location_on_outlined,
                            size: 14,
                            color: DesignTokens.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            address.label!,
                            style: const TextStyle(
                              color: DesignTokens.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radius8,
                        ),
                        border: Border.all(
                          color: DesignTokens.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'address.default'.tr(),
                        style: const TextStyle(
                          color: DesignTokens.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? DesignTokens.white.withValues(alpha: 0.7)
                      : DesignTokens.black.withValues(alpha: 0.54),
                ),
                onSelected: (value) async {
                  HapticFeedback.lightImpact();
                  if (value == 'edit') {
                    appPushNamed(context,
                      AppRoutes.addEditAddress,
                      arguments: address,
                    );
                  } else if (value == 'delete') {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('common.confirm_delete'.tr()),
                        content: Text('address.delete_confirmation'.tr()),
                        actions: [
                          Semantics(
                            button: true,
                            label: 'btn-cancel-delete-address',
                            child: TextButton(
                              onPressed: () => appPop(context, false),
                              child: Text('common.cancel'.tr()),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'btn-confirm-delete-address',
                            child: TextButton(
                              onPressed: () => appPop(context, true),
                              child: Text(
                                'common.delete'.tr(),
                                style: const TextStyle(
                                  color: DesignTokens.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (address.addressId != null) {
                        ref
                            .read(addressManagementViewModelProvider.notifier)
                            .deleteAddress(address.addressId!);
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('address.delete_failed'.tr()),
                            backgroundColor: DesignTokens.error,
                          ),
                        );
                      }
                    }
                  } else if (value == 'set_default') {
                    if (address.addressId != null) {
                      ref
                          .read(addressManagementViewModelProvider.notifier)
                          .setDefaultAddress(address.addressId!);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: DesignTokens.primary,
                        ),
                        const SizedBox(width: 12),
                        Text('common.edit'.tr()),
                      ],
                    ),
                  ),
                  if (!address.isDefault)
                    PopupMenuItem(
                      value: 'set_default',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: DesignTokens.success,
                          ),
                          const SizedBox(width: 12),
                          Text('address.set_as_default'.tr()),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: DesignTokens.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'common.delete'.tr(),
                          style: const TextStyle(color: DesignTokens.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.white.withValues(alpha: 0.04)
                  : DesignTokens.surfaceVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: DesignTokens.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address.formattedAddress,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (address.phoneNumber != null &&
              address.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.white.withValues(alpha: 0.04)
                    : DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: DesignTokens.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    address.phoneNumber!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────

// ═══ Widget Previews ═══

final _mockAddresses = [
  Address(
    street: '100 King St W',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5X 1A9',
    country: 'Canada',
  ),
  Address(
    street: '200 Bloor St E',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M4W 1E6',
    country: 'Canada',
  ),
];

Widget _addressManagement() => _addressManagementWithAddresses();

Widget _addressManagementEmpty() => previewScopeLoggedIn(
  extraOverrides: [
    userAddressesProvider.overrideWith((ref) => Stream.value([])),
  ],
  child: AddressManagementScreen(),
);

Widget _addressManagementWithAddresses() => previewScopeLoggedIn(
  extraOverrides: [
    userAddressesProvider.overrideWith((ref) => Stream.value(_mockAddresses)),
  ],
  child: AddressManagementScreen(),
);

@Preview(
  name: 'Address Management — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddressManagementScreenMobile() =>
    previewMobile(child: _addressManagement());

@Preview(
  name: 'Address Management — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewAddressManagementScreenTablet() =>
    previewTablet(child: _addressManagement());

@Preview(
  name: 'Address Management — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddressManagementScreenDesktop() =>
    previewDesktop(child: _addressManagementWithAddresses());

@Preview(
  name: 'Address Management — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewAddressManagementScreenWeb() =>
    previewWeb(child: _addressManagementWithAddresses());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Address Management Light — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddressManagementLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);

@Preview(
  name: 'Address Management Light — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewAddressManagementLightTablet() => previewTablet(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);

@Preview(
  name: 'Address Management Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddressManagementLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);

@Preview(
  name: 'Address Management Light — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewAddressManagementLightWeb() => previewWeb(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);

// ── Empty State Dark ──────────────────────────────────────────────────────────
@Preview(
  name: 'Address Management Empty Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddressManagementEmptyMobile() =>
    previewMobile(child: _addressManagementEmpty());

@Preview(
  name: 'Address Management Empty Dark — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewAddressManagementEmptyTablet() =>
    previewTablet(child: _addressManagementEmpty());

@Preview(
  name: 'Address Management Empty Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddressManagementEmptyDesktop() =>
    previewDesktop(child: _addressManagementEmpty());

@Preview(
  name: 'Address Management Empty Dark — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewAddressManagementEmptyWeb() =>
    previewWeb(child: _addressManagementEmpty());

// ── With Addresses Dark ───────────────────────────────────────────────────────
@Preview(
  name: 'Address Management With Addresses Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddressManagementWithAddrMobile() =>
    previewMobile(child: _addressManagementWithAddresses());

@Preview(
  name: 'Address Management With Addresses Dark — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewAddressManagementWithAddrTablet() =>
    previewTablet(child: _addressManagementWithAddresses());

@Preview(
  name: 'Address Management With Addresses Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddressManagementWithAddrDesktop() =>
    previewDesktop(child: _addressManagementWithAddresses());

@Preview(
  name: 'Address Management With Addresses Dark — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewAddressManagementWithAddrWeb() =>
    previewWeb(child: _addressManagementWithAddresses());

// ── With Addresses Light ──────────────────────────────────────────────────────
@Preview(
  name: 'Address Management With Addresses Light — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddressManagementWithAddrLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);

@Preview(
  name: 'Address Management With Addresses Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddressManagementWithAddrLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _addressManagementWithAddresses(),
);
