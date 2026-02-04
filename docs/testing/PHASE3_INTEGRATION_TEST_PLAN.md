# Phase 3 Integration - Test Plan

## ✅ Session Timeout Testing

### Manual Tests (Staging)
1. **Basic Timeout**
   ```
   - Login to app
   - Wait 1 hour (or temporarily reduce timeout to 1 min for testing)
   - Observe auto-logout + snackbar notification
   - Verify redirected to login screen
   ```

2. **Activity Reset**
   ```
   - Login to app
   - After 30 min, tap anywhere in the app
   - Verify timer resets (check logs: "recordActivity" called)
   - Wait another 30 min without interaction
   - Should NOT timeout (timer was reset)
   ```

3. **Multi-User Scenario**
   ```
   - Login as User A
   - Switch to User B (new browser/device)
   - User A should timeout independently
   - Verify no cross-contamination
   ```

### Automated Test (Flutter)
```dart
// test/integration_test/session_timeout_test.dart
testWidgets('Session timeout after 1 hour inactivity', (tester) async {
  // Mock time and Firebase Auth
  await tester.pumpWidget(ProviderScope(child: OrignaApp()));
  
  // Login
  // ... authenticate user
  
  // Fast-forward time 1 hour
  await tester.pump(Duration(hours: 1));
  
  // Verify logout occurred
  expect(find.byType(LoginScreen), findsOneWidget);
  expect(find.text('Session expired'), findsOneWidget);
});
```

---

## ✅ Rate Limiting Testing

### Manual Tests (Staging)

#### Test 1: `create_checkout` (5 req/1min)
```bash
# Send 6 requests in 30 seconds
for i in {1..6}; do
  curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/create_checkout_session \
    -H "Content-Type: application/json" \
    -d '{"items": [{"productId": "test123", "quantity": 1}]}'
  sleep 5
done

# Expected: First 5 succeed, 6th returns 429 "Rate limit exceeded"
```

#### Test 2: `create_connect_account` (5 req/hour)
```bash
# Send 6 requests immediately
for i in {1..6}; do
  curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/create_connect_account \
  echo "Request $i sent"
done

# Expected: First 5 succeed (or return "already exists"), 6th returns 429
```

#### Test 3: `create_account_link` (10 req/5min)
```bash
# Send 11 requests in 2 minutes
for i in {1..11}; do
  curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/create_account_link \
    -H "Content-Type: application/json" \
    -d '{"refreshUrl": "...", "returnUrl": "..."}'
  sleep 10
done

# Expected: First 10 succeed, 11th returns 429
```

### Verify Rate Limiter Firestore Collection
```bash
# Check rate_limits collection in Firestore Console
# Should see documents like:
# - create_checkout_user_ABC123: {count: 5, first_request: ..., last_request: ...}
# - create_connect_account_ip_1.2.3.4: {count: 5, ...}

# After window expires, count should reset to 1
```

---

## ✅ KYC/Sanctions Check Testing

### Manual Tests (Staging)

#### Test 1: Normal User (Should Pass)
```bash
# Register seller with normal name
curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/create_connect_account \

# Expected: Success, Stripe account created
# Logs: "✅ KYC check passed for john@example.com"
```

#### Test 2: Blocked Keywords (Should Fail)
```bash
# Register seller with sanctioned keyword in name
# User display name: "Terrorist Organization Test"
curl -X POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/create_connect_account \

# Expected: 403 PERMISSION_DENIED
# Response: "Unable to complete seller registration. Please contact support."
# Logs: "🚨 SANCTIONS ALERT: User XYZ failed KYC check: Matched sanctions keyword: terrorist"
# Firestore: security_alerts collection has new document
```

#### Test 3: Check Security Alerts Collection
```javascript
// Firestore Console → security_alerts collection
// Should contain documents like:
{
  type: 'sanctions_match',
  userId: 'ABC123',
  userName: 'Terrorist Test',
  userEmail: 'test@blocked.com',
  reason: 'Matched sanctions keyword: terrorist',
  action: 'seller_registration_blocked',
  timestamp: Timestamp(...)
}
```

---

## 🚀 Production Readiness Checklist

### Before Launch
- [ ] Replace `_check_sanctions_list()` placeholder with real KYC API
  - [ ] Sign up for ComplyAdvantage (or Trulioo/Onfido)
  - [ ] Add API key to Firebase Functions secrets
  - [ ] Test API integration in staging
  - [ ] Add retry logic + timeout (5s max)
  - [ ] Fail open on API errors (log alert, allow signup)

- [ ] Session Timeout Integration
  - [ ] Verify `OrignaApp` correctly wraps with `GestureDetector`
  - [ ] Test on Web, Android, iOS (all platforms)
  - [ ] Ensure no BuildContext leak across async boundary
  - [ ] Confirm snackbar shows before navigation

- [ ] Rate Limiting
  - [ ] Consider migrating to Redis (Firestore has latency + cost at scale)
  - [ ] Add monitoring alerts for high rate limit hits
  - [ ] Tune limits based on real traffic patterns
  - [ ] Document limits in API docs

### Monitoring & Alerts
- [ ] Set up Sentry alerts for:
  - [ ] KYC API failures (> 5% error rate)
  - [ ] Rate limit exhaustion (> 1000/day per user)
  - [ ] Session timeout errors
  
- [ ] Firebase Console monitoring:
  - [ ] Functions error rate < 0.1%
  - [ ] Functions execution time < 5s
  - [ ] Rate limiter Firestore reads < 10k/day

### Performance Targets
- Session timeout: No performance impact (timer runs in background)
- Rate limiting: +50ms per request (Firestore read)
- KYC check: +500ms per seller registration (API call)

---

## 📝 Test Execution Log

### Session Timeout
- [ ] Manual test (1h timeout): ___________
- [ ] Activity reset test: ___________
- [ ] Multi-user test: ___________

### Rate Limiting
- [ ] create_checkout (5/1min): ___________
- [ ] create_connect_account (5/1h): ___________
- [ ] create_account_link (10/5min): ___________
- [ ] Firestore collection verified: ___________

### KYC/Sanctions
- [ ] Normal user passes: ___________
- [ ] Blocked keyword fails: ___________
- [ ] Security alerts logged: ___________
- [ ] Production API integrated: ___________

---

## 🔧 Rollback Plan

If issues found in production:

1. **Session Timeout Bug**
   ```dart
   // Temporarily disable in OrignaApp
   // Comment out: _sessionTimeout.startMonitoring(context);
   ```

2. **Rate Limiting Too Strict**
   ```python
   # In functions/main.py, increase limits:
   max_requests=10,  # was 5
   window_minutes=2   # was 1
   ```

3. **KYC API Down**
   ```python
   # Temporarily fail open (already implemented):
   # On API error, log alert but allow signup
   return False, "KYC check temporarily unavailable"
   ```

---

## 📊 Success Metrics

- **Session Timeout**: < 0.1% false positives (users logged out during activity)
- **Rate Limiting**: < 1% legitimate requests blocked
- **KYC Check**: 0 false negatives (no sanctioned users approved)
- **Performance**: P95 latency increase < 100ms
