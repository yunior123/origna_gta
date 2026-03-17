/**
 * OrignaGTA — Pure HTTP API Client
 * Extracted from api-helpers.ts for use in Vitest-based agent-browser tests.
 * No Playwright/browser dependencies — pure fetch-based HTTP calls.
 */

import {
  ORIGNABASE_URL,
  TEST_ACCOUNTS,
  TEST_UIDS,
  TEST_PRODUCTS,
  DEFAULT_PASS,
} from './config.js';
import type { AuthData, DiscoveredProduct } from './types.js';
import {
  signIn,
  useOrignaBaseAuth,
} from './auth.js';

// Re-export auth functions so spec files can import everything from api-client
export { signIn, getBootstrapAdminAccessToken, useOrignaBaseAuth, fetchWithRetry } from './auth.js';
export {
  resolveUiEmail,
  ensureOrignaBaseUiAccount,
  setOrignaBaseUserEmailVerified,
  setOrignaBaseUserTermsVersion,
  setOrignaBaseUserSuspended,
  getAuthProviders,
  getPublicConfigValue,
} from './auth.js';

// ════════════════════════════════════════════════════════════════════
// GRAPHQL HELPERS
// ════════════════════════════════════════════════════════════════════

type PathInfo = {
  collection: string;
  id?: string;
  parentId?: string;
  parentCollection?: string;
  docPath: string;
};

export function splitPath(path: string): string[] {
  return path.split('/').map(s => s.trim()).filter(Boolean);
}

export function pathInfo(path: string): PathInfo {
  const parts = splitPath(path);
  if (parts.length < 1 || parts.length % 2 !== 0) throw new Error(`Invalid document path: ${path}`);
  const collections = parts.filter((_, i) => i % 2 === 0);
  const ids = parts.filter((_, i) => i % 2 === 1);
  const collection = collections.join('__');
  const info: PathInfo = { collection, docPath: path };
  if (ids.length > 0) info.id = ids[ids.length - 1];
  if (collections.length > 1) {
    info.parentCollection = collections.slice(0, -1).join('__');
    info.parentId = ids[ids.length - 2];
  }
  return info;
}

export function collectionPathInfo(path: string): PathInfo {
  const parts = splitPath(path);
  if (parts.length < 1 || parts.length % 2 === 0) throw new Error(`Invalid collection path: ${path}`);
  const collections = parts.filter((_, i) => i % 2 === 0);
  const ids = parts.filter((_, i) => i % 2 === 1);
  const info: PathInfo = {
    collection: collections.join('__'),
    docPath: path,
  };
  if (collections.length > 1) {
    info.parentCollection = collections.slice(0, -1).join('__');
    info.parentId = ids[ids.length - 1];
  }
  return info;
}

export function toParentRef(info: PathInfo): string | undefined {
  if (!info.parentCollection || !info.parentId) return undefined;
  return `${info.parentCollection}:${info.parentId}`;
}

export function normalizeFields(fields: Record<string, any>): Record<string, any> {
  const entries = Object.entries(fields || {});
  const looksSurrealDB =
    entries.length > 0 &&
    entries.every(([, value]) =>
      value &&
      typeof value === 'object' &&
      Object.keys(value).some(k =>
        [
          'stringValue',
          'integerValue',
          'doubleValue',
          'booleanValue',
          'nullValue',
          'timestampValue',
          'arrayValue',
          'mapValue',
        ].includes(k)
      )
    );

  if (!looksSurrealDB) return fields;

  const normalized: Record<string, any> = {};
  for (const [k, v] of entries) normalized[k] = parseVal(v);
  return normalized;
}

export function wrapSurrealDBDoc(path: string, data: Record<string, any> | null): any {
  if (!data) return null;
  return {
    name: path,
    fields: toSurrealDBFields(data),
  };
}

export function parseGraphQLValue(value: any): any {
  if (typeof value !== 'string') return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

export async function obGraphQL(query: string, variables: Record<string, any> = {}, token?: string): Promise<any> {
  if (!ORIGNABASE_URL) {
    return {
      ok: false,
      status: 503,
      body: { errors: [{ message: 'OrignaBase URL is not configured for this target environment' }] },
    };
  }
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${ORIGNABASE_URL}/graphql`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  });

  let body: any = {};
  try {
    body = await res.json();
  } catch {
    body = {};
  }

  return { ok: res.ok && !body?.errors, status: res.status, body };
}

// ════════════════════════════════════════════════════════════════════
// CRUD — readDoc, getDoc, writeDoc, deleteDoc, listCollection
// ════════════════════════════════════════════════════════════════════

export async function readDoc(path: string, token?: string): Promise<any> {
  const info = pathInfo(path);
  if (!info.id) return null;
  const query = `
    query GetDoc($collection: String!, $id: String!) {
      get(collection: $collection, id: $id)
    }
  `;
  const result = await obGraphQL(query, { collection: info.collection, id: info.id }, token);
  if (!result.ok) return null;
  const raw = parseGraphQLValue(result.body?.data?.get);
  if (!raw || typeof raw !== 'object') return null;

  if (info.parentCollection && raw.parent_id && raw.parent_id !== toParentRef(info)) {
    return null;
  }

  return wrapSurrealDBDoc(path, raw as Record<string, any>);
}

export async function getDoc(path: string, token?: string): Promise<any> {
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

export async function writeDoc(path: string, fields: Record<string, any>, token?: string, partial = true): Promise<boolean> {
  const info = pathInfo(path);
  if (!info.id) return false;

  const incoming = normalizeFields(fields);
  const parentRef = toParentRef(info);
  const baseData = parentRef ? { ...incoming, parent_id: parentRef, parent_collection: info.parentCollection } : incoming;
  const existingDoc = partial ? (await getDoc(path, token) || {}) : {};
  const { id: _stripId, ...existingClean } = existingDoc as Record<string, any>;
  const finalData = partial ? { ...existingClean, ...baseData } : baseData;

  const mutation = `
    mutation SetDoc($collection: String!, $id: String!, $data: JSON!) {
      set(collection: $collection, id: $id, data: $data)
    }
  `;
  const result = await obGraphQL(mutation, {
    collection: info.collection,
    id: info.id,
    data: finalData,
  }, token);
  return result.ok;
}

export async function deleteDoc(path: string, token?: string): Promise<boolean> {
  const info = pathInfo(path);
  if (!info.id) return false;
  const mutation = `
    mutation DeleteDoc($collection: String!, $id: String!) {
      delete(collection: $collection, id: $id)
    }
  `;
  const result = await obGraphQL(mutation, { collection: info.collection, id: info.id }, token);
  return result.ok;
}

export async function listCollection(collectionPath: string, token?: string): Promise<any[]> {
  const info = collectionPathInfo(collectionPath);
  const filters = toParentRef(info) ? { parent_id: { _eq: toParentRef(info) } } : {};
  const query = `
    query ListDocs($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(query, { collection: info.collection, filters }, token);
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((doc: any) => doc && typeof doc === 'object')
    .map((doc: any) => {
      const { id, _id, _rev, _created, _updated, ...rest } = doc;
      return id ? { id, ...rest } : rest;
    });
}

// ════════════════════════════════════════════════════════════════════
// VALUE CONVERSION
// ════════════════════════════════════════════════════════════════════

export function parseVal(v: any): any {
  if (!v) return null;
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return v.doubleValue;
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.nullValue !== undefined) return null;
  if (v.timestampValue) return v.timestampValue;
  if (v.arrayValue) return (v.arrayValue.values || []).map(parseVal);
  if (v.mapValue) {
    const o: Record<string, any> = {};
    for (const [k, val] of Object.entries((v.mapValue.fields || {}) as Record<string, any>)) {
      o[k] = parseVal(val);
    }
    return o;
  }
  return v;
}

export function parseDoc(doc: any): any {
  if (!doc?.fields) return null;
  const r: Record<string, any> = {};
  for (const [k, v] of Object.entries(doc.fields as Record<string, any>)) {
    r[k] = parseVal(v);
  }
  return r;
}

export function toSurrealDBFields(obj: Record<string, any>): any {
  const f: Record<string, any> = {};
  for (const [k, v] of Object.entries(obj)) f[k] = toFsVal(v);
  return f;
}

export function toFsVal(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toFsVal) } };
  if (typeof v === 'object') return { mapValue: { fields: toSurrealDBFields(v) } };
  return { stringValue: String(v) };
}

// ════════════════════════════════════════════════════════════════════
// CALLABLE FUNCTION INVOCATION
// ════════════════════════════════════════════════════════════════════

export async function callCallable(fn: string, data: any, token: string, timeoutMs = 20_000): Promise<any> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  function decodeJwtPayload(jwt: string): any {
    try {
      const [, payload] = jwt.split('.');
      if (!payload) return {};
      const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
      const pad = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
      return JSON.parse(Buffer.from(`${normalized}${pad}`, 'base64').toString('utf8'));
    } catch {
      return {};
    }
  }

  function tokenUserId(jwt: string): string | undefined {
    const payload = decodeJwtPayload(jwt);
    return payload.user_id || payload.sub || payload.uid;
  }

  function remapSort(sortBy?: string): string | undefined {
    switch (sortBy) {
      case 'price_asc':
      case 'priceLowToHigh':
        return 'priceCents';
      case 'price_desc':
      case 'priceHighToLow':
        return 'priceCents';
      case 'newest':
      case 'relevance':
        return 'createdAt';
      default:
        return undefined;
    }
  }

  function portedRequest(fnName: string, payload: any): { path: string; body: any } | null {
    const userId = tokenUserId(token);
    switch (fnName) {
      case 'create_checkout_session': {
        const { userId: _uid, ...checkoutRest } = payload ?? {};
        return { path: '/api/checkout/session', body: checkoutRest };
      }
      case 'get_user_profile':
        return { path: '/api/users/profile/get', body: { userId } };
      case 'update_user_profile':
        return { path: '/api/users/profile/update', body: { userId, ...payload } };
      case 'create_user_profile':
        return { path: '/api/users/create-profile', body: payload };
      case 'update_email_consent':
        return {
          path: '/api/users/email-consent',
          body: {
            userId,
            consent: Boolean(payload?.consent ?? payload?.emailConsent),
          },
        };
      case 'delete_account':
        return { path: '/api/auth/delete-account', body: payload };
      case 'submit_rating':
        return { path: '/api/products/submit-rating', body: payload };
      case 'ask_question':
        return { path: '/api/products/questions/ask', body: { userId, ...payload } };
      case 'answer_question':
        return { path: '/api/products/questions/answer', body: { userId, ...payload } };
      case 'vote_review_helpful':
        return { path: '/api/products/review-vote', body: { userId, ...payload } };
      case 'get_seller_metrics':
        return {
          path: '/graphql',
          body: {
            query: `query ListDocs($collection: String!, $filters: JSON) { list(collection: $collection, filters: $filters, limit: 50) }`,
            variables: { collection: 'seller_metrics', filters: { sellerId: { _eq: userId } } },
          },
        };
      case 'update_notification_preferences':
        return { path: '/api/users/notification-preferences', body: { userId, ...payload } };
      case 'add_buyer_address':
        return {
          path: '/api/users/address/add',
          body: {
            userId,
            street: payload?.street,
            apartment: payload?.apartment,
            city: payload?.city,
            province: payload?.province ?? payload?.state,
            postalCode: payload?.postalCode,
            country: payload?.country,
            phoneNumber: payload?.phoneNumber,
            label: payload?.label,
            isDefault: payload?.isDefault ?? false,
          },
        };
      case 'update_buyer_address':
        return {
          path: '/api/users/address/update',
          body: {
            userId,
            addressId: payload?.addressId,
            street: payload?.street,
            apartment: payload?.apartment,
            city: payload?.city,
            province: payload?.province ?? payload?.state,
            postalCode: payload?.postalCode,
            country: payload?.country,
            phoneNumber: payload?.phoneNumber,
            label: payload?.label,
            isDefault: payload?.isDefault,
          },
        };
      case 'delete_buyer_address':
        return {
          path: '/api/users/address/delete',
          body: {
            userId,
            addressId: payload?.addressId,
          },
        };
      case 'set_default_buyer_address':
        return {
          path: '/api/users/address/set-default',
          body: {
            userId,
            addressId: payload?.addressId,
          },
        };
      case 'get_mail_logs':
      case 'e2e_get_mail_logs':
        return { path: '/api/admin/mail-logs', body: payload };
      case 'get_products_paginated':
        return {
          path: '/api/products/list',
          body: {
            page: payload?.page ?? 1,
            limit: payload?.limit ?? 20,
            category: payload?.category,
            subcategory: payload?.subcategory,
            sellerId: payload?.sellerId,
            orderBy: remapSort(payload?.sortBy) ?? payload?.orderBy,
            orderDirection:
              payload?.sortBy === 'price_asc'
                ? 'asc'
                : payload?.sortBy === 'price_desc'
                  ? 'desc'
                  : (payload?.orderDirection ?? 'desc'),
            startAfter: payload?.startAfter,
            minPriceCents: payload?.minPriceCents,
            maxPriceCents: payload?.maxPriceCents,
          },
        };
      case 'get_seller_products_paginated':
        return {
          path: '/api/products/seller-list',
          body: {
            sellerId: payload?.sellerId ?? userId,
            page: payload?.page ?? 1,
            limit: payload?.limit ?? 20,
            startAfter: payload?.startAfter,
            includeInactive: payload?.includeInactive ?? false,
          },
        };
      case 'create_product_atomic': {
        if (!userId) return null;
        const {
          productData,
          testImageUrls,
          imageUrls,
          shippingConfig,
          ...rest
        } = payload || {};
        const source = productData && typeof productData === 'object'
          ? { ...productData, ...rest }
          : rest;
        return {
          path: '/api/products/create-atomic',
          body: {
            userId,
            productData: {
              ...source,
              title: source.title ?? source.name,
              name: source.name ?? source.title,
              categoryId: source.categoryId != null ? Number(source.categoryId) : source.categoryId,
              priceCents:
                source.priceCents ??
                (typeof source.price === 'number' ? Math.round(source.price * 100) : undefined),
              lifecycleStatus: source.lifecycleStatus ?? 'active',
              shippingConfig: shippingConfig ?? source.shippingConfig,
            },
            testImageUrls: testImageUrls ?? imageUrls ?? [],
          },
        };
      }
      case 'update_product': {
        if (!userId) return null;
        const { productId, userId: _ignored, ...productData } = payload || {};
        return {
          path: '/api/products/update',
          body: {
            productId,
            userId,
            productData,
          },
        };
      }
      case 'delete_product':
        return {
          path: '/api/products/delete',
          body: {
            productId: payload?.productId,
            userId,
          },
        };
      case 'bulk_update_products':
        return {
          path: '/api/products/bulk-update',
          body: {
            userId,
            productIds: payload?.productIds ?? [],
            action: payload?.action,
            update: payload?.update ?? { lifecycleStatus: payload?.action === 'pause' ? 'inactive' : 'active' },
          },
        };
      case 'admin_approve_product':
        return {
          path: '/api/admin/approve-product',
          body: {
            adminId: userId,
            productId: payload?.productId,
          },
        };
      case 'toggle_favorite':
        return {
          path: '/api/products/toggle-favorite',
          body: {
            productId: payload?.productId,
            userId,
          },
        };
      case 'update_order_status':
        return {
          path: '/api/orders/update-status',
          body: {
            orderId: payload?.orderId,
            newStatus: payload?.newStatus,
            userId,
            trackingNumber: payload?.trackingNumber,
            carrier: payload?.carrier,
          },
        };
      case 'confirm_item_receipt':
        return {
          path: '/api/orders/confirm-receipt',
          body: {
            orderId: payload?.orderId,
            productId: payload?.productId ?? payload?.cartItemId ?? '',
            userId,
          },
        };
      case 'cancel_order':
        return {
          path: '/api/orders/cancel',
          body: {
            orderId: payload?.orderId,
            userId,
          },
        };
      case 'create_return_request':
        return {
          path: '/api/returns/create',
          body: {
            orderId: payload?.orderId,
            productId: payload?.productId ?? payload?.cartItemId ?? '',
            userId,
            returnReason: payload?.returnReason ?? payload?.reason,
          },
        };
      case 'approve_return_request':
        return {
          path: '/api/returns/approve',
          body: {
            returnId: payload?.returnId ?? payload?.orderId,
            userId,
            action: payload?.action ?? 'approve',
            returnTrackingNumber: payload?.returnTrackingNumber,
            returnAdminNote: payload?.returnAdminNote ?? payload?.adminNote,
          },
        };
      case 'activate_license':
        return { path: '/api/digital/activate-license', body: { userId, ...payload } };
      case 'e2e_seed_license':
        return { path: '/api/admin/e2e/seed-license', body: { adminId: userId, ...payload } };
      case 'admin_create_coupon':
        return { path: '/api/admin/create-coupon', body: { adminId: userId, ...payload } };
      case 'admin_delete_product_question':
        return { path: '/api/admin/delete-question', body: { adminId: userId, questionId: payload?.questionId } };
      case 'admin_delete_product_rating':
        return { path: '/api/admin/delete-rating', body: { adminId: userId, ratingId: payload?.ratingId } };
      case 'admin_delete_review':
        return { path: '/api/admin/delete-review', body: { adminId: userId, reviewId: payload?.reviewId } };
      case 'admin_flag_review':
        return { path: '/api/admin/flag-review', body: { adminId: userId, reviewId: payload?.reviewId, reason: payload?.reason } };
      case 'admin_get_reviews':
        return { path: '/api/admin/reviews', body: { adminId: userId, ...payload } };
      case 'admin_get_users':
        return { path: '/api/admin/users', body: { adminId: userId, ...payload } };
      case 'admin_mfa_enroll':
        return { path: '/api/admin/mfa-enroll', body: { adminId: userId, ...payload } };
      case 'admin_mfa_verify':
        return { path: '/api/admin/mfa-verify', body: { adminId: userId, ...payload } };
      case 'admin_mfa_verify_backup':
        return { path: '/api/admin/mfa-verify-backup', body: { adminId: userId, ...payload } };
      case 'admin_refund_order':
        return { path: '/api/admin/refund-order', body: { adminId: userId, orderId: payload?.orderId, reason: payload?.reason } };
      case 'admin_reject_product':
        return { path: '/api/admin/reject-product', body: { adminId: userId, productId: payload?.productId, reason: payload?.reason } };
      case 'admin_suspend_user':
        return { path: '/api/admin/suspend-user', body: { adminId: userId, targetUserId: payload?.userId ?? payload?.targetUserId, reason: payload?.reason } };
      case 'admin_update_product_stock':
        return { path: '/api/admin/update-stock', body: { adminId: userId, productId: payload?.productId, quantity: payload?.quantity } };
      case 'answer_product_question':
        return { path: '/api/qa/answer', body: { userId, questionId: payload?.questionId, answer: payload?.answer } };
      case 'answer_review':
        return { path: '/api/products/answer-review', body: { userId, reviewId: payload?.reviewId, answer: payload?.answer } };
      case 'apply_coupon':
        return { path: '/api/checkout/apply-coupon', body: { userId, couponCode: payload?.couponCode } };
      case 'approve_shipping_cost':
        return { path: '/api/shipping/approve', body: { userId, orderId: payload?.orderId, shippingCost: payload?.shippingCost } };
      case 'ask_product_question':
        return { path: '/api/qa/ask', body: { userId, productId: payload?.productId, question: payload?.question } };
      case 'calculate_shipping_cost':
        return { path: '/api/shipping/calculate', body: { ...payload } };
      case 'cancel_subscription':
        return { path: '/api/subscriptions/cancel', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'capture_payment':
        return { path: '/api/payments/capture', body: { userId, paymentIntentId: payload?.paymentIntentId } };
      case 'cleanup_fcm_token':
        return { path: '/api/users/cleanup-fcm-token', body: { userId } };
      case 'configure_algolia':
        return { path: '/api/admin/configure-algolia', body: { adminId: userId } };
      case 'create_account_link':
        return { path: '/api/connect/account-link', body: { userId } };
      case 'create_connect_account':
        return { path: '/api/connect/create-account', body: { userId } };
      case 'create_stripe_login_link':
        return { path: '/api/connect/account-link', body: { userId } };
      case 'create_subscription':
        return { path: '/api/subscriptions/create', body: { userId, ...payload } };
      case 'create_warehouse':
        return { path: '/api/warehouses/create', body: { userId, ...payload } };
      case 'deactivate_license':
        return { path: '/api/digital/deactivate-license', body: { userId, ...payload } };
      case 'deactivate_supplier_platform':
        return { path: '/api/admin/deactivate-supplier-platform', body: { userId } };
      case 'delete_message':
        return { path: '/api/chat/delete-message', body: { userId, messageId: payload?.messageId } };
      case 'delete_product_images':
        return { path: '/api/products/delete-images', body: { userId, productId: payload?.productId, imageUrls: payload?.imageUrls } };
      case 'delete_warehouse':
        return { path: '/api/warehouses/delete', body: { userId, warehouseId: payload?.warehouseId } };
      case 'export_my_data':
        return { path: '/api/admin/export-data', body: { userId } };
      case 'generate_book_download_session':
        return { path: '/api/digital/book-download', body: { userId, productId: payload?.productId } };
      case 'generate_software_download_session':
        return { path: '/api/digital/software-download', body: { userId, productId: payload?.productId } };
      case 'get_address_suggestions':
        return { path: '/api/addresses/suggestions', body: { query: payload?.query } };
      case 'get_chat_threads':
        return { path: '/api/chat/threads', body: { userId, ...payload } };
      case 'get_connect_account_status':
        return { path: '/api/connect/status', body: { userId } };
      case 'get_or_create_chat':
        return { path: '/api/chat/get-or-create', body: {
          userId,
          otherUserId: payload?.otherUserId ?? payload?.other_user_id ?? payload?.participantId,
          other_user_id: payload?.otherUserId ?? payload?.other_user_id ?? payload?.participantId,
          product_id: payload?.productId ?? payload?.product_id ?? null,
        }};
      case 'get_order_detail': {
        const rawOid = String(payload?.orderId ?? '');
        const oid = rawOid.includes(':') ? rawOid.split(':', 2)[1] : rawOid;
        return {
          path: '/graphql',
          body: {
            query: `query GetDoc($collection: String!, $id: String!) { get(collection: $collection, id: $id) }`,
            variables: { collection: 'orders', id: oid },
          },
        };
      }
      case 'get_orders': {
        const filters: Record<string, any> = { buyerId: { _eq: userId } };
        if (payload?.status) {
          const s = String(payload.status).toLowerCase();
          if (s === 'completed' || s === 'delivered') {
            filters.status = { _in: ['delivered', 'DELIVERED', 'completed', 'COMPLETED'] };
          } else if (s === 'cancelled' || s === 'canceled') {
            filters.status = { _in: ['cancelled', 'CANCELLED', 'canceled'] };
          } else {
            filters.status = { _eq: payload.status };
          }
        }
        return {
          path: '/graphql',
          body: {
            query: `query ListOrders($collection: String!, $filters: JSON, $limit: Int) { list(collection: $collection, filters: $filters, limit: $limit) }`,
            variables: { collection: 'orders', filters, limit: payload?.limit ?? 50 },
          },
        };
      }
      case 'get_payment_providers':
        return { path: '/api/payments/providers/list', body: { ...payload } };
      case 'get_product_questions':
        return { path: '/api/products/questions/list', body: { productId: payload?.productId, ...payload } };
      case 'get_product_ratings_paginated':
        return { path: '/api/products/ratings', body: { productId: payload?.productId, page: payload?.page ?? 1, limit: payload?.limit ?? 20 } };
      case 'get_provider_status':
        return { path: '/api/payments/providers/status', body: { providerId: payload?.providerId } };
      case 'get_seller_warehouses':
        return { path: '/api/warehouses/list', body: { userId, ...payload } };
      case 'get_subscription_status':
        return { path: '/api/subscriptions/status', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'mark_messages_read':
        return { path: '/api/chat/mark-read', body: { userId, messageIds: payload?.messageIds } };
      case 'reactivate_subscription':
        return { path: '/api/subscriptions/reactivate', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'refund_order_item':
        return { path: '/api/orders/refund-item', body: { userId, orderId: payload?.orderId, itemId: payload?.itemId } };
      case 'reject_return_request':
        return { path: '/api/returns/reject', body: { userId, returnId: payload?.returnId } };
      case 'report_message':
        return { path: '/api/chat/report', body: { userId, messageId: payload?.messageId, reason: payload?.reason } };
      case 'search_products':
        return { path: '/api/products/search', body: { ...payload } };
      case 'send_chat_message':
        return { path: '/api/chat/send', body: { userId, threadId: payload?.threadId, message: payload?.message } };
      case 'send_message':
        return { path: '/api/chat/send', body: { userId, ...payload } };
      case 'start_chat_thread':
        return { path: '/api/chat/start', body: { userId, otherUserId: payload?.otherUserId ?? payload?.participantId ?? payload?.recipientId, productId: payload?.productId, initialMessage: payload?.initialMessage } };
      case 'submit_product_rating':
        return { path: '/api/products/submit-rating', body: { userId, productId: payload?.productId, orderId: payload?.orderId, rating: payload?.rating, review: payload?.review } };
      case 'submit_product_rating_atomic':
        return { path: '/api/products/submit-rating-atomic', body: { userId, productId: payload?.productId, rating: payload?.rating, review: payload?.review } };
      case 'subscribe_stock_notification':
        return { path: '/api/products/stock-notify/subscribe', body: { userId, productId: payload?.productId, variantKey: payload?.variantKey } };
      case 'suspend_seller':
        return { path: '/api/admin/suspend-seller', body: { adminId: userId, sellerId: payload?.sellerId, reason: payload?.reason } };
      case 'unsubscribe_email':
        return { path: '/api/admin/unsubscribe-email', body: { email: payload?.email, token: payload?.token } };
      case 'unsubscribe_stock_notification':
        return { path: '/api/products/stock-notify/unsubscribe', body: { userId, productId: payload?.productId, variantKey: payload?.variantKey } };
      case 'unsuspend_seller':
        return { path: '/api/admin/unsuspend-seller', body: { adminId: userId, sellerId: payload?.sellerId } };
      case 'update_item_status':
        return { path: '/api/orders/update-item-status', body: { userId, orderId: payload?.orderId, productId: payload?.productId ?? payload?.itemId, newStatus: payload?.newStatus ?? payload?.status, trackingNumber: payload?.trackingNumber, carrier: payload?.carrier } };
      case 'update_payment_provider':
        return { path: '/api/payments/update-provider', body: { userId, ...payload } };
      case 'update_shipping_cost':
        return { path: '/api/orders/update-shipping', body: { userId, ...payload } };
      case 'update_user_roles':
        return { path: '/api/admin/update-roles', body: { adminId: userId, targetUserId: payload?.userId ?? payload?.targetUserId, roles: payload?.roles } };
      case 'update_warehouse':
        return { path: '/api/warehouses/update', body: { userId, warehouseId: payload?.warehouseId, ...payload } };
      case 'upload_product_images':
        return { path: '/api/products/upload-images', body: { userId, productId: payload?.productId, imageUrls: payload?.imageUrls } };
      case 'add_to_cart':
        return { path: '/api/cart/add', body: { userId, productId: payload?.productId, quantity: payload?.quantity ?? 1 } };
      case 'remove_from_cart':
        return { path: '/api/cart/remove', body: { userId, productId: payload?.productId } };
      case 'get_cart':
        return { path: '/api/cart/get', body: { userId } };
      case 'clear_cart':
        return { path: '/api/cart/clear', body: { userId } };
      case 'update_cart_quantity':
        return { path: '/api/cart/update', body: { userId, productId: payload?.productId, quantity: payload?.quantity } };
      case 'verify_cart_prices':
        return { path: '/api/cart/verify-prices', body: { userId, cartItems: payload?.cartItems } };
      case 'verify_license':
        return { path: '/api/digital/verify-license', body: { licenseKey: payload?.licenseKey, email: payload?.email } };

      default:
        return null;
    }
  }

  async function normalizePortedResponse(fnName: string, body: any): Promise<any> {
    switch (fnName) {
      case 'create_checkout_session': {
        const sessionId = body?.sessionId ?? body?.session_id ?? null;
        // In API-only mode we cannot resolve checkout URL from Stripe — return null
        const checkoutUrl =
          body?.checkoutUrl ??
          body?.checkout_url ??
          body?.url ??
          null;
        return {
          ...body,
          sessionId,
          checkoutUrl,
        };
      }
      case 'get_orders': {
        const rawList = body?.data?.list ?? body?.orders ?? [];
        const orders = Array.isArray(rawList) ? rawList : (typeof rawList === 'string' ? JSON.parse(rawList) : []);
        return { success: true, orders };
      }
      case 'get_order_detail': {
        const order = body?.data?.get ?? body;
        return { success: true, ...order };
      }
      case 'get_connect_account_status':
        return {
          ...body,
          stripeAccountId: body?.stripeAccountId ?? body?.accountId ?? body?.account_id,
          onboardingCompleted: body?.onboardingCompleted ?? body?.onboarding_completed ?? false,
          chargesEnabled: body?.chargesEnabled ?? body?.charges_enabled ?? false,
          payoutsEnabled: body?.payoutsEnabled ?? body?.payouts_enabled ?? false,
        };
      case 'get_seller_metrics': {
        const rawMetrics = body?.data?.list ?? [];
        const metrics = Array.isArray(rawMetrics) ? rawMetrics : [];
        return { success: true, metrics };
      }
      case 'get_products_paginated':
      case 'get_seller_products_paginated':
        return {
          success: true,
          products: Array.isArray(body?.products) ? body.products : [],
          nextCursor: body?.nextCursor ?? body?.next_cursor ?? null,
          hasMore: Boolean(body?.hasMore ?? body?.has_more),
          totalFetched: body?.totalFetched ?? body?.total_fetched ?? 0,
        };
      case 'toggle_favorite':
        return {
          success: Boolean(body?.success),
          favorited: body?.favorited ?? body?.favorite ?? false,
        };
      default:
        return body;
    }
  }

  const usePrimaryBackend = useOrignaBaseAuth();
  if (usePrimaryBackend && !ORIGNABASE_URL) {
    return {
      error: {
        message: `ORIGNABASE_URL is required for primary E2E backend calls (${fn})`,
        status: 'FAILED_PRECONDITION',
      },
    };
  }

  const ported = usePrimaryBackend ? portedRequest(fn, data) : null;
  if (usePrimaryBackend && !ported) {
    return {
      error: {
        message: `Primary E2E helper has no OrignaBase route for ${fn}. Add a portedRequest mapping instead of falling back to Cloud Functions.`,
        status: 'FAILED_PRECONDITION',
      },
    };
  }

  const url = ported
    ? `${ORIGNABASE_URL}${ported.path}`
    : `${ORIGNABASE_URL}/${fn}`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(ported ? ported.body : { data }),
      signal: controller.signal,
    });
    const text = await res.text();
    try {
      const body = JSON.parse(text);
      if (!res.ok) {
        const rawErr = body?.error ?? { code: res.status, status: res.status, message: body?.message || text.substring(0, 200) };
        const normalizedCode = (() => {
          const c = rawErr.code ?? res.status;
          if (typeof c === 'string' && isNaN(Number(c))) return c;
          const n = typeof c === 'number' ? c : Number(c);
          if (n === 401) return 'unauthenticated';
          if (n === 403) return 'permission-denied';
          if (n === 404) return 'not-found';
          if (n === 400 || n === 422) return 'invalid-argument';
          if (n === 409) return 'already-exists';
          if (n === 429) return 'resource-exhausted';
          if (n >= 500) return 'internal';
          return String(c);
        })();
        return { error: { ...rawErr, code: normalizedCode } };
      }
      if (ported) {
        return await normalizePortedResponse(fn, body);
      }
      return body.data !== undefined ? { result: body.data } : body;
    } catch {
      return { error: { message: `Non-JSON response (${res.status}): ${text.substring(0, 200)}`, status: res.status >= 400 ? 'NOT_FOUND' : 'INTERNAL' } };
    }
  } catch (err: any) {
    if (err.name === 'AbortError') {
      return { error: { message: `Request timeout after ${timeoutMs}ms for ${fn}`, status: 'DEADLINE_EXCEEDED' } };
    }
    return { error: { message: err.message || String(err), status: 'INTERNAL' } };
  } finally {
    clearTimeout(timer);
  }
}

// ════════════════════════════════════════════════════════════════════
// callOk / callExpectError / normalizeErrorCode
// ════════════════════════════════════════════════════════════════════

export async function callOk(fn: string, data: any, token: string): Promise<any> {
  const MAX_ATTEMPTS = 4;
  const RATE_LIMIT_WAITS = [2_000, 5_000, 10_000];
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const body = await callCallable(fn, data, token);
    if (body.error) {
      const status = body.error.status;
      if (attempt < MAX_ATTEMPTS - 1) {
        const errMsg = (body.error.message || '');
        const is429 = status === 429 || errMsg.includes('429') || errMsg.toLowerCase().includes('too many') || errMsg.toLowerCase().includes('rate limit');
        const is500 = status === 500;
        if (is500 || is429) {
          const wait = is429 ? (RATE_LIMIT_WAITS[attempt] ?? 90_000) : 5_000;
          console.log(`${is429 ? 'Rate limit' : 'Server error'} on ${fn}, waiting ${wait / 1000}s... (attempt ${attempt + 1}/${MAX_ATTEMPTS})`);
          await new Promise(r => setTimeout(r, wait));
          continue;
        }
      }
      throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
    }
    return body.result || body;
  }
  throw new Error(`${fn} failed after ${MAX_ATTEMPTS} retries`);
}

function normalizeErrorCode(error: any): { code: string; message: string } {
  const STATUS_TO_CODE: Record<string, string> = {
    'PERMISSION_DENIED': 'permission-denied',
    'FAILED_PRECONDITION': 'failed-precondition',
    'NOT_FOUND': 'not-found',
    'UNAUTHENTICATED': 'unauthenticated',
    'INVALID_ARGUMENT': 'invalid-argument',
    'ALREADY_EXISTS': 'already-exists',
    'RESOURCE_EXHAUSTED': 'resource-exhausted',
    'CANCELLED': 'cancelled',
    'UNAVAILABLE': 'unavailable',
    'INTERNAL': 'internal',
    'DEADLINE_EXCEEDED': 'deadline-exceeded',
    'UNIMPLEMENTED': 'unimplemented',
    'OUT_OF_RANGE': 'out-of-range',
    'DATA_LOSS': 'data-loss',
    'ABORTED': 'aborted',
  };
  const HTTP_TO_CODE: Record<number, string> = {
    400: 'invalid-argument',
    401: 'unauthenticated',
    403: 'permission-denied',
    404: 'not-found',
    405: 'unimplemented',
    409: 'already-exists',
    410: 'not-found',
    422: 'invalid-argument',
    429: 'resource-exhausted',
    500: 'internal',
    502: 'unavailable',
    503: 'unavailable',
    504: 'deadline-exceeded',
  };
  const bodyCode = error.code;
  const rawCode = typeof bodyCode === 'string' && isNaN(Number(bodyCode))
    ? bodyCode
    : (bodyCode ?? error.status);
  const code = typeof rawCode === 'number'
    ? (HTTP_TO_CODE[rawCode] ?? String(rawCode))
    : (STATUS_TO_CODE[rawCode] ?? rawCode?.toLowerCase()?.replace(/_/g, '-') ?? 'unknown');
  return { code, message: error.message || error.details || '' };
}

export async function callExpectError(fn: string, data: any, token: string): Promise<{ code: string; message: string }> {
  const body = await callCallable(fn, data, token);
  if (body.error) return normalizeErrorCode(body.error);
  if (body.result?.error) return normalizeErrorCode(body.result.error);
  return {
    code: 'unexpected-success',
    message: `Expected ${fn} to fail but it succeeded: ${JSON.stringify(body)}`,
  };
}

// ════════════════════════════════════════════════════════════════════
// EMAIL VERIFICATION
// ════════════════════════════════════════════════════════════════════

export async function verifyEmailSent(email: string, adminToken?: string): Promise<any[]> {
  let token = adminToken;
  if (!token) {
    const auth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    token = auth.idToken;
  }
  const res = await callOk('e2e_get_mail_logs', { to: email }, token);
  return res.logs || [];
}

// ════════════════════════════════════════════════════════════════════
// CHECKOUT HELPERS
// ════════════════════════════════════════════════════════════════════

export async function buildCheckoutPayload(
  buyerUid: string,
  productId: string,
  quantity = 1,
  token?: string
): Promise<{ data: any; product: any; buyer: any }> {
  const fallbackAddress = {
    street: '100 King St W',
    apartment: '',
    city: 'Toronto',
    state: 'ON',
    province: 'ON',
    postalCode: 'M5X 1A9',
    country: 'Canada',
    phoneNumber: '+14165550000',
  };

  const stripCollectionPrefix = (id: string): string =>
    id.includes(':') ? id.split(':', 2)[1] : id;

  let resolvedProductId = stripCollectionPrefix(productId);
  let prodDoc = await readDoc(`products/${resolvedProductId}`, token);
  let product = parseDoc(prodDoc);
  if (!product) {
    const products = await listCollection('products', token);
    const fallback = products.find((p) =>
      (p.stockQuantity ?? 0) > 0 &&
      ((p.lifecycleStatus ?? p.status) === 'active')
    ) ?? products.find((p) => (p.stockQuantity ?? 0) > 0) ?? products[0];
    if (fallback?.id) {
      resolvedProductId = stripCollectionPrefix(String(fallback.id));
      prodDoc = await readDoc(`products/${resolvedProductId}`, token);
      product = parseDoc(prodDoc);
    }
  }
  if (!product) {
    resolvedProductId = 'product_001';
  }

  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  if (!product) {
    return {
      data: {
        userId: buyerUid,
        items: [{ productId: resolvedProductId, quantity }],
        shippingAddress: {
          ...fallbackAddress,
          street: address.street || fallbackAddress.street,
          apartment: address.apartment || fallbackAddress.apartment,
          city: address.city || fallbackAddress.city,
          state: address.state || fallbackAddress.state,
          province: address.province || address.state || fallbackAddress.province,
          postalCode: address.postalCode || fallbackAddress.postalCode,
          country: address.country || fallbackAddress.country,
          phoneNumber: address.phoneNumber || fallbackAddress.phoneNumber,
        },
        deliverySpeed: 'standard',
      },
      product: { id: resolvedProductId },
      buyer,
    };
  }

  const productPriceCents: number = product.priceCents ?? Math.round((product.price ?? 0) * 100);
  const productPriceFloat: number = product.price ?? (productPriceCents / 100);

  const data = {
    userId: buyerUid,
    items: [{
      productId: resolvedProductId,
      name: product.name || product.title || `Product ${resolvedProductId}`,
      price: productPriceFloat,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || [`https://picsum.photos/seed/${product.id ?? 'default'}/400/400`],
      isDigital: product.isDigital || false,
    }],
    subtotalCents: productPriceCents * quantity,
    shippingAddress: {
      street: address.street || fallbackAddress.street,
      apartment: address.apartment || '',
      city: address.city || fallbackAddress.city,
      state: address.state || fallbackAddress.state,
      province: address.province || address.state || fallbackAddress.province,
      postalCode: address.postalCode || fallbackAddress.postalCode,
      country: address.country || fallbackAddress.country,
      phoneNumber: address.phoneNumber || fallbackAddress.phoneNumber,
    },
  };
  return { data, product, buyer };
}

export async function buildMultiSellerPayload(
  buyerUid: string,
  items: { productId: string; quantity: number }[],
  token?: string
): Promise<any> {
  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  const cartItems: any[] = [];
  let subtotal = 0;
  for (const { productId, quantity } of items) {
    const prodDoc = await readDoc(`products/${productId}`, token);
    const product = parseDoc(prodDoc);
    if (!product) throw new Error(`Product ${productId} not found in SurrealDB.`);
    cartItems.push({
      productId,
      name: product.name || product.title || `Product ${productId}`,
      price: product.price,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || [`https://picsum.photos/seed/${product.id ?? 'default'}/400/400`],
      isDigital: product.isDigital || false,
    });
    subtotal += product.price * quantity;
  }

  return {
    userId: buyerUid,
    items: cartItems,
    subtotalCents: Math.round(subtotal * 100),
    shippingAddress: {
      street: address.street || '100 King St W',
      apartment: address.apartment || '',
      city: address.city || 'Toronto',
      state: address.state || 'ON',
      postalCode: address.postalCode || 'M5X 1A9',
      country: address.country || 'Canada',
      phoneNumber: address.phoneNumber || '+14165550000',
    },
  };
}

// ════════════════════════════════════════════════════════════════════
// FULL CHECKOUT FLOWS (API-only — no browser interaction)
// ════════════════════════════════════════════════════════════════════

/**
 * Full checkout: create checkout session, open Stripe page, fill card, and pay.
 */
export async function fullCheckoutAndPay(
  buyerEmail: string,
  productId: string,
  quantity = 1,
  password = DEFAULT_PASS
): Promise<{ orderId: string; checkoutUrl: string | null }> {
  const auth = await signIn(buyerEmail, password);
  const { data } = await buildCheckoutPayload(auth.localId, productId, quantity, auth.idToken);
  const uniqueData = { ...data, idempotencyKey: `fcp-${Date.now()}-${Math.random().toString(36).slice(2)}` };
  const result = await callOk('create_checkout_session', uniqueData, auth.idToken);

  if (!result.orderId) throw new Error('Checkout failed: no orderId returned');

  const checkoutUrl = result.checkoutUrl ?? result.sessionUrl ?? null;
  if (checkoutUrl) {
    // Complete Stripe payment via agent-browser
    const { AgentBrowser } = await import('./agent-browser.js');
    const browser = new AgentBrowser();
    try {
      await browser.open(checkoutUrl);
      // Wait for Stripe page to load (not Flutter)
      await new Promise(r => setTimeout(r, 5000));

      // Fill Stripe card form
      let snap = await browser.snapshot({ interactive: true, compact: true });
      const cardField = browser.findByLabel(snap, /card number|numéro de carte/i);
      const expField = browser.findByLabel(snap, /expir/i);
      const cvcField = browser.findByLabel(snap, /cvc|security|sécurité/i);
      const nameField = browser.findByLabel(snap, /cardholder|titulaire|billing name/i);
      const emailField = browser.findByLabel(snap, /email/i);
      if (cardField) await browser.fill(cardField.ref, '4242424242424242');
      if (expField) await browser.fill(expField.ref, '12/34');
      if (cvcField) await browser.fill(cvcField.ref, '123');
      if (nameField) await browser.fill(nameField.ref, 'Test Buyer');
      if (emailField) await browser.fill(emailField.ref, buyerEmail);

      // Click pay button
      snap = await browser.snapshot({ interactive: true, compact: true });
      const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i)
        ?? browser.findByLabel(snap, /pay|payer|subscribe|submit/i);
      if (payBtn) await browser.click(payBtn.ref);

      // Wait for payment to process
      await new Promise(r => setTimeout(r, 10000));
    } finally {
      // Clear state to prevent Stripe cookies from redirecting future navigations
      await browser.clearState().catch(() => {});
      await browser.close().catch(() => {});
    }
  }

  return { orderId: result.orderId, checkoutUrl };
}

/**
 * Full multi-seller checkout: create session, open Stripe, fill card, and pay.
 */
export async function fullMultiSellerCheckoutAndPay(
  buyerEmail: string,
  items: { productId: string; quantity: number }[],
  password = DEFAULT_PASS
): Promise<{ orderId: string }> {
  const auth = await signIn(buyerEmail, password);
  const payload = await buildMultiSellerPayload(auth.localId, items, auth.idToken);
  const uniquePayload = { ...payload, idempotencyKey: `fmcp-${Date.now()}-${Math.random().toString(36).slice(2)}` };
  const result = await callOk('create_checkout_session', uniquePayload, auth.idToken);

  if (!result.orderId) throw new Error('Multi-seller checkout failed: no orderId');

  const checkoutUrl = result.checkoutUrl ?? result.sessionUrl ?? null;
  if (checkoutUrl) {
    const { AgentBrowser } = await import('./agent-browser.js');
    const browser = new AgentBrowser();
    try {
      await browser.open(checkoutUrl);
      await new Promise(r => setTimeout(r, 5000));

      let snap = await browser.snapshot({ interactive: true, compact: true });
      const cardField = browser.findByLabel(snap, /card number|numéro de carte/i);
      const expField = browser.findByLabel(snap, /expir/i);
      const cvcField = browser.findByLabel(snap, /cvc|security|sécurité/i);
      const nameField = browser.findByLabel(snap, /cardholder|titulaire|billing name/i);
      const emailField = browser.findByLabel(snap, /email/i);
      if (cardField) await browser.fill(cardField.ref, '4242424242424242');
      if (expField) await browser.fill(expField.ref, '12/34');
      if (cvcField) await browser.fill(cvcField.ref, '123');
      if (nameField) await browser.fill(nameField.ref, 'Test Buyer');
      if (emailField) await browser.fill(emailField.ref, buyerEmail);

      snap = await browser.snapshot({ interactive: true, compact: true });
      const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i)
        ?? browser.findByLabel(snap, /pay|payer|subscribe|submit/i);
      if (payBtn) await browser.click(payBtn.ref);

      await new Promise(r => setTimeout(r, 10000));
    } finally {
      await browser.clearState().catch(() => {});
      await browser.close().catch(() => {});
    }
  }

  return { orderId: result.orderId };
}

// ════════════════════════════════════════════════════════════════════
// ORDER HELPERS
// ════════════════════════════════════════════════════════════════════

function normalizeOrderShape(order: any): any {
  if (!order || typeof order !== 'object') return order;
  return {
    ...order,
    orderStatus: order.orderStatus ?? order.status ?? null,
    paymentStatus: order.paymentStatus ?? order.payment_status ?? null,
    userId: order.userId ?? order.buyerId ?? order.buyer_id ?? null,
  };
}

export async function getOrder(orderId: string, token?: string): Promise<any> {
  const doc = await readDoc(`orders/${orderId}`, token);
  return doc ? normalizeOrderShape(parseDoc(doc)) : null;
}

export async function getProductStock(productId: string, token?: string): Promise<number> {
  const doc = await readDoc(`products/${productId}`, token);
  return doc ? (parseDoc(doc)?.stockQuantity ?? 0) : 0;
}

export async function pollDocField(
  path: string,
  field: string,
  expected: any,
  token?: string,
  maxMs = 30_000
): Promise<any> {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const doc = await readDoc(path, token);
    if (doc) {
      const parsed = parseDoc(doc);
      if (parsed?.[field] === expected) return parsed;
    }
    await new Promise(r => setTimeout(r, 2_000));
  }
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

export async function simulateConcurrent(
  fn: () => Promise<unknown>,
  concurrency: number
): Promise<{ succeeded: number; failed: number; errors: string[] }> {
  const results = await Promise.allSettled(
    Array.from({ length: concurrency }, fn)
  );
  const succeeded = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected').length;
  const errors = results
    .filter((r): r is PromiseRejectedResult => r.status === 'rejected')
    .map(r => r.reason?.message ?? String(r.reason));
  return { succeeded, failed, errors };
}

export async function pollDoc<T>(
  path: string,
  condition: (data: T) => boolean,
  token?: string,
  { timeout = 10_000, interval = 500 } = {}
): Promise<T> {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const doc = await readDoc(path, token);
    const data = doc ? parseDoc(doc) as T : null;
    if (data && condition(data)) return data;
    await new Promise(r => setTimeout(r, interval));
  }
  throw new Error(`pollDoc timeout: condition not met for ${path} within ${timeout}ms`);
}

export async function waitForOrderStatus(
  orderId: string,
  targetStatuses: string[],
  token?: string,
  maxWaitMs = 90_000
): Promise<any> {
  const start = Date.now();
  let lastOrder: any = null;
  while (Date.now() - start < maxWaitMs) {
    const doc = await readDoc(`orders/${orderId}`, token);
    if (doc) {
      const order = normalizeOrderShape(parseDoc(doc));
      lastOrder = order;
      const status = (order?.orderStatus ?? '').toLowerCase();
      if (order && targetStatuses.some(s => s.toLowerCase() === status)) return order;
    }
    await new Promise(r => setTimeout(r, 3_000));
  }
  const currentStatus = lastOrder?.orderStatus || lastOrder?.status || 'unknown';
  throw new Error(
    `waitForOrderStatus timeout: order ${orderId} expected [${targetStatuses}] but got "${currentStatus}" after ${maxWaitMs}ms`
  );
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT DISCOVERY
// ════════════════════════════════════════════════════════════════════

let _cachedProducts: DiscoveredProduct[] | null = null;

export function invalidateProductCache(): void {
  _cachedProducts = null;
}

export const STABLE_TEST_PRODUCTS: Array<{ id: string; sellerUid: string; prefix: string; country?: string }> = [
  { id: 'e2e_product_admin_seller', sellerUid: TEST_UIDS.ADMIN, prefix: 'A' },
  { id: 'e2e_product_test_seller', sellerUid: TEST_UIDS.SELLER, prefix: 'B' },
  { id: 'e2e_product_intl_seller', sellerUid: TEST_UIDS.SELLER, prefix: 'C', country: 'China' },
];

export async function discoverProducts(_token?: string): Promise<DiscoveredProduct[]> {
  if (_cachedProducts) return _cachedProducts;

  if (useOrignaBaseAuth()) {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const obProducts: DiscoveredProduct[] = [];
    for (const { id, sellerUid, prefix, country } of STABLE_TEST_PRODUCTS) {
      let product: DiscoveredProduct | null = null;
      try {
        const fields = await getDoc(`products/${id}`, adminAuth.idToken);
        if (fields && (fields.lifecycleStatus === 'active' || fields.status === 'active') && (fields.stockQuantity ?? 0) > 0) {
          if (fields.sellerId !== sellerUid) {
            await writeDoc(`products/${id}`, toSurrealDBFields({ sellerId: sellerUid }), adminAuth.idToken, true);
            fields.sellerId = sellerUid;
          }
          product = {
            id,
            name: fields.name || `E2E Product ${prefix}`,
            price: fields.priceCents ? fields.priceCents / 100 : (fields.price ?? 0),
            sellerId: sellerUid,
            stockQuantity: fields.stockQuantity ?? 100,
            lifecycleStatus: 'active',
          };
        }
      } catch { /* will create below */ }

      if (!product) {
        const address = country === 'China'
          ? { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' }
          : undefined;
        product = await createDummyProduct(sellerUid, prefix, id, address);
      }
      obProducts.push(product);
    }
    _cachedProducts = obProducts;
    return _cachedProducts;
  }

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const products: DiscoveredProduct[] = [];

  for (const { id, sellerUid, prefix, country } of STABLE_TEST_PRODUCTS) {
    let product: DiscoveredProduct | null = null;
    try {
      const fields = await getDoc(`products/${id}`, adminAuth.idToken);
      if (fields && (fields.lifecycleStatus === 'active' || fields.status === 'active')) {
        const currentStock = fields.stockQuantity ?? 0;
        if (currentStock < 10) {
          await writeDoc(`products/${id}`, toSurrealDBFields({ stockQuantity: 200 }), adminAuth.idToken, true);
          fields.stockQuantity = 200;
        }

        if (id === 'e2e_product_intl_seller') {
          const patches: Record<string, unknown> = {};
          if (fields.sellerAddress?.country !== 'China') {
            patches.sellerAddress = { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' };
            fields.sellerAddress = patches.sellerAddress as typeof fields.sellerAddress;
          }
          if (!fields.isInternational) {
            patches.isInternational = true;
            fields.isInternational = true;
          }
          if (Object.keys(patches).length > 0) {
            await writeDoc(`products/${id}`, toSurrealDBFields(patches), adminAuth.idToken, true);
          }
        }

        if (fields.sellerId !== sellerUid) {
          await writeDoc(`products/${id}`, toSurrealDBFields({ sellerId: sellerUid }), adminAuth.idToken, true);
          fields.sellerId = sellerUid;
        }

        if ((fields.stockQuantity ?? 0) > 0) {
          product = {
            id,
            name: fields.name || `E2E Product ${prefix}`,
            price: fields.price || 0,
            sellerId: sellerUid,
            stockQuantity: fields.stockQuantity,
            lifecycleStatus: 'active',
          };
        }
      }
    } catch { /* will create below */ }

    if (!product) {
      const address = country === 'China'
        ? { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' }
        : undefined;
      product = await createDummyProduct(sellerUid, prefix, id, address);
    }
    products.push(product);
  }

  _cachedProducts = products;
  return _cachedProducts;
}

export async function getTestProduct(token: string, excludeSellerId?: string): Promise<DiscoveredProduct> {
  const products = await discoverProducts(token);
  const candidates = excludeSellerId
    ? products.filter(p => p.sellerId !== excludeSellerId)
    : products;

  if (candidates.length === 0) {
    throw new Error('No purchasable products found (after excluding seller).');
  }

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  for (const product of candidates.slice(0, 5)) {
    try {
      const doc = await readDoc(`products/${product.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        product.stockQuantity = live.stockQuantity;
        return product;
      }
    } catch { /* skip, try next */ }
  }

  invalidateProductCache();
  const fresh = await discoverProducts(token);
  const freshCandidates = excludeSellerId
    ? fresh.filter(p => p.sellerId !== excludeSellerId)
    : fresh;

  if (freshCandidates.length === 0) {
    throw new Error('All products are out of stock. Restock dev SurrealDB.');
  }
  return freshCandidates[0];
}

export async function getTwoSellerProducts(token: string): Promise<[DiscoveredProduct, DiscoveredProduct] | null> {
  const products = await discoverProducts(token);
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const sellers = new Map<string, DiscoveredProduct>();

  for (const p of products) {
    if (sellers.has(p.sellerId)) continue;
    try {
      const doc = await readDoc(`products/${p.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        p.stockQuantity = live.stockQuantity;
        sellers.set(p.sellerId, p);
      }
    } catch { /* skip */ }
    if (sellers.size >= 2) break;
  }

  if (sellers.size < 2) return null;
  const [a, b] = [...sellers.values()];
  return [a, b];
}

export async function createDummyProduct(
  sellerUid: string,
  prefix: string,
  productId?: string,
  customAddress?: { street: string; city: string; state: string; postalCode: string; country: string }
): Promise<DiscoveredProduct> {
  const sampleImageUrls = [
    `https://picsum.photos/seed/${prefix}a/400/400`,
    `https://picsum.photos/seed/${prefix}b/400/400`,
  ];

  if (useOrignaBaseAuth()) {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const id = productId ?? `test_dummy_${prefix}_${Date.now()}`;
    const productData = {
      sellerId: sellerUid,
      sellerSku: `DUMMY-${prefix}-STABLE`,
      name: `Dummy Test Product ${prefix}`,
      title: `Dummy Test Product ${prefix}`,
      description: 'A high-quality test product created for E2E testing purposes.',
      priceCents: 1599,
      price: 15.99,
      lifecycleStatus: 'active',
      stockQuantity: 100,
      categoryId: 1,
      imageUrls: sampleImageUrls,
      keywords: ['dummy', prefix],
      sellerAddress: customAddress || {
        street: '100 University Ave',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5J 1V6',
        country: 'Canada',
      },
      isInternational: customAddress ? customAddress.country !== 'Canada' : false,
    };
    const ok = await writeDoc(`products/${id}`, toSurrealDBFields(productData), adminAuth.idToken, true);
    if (!ok) throw new Error(`createDummyProduct: writeDoc failed for ${id}`);
    return {
      id,
      name: productData.name,
      price: productData.price,
      sellerId: sellerUid,
      stockQuantity: 100,
      lifecycleStatus: 'active',
    };
  }

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const id = productId ?? `test_dummy_${prefix}_${Date.now()}`;
  const productData = {
    sellerId: sellerUid,
    sellerSku: `DUMMY-${prefix}-STABLE`,
    name: `Dummy Test Product ${prefix}`,
    description: `A high-quality test product created for E2E testing purposes.`,
    price: 15.99,
    lifecycleStatus: 'active',
    stockQuantity: 100,
    categoryId: 1,
    imageUrls: sampleImageUrls,
    keywords: ['dummy', prefix],
    sellerAddress: customAddress || {
      street: '100 University Ave',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5J 1V6',
      country: 'Canada'
    },
    isInternational: customAddress ? customAddress.country !== 'Canada' : false,
  };

  const ok = await writeDoc(`products/${id}`, toSurrealDBFields(productData), adminAuth.idToken, true);
  if (!ok) throw new Error(`Failed to create dummy product for ${sellerUid}`);

  return {
    id,
    name: productData.name,
    price: productData.price,
    sellerId: productData.sellerId,
    stockQuantity: productData.stockQuantity,
    lifecycleStatus: productData.lifecycleStatus,
  };
}

export async function ensureTwoSellerProducts(_token: string): Promise<[DiscoveredProduct, DiscoveredProduct]> {
  const products = await discoverProducts();
  const adminProd = products.find(p => p.sellerId === TEST_UIDS.ADMIN);
  const sellerProd = products.find(p => p.sellerId === TEST_UIDS.SELLER);
  if (!adminProd || !sellerProd) {
    invalidateProductCache();
    const fresh = await discoverProducts();
    const a = fresh.find(p => p.sellerId === TEST_UIDS.ADMIN);
    const b = fresh.find(p => p.sellerId === TEST_UIDS.SELLER);
    if (!a || !b) throw new Error('ensureTwoSellerProducts: failed to ensure products for both sellers');
    return [a, b];
  }
  return [adminProd, sellerProd];
}

export async function ensureOosProduct(): Promise<void> {
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const id = TEST_PRODUCTS.OOS;
  let exists = false;
  try {
    const fields = await getDoc(`products/${id}`, adminAuth.idToken);
    exists = !!(fields && (fields.lifecycleStatus === 'active' || fields.status === 'active'));
    if (exists && (fields.stockQuantity ?? 1) !== 0) {
      await writeDoc(`products/${id}`, toSurrealDBFields({ stockQuantity: 0 }), adminAuth.idToken, true);
    }
  } catch { /* not found -- will create */ }

  if (!exists) {
    await writeDoc(`products/${id}`, toSurrealDBFields({
      productId: id,
      sellerId: TEST_UIDS.ADMIN,
      sellerSku: 'OOS-E2E-STABLE',
      name: 'Out-of-Stock Test Product (E2E)',
      description: 'Dedicated out-of-stock product for stock notification E2E tests. Stock must always be 0.',
      price: 49.99,
      priceCents: 4999,
      lifecycleStatus: 'active',
      stockQuantity: 0,
      categoryId: 1,
      imageUrls: ['https://picsum.photos/seed/oos-test-e2e/400/400'],
      keywords: ['oos', 'test', 'e2e'],
      hasVariants: false,
      variants: [],
      isDigital: false,
      sellerAddress: {
        street: '100 University Ave',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5J 1V6',
        country: 'Canada',
      },
      isInternational: false,
      rating: 0,
      ratingCount: 0,
    }), adminAuth.idToken, true);
  }
}

// ════════════════════════════════════════════════════════════════════
// SELLER AUTH
// ════════════════════════════════════════════════════════════════════

export const SELLER_UID_TO_EMAIL: Record<string, string> = {
  [TEST_UIDS.ADMIN]: TEST_ACCOUNTS.ADMIN_EMAIL,
  [TEST_UIDS.SELLER]: TEST_ACCOUNTS.SELLER_EMAIL,
};

export async function getSellerAuth(sellerId: string): Promise<AuthData> {
  const email = SELLER_UID_TO_EMAIL[sellerId];
  if (!email) throw new Error(`Unknown seller UID: ${sellerId}. Add mapping to SELLER_UID_TO_EMAIL.`);
  return signIn(email);
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT MANIPULATION
// ════════════════════════════════════════════════════════════════════

export async function setProductTrending(productId: string, isTrending: boolean, adminToken?: string): Promise<boolean> {
  const token = adminToken ?? (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS)).idToken;
  const docData = await getDoc(`products/${productId}`, token);
  if (!docData) throw new Error(`Product ${productId} not found`);

  const updates: Record<string, any> = {
    isTrending: isTrending,
    trendingAt: isTrending ? new Date() : null
  };

  return writeDoc(`products/${productId}`, toSurrealDBFields(updates), token, true);
}

// ════════════════════════════════════════════════════════════════════
// COLLECTION LISTING (aliases)
// ════════════════════════════════════════════════════════════════════

export async function listDocs(collectionPath: string, token?: string): Promise<any[]> {
  return listCollection(collectionPath, token);
}

export async function listSubcollection(
  parentCollection: string,
  parentId: string,
  subcollection: string,
  token?: string
): Promise<any[]> {
  return listCollection(`${parentCollection}/${parentId}/${subcollection}`, token);
}

export async function listUserAddresses(userId: string, token?: string): Promise<any[]> {
  const query = `
    query ListAddresses($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(query, {
    collection: 'addresses',
    filters: { userId: { _eq: userId } },
  }, token);
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((doc: any) => doc && typeof doc === 'object')
    .map((doc: any) => {
      const { id, _id, _rev, _created, _updated, ...rest } = doc;
      const strippedId = typeof id === 'string' && id.includes(':') ? id.split(':', 2)[1] : id;
      return strippedId ? { id: strippedId, ...rest } : rest;
    });
}

export async function querySurrealDB(structuredQuery: any, token?: string): Promise<any[]> {
  const from = structuredQuery?.from?.[0]?.collectionId;
  if (!from) return [];
  return listCollection(from, token);
}

// ════════════════════════════════════════════════════════════════════
// UTILITIES
// ════════════════════════════════════════════════════════════════════

export function uid(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}
