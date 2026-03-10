// coverage:ignore-file
import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'admin_repository.dart';

/// OrignaBase admin repository.
class OrignaBaseAdminRepository implements AdminRepository {
  final OrignaBase _ob;

  OrignaBaseAdminRepository(this._ob);

  String _requireCurrentUserId() {
    final userId = _ob.auth.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Authentication required');
    }
    return userId;
  }

  // ---------------------------------------------------------------------------
  // OrignaBase HTTP endpoint mappings
  // ---------------------------------------------------------------------------

  @override
  Future<void> approveProduct(String productId) async {
    await _ob.request('POST', '/api/admin/approve-product', body: {
      Fields.productId: productId,
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _ob.request('POST', '/api/products/delete', body: {
      Fields.productId: productId,
    });
  }

  @override
  Future<void> disableAdminMfa(String code) async {
    final adminUserId = _requireCurrentUserId();
    await _ob.request('POST', '/api/admin/mfa/disable', body: {
      'userId': adminUserId,
      ApiKeys.code: code,
    });
  }

  @override
  Future<Map<String, dynamic>> enableAdminMfa() async {
    final adminUserId = _requireCurrentUserId();
    final result = await _ob.request('POST', '/api/admin/mfa/enroll', body: {
      'userId': adminUserId,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<UserModel?> fetchUserById(String userId) async {
    final doc = await _ob.collection(Collections.users).doc(userId).get();
    if (doc == null || !doc.exists) return null;
    return UserModel.fromMap({Fields.uid: doc.id, ...doc.data});
  }

  @override
  Future<Map<String, dynamic>> getPaymentProviders() async {
    final adminUserId = _requireCurrentUserId();
    final result =
        await _ob.request('POST', '/api/payments/providers/list', body: {
          'adminUserId': adminUserId,
        });
    final data = Map<String, dynamic>.from(result as Map);
    final providers = data[ApiKeys.providers];
    if (providers is List) {
      final normalized = <String, dynamic>{};
      for (final item in providers) {
        if (item is! Map) continue;
        final provider = Map<String, dynamic>.from(item);
        final id = provider['name']?.toString();
        if (id == null || id.isEmpty) continue;
        final configured = provider['webhookConfigured'] == true;
        normalized[id] = <String, dynamic>{
          ApiKeys.enabled: provider[ApiKeys.enabled] == true,
          ApiKeys.configured: configured,
          ApiKeys.missingKeys: configured ? const <String>[] : <String>['webhook'],
          'mode': provider['mode'],
        };
      }
      return {ApiKeys.success: data[ApiKeys.success] == true, ApiKeys.providers: normalized};
    }
    return data;
  }

  @override
  Future<void> flagReview(String reviewId, {required bool flagged}) async {
    await _ob.request('POST', '/api/admin/flag-review', body: {
      Fields.reviewId: reviewId,
      Fields.flagged: flagged,
    });
  }

  @override
  Future<void> refundOrder(String orderId,
      {String reason = 'Admin refund'}) async {
    await _ob.request('POST', '/api/orders/refunds/item', body: {
      Fields.orderId: orderId,
      Fields.reason: reason,
    });
  }

  @override
  Future<void> rejectProduct(String productId, String reason) async {
    await _ob.request('POST', '/api/admin/reject-product', body: {
      Fields.productId: productId,
      Fields.reason: reason,
    });
  }

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {
    if (suspended) {
      await _ob.request('POST', '/api/admin/suspend-seller', body: {
        Fields.sellerId: userId,
        ApiKeys.reason: 'Suspended by admin',
      });
    } else {
      await _ob.request('POST', '/api/admin/unsuspend-seller', body: {
        Fields.sellerId: userId,
        ApiKeys.reason: 'Unsuspended by admin',
      });
    }
  }

  @override
  Future<void> updatePaymentProvider(String provider, bool enabled,
      {String? reason}) async {
    final adminUserId = _requireCurrentUserId();
    await _ob.request('POST', '/api/payments/providers/update', body: {
      'adminUserId': adminUserId,
      'providerName': provider,
      ApiKeys.enabled: enabled,
    });
  }

  @override
  Future<void> updateProductStock(String productId, int quantity) async {
    await _ob.request('POST', '/api/admin/update-stock', body: {
      Fields.productId: productId,
      Fields.stockQuantity: quantity,
    });
  }

  @override
  Future<void> updateUserRoles(String userId,
      {List<String> add = const [],
      List<String> remove = const [],
      String? reason}) async {
    await _ob.request('POST', '/api/admin/update-roles', body: {
      Fields.targetUserId: userId,
      ApiKeys.add: add,
      ApiKeys.remove: remove,
      ApiKeys.reason: reason ?? 'No reason provided',
    });
  }

  @override
  Future<Map<String, dynamic>> verifyAdminMfa(String code) async {
    final adminUserId = _requireCurrentUserId();
    final result = await _ob.request('POST', '/api/admin/mfa/verify', body: {
      'userId': adminUserId,
      ApiKeys.code: code,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _ob.request('POST', '/api/admin/delete-review', body: {
      Fields.reviewId: reviewId,
    });
  }

  // ---------------------------------------------------------------------------
  // Realtime streams (polling-based until OrignaBase supports query snapshots)
  // ---------------------------------------------------------------------------

  static const _pollInterval = Duration(seconds: 5);

  @override
  Stream<List<OrderModel>> watchOrders({String? status, int limit = 50}) {
    return _poll<OrderModel>(
      fetch: () async {
        var query = _ob
            .collection(Collections.orders)
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit);
        if (status != null && status != FilterValues.all) {
          query = query.where(Fields.orderStatus, isEqualTo: status);
        }
        final snapshot = await query.get();
        return snapshot.docs.map((doc) {
          return OrderModel.fromMap({Fields.orderId: doc.id, ...doc.data});
        }).toList();
      },
    );
  }

  @override
  Stream<List<ProductModel>> watchProducts(
      {int limit = 100, String? sellerId}) {
    return _poll<ProductModel>(
      fetch: () async {
        Query query = _ob.collection(Collections.products);
        if (sellerId != null && sellerId.isNotEmpty) {
          query = query.where(Fields.sellerId, isEqualTo: sellerId);
        }
        final snapshot = await query
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit)
            .get();
        return snapshot.docs.map((doc) {
          return ProductModel.fromMap(
              {Fields.productId: doc.id, ...doc.data});
        }).toList();
      },
    );
  }

  @override
  Stream<List<ProductModel>> watchPendingReviewProducts({int limit = 200}) {
    return _poll<ProductModel>(
      fetch: () async {
        final snapshot = await _ob
            .collection(Collections.products)
            .where(Fields.lifecycleStatus,
                isEqualTo: ProductLifecycleStatusValues.underReview)
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit)
            .get();
        return snapshot.docs.map((doc) {
          return ProductModel.fromMap(
              {Fields.productId: doc.id, ...doc.data});
        }).toList();
      },
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchReviews(
      {bool flaggedOnly = false, bool hasPhotosOnly = false, int limit = 100}) {
    return _poll<Map<String, dynamic>>(
      fetch: () async {
        Query query = _ob.collection(Collections.productRatings);
        if (flaggedOnly) {
          query = query.where(Fields.isFlagged, isEqualTo: true);
        }
        if (hasPhotosOnly) {
          query = query.where(Fields.hasPhotos, isEqualTo: true);
        }
        final snapshot = await query
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit)
            .get();
        return snapshot.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data})
            .toList();
      },
    );
  }

  @override
  Stream<List<UserModel>> watchSellers({int limit = 100}) {
    return _poll<UserModel>(
      fetch: () async {
        final snapshot = await _ob
            .collection(Collections.users)
            .where(Fields.roles, contains: UserRoleValues.seller)
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit)
            .get();
        return snapshot.docs
            .map((doc) =>
                UserModel.fromMap({Fields.uid: doc.id, ...doc.data}))
            .toList();
      },
    );
  }

  @override
  Stream<List<UserModel>> watchUsers({int limit = 100}) {
    return _poll<UserModel>(
      fetch: () async {
        final snapshot = await _ob
            .collection(Collections.users)
            .orderBy(Fields.createdAt, descending: true)
            .limit(limit)
            .get();
        return snapshot.docs
            .map((doc) =>
                UserModel.fromMap({Fields.uid: doc.id, ...doc.data}))
            .toList();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Generic polling helper
  // ---------------------------------------------------------------------------
  Stream<List<T>> _poll<T>({required Future<List<T>> Function() fetch}) {
    late StreamController<List<T>> controller;
    Timer? timer;

    Future<void> doFetch() async {
      try {
        final results = await fetch();
        if (!controller.isClosed) controller.add(results);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<T>>(
      onListen: () {
        doFetch();
        timer = Timer.periodic(_pollInterval, (_) => doFetch());
      },
      onCancel: () => timer?.cancel(),
    );

    return controller.stream;
  }
}
