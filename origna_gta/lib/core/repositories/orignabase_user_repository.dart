// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show ApiEndpoints, Collections, Fields, PolicyVersionValues;
import 'package:origna_gta/utils/constants.dart';
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

  // ---------------------------------------------------------------------------
  // Address CRUD (direct OrignaBase operations)
  // ---------------------------------------------------------------------------

  @override
  Future<String> addBuyerAddress(Address address) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }
    
    final addressId = const Uuid().v4();
    final docRef = _ob.collection(Collections.addresses).doc(addressId);
    
    await docRef.set({
      Fields.userId: userId,
      ..._addressPayload(address),
    });
    
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
        .doc(userId)
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
  
  Future<void> _clearOtherDefaultAddresses(String userId, String exceptAddressId) async {
    try {
      final snapshot = await _ob
          .collection(Collections.addresses)
          .where(Fields.userId, isEqualTo: userId)
          .where(Fields.isDefault, isEqualTo: true)
          .get();
          
      for (final doc in snapshot.docs) {
        if (doc.id != exceptAddressId) {
          await _ob.collection(Collections.addresses).doc(doc.id).update({
            Fields.isDefault: false,
          });
        }
      }
    } catch (e) {
      // Best effort to clear other defaults
      debugPrint('Warning: failed to clear other default addresses: $e');
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
    final rawAddress = doc[Fields.address];
    if (rawAddress is Map<String, dynamic>) {
      final merged = <String, dynamic>{...rawAddress};
      if (doc.containsKey('label')) merged['label'] = doc['label'];
      if (doc.containsKey('isDefault')) merged[Fields.isDefault] = doc['isDefault'];
      return Address.fromMap(merged, docId: docId);
    }
    return Address.fromMap(doc, docId: docId);
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
  Stream<List<Address>> watchAddresses(String userId) {
    late StreamController<List<Address>> controller;
    Timer? timer;

    Future<void> fetch() async {
      try {
        final snapshot = await _ob
            .collection(Collections.addresses)
            .where(Fields.userId, isEqualTo: userId)
            .get();
        final values = snapshot.docs
            .map((doc) => _parseAddressDocument(doc.data, docId: doc.id))
            .toList();
        values.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
        if (!controller.isClosed) {
          controller.add(values);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<List<Address>>(
      onListen: () {
        fetch();
        timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());
      },
      onCancel: () {
        timer?.cancel();
      },
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

    Future<void> fetch() async {
      try {
        final userDoc = await _ob
            .collection(Collections.users)
            .doc(userId)
            .get();
        final spDoc = await _ob
            .collection(Collections.sellerProfiles)
            .doc(userId)
            .get();
        final status = _parseSellerStatus(
          userDoc?.exists == true ? userDoc!.data : null,
          spDoc?.exists == true ? spDoc!.data : null,
        );
        if (!controller.isClosed) {
          controller.add(status);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<SellerAccountStatus>(
      onListen: () {
        fetch();
        timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());
      },
      onCancel: () {
        timer?.cancel();
      },
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
    final roles = List<String>.from(userData?[Fields.roles] ?? const []);
    final isSeller =
        roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin);
    final chargesEnabled = spData?[Fields.chargesEnabled] == true;
    final payoutsEnabled = spData?[Fields.payoutsEnabled] == true;
    final onboardingCompleted = spData?[Fields.onboardingCompleted] == true;
    final pendingRequirements = List<String>.from(
      spData?[Fields.pendingRequirements] ?? const [],
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
