import 'dart:async';
import 'dart:math';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show ApiEndpoints, BusinessRules, Collections, Fields, PolicyVersionValues;
import 'package:origna_gta/models/generated/base_models.dart' show UserRole;
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:uuid/uuid.dart';

/// OrignaBase implementation of [UserRepository].
///
/// User profile watching uses OrignaBase document-level `.snapshots()`.
/// Address subcollection uses collection-level `.snapshots()`.
/// Seller account status uses polling since it combines two collections.
class OrignaBaseUserRepository implements UserRepository {
  final OrignaBase _ob;

  OrignaBaseUserRepository(this._ob);

  // ---------------------------------------------------------------------------
  // Auth helper
  // ---------------------------------------------------------------------------

  String? get _currentUserId {
    return _ob.auth.currentUserId;
  }

  /// Strip SurrealDB collection prefix from an ID so it can be used as a
  /// document key in a *different* collection.
  ///
  /// `"users:abc123"` → `"abc123"`;  `"abc123"` → `"abc123"`.
  static String _bareId(String id) {
    final idx = id.indexOf(':');
    return idx >= 0 ? id.substring(idx + 1) : id;
  }

  // ---------------------------------------------------------------------------
  // Address CRUD (direct OrignaBase operations)
  // ---------------------------------------------------------------------------

  @override
  Future<String> addBuyerAddress(Address address) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final addressId = const Uuid().v4().replaceAll('-', '');
    final docRef = _ob.collection(Collections.addresses).doc(addressId);

    final created = await docRef.set({
      Fields.userId: userId,
      ..._addressPayload(address),
    });
    if (created == null) {
      throw OrignaBaseException(
        'Failed to create address — permission denied or internal error',
      );
    }

    if (address.isDefault) {
      await _clearOtherDefaultAddresses(userId, addressId);
    }

    return addressId;
  }

  @override
  Future<void> deleteBuyerAddress(String addressId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final docRef = _ob.collection(Collections.addresses).doc(addressId);
    final doc = await docRef.get();

    if (doc != null && doc.exists && doc.data[Fields.userId] == userId) {
      await docRef.delete();
    } else {
      throw Exception('Address not found or unauthorized');
    }
  }

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async {
    final userDoc = await _ob.collection(Collections.users).doc(userId).get();
    final spDoc = await _ob
        .collection(Collections.sellerProfiles)
        .doc(_bareId(userId))
        .get();
    return _parseSellerStatus(
      userDoc?.exists == true ? userDoc!.data : null,
      spDoc?.exists == true ? spDoc!.data : null,
    );
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _ob.request(
      'POST',
      ApiEndpoints.usersProfileGet,
      body: {Fields.userId: userId},
    );
    final data = Map<String, dynamic>.from(response as Map);
    if (data['success'] != true) return null;
    final profile = Map<String, dynamic>.from(data)..remove('success');
    if (profile.isEmpty) return null;
    profile.putIfAbsent(Fields.uid, () => userId);
    final address = profile[Fields.address];
    if (address is Map<String, dynamic>) {
      profile[Fields.address] = {...address, Fields.userId: userId};
    }
    return UserModel.fromMap(profile);
  }

  @override
  Future<void> recordTermsAcceptance() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }
    final response = await _ob.request(
      'POST',
      ApiEndpoints.usersProfileUpdate,
      body: {
        Fields.userId: userId,
        Fields.termsAcceptedAt: true,
        Fields.termsVersion: PolicyVersionValues.defaultVersion,
      },
    );
    final data = Map<String, dynamic>.from(response as Map);
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to record terms acceptance');
    }
  }

  @override
  Future<void> setDefaultBuyerAddress(String addressId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final docRef = _ob.collection(Collections.addresses).doc(addressId);
    final doc = await docRef.get();

    if (doc != null && doc.exists && doc.data[Fields.userId] == userId) {
      await docRef.update({Fields.isDefault: true});
      await _clearOtherDefaultAddresses(userId, addressId);
    } else {
      throw Exception('Address not found or unauthorized');
    }
  }

  Future<void> _clearOtherDefaultAddresses(
    String userId,
    String exceptAddressId,
  ) async {
    try {
      final snapshot = await _ob
          .collection(Collections.addresses)
          .where(Fields.userId, isEqualTo: userId)
          .where(Fields.isDefault, isEqualTo: true)
          .limit(BusinessRules.addressesPageSize)
          .get();

      // doc.id may include collection prefix (e.g., "addresses:abc123").
      // Strip it so comparison works regardless of whether exceptAddressId
      // was passed as a bare ID or a full path.
      final bareExcept = _bareId(exceptAddressId).replaceAll('`', '');

      for (final doc in snapshot.docs) {
        final bareDocId = _bareId(doc.id).replaceAll('`', '');
        if (bareDocId != bareExcept) {
          await _ob.collection(Collections.addresses).doc(bareDocId).update({
            Fields.isDefault: false,
          });
        }
      }
    } catch (e) {
      // Best effort to clear other defaults
      AppLogger.w(
        'Warning: failed to clear other default addresses: $e',
        tag: 'user',
      );
    }
  }

  Map<String, dynamic> _addressPayload(Address address) {
    return {
      'street': address.street,
      'city': address.city,
      'province': address.state,
      'postalCode': address.postalCode,
      'country': address.country,
      'label': address.label,
      'isDefault': address.isDefault,
    };
  }

  Address _parseAddressDocument(Map<String, dynamic> doc, {String? docId}) {
    // Strip collection prefix from docId (e.g., "addresses:abc123" → "abc123")
    // and backticks that SurrealDB adds around UUIDs (e.g., "`abc-123`" → "abc-123").
    final bareDocId = docId != null ? _bareId(docId).replaceAll('`', '') : null;

    final rawAddress = doc[Fields.address];
    if (rawAddress is Map<String, dynamic>) {
      final merged = <String, dynamic>{...rawAddress};
      if (doc.containsKey('label')) merged['label'] = doc['label'];
      if (doc.containsKey('isDefault'))
        merged[Fields.isDefault] = doc['isDefault'];
      return Address.fromMap(merged, docId: bareDocId);
    }
    return Address.fromMap(doc, docId: bareDocId);
  }

  @override
  Future<void> updateBuyerAddress(String addressId, Address address) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final docRef = _ob.collection(Collections.addresses).doc(addressId);
    final doc = await docRef.get();

    if (doc != null && doc.exists && doc.data[Fields.userId] == userId) {
      await docRef.update(_addressPayload(address));
      if (address.isDefault) {
        await _clearOtherDefaultAddresses(userId, addressId);
      }
    } else {
      throw Exception('Address not found or unauthorized');
    }
  }

  @override
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  }) async {
    final updates = <String, dynamic>{Fields.userId: userId};
    if (notifyNewProducts != null) {
      updates[Fields.notifyNewProducts] = notifyNewProducts;
    }
    if (notifyTrending != null) updates[Fields.notifyTrending] = notifyTrending;
    if (updates.length == 1) return;
    final response = await _ob.request(
      'POST',
      ApiEndpoints.usersNotificationPreferences,
      body: updates,
    );
    final data = Map<String, dynamic>.from(response as Map);
    if (data['success'] != true) {
      throw Exception(
        data['error'] ?? 'Failed to update notification preferences',
      );
    }
  }

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {
    final response = await _ob.request(
      'POST',
      ApiEndpoints.usersProfileUpdate,
      body: {Fields.userId: userId, Fields.preferredLanguage: lang},
    );
    final data = Map<String, dynamic>.from(response as Map);
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to update language preference');
    }
  }

  @override
  Stream<List<Address>> watchAddresses(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    late StreamController<List<Address>> controller;
    Timer? timer;
    var delay = const Duration(seconds: 5);
    // ignore: prefer_function_declarations_over_variables
    late void Function() schedule;
    schedule = () {
      timer = Timer(delay, () async {
        try {
          final snapshot = await _ob
              .collection(Collections.addresses)
              .where(Fields.userId, isEqualTo: userId)
              .limit(limit)
              .offset(offset)
              .get();
          final values = snapshot.docs
              .map((doc) => _parseAddressDocument(doc.data, docId: doc.id))
              .toList();
          values.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
          delay = const Duration(seconds: 5); // reset on success
          if (!controller.isClosed) controller.add(values);
        } catch (e) {
          delay = Duration(seconds: min(delay.inSeconds * 2, 60));
          if (!controller.isClosed) controller.addError(e);
        }
        if (!controller.isClosed) schedule();
      });
    };

    Future<void> fetchOnce() async {
      try {
        final snapshot = await _ob
            .collection(Collections.addresses)
            .where(Fields.userId, isEqualTo: userId)
            .limit(limit)
            .offset(offset)
            .get();
        final values = snapshot.docs
            .map((doc) => _parseAddressDocument(doc.data, docId: doc.id))
            .toList();
        values.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
        delay = const Duration(seconds: 5);
        if (!controller.isClosed) controller.add(values);
      } catch (e) {
        delay = Duration(seconds: min(delay.inSeconds * 2, 60));
        if (!controller.isClosed) controller.addError(e);
      }
      if (!controller.isClosed) schedule();
    }

    controller = StreamController<List<Address>>(
      onListen: () => fetchOnce(),
      onCancel: () => timer?.cancel(),
    );

    return controller.stream;
  }

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) {
    // OrignaBase supports document-level snapshots. Combine user doc and
    // seller_profiles doc into a single stream using polling, since we need
    // to watch two separate top-level collections.
    late StreamController<SellerAccountStatus> controller;
    Timer? timer;
    var delay = const Duration(seconds: 5);

    // ignore: prefer_function_declarations_over_variables
    late void Function() schedule;
    schedule = () {
      timer = Timer(delay, () async {
        try {
          final userDoc = await _ob
              .collection(Collections.users)
              .doc(userId)
              .get();
          final spDoc = await _ob
              .collection(Collections.sellerProfiles)
              .doc(_bareId(userId))
              .get();
          final status = _parseSellerStatus(
            userDoc?.exists == true ? userDoc!.data : null,
            spDoc?.exists == true ? spDoc!.data : null,
          );
          delay = const Duration(seconds: 5); // reset on success
          if (!controller.isClosed) controller.add(status);
        } catch (e) {
          delay = Duration(seconds: min(delay.inSeconds * 2, 60));
          if (!controller.isClosed) controller.addError(e);
        }
        if (!controller.isClosed) schedule();
      });
    };

    Future<void> fetchOnce() async {
      try {
        final userDoc = await _ob
            .collection(Collections.users)
            .doc(userId)
            .get();
        final spDoc = await _ob
            .collection(Collections.sellerProfiles)
            .doc(_bareId(userId))
            .get();
        final status = _parseSellerStatus(
          userDoc?.exists == true ? userDoc!.data : null,
          spDoc?.exists == true ? spDoc!.data : null,
        );
        delay = const Duration(seconds: 5);
        if (!controller.isClosed) controller.add(status);
      } catch (e) {
        delay = Duration(seconds: min(delay.inSeconds * 2, 60));
        if (!controller.isClosed) controller.addError(e);
      }
      if (!controller.isClosed) schedule();
    }

    controller = StreamController<SellerAccountStatus>(
      onListen: () => fetchOnce(),
      onCancel: () => timer?.cancel(),
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  SellerAccountStatus _parseSellerStatus(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? spData,
  ) {
    final rawRoles = userData?[Fields.roles] as Iterable? ?? const [];
    final roles = rawRoles
        .map((r) => r is UserRole ? r.name : r.toString())
        .toList();
    final isSeller =
        roles.contains(UserRoleValues.seller) ||
        roles.contains(UserRoleValues.admin);
    final chargesEnabled = spData?[Fields.chargesEnabled] == true;
    final payoutsEnabled = spData?[Fields.payoutsEnabled] == true;
    final onboardingCompleted = spData?[Fields.onboardingCompleted] == true;
    final pendingRequirements = List<String>.from(
      spData?[Fields.pendingRequirements] as Iterable? ?? const <String>[],
    );
    return SellerAccountStatus(
      isSeller: isSeller,
      chargesEnabled: chargesEnabled && payoutsEnabled,
      detailsSubmitted: onboardingCompleted,
      hasPendingRequirements: pendingRequirements.isNotEmpty,
      pendingRequirements: pendingRequirements,
    );
  }
}
