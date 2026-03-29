# OrignaBase Flutter SDK — API Reference

### orignabase.dart
**Purpose**: Public API entry point that exports all SDK modules.

**Classes**: None (pure export module)

**Public Exports**:
- `client.dart` — OrignaBase client, HTTP transport, GraphQL
- `auth.dart` — Authentication service with MFA/TOTP
- `batch.dart` — WriteBatch for atomic operations
- `collection.dart` — CollectionRef, DocumentRef for CRUD
- `document.dart` — Document representation
- `errors.dart` — Exception hierarchy
- `field_value.dart` — FieldValue sentinels
- `query.dart` — Immutable Query builder
- `realtime.dart` — WebSocket subscriptions
- `storage.dart` — File upload/download with presigned URLs
- `offline.dart` — Offline cache with write queue
- `subcollection.dart` — Firestore-style subcollections
- `config.dart` — Remote Config
- `aggregate.dart` — SQL aggregates

---

### client.dart
**Purpose**: Main OrignaBase client, HTTP transport layer with exponential backoff retry logic for 429 rate limits, GraphQL bridge, and connection pooling. Serves as the single entry point for all backend communication.

**Classes**:
- `OrignaBase` — main client singleton

**Public Methods**:
- `OrignaBase.initialize({required String url, http.Client? httpClient, OfflineStorage? offlineStorage})` → `OrignaBase` — initializes client with backend URL, optional custom HTTP client, and optional offline storage. Returns singleton instance.
- `collection(String name)` → `CollectionRef` — returns Firestore-like collection reference for CRUD operations.
- `batch()` → `WriteBatch` — returns new WriteBatch for atomic multi-document operations.
- `graphql(String query, {Map<String, dynamic>? variables})` → `Future<Map<String, dynamic>>` — executes GraphQL query/mutation, returns response data. **GraphQL Call**: POST `/graphql` with query string and optional variables map. **Error Handling**: throws typed exceptions via `_throwForStatus()` (401→AuthException, 403→ForbiddenException, 404→NotFoundException, 409→ConflictException, 422→ValidationException, 429→RateLimitException).
- `request(String method, String path, {Map<String, dynamic>? body, Map<String, String>? headers})` → `Future<Map<String, dynamic>>` — low-level HTTP request with built-in exponential backoff retry logic. **HTTP Call**: Executes GET/POST/PUT/DELETE to `{url}{path}`. **Retry Logic**: 429 responses trigger exponential backoff (1s → 2s → 4s, max 3 retries). Respects `Retry-After` header if present. **Error Handling**: calls `_throwForStatus()` on non-2xx responses.
- `search(String index, String query, {int? limit, int? offset, String? filter})` → `Future<Map<String, dynamic>>` — full-text search against Meilisearch index. **HTTP Call**: POST `/search/{index}` with query, limit, offset, filter as body.
- `closeRealtime()` → `void` — explicitly closes WebSocket connection (RealtimeClient.disconnect()).
- `dispose()` → `void` — cleanup all resources: closes realtime WebSocket, cancels auth state stream, purges offline cache, closes HTTP client.
- `auth` (getter) → `OrignaBaseAuth` — returns auth service instance (lazy-initialized).
- `realtime` (getter) → `RealtimeClient` — returns realtime WebSocket client (lazy-initialized, shared connection pool).
- `storage` (getter) → `OrignaBaseStorage` — returns storage service (lazy-initialized).
- `config` (getter) → `OrignaBaseConfig` — returns remote config service (lazy-initialized).
- `url` (getter) → `String` — returns backend URL.

**Internal Methods**:
- `_executeHttp(String method, String path, {Map<String, dynamic>? body, Map<String, String>? headers})` → `Future<Map<String, dynamic>>` — single HTTP request without retry, handles GET/POST/PUT/DELETE, injects Bearer token from `auth.accessToken` if present.
- `_throwForStatus(int statusCode, {String message})` → `void` — maps HTTP status codes to typed exceptions (401→AuthException, 403→ForbiddenException, 404→NotFoundException, 409→ConflictException, 422→ValidationException, 429→RateLimitException, others→OrignaBaseException).
- `_calculateBackoff(int attempt)` → `Duration` — calculates exponential backoff duration: `(1 << attempt).clamp(1, 60)` seconds.

**Error Handling**: 
- All HTTP errors mapped via `_throwForStatus()` to typed exception hierarchy.
- 429 (RateLimitException) triggers automatic exponential backoff retry (max 3 attempts).
- `graphql()` wraps GraphQL-level errors in OrignaBaseException.
- Network errors wrapped in NetworkException.

**Token Management**:
- Token is obtained from `auth` service (which manages JWT lifecycle).
- Token automatically refreshed by auth service on expiry; client uses current token.

---

### auth.dart
**Purpose**: Authentication service handling user registration, login, password reset, email verification, MFA/TOTP setup and verification, magic links, and social sign-in (Google, Apple, OIDC). Manages JWT tokens and auth state broadcast stream.

**Classes**:
- `OrignaBaseAuth` — auth state manager, token lifecycle
- `AuthState` — snapshot of auth state (userId, email, roles, emailVerified, mfaRequired, challengeToken)
- `AuthStatus` enum — `authenticated`, `unauthenticated`
- `MfaSetupResult` — MFA setup response (qrCodeBase64, manualKey, appleOtpauthUrl)

**Public Methods**:
- `register(String email, String password)` → `Future<AuthState>` — user registration. **HTTP Call**: POST `/auth/register` with `{email, password}`. Returns AuthState with tokens.
- `signInWithEmail(String email, String password)` → `Future<AuthState>` — email/password login. **HTTP Call**: POST `/auth/login` with `{email, password}`. Returns AuthState (mfaRequired=true if MFA enabled and needs challenge).
- `refreshToken()` → `Future<AuthState>` — refresh access token using refresh token. **HTTP Call**: POST `/auth/refresh` with body `{refresh_token: currentRefreshToken}` (NOT Bearer header). Returns new AuthState with updated tokens.
- `signInWithGoogle(String idToken)` → `Future<AuthState>` — Google OAuth sign-in. **HTTP Call**: POST `/auth/google` with `{id_token: idToken}`. Returns AuthState with tokens.
- `signInWithApple(String authorizationCode, {String? displayName})` → `Future<AuthState>` — Apple OAuth sign-in. **HTTP Call**: POST `/auth/apple` with `{authorization_code, display_name}`. Returns AuthState.
- `signInWithOidc(String accessToken)` → `Future<AuthState>` — OIDC provider sign-in. **HTTP Call**: POST `/auth/oidc` with `{access_token: accessToken}`. Returns AuthState.
- `forgotPassword(String email)` → `Future<void>` — initiate password reset flow. **HTTP Call**: POST `/auth/forgot-password` with `{email}`. Sends reset link to email.
- `resetPassword(String token, String newPassword)` → `Future<void>` — reset password with reset token. **HTTP Call**: POST `/auth/reset-password` with `{token, new_password}`.
- `signInAnonymously()` → `Future<AuthState>` — anonymous sign-in (no credentials). **HTTP Call**: POST `/auth/anonymous` with empty body. Returns AuthState with anonymous userId.
- `upgradeAnonymous(String email, String password, {String? displayName})` → `Future<AuthState>` — convert anonymous user to email user. **HTTP Call**: POST `/auth/anonymous/upgrade` with `{email, password, display_name}`. Returns AuthState with new tokens.
- `sendMagicLink(String email)` → `Future<void>` — send passwordless login link. **HTTP Call**: POST `/auth/magic-link` with `{email}`. Email contains magic link token.
- `verifyMagicLink(String token)` → `Future<AuthState>` — verify magic link token and complete login. **HTTP Call**: POST `/auth/verify-magic-link` with `{token}`. Returns AuthState with tokens.
- `sendEmailVerification()` → `Future<void>` — send email verification link to current user. **HTTP Call**: POST `/auth/send-verification` (uses JWT auth). Email contains verification token.
- `verifyEmail(String token)` → `Future<void>` — verify email with verification token. **HTTP Call**: POST `/auth/verify-email` with `{token}`. Marks email as verified on user record.
- `setupMfa()` → `Future<MfaSetupResult>` — initiate TOTP setup. **HTTP Call**: POST `/auth/mfa/setup` (JWT auth). Returns QR code base64, manual key, and Apple OTPAuth URL for authenticator apps.
- `verifyMfaSetup(String totpCode)` → `Future<List<String>>` — verify TOTP code during MFA setup and get recovery codes. **HTTP Call**: POST `/auth/mfa/verify-setup` with `{totp_code}` (JWT auth). Returns list of recovery codes.
- `verifyMfaChallenge(String challengeToken, String totpCode)` → `Future<AuthState>` — complete MFA challenge during login. **HTTP Call**: POST `/auth/mfa/challenge` with `{challenge_token, totp_code}`. Returns AuthState with full tokens.
- `useMfaRecoveryCode(String challengeToken, String recoveryCode)` → `Future<AuthState>` — use recovery code if TOTP device lost. **HTTP Call**: POST `/auth/mfa/recovery` with `{challenge_token, recovery_code}`. Returns AuthState (recovery code becomes invalid after use).
- `disableMfa(String totpCode)` → `Future<void>` — disable TOTP on account. **HTTP Call**: DELETE `/auth/mfa` with body `{totp_code}` (JWT auth). Requires current TOTP code for verification.
- `getLoginHistory({int limit = 20, int offset = 0})` → `Future<List<Map<String, dynamic>>>` — fetch user's login history. **HTTP Call**: GET `/api/security/login-history?limit={limit}&offset={offset}` (JWT auth). Returns login records.
- `getKnownDevices()` → `Future<List<Map<String, dynamic>>>` — list all known devices. **HTTP Call**: GET `/api/security/known-devices` (JWT auth). Returns device list with IDs, names, last IP, last used timestamp.
- `removeDevice(String deviceId)` → `Future<void>` — revoke device trust. **HTTP Call**: DELETE `/api/security/known-devices/{deviceId}` (JWT auth).
- `getSecurityAlerts()` → `Future<List<Map<String, dynamic>>>` — fetch security alerts for suspicious activity. **HTTP Call**: GET `/api/security/alerts` (JWT auth). Returns alerts.
- `acknowledgeAlert(String alertId)` → `Future<void>` — mark alert as acknowledged. **HTTP Call**: POST `/api/security/alerts/{alertId}/acknowledge` (JWT auth).
- `signOut()` → `Future<void>` — sign out current user: clears tokens, closes realtime WebSocket, purges offline cache, broadcasts auth state change.
- `restoreSession({required String accessToken, String? refreshToken, String? email})` → `AuthState` — restore session from OAuth callback tokens (used after OAuth redirect). Synchronous, updates internal state and broadcasts.
- `authStateChanges` (getter) → `Stream<AuthState>` — broadcast stream of auth state changes (authenticated ↔ unauthenticated). Emits current state on subscription.
- `currentState` (getter) → `AuthState` — current auth snapshot (synchronous).
- `currentUserId` (getter) → `String?` — extracts `sub` claim from JWT (user UUID).
- `currentEmail` (getter) → `String?` — from JWT `email` claim or last known email.
- `currentRoles` (getter) → `List<String>` — extracts `roles` array from JWT claims.
- `isEmailVerified` (getter) → `bool` — checks `email_verified` claim from JWT.
- `accessToken` (getter) → `String?` — current access token (for debugging, not for manual use).
- `refreshToken` (getter) → `String?` — current refresh token (for debugging only).

**Internal Methods**:
- `_decodeClaims(String? token)` → `Map<String, dynamic>` — base64URL decodes JWT payload (no verification), handles nanosecond timestamp precision conversion. Returns empty map if token is null or invalid.
- `_handleAuthResponse(Map<String, dynamic> response)` → `AuthState` — extracts `access_token`, `refresh_token`, user data from response, stores tokens, broadcasts auth state change, returns AuthState.
- `_handleAuthResponseWithMfa(Map<String, dynamic> response)` → `AuthState` — checks for `mfa_required: true` in response, extracts `challenge_token`, returns AuthState with mfaRequired=true for caller to handle MFA challenge.

**Error Handling**:
- All HTTP errors mapped to typed exceptions via client layer.
- 401 Unauthorized → AuthException (invalid credentials, expired token).
- 422 Validation → ValidationException (invalid email format, weak password, etc.).
- TOTP verification failure → ValidationException.
- Recovery codes exhausted → ConflictException.

**Token Management**:
- Access token stored in `_accessToken` field.
- Refresh token stored in `_refreshToken` field.
- JWT claims decoded via `_decodeClaims()` using base64URL decode + JSON parse (no signature verification on client).
- Token refresh handled via `refreshToken()` method (called automatically by SDK on 401, or manually by app).
- Tokens cleared on `signOut()` or if verification fails.

---

### errors.dart
**Purpose**: Exception hierarchy for type-safe error handling across SDK. All HTTP and runtime errors wrapped in domain-specific exception types.

**Classes**:
- `OrignaBaseException extends Exception` — base exception with message and optional statusCode. Used for generic errors.
- `AuthException extends OrignaBaseException` — 401 Unauthorized (invalid credentials, expired token, missing auth).
- `ForbiddenException extends OrignaBaseException` — 403 Forbidden (insufficient permissions, RLS violation).
- `NotFoundException extends OrignaBaseException` — 404 Not Found (document/collection doesn't exist).
- `ValidationException extends OrignaBaseException` — 422 Unprocessable Entity (invalid input, constraint violation).
- `NetworkException extends OrignaBaseException` — connection/timeout errors (DNS failure, socket timeout, etc.).
- `ConflictException extends OrignaBaseException` — 409 Conflict (version mismatch, duplicate key, constraint conflict).
- `RateLimitException extends OrignaBaseException` — 429 Too Many Requests (rate limit exceeded).

**Public Methods** (all exceptions):
- Constructor: `ClassName(String message, {int? statusCode})` → exception instance.
- `message` (property) → String — error message.
- `statusCode` (property) → int? — HTTP status code (null for network errors).
- `toString()` → String — formatted error message.

**Error Mapping** (from HTTP status codes in client.dart):
| HTTP Status | Exception | Usage |
|-------------|-----------|-------|
| 401 | AuthException | Auth required, credentials invalid, token expired |
| 403 | ForbiddenException | Missing permissions, RLS denied access |
| 404 | NotFoundException | Document/collection not found |
| 409 | ConflictException | Update conflict, duplicate key |
| 422 | ValidationException | Invalid input, business rule violation |
| 429 | RateLimitException | Rate limit exceeded (auto-retried by client) |
| other 4xx/5xx | OrignaBaseException | Generic HTTP error |
| Network errors | NetworkException | Connection timeout, DNS failure, etc. |

---

### collection.dart
**Purpose**: Firestore-like collection and document references for CRUD operations. Implements reactive patterns via snapshots() for realtime subscriptions.

**Classes**:
- `CollectionRef extends Query` — reference to a collection.
- `DocumentRef` — reference to a single document.

**Public Methods (CollectionRef)**:
- `doc(String id)` → `DocumentRef` — returns DocumentRef for document with given ID.
- `subcollection(String docId, String childCollection)` → `SubcollectionRef` — returns reference to subcollection under parent document.
- `snapshots()` → `Stream<DocumentChange>` — realtime subscription to collection changes. Uses shared RealtimeClient connection. **WebSocket Call**: sends `{type: 'subscribe', collection: name}` message. Broadcasts DocumentChange events (create/update/delete) as they occur. Auto-reconnects on disconnect.
- `add(Map<String, dynamic> data)` → `Future<Document>` — add new document with auto-generated ID. **GraphQL Call**: POST mutation `create(collection: collectionName, data: data)`. Returns created Document.

**Public Methods (DocumentRef)**:
- `subcollection(String childCollection)` → `SubcollectionRef` — returns nested subcollection reference.
- `get()` → `Future<Document?>` — fetch document by ID. **GraphQL Call**: POST query `get(collection: collectionName, id: documentId)`. Returns null if not found (catches NotFoundException).
- `update(Map<String, dynamic> data)` → `Future<Document?>` — update document fields. **GraphQL Call**: Detects FieldValue sentinels, calls either `update(collection, id, data)` or `updateWithFieldValues(collection, id, fieldValues)` mutation depending on presence of FieldValue. Returns updated Document or null if not found.
- `set(Map<String, dynamic> data)` → `Future<Document?>` — create or replace entire document. **GraphQL Call**: POST mutation `set(collection: collectionName, id: documentId, data: data)`. Returns Document or null if collection doesn't exist.
- `delete()` → `Future<void>` — delete document by ID. **GraphQL Call**: POST mutation `delete(collection: collectionName, id: documentId)`. No return value (returns null if document already deleted).
- `snapshots()` → `Stream<DocumentChange>` — realtime subscription to single document changes. **WebSocket Call**: sends `{type: 'subscribe', collection: collectionName, document_id: documentId}` message. Broadcasts DocumentChange events when this specific document is created/updated/deleted. Auto-reconnects on disconnect.

**Internal Methods**:
- `_processFieldValues(Map<String, dynamic> data)` → `Map<String, dynamic>` — converts FieldValue sentinels to GraphQL format for mutations.

**Error Handling**:
- NotFoundException on get() returns null (suppressed, not thrown).
- NotFoundException on update/set/delete thrown if collection doesn't exist.
- Other HTTP errors (401, 403, 429, etc.) propagated from client layer.

**Token Management**:
- All GraphQL mutations inherit JWT auth from client (Bearer token auto-attached).
- Realtime subscriptions inherit Bearer token from auth service.

---

### query.dart
**Purpose**: Immutable Query builder implementing Firestore-style fluent query syntax. Supports filtering, ordering, pagination, and field selection. All methods return new Query instances (immutable pattern).

**Classes**:
- `Query` — base query builder (immutable).
- `QueryFilter` — internal filter representation (field, operator, value).
- `QuerySnapshot` — query result container (docs, hasMore, size, lastDocument).

**Public Methods**:
- `where(String field, {dynamic isEqualTo, isNotEqualTo, isGreaterThan, isGreaterThanOrEqualTo, isLessThan, isLessThanOrEqualTo, List<dynamic>? whereIn, dynamic contains, dynamic startsWith})` → `Query` — add filter condition, returns new Query (immutable). Only one operator per where() call (others must be null).
- `orderBy(String field, {bool descending = false})` → `Query` — set sort field and direction, returns new Query. Replaces previous orderBy.
- `limit(int count)` → `Query` — cap result count to N documents, returns new Query.
- `offset(int count)` → `Query` — skip first N results, returns new Query.
- `startAfter(Document document)` → `Query` — cursor-based pagination starting after given document's ID, returns new Query.
- `startAfterId(String documentId)` → `Query` — cursor pagination by document ID string, returns new Query.
- `select(List<String> fields)` → `Query` — field projection (fetch only specified fields), returns new Query.
- `get()` → `Future<QuerySnapshot>` — execute query and fetch results. **GraphQL Call**: POST mutation `list(collection: collectionName, filters: {...}, order_by: field, ascending: bool, limit: count, offset: count, select: [fields])`. Filters converted to GraphQL object format `{field: {_op: value}}` merged into single filters object. Implements N+1 pagination pattern (requests limit+1 documents to set hasMore flag). Returns QuerySnapshot with docs[], hasMore, size, lastDocument.
- `count()` → `Future<int>` — get count of documents matching query (without fetching documents). **GraphQL Call**: Similar to get() but uses `count()` aggregate instead of `list()`.

**Filter Operators Supported**:
- `isEqualTo` → `_eq`
- `isNotEqualTo` → `_ne`
- `isGreaterThan` → `_gt`
- `isGreaterThanOrEqualTo` → `_gte`
- `isLessThan` → `_lt`
- `isLessThanOrEqualTo` → `_lte`
- `whereIn` → `_in`
- `contains` → `_contains` (for strings/arrays)
- `startsWith` → `_startswith` (for strings)

**GraphQL Integration**:
- Filters merged into single object: `{field1: {_eq: value}, field2: {_gt: value}}`
- If no filters, passes empty object `{}`.
- Order: `{field: 'fieldName', ascending: !descending}`.
- Pagination: `{limit: limit, offset: offset}`.
- Selection: `{fields: ['field1', 'field2']}`.

**QuerySnapshot Methods**:
- `docs` (getter) → `List<Document>` — array of document results.
- `size` (getter) → `int` — number of documents returned (may be less than limit due to end-of-collection).
- `hasMore` (getter) → `bool` — whether more results exist beyond this page (determined by requesting limit+1 documents).
- `isEmpty` (getter) → `bool` — whether docs is empty.
- `isNotEmpty` (getter) → `bool` — whether docs is not empty.
- `lastDocument` (getter) → `Document?` — last document in results (useful for cursor pagination via startAfter()).

**Error Handling**:
- NotFoundException thrown if collection doesn't exist.
- ValidationException thrown if filter operators are invalid.
- Other HTTP errors propagated from client layer.

**Token Management**:
- GraphQL mutations inherit JWT auth from client.

---

### batch.dart
**Purpose**: WriteBatch accumulates create/update/delete operations and commits them grouped by operation type and collection. NOT truly atomic — operations grouped into separate GraphQL mutations per type.

**Classes**:
- `WriteBatch` — batch write accumulator.
- `_BatchOperation` (internal) — operation record (type, collection, id, data).
- `_BatchOpType` enum (internal) — `create`, `update`, `delete`.

**Public Methods**:
- `create(String collection, Map<String, dynamic> data)` → `void` — queue create operation with auto-generated ID.
- `createWithId(String collection, String id, Map<String, dynamic> data)` → `void` — queue create operation with specified ID.
- `update(String collection, String id, Map<String, dynamic> data)` → `void` — queue update operation (partial fields).
- `delete(String collection, String id)` → `void` — queue delete operation.
- `commit()` → `Future<List<Map<String, dynamic>>>` — execute all queued operations grouped by type. **GraphQL Calls**:
  - All creates grouped by collection: POST mutation `batchCreate(collection: collectionName, docs: [{data}, ...])`
  - All updates grouped by collection: POST mutation `batchUpdate(collection: collectionName, updates: [{id, data}, ...])`
  - All deletes grouped by collection: POST mutation `batchDelete(collection: collectionName, ids: [id1, id2, ...])`
  - Returns list of mutation results (one per operation type).
- `length` (getter) → `int` — number of operations queued.
- `isEmpty` (getter) → `bool` — whether batch is empty.
- `clear()` → `void` — discard all queued operations.

**Important Notes**:
- Operations grouped by type (creates, updates, deletes) sent as separate GraphQL mutations.
- If one mutation fails, previously completed mutations are NOT rolled back (not atomic).
- Operations within same type executed in order for each collection.

**FieldValue Processing**:
- Automatically converts FieldValue sentinels via `_processFieldValues()` before sending mutations.
- Example: `{views: FieldValue.increment(1)}` → `{views: {_increment: 1}}` before GraphQL call.

**Error Handling**:
- If any mutation fails, exception thrown and remaining mutations not executed.
- Partial results may exist in PostgreSQL if earlier mutations succeeded.
- Caller must handle cleanup/retry logic if batch partially fails.

**Token Management**:
- All GraphQL mutations inherit JWT auth from client.

---

### field_value.dart
**Purpose**: Sentinel values representing server-side operations for atomic updates. Converted to special GraphQL format before mutation execution.

**Classes**:
- `FieldValue` — immutable sentinel with `_type` and optional `_value`.

**Static Factory Methods**:
- `FieldValue.serverTimestamp()` → `FieldValue` — sets field to server's current timestamp (PostgreSQL `NOW()`).
- `FieldValue.increment(num value)` → `FieldValue` — increments numeric field by value (can be negative for decrement). Example: `.increment(-5)` decrements by 5.
- `FieldValue.arrayUnion(List<dynamic> elements)` → `FieldValue` — adds elements to array field (only if not already present). Idempotent across multiple calls.
- `FieldValue.arrayRemove(List<dynamic> elements)` → `FieldValue` — removes elements from array field (no error if element not present).
- `FieldValue.delete()` → `FieldValue` — deletes field entirely from document.

**Public Methods**:
- `toApiMap(String fieldName)` → `Map<String, dynamic>` — converts to GraphQL API format. Returns map like `{fieldName: {_marker: value}}` for use in `updateWithFieldValues` mutation.
- `type` (getter) → `String` — internal type identifier (for debugging).

**API Format Examples**:
- `FieldValue.serverTimestamp()` → `{'updated_at': {'_serverTimestamp': true}}`
- `FieldValue.increment(1)` → `{'views': {'_increment': 1}}`
- `FieldValue.increment(-5)` → `{'balance': {'_increment': -5}}`
- `FieldValue.arrayUnion(['dart'])` → `{'tags': {'_arrayUnion': ['dart']}}`
- `FieldValue.arrayRemove(['old'])` → `{'tags': {'_arrayRemove': ['old']}}`
- `FieldValue.delete()` → `{'temp_field': {'_delete': true}}`

**Usage Pattern**:
```dart
doc.update({
  'views': FieldValue.increment(1),
  'updated_at': FieldValue.serverTimestamp(),
  'tags': FieldValue.arrayUnion(['featured']),
});
```

**Error Handling**:
- Invalid field names → ValidationException from server.
- Type mismatch (e.g., increment on non-numeric field) → ValidationException from server.

**Token Management**:
- FieldValue mutations inherit JWT auth from client.

---

### realtime.dart
**Purpose**: WebSocket-based realtime subscriptions with automatic reconnection using exponential backoff. Manages subscriptions, handles incoming events, and re-registers subscriptions after reconnect.

**Classes**:
- `RealtimeClient` — WebSocket connection manager.
- `ChangeType` enum — `create`, `update`, `delete`.
- `DocumentChange` — event containing type and document.
- `_SubEntry` (internal) — subscription registration record.

**Public Methods**:
- `connect()` → `void` — establish WebSocket connection to `/realtime` endpoint. Injects Bearer token if available. Re-registers all active subscriptions after successful connect.
- `disconnect()` → `void` — close WebSocket permanently and cleanup all resources. Closes all subscription stream controllers.
- `subscribeDocument(String collection, String documentId)` → `Stream<DocumentChange>` — subscribe to single document changes. **WebSocket Call**: sends `{type: 'subscribe', id: subId, collection: collection, document_id: documentId}`. Returns broadcast stream. Automatically unsubscribes when stream is cancelled.
- `subscribe(String collection, {String? filter})` → `Stream<DocumentChange>` — subscribe to all changes in collection with optional filter. **WebSocket Call**: sends `{type: 'subscribe', id: subId, collection: collection, filter: filter}` (filter omitted if null). Returns broadcast stream. Filter format: same as query filters (e.g., `{status: {_eq: 'active'}}`).

**WebSocket Protocol**:
- Subscribe message: `{type: 'subscribe', id: subId, collection: collectionName, document_id?: docId, filter?: filterObj}`
- Unsubscribe message: `{type: 'unsubscribe', id: subId}`
- Incoming message: `{subscription_id: subId, event: {action: 'create'|'update'|'delete', collection: collectionName, document_id: docId, data: {...}}}`

**Auto-Reconnect**:
- Exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s (capped).
- Triggered on socket disconnect or error.
- All active subscriptions automatically re-registered after successful reconnect.

**Token Management**:
- Token from `_client.auth.accessToken` getter.

**Internal Methods**:
- `_doConnect()` → `void` — establish WebSocket connection with headers, parse URI (convert http/https to ws/wss), re-register all active subscriptions, reset reconnect counter.
- `_scheduleReconnect()` → `void` — schedule reconnection attempt with exponential backoff.
- `_backoffDuration()` → `Duration` — calculate backoff: `(1 << attempt).clamp(1, 30)` seconds.
- `_sendSubscribe(_SubEntry sub)` → `void` — send subscription JSON message via WebSocket.
- `_unsubscribe(String subId)` → `void` — send unsubscribe message and close stream controller.
- `_handleMessage(dynamic rawMessage)` → `void` — parse incoming JSON, extract subscription ID and event, dispatch DocumentChange to appropriate stream.

**Error Handling**:
- Connection errors (DNS failure, timeout) trigger automatic reconnection.
- Invalid message format silently ignored.
- Subscription stream errors logged and reconnection scheduled.

---

### storage.dart
**Purpose**: File upload/download via 2-step presigned URL pattern. Supports regular uploads and resumable uploads with chunking and progress tracking.

**Classes**:
- `OrignaBaseStorage` — storage service.
- `UploadTask` — resumable upload with progress tracking.
- `UploadProgress` — progress snapshot.

**Public Methods (OrignaBaseStorage)**:
- `upload(String path, Uint8List data, {String contentType = 'application/octet-stream'})` → `Future<Map<String, dynamic>>` — regular file upload. **Flow**: (1) POST `/storage/presign/upload` with `{paths: [path], ttl_secs: 3600}` → get `upload_url`. (2) PUT data to signed URL with `Content-Type: contentType` header. Returns response map.
- `download(String path)` → `Future<Uint8List>` — download file. **Flow**: (1) POST `/storage/presign/download` with `{paths: [path], ttl_secs: 3600}` → get `download_url`. (2) GET from signed URL. Returns file bytes.
- `delete(String path)` → `Future<void>` — delete file. **HTTP Call**: POST `/storage/batch-delete` with `{paths: [path]}`.
- `uploadResumable(String path, Uint8List data, {String contentType = 'application/octet-stream', int chunkSize = 256 * 1024})` → `UploadTask` — start resumable upload with default 256KB chunks. Returns UploadTask immediately (non-blocking).
- `resumeUpload(String sessionId, Uint8List data, {int chunkSize = 256 * 1024})` → `UploadTask` — resume interrupted upload from session ID.

**UploadTask Methods**:
- `onProgress` (setter) → `void` — register progress callback: `(UploadProgress progress) { /* ... */ }`.
- `future` (getter) → `Future<Map<String, dynamic>>` — completes when upload finishes, resolves with response map.
- `sessionId` (getter) → `String?` — session ID (available after init, null before).
- `cancel()` → `Future<void>` — cancel resumable upload. **HTTP Call**: DELETE `/storage/upload/resumable/{sessionId}`.

**Resumable Upload Flow**:
1. **Init**: POST `/storage/upload/resumable` with `{path, content_type, total_size}` → returns `{id: sessionId, bytes_received: offset}`.
2. **Check**: GET `/storage/upload/resumable/{sessionId}?action=status` → returns current `bytes_received` offset.
3. **Upload Chunk**: PATCH `/storage/upload/resumable/{sessionId}` with chunk data + header `Upload-Offset: currentOffset` → returns `{bytes_received: newOffset}`.
4. **Repeat** until `bytes_received >= total_size`.

**UploadProgress**:
- `bytesTransferred` (getter) → `int` — bytes uploaded so far.
- `totalBytes` (getter) → `int` — total file size.
- `sessionId` (getter) → `String?` — resumable session ID.
- `fraction` (getter) → `double` — progress as 0.0–1.0.
- `isComplete` (getter) → `bool` — whether upload finished.

**URL Rewriting**:
- If server returns local address (0.0.0.0) in presigned URL, SDK rewrites to client's base URL host for cross-origin access.

**Error Handling**:
- NotFoundException thrown if download presign fails (path doesn't exist).
- OrignaBaseException thrown if upload presign fails.
- RateLimitException (429) triggers automatic retry (client layer).
- NetworkException on connection loss (resumable upload can be resumed).

**Token Management**:
- Presign requests include JWT auth (Bearer token).
- Upload/download to signed URLs do NOT include JWT (URL is self-authenticating, expires in 1 hour).

---

### offline.dart
**Purpose**: Offline-first cache with persistent write queue and automatic replay on reconnect. Allows app to queue writes while offline and auto-replay when online.

**Classes**:
- `OfflineCache` — in-memory cache with persistent write queue.
- `PendingWrite` — queued write operation (id, collection, operation, data, documentId, createdAt, retries).

**Public Methods**:
- `bindClient(OrignaBase client)` → `void` — bind to client for replay operations.
- `isOnline` (getter/setter) → `bool` — current online/offline status. Setting to true triggers `replayQueue()`.
- `pendingCount` (getter) → `int` — number of pending writes.
- `pendingWriteCount` (stream) → `Stream<int>` — broadcast stream emitting pending write count changes.
- `replayQueue()` → `Future<void>` — replay all pending writes in order. Removes write on success, increments retry counter on failure. Continues despite individual failures.
- `clearAll()` → `Future<void>` — clear all cached data and write queue.
- `cache(String collection, String id, Map<String, dynamic> data)` → `void` — cache document locally.
- `getCached(String collection, String id)` → `Map<String, dynamic>?` — retrieve cached document.
- `queueWrite(String collection, String operation, String documentId, Map<String, dynamic> data)` → `Future<void>` — queue write operation (create/update/delete) for replay.

**Pending Write Persistence**:
- Writes persisted as JSON in `OfflineStorage` (platform-specific: SharedPreferences on Android, UserDefaults on iOS, localStorage on web).
- Each write has: `id` (UUID), `collection`, `operation` (create/update/delete), `data`, `documentId`, `createdAt` (timestamp), `retries` (counter).
- On app restart, queue auto-loaded from persistent storage.

**Replay Logic**:
- Writes replayed in order (FIFO by `createdAt`).
- Operation `create` → `client.collection(name).add(data)`.
- Operation `update` → `client.collection(name).doc(id).update(data)`.
- Operation `delete` → `client.collection(name).doc(id).delete()`.
- On success: write removed from queue.
- On failure: retry counter incremented, write stays in queue (will retry on next online event or manual `replayQueue()` call).
- Max retries configurable (default 10); writes exceeding max retries marked as failed and logged.

**Error Handling**:
- Individual write failures don't stop replay of subsequent writes.
- Failed writes logged with retry count for manual intervention.
- `replayQueue()` throws only if binding is null (no client bound).

**Token Management**:
- Offline operations use client's current token when replayed (captured at replay time, not at queue time).

---

### document.dart
**Purpose**: Document representation and query result container.

**Classes**:
- `Document` — represents a single document with id, collection, and data.
- `QuerySnapshot` — query result container (docs list, pagination info).

**Document Methods**:
- `exists` (getter) → `bool` — whether document ID is non-empty.
- `id` (getter) → `String` — document ID.
- `collection` (getter) → `String` — collection name.
- `data` (getter) → `Map<String, dynamic>` — document data.
- `get<T>(String field)` → `T?` — get typed field value.
- `operator [](String key)` → `dynamic` — map-like access to data (returns data[key]).
- `containsKey(String key)` → `bool` — check if field exists in data.
- `fromMap(String collection, Map<String, dynamic> map)` (factory) → `Document` — creates Document from map. Strips internal fields (`_id`, `_rev`, `_created`, `_updated`). Normalizes nanosecond timestamps to microsecond precision for Dart DateTime.parse compatibility.
- `toMap()` → `Map<String, dynamic>` — returns document data map.

**QuerySnapshot Methods**:
- `docs` (getter) → `List<Document>` — list of document results (may be empty).
- `size` (getter) → `int` — number of documents returned.
- `hasMore` (getter) → `bool` — whether more results exist beyond current page.
- `isEmpty` (getter) → `bool` — whether docs list is empty.
- `isNotEmpty` (getter) → `bool` — whether docs list is not empty.
- `lastDocument` (getter) → `Document?` — last document in results (null if empty).

---

### subcollection.dart
**Purpose**: Emulate Firestore subcollections using double-underscore naming convention and automatic parent ID injection. Allows nested collection syntax without server-side subcollection support.

**Classes**:
- `SubcollectionRef extends Query` — subcollection reference.
- `_SubcollectionQuery extends Query` (internal) — query wrapper that auto-injects parent filter.

**Design Pattern**:
- Firestore path `/users/{uid}/orders` → PostgreSQL table `users__orders` (double underscore separator).
- Parent document ID stored in `parent_id` field on each child document.
- Example: orders for user `users:user123` have `parent_id: 'users:user123'`.

**Public Methods (SubcollectionRef)**:
- `doc(String id)` → `DocumentRef` — returns DocumentRef for document in subcollection.
- `add(Map<String, dynamic> data)` → `Future<Document>` — add to subcollection. Automatically injects `parent_id` and `parent_collection` fields before creating. **GraphQL Call**: creates document with injected fields.
- `get()` → `Future<QuerySnapshot>` — query subcollection. Automatically prepends `parent_id` filter before execution. Returns QuerySnapshot.
- `subcollection(String docId, String nestedCollection)` → `SubcollectionRef` — nested subcollection (3+ levels, e.g., orders/order123/items).
- `where(String field, {...})` → `_SubcollectionQuery` — add filter (returns _SubcollectionQuery wrapper).
- `orderBy(String field, {bool descending = false})` → `_SubcollectionQuery` — set order (returns wrapper).
- `limit(int count)` → `_SubcollectionQuery` — cap results (returns wrapper).
- `offset(int count)` → `_SubcollectionQuery` — skip results (returns wrapper).
- `select(List<String> fields)` → `_SubcollectionQuery` — field projection (returns wrapper).
- `snapshots()` → `Stream<DocumentChange>` — realtime subscription to subcollection. Filters received events by `parent_id` before dispatching.

**Internal (SubcollectionRef)**:
- `_SubcollectionQuery` wraps base Query and injects `parent_id` filter in `get()` before execution.
- All where/orderBy/limit/offset methods return _SubcollectionQuery to preserve parent context.

**Error Handling**:
- NotFoundException thrown if parent collection doesn't exist (when attempting to filter by parent_id).
- Other HTTP errors propagated normally.

**Token Management**:
- GraphQL calls inherit JWT auth from client.

---

### config.dart
**Purpose**: Remote Config (Firebase Remote Config replacement). Key-value configuration system with admin-only write access.

**Classes**:
- `OrignaBaseConfig` — config service.

**Public Methods**:
- `getAll()` → `Future<Map<String, dynamic>>` — fetch all config key-value pairs. **HTTP Call**: GET `/config`. Returns map of all keys.
- `get(String key)` → `Future<dynamic>` — fetch single config value. **HTTP Call**: GET `/config/{key}`. Returns value (type varies).
- `getString(String key)` → `Future<String>` — fetch as string. Returns empty string if not found or invalid type.
- `getBool(String key)` → `Future<bool>` — fetch as bool. Returns false if not found, parses string 'true'/'false'.
- `getInt(String key)` → `Future<int>` — fetch as int. Returns 0 if not found or invalid type.
- `getDouble(String key)` → `Future<double>` — fetch as double. Returns 0.0 if not found or invalid type.
- `set(String key, dynamic value)` → `Future<void>` — set config value (admin only). **HTTP Call**: PUT `/_admin/config/{key}` with value in body. Throws ForbiddenException if not admin.
- `delete(String key)` → `Future<void>` — delete config key (admin only). **HTTP Call**: DELETE `/_admin/config/{key}`. Throws ForbiddenException if not admin.

**Error Handling**:
- NotFoundException thrown if key doesn't exist.
- ForbiddenException thrown if trying to set/delete without admin role.
- Type conversion errors return default values (getters never throw on type mismatch).

**Token Management**:
- Set/delete operations require JWT auth with admin role.

---

### aggregate.dart
**Purpose**: Build SQL aggregate queries (COUNT, SUM, AVG) with filtering.

**Classes**:
- `AggregateQuery extends Query` — aggregate query builder.

**Public Methods**:
- `toCountQuery()` → `Map<String, dynamic>` — builds `SELECT count() as total FROM collection WHERE ... GROUP ALL` query. Returns query map for POST to `/api/query`.
- `toSumQuery(String field)` → `Map<String, dynamic>` — builds `SELECT math::sum(field) as total FROM collection WHERE ...` query. Returns query map.
- `toAvgQuery(String field)` → `Map<String, dynamic>` — builds `SELECT math::mean(field) as average FROM collection WHERE ...` query. Returns query map.

**Operator Mapping** (for WHERE clause):
| Filter Operator | SQL Operator |
|---|---|
| `_eq` | `=` |
| `_ne` | `!=` |
| `_gt` | `>` |
| `_gte` | `>=` |
| `_lt` | `<` |
| `_lte` | `<=` |
| `_in` | `IN` |
| `_contains` | `CONTAINS` |
| `_startswith` | `~` |

**Internal Methods**:
- `_filterToSqlCondition(QueryFilter filter)` → `String` — converts QueryFilter to SQL WHERE clause syntax (e.g., `field = value`, `field > 100`, `field IN [1, 2, 3]`).

**Error Handling**:
- Invalid field names → validation error from PostgreSQL.
- Type mismatches (e.g., SUM on non-numeric field) → PostgreSQL error.

**Token Management**:
- Query requests include JWT auth (Bearer token).

---

This completes the comprehensive function-level documentation for the OrignaBase Flutter SDK, covering all 15 Dart modules with method signatures, HTTP/GraphQL calls, error handling, and token management patterns.