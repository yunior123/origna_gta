# STATE.md

Audited compliance violations across consent, privacy, and email systemsAudited compliance violations across consent, privacy, and email systemsLet me read the remaining uploaded files to do a thorough audit.Reading all uploaded files for auditScriptLet me read the remaining uploaded files to do a thorough audit.Read login screenScriptNow let me read the remaining files.Read remaining filesScriptNow I have all the files. Let me analyze them carefully for the compliance audit findings. Let me go through each checklist item:

CASL consent - marketing opt-in checkbox exists in login_screen but handleAuth() is called WITHOUT passing marketingOptIn. And in create_user_profile, MARKETING_OPT_IN is hardcoded to False regardless of what user chose.
PIPEDA/Quebec Law 25 - Privacy policy acceptance not tracked separately. Terms/privacy consent doesn't record termsVersion or privacyPolicyVersion explicitly at signup time (though create_user_profile does set these with PolicyVersionValues.DEFAULT). But marketingOptIn isn't passed from UI → backend.
Terms acceptance - The signup flow only sends email/password/name to the backend, omitting marketingOptIn and terms version entirely. The backend does set these fields serverside at PolicyVersionValues.DEFAULT but never captures IP address or user agent data.
Terms version - terms_provider.dart pulls from Remote Config with a hardcoded fallback, so there's no actual version tracking happening.
Privacy policy screen - It's just loading from a translation key with no version information displayed to users.
Unsubscribe flow - The unsubscribe URL generation uses HMAC signing, but the order confirmation email function appears to be cut off mid-call.

The unsubscribe link generation doesn't pass the recipient's email address, so the signed URL won't be properly personalized for each recipient.

Physical address - Included in the footer.
Language selector - Updates Firestore but doesn't sync with email preferences.
Minor protection - No age verification at signup.
Terms screen accuracy - The terms screen only displays the year from DateTime.now(), not the full date. Terms themselves come from Remote Config with hardcoded fallback values.
Legal screen - Hardcodes "Last updated February 2026" around line 200.

Now I'm identifying the critical issues, starting with the login screen's handleAuth() call around line 240.
The backend never receives the marketing opt-in consent, so CASL compliance isn't actually being tracked. The order confirmation email calls the footer function without the recipient's email, which means the unsubscribe URL falls back to a generic one instead of being personalized. Terms are pulled from Remote Config with hardcoded fallbacks and no version history, which breaks the audit trail requirement. Privacy policy content comes from translation keys with no version information displayed. User consent records don't capture IP address or user agent. The legal screen hardcodes an outdated date. The email service has a hardcoded dev fallback for the unsubscribe secret.
The email consent update logic lacks a state machine, so users can re-opt-in after explicitly unsubscribing without going through the consent flow again. Language changes don't sync to email service metadata. The terms screen only shows year-level precision instead of exact dates. The marketing opt-in is always set to false regardless of what the user actually selected. In the login screen, the marketing checkbox appears in both login and signup modes when it should only show during signup. Looking closer at the code, the checkbox is outside the login mode conditional block, so it's rendering in both flows. The terms links also seem incomplete.
The terms and privacy policy links display current content, but the backend accepts a hardcoded default policy version with no verification that what's displayed matches what's being accepted. There's no age gate at signup yet. Several transactional emails skip the recipient email parameter when calling the wrapper, so personalized unsubscribe URLs aren't being generated. The quick navigation pill in the terms screen is 38px tall, which falls below WCAG 2.5.8 touch target requirements.
Now I need to verify the consent method values match between Dart and Python implementations, and document the exact line numbers for these issues.Afficher plusTerminé[CRITICAL] login_screen.dart:~240
PROBLEM: handleAuth() called with only email/password/name — marketingOptIn state is never passed to backend, so CASL consent is silently dropped on every signup.
FIX: Add marketingOptIn: state.marketingOptIn param to handleAuth() call, and propagate it from handleAuth → create_user_profile Cloud Function request.
[CRITICAL] email_service.py:~490 (get_order_confirmation_email)
PROBLEM: _casl_compliant_footer(include_gst=True, lang=lang) called without recipient_email — falls back to generic unsigned UNSUBSCRIBE_URL instead of a signed per-user URL, making the unsubscribe link non-functional and non-CASL-compliant for this email.
FIX: Add recipient_email=order_data.get(Fields.CUSTOMER_EMAIL, '') to this footer call (same pattern used in send_payment_capture_failed_email).
ALSO: email_service.py:~560 (get_order_shipped_email), ~620 (get_order_delivered_email), ~670 (get_order_cancelled_email), ~730 (get_order_processing_email) — all call _email_wrapper without recipient_email, so same unsigned URL bug applies.
[HIGH] login_screen.dart:~205
PROBLEM: Marketing opt-in Checkbox is rendered outside the if (!state.isLogin) block — it appears on the login form too, which is nonsensical and misleads users about CASL consent scope.
FIX: Wrap the marketing opt-in Row in if (!state.isLogin) same as the terms checkbox block.
[HIGH] users.py:~90 (create_user_profile)
PROBLEM: Fields.MARKETING_OPT_IN is always hardcoded to False regardless of client-sent value — actual user CASL opt-in is silently ignored even once the frontend passes it.
FIX: Read marketing_opt_in = bool(data.get(Fields.MARKETING_OPT_IN, False)) and use it in the user_ref.set(...) call.
[HIGH] users.py:~90 (create_user_profile)
PROBLEM: No IP address or user agent recorded in consent record — PIPEDA requires full audit trail of consent circumstances.
FIX: Extract client_ip = req.raw_request.headers.get('X-Forwarded-For', '') and user_agent = req.raw_request.headers.get('User-Agent', '') from the Cloud Function request; write to Fields.CONSENT_IP and Fields.CONSENT_USER_AGENT.
[HIGH] terms_provider.dart:~60
PROBLEM: Terms loaded from Firebase Remote Config with hardcoded 600-line fallback string — there is zero version tracking, so the version accepted by the user (PolicyVersionValues.DEFAULT) is disconnected from the actual content displayed.
FIX: Move terms to config/{terms_and_conditions} Firestore doc with content + version + updatedAt fields; return both fields from the provider so TermsScreen can display the version and pass it to handleAuth at signup.
[HIGH] privacy_policy_screen.dart:~10
PROBLEM: Privacy policy loaded from 'legal.privacy_policy_content'.tr() translation key — no version displayed, no guarantee the content matches the PolicyVersionValues.DEFAULT version recorded in Firestore at signup.
FIX: Fetch from config/{privacy_policy} Firestore doc (same pattern as terms); display version number in LegalScreenBody hero subtitle.
[HIGH] legal_screen_body.dart:~200
PROBLEM: 'Last updated February 2026' hardcoded in _buildHeroHeader — will become immediately stale after first policy update, violating accuracy requirement.
FIX: Add lastUpdated DateTime? param to LegalScreenBody; fetch from Firestore updatedAt field; format dynamically via DateFormat.yMMMMd().
[HIGH] email_service.py:~25
PROBLEM: _UNSUBSCRIBE_SECRET falls back to hardcoded "origna-unsub-default-dev-key" if secret is empty — a misconfigured production environment silently signs tokens with a guessable key, allowing anyone to forge unsubscribe URLs.
FIX: At module load time, if not IS_EMULATOR and not _raw_unsub_secret: raise RuntimeError("UNSUBSCRIBE_HMAC_SECRET not set in production").
[MEDIUM] terms_screen.dart:~380
PROBLEM: Hero displays 'Last updated ${DateTime.now().year}' — only year precision, and DateTime.now() is the build time rather than the actual policy update date, violating version accuracy requirement.
FIX: Pass updatedAt from Firestore provider and display full date, e.g. DateFormat('MMMM d, y').format(updatedAt).
[MEDIUM] language_selector.dart:~65
PROBLEM: updatePreferredLanguage() updates Firestore preferredLanguage but never propagates to email service metadata (Mailjet custom fields) — users continue receiving emails in the wrong language.
FIX: After updating Firestore, call a backend update_user_profile endpoint that writes preferredLanguage to Mailjet contact properties via Mailjet Contacts API.
[MEDIUM] users.py:~260 (update_email_consent)
PROBLEM: Re-opt-in allowed unconditionally even if unsubscribedAt exists — CASL requires a new express consent flow (not just a toggle) to re-subscribe after an explicit unsubscribe.
FIX: Before updating, existing = user_doc.to_dict(); if email_consent and existing.get('unsubscribedAt'): raise HttpsError('failed-precondition', 'Must complete re-consent flow').
[LOW] login_screen.dart:~175
PROBLEM: Terms/privacy links open openTermsOfService(context) / openPrivacyPolicy(context) which display current live content, but the version recorded at signup is PolicyVersionValues.DEFAULT — if content changed since last deploy, the user accepts a different version than what they read.
FIX: After migrating terms/privacy to Firestore, pass the fetched version into handleAuth at signup so the recorded version matches the displayed one.
[BONUS] login_screen.dart:~1
PROBLEM: No age gate at signup — minors can register freely; PIPEDA requires parental consent for users under 13, and Quebec Law 25 has additional protections for minors.
FIX: Add age confirmation checkbox 'I confirm I am 13 years of age or older' in the signup form; gate handleAuth on it; record ageConfirmedAt: server_ts in create_user_profile.
[BONUS] email_service.py:~380
PROBLEM: _casl_compliant_footer includes Privacy: <privacy_officer_email> but no phone number — Quebec Law 25 Art. 3.1 requires the DPO to be reachable by a second accessible means.
FIX: Add EmailConfig.PRIVACY_OFFICER_PHONE constant; include in footer: Privacy: {email} | {phone}.
[BONUS] terms_screen.dart:~310
PROBLEM: Quick nav pill SizedBox(height: 38) — 38dp touch target is below WCAG 2.5.8 minimum of 44dp.
FIX: Change to SizedBox(height: 44) and ensure the inner pill Container also has constraints: BoxConstraints(minHeight: 44).
[BONUS] terms_screen.dart:~320 & legal_screen_body.dart:~310
PROBLEM: Section nav pills use GestureDetector without Semantics(button: true) — not keyboard/screen-reader accessible.
FIX: Wrap in Semantics(button: true, label: 'Jump to section ${section.number}') and handle onKeyEvent for Enter/Space.
[BONUS] schema_constants.dart:ConsentMethodValues (if present)
PROBLEM: ConsentMethodValues in Dart must include userPreference and unsubscribe — users.py uses ConsentMethodValues.USER_PREFERENCE and ConsentMethodValues.UNSUBSCRIBE but Dart enum may be missing these, causing silent null on Dart-side reads.
FIX: Verify schema_constants.dart has static const userPreference = 'user_preference' and static const unsubscribe = 'unsubscribe'; add if missing.
[BONUS] users.py:~240 (update_email_consent)
PROBLEM: Sets unsubscribedAt implicitly via consentMethod = UNSUBSCRIBE but never actually writes an unsubscribedAt timestamp field — making future re-consent state-machine check (above) impossible.
FIX: Add Fields.UNSUBSCRIBED_AT: get_server_timestamp() if not email_consent else firestore.DELETE_FIELD to the user_ref.update(...) call.
[BONUS] terms_provider.dart:~55
PROBLEM: remoteConfig.getString('terms_and_conditions') returns empty string on first launch or cache miss, then falls back to hardcoded content — no differentiation between "offline" and "no policy set", making it impossible to detect a missing configuration.
FIX: Log a Sentry warning when falling back; after migrating to Firestore this fallback path becomes unreachable and should throw.
[BONUS] login_screen.dart:~170
PROBLEM: 'I agree to the ' and 'Terms & Conditions' and ' and ' and 'Privacy Policy' are hardcoded English strings in RichText — not localised via easy_localization, breaking Bill 96 compliance for French-speaking users.
FIX: Replace with 'auth.terms_consent_text'.tr() supporting two named placeholders {terms} and {privacy}, and use TextSpan composition with localised links.

```
[CRITICAL] functions/main.py:handler imports (lines ~43-130)
PROBLEM: All handler modules are imported at module level BEFORE firebase_admin.initialize_app() (line ~155). Any handler that calls firestore.client() or auth at module level will crash on cold start with "Firebase app not initialized."
FIX: Move firebase_admin.initialize_app() to the top of the file, immediately after the monkey-patch block and before any handler imports.

[HIGH] lib/utils/utils.dart:addToCart (~line 220)
PROBLEM: cartRef.where(...).get() is a collection query executed inside a Firestore runTransaction — collection queries inside transactions are NOT retried and NOT isolated, breaking the stock-check atomicity. Two concurrent addToCart calls can both read qty=0 and both succeed, overselling stock.
FIX: Store cart items as a known document ID (e.g., cartRef.doc(productId)) so transaction.get(cartRef.doc(productId)) is used instead of a collection query inside the transaction.

[HIGH] lib/utils/utils.dart:calculateShippingCost (~line 270)
PROBLEM: Geoapify API key (ConfigService().geoapifyKey) is embedded in a direct HTTP call from the Flutter frontend — the key is visible in the compiled JS bundle, exposing it to any user inspecting network traffic.
FIX: Proxy all Geoapify routing calls through a Cloud Function (the calculate_shipping_cost function already exists); remove the direct Geoapify HTTP call from the client.

[HIGH] functions/config.py:PLATFORM_FEE_PERCENT (~line 112)
PROBLEM: PLATFORM_FEE_PERCENT = PLATFORM_FEE_RATIO (= 0.025) aliases a ratio to a name implying a percentage. Any handler that multiplies by PLATFORM_FEE_PERCENT expecting 2.5 will silently compute a 0.025% fee (100× too small).
FIX: Delete the PLATFORM_FEE_PERCENT alias entirely; all callers must use PLATFORM_FEE_RATIO with a comment clarifying it is a ratio.

[HIGH] functions/config.py:init_sentry (~line 287)
PROBLEM: options.environment is hardcoded to "production" regardless of CURRENT_ENV. DEV and STAGING errors are logged as production in Sentry, making triage impossible and polluting production dashboards.
FIX: Replace hardcoded "production" with CURRENT_ENV.value (yields "dev", "staging", "production", or "emulator").

[MEDIUM] lib/screens/common_screens.dart:AuthRequiredGate (~line 75)
PROBLEM: Suspended user check uses ref.watch(userProfileProvider).valueOrNull — returns null while profile is loading, so a suspended user passes the suspension gate during the brief window before Firestore returns their profile.
FIX: Treat null profile the same as "suspended" in AuthRequiredGate — show the loading spinner, not the child, until the profile is confirmed non-null and non-suspended.

[MEDIUM] lib/screens/main_screen.dart:_timedOut (~line 30)
PROBLEM: Once _timedOut = true, it is never reset to false even if userProfileProvider resolves with data immediately after the 3-second timeout. The HomeScreen permanently receives userModel: null for that session.
FIX: In the build method, only apply the timeout fallback when userProfileAsync.isLoading is still true AND _timedOut; once data arrives, set _timedOut = false in a post-frame callback.

[MEDIUM] lib/utils/env_config.dart:baseUrl (~line 75)
PROBLEM: emulator baseUrl returns http://localhost:5005, but main.dart connects Firebase Functions emulator to port 5001. Any code using envConfig.baseUrl for function calls in emulator mode will hit the wrong port.
FIX: Change emulator baseUrl to http://localhost:5001 or align the Functions emulator port to 5005 across all config files.

[MEDIUM] functions/function_options.py (general)
PROBLEM: Payment on_call handlers (create_checkout_session, capture_payment) use DEFAULT_OPTIONS with no explicit timeout_sec, falling back to Firebase's 60-second default. Checkout involves Stripe API + Firestore transactions and can silently timeout under load.
FIX: Add a PAYMENT_OPTIONS dict with timeout_sec=120 and apply it to all payment on_call handlers.

[LOW] lib/services/session_timeout_service.dart:_handleTimeout (~line 52)
PROBLEM: _handleTimeout is called from a Timer closure that captured context from startMonitoring (called in initState). After 15 minutes of navigation, the root widget's ScaffoldMessenger may be obscured by modal routes, silently dropping the "session expired" snackbar.
FIX: Use NotificationService.scaffoldMessengerKey.currentState?.showSnackBar(...) instead of ScaffoldMessenger.of(context) so the snackbar always targets the root messenger.

[LOW] lib/services/analytics_service.dart (entire file)
PROBLEM: File is empty. If analytics events are tracked anywhere in the app (product views, checkout starts, etc.), all calls are silent no-ops. Audit checklist item 5 (analytics disabled in emulator/dev) cannot be verified.
FIX: Either implement the stub with environment guard (return early if isEmulator || isDev) or document that analytics is intentionally deferred post-launch.

[BONUS] lib/origna_app.dart:_ProductBySlugScreen (~line 480)
PROBLEM: Uses CircularProgressIndicator — banned per CLAUDE.md design system rules; must use ModernLoadingIndicator.
FIX: Replace CircularProgressIndicator() with const ModernLoadingIndicator().

[BONUS] lib/origna_app.dart:_onGenerateInitialRoutes (~line 55) and _onGenerateRoute (~line 125)
PROBLEM: Both functions use MaterialPageRoute directly everywhere. While this is the correct pattern for onGenerateRoute handlers, the subscription-related routes (subscriptionSuccess, subscriptionCancel) are missing from _onGenerateInitialRoutes, so deep-linking directly to /subscription/success after a Stripe redirect fails to resolve.
FIX: Add /subscription/success and /subscription/cancel handling to _onGenerateInitialRoutes mirroring _onGenerateRoute.

[BONUS] lib/origna_app.dart:initState auth listener (~line 390)
PROBLEM: ensureUserDocumentExists() is awaited in the auth listener but any exception is swallowed with a debugPrint. A Firestore permission error here (e.g., rules misconfiguration) silently leaves the user without a profile document, causing downstream null crashes.
FIX: Log the exception to Sentry via AppError.log(e) in addition to debugPrint so production failures are visible.

[BONUS] lib/utils/utils.dart:calculateShippingCost — context capture after await (~line 310)
PROBLEM: addToCart shows a SnackBar via ScaffoldMessenger.of(context) after the Firestore transaction completes, without checking context.mounted first. A widget disposed mid-transaction causes a "widget tree out of sync" debug error (not a crash in release, but bad practice).
FIX: Wrap the post-await SnackBar call in if (context.mounted) { ... } — already done in the error path but missing in the success path at the end of addToCart.

[BONUS] lib/screens/common_screens.dart:EmailVerificationRequiredScreen (_checkVerification, ~line 400)
PROBLEM: After verifying email and calling navigator.pushNamedAndRemoveUntil, the freshUser variable is captured before await user.reload(). If Firebase updates currentUser asynchronously, freshUser could still reference the pre-reload instance where emailVerified is false.
FIX: Re-fetch currentUser after reload: final freshUser = FirebaseAuth.instance.currentUser; (already done correctly). Confirm that ensureUserDocumentExists() is only called after freshUser.emailVerified == true — it is, but missing context.mounted check before that await call.

[BONUS] functions/config.py:_secrets() (~line 195)
PROBLEM: APP_SECRETS_PARAM.value is accessed at call time (not at module load), but if the Secret Manager value is malformed JSON, json.loads() raises an unhandled exception that crashes the entire function invocation with no user-facing error message.
FIX: Wrap json.loads(raw) in a try/except (ValueError, json.JSONDecodeError) and raise a descriptive HttpsError or log + return empty dict.
```

---

```
[CRITICAL] firestore.rules:331
PROBLEM: create allow-list includes 'active' in the valid lifecycleStatus set for seller-created products, letting any approved seller publish directly without admin approval.
FIX: Change the set to `['draft', 'under_review']` only — remove 'active'.

[CRITICAL] firestore.rules:304–327 + product_repository.dart:68–82
PROBLEM: `shipFromCountry` and `shipFromCountries` are written by `addProduct`/`addProductWithId` (lines 70, 81) but are absent from the `hasOnly([...])` allowlist in the create rule — every warehouse-enriched product creation is silently rejected with permission-denied.
FIX: Add `'shipFromCountry', 'shipFromCountries'` to the `hasOnly` list on create (line 323–324 region) and the matching update allowlist (line 339–353).

[HIGH] products.py:436–444
PROBLEM: `delete_product` soft-deletes the product and removes it from Algolia but never purges `users/{uid}/favorites/{productId}` docs across all buyers — orphan entries accumulate forever.
FIX: After the soft-delete, enqueue a Cloud Task (or Firestore trigger on the product doc) that fans out `collectionGroup('favorites').where('productId','==',productId)` deletes in batches of 500.
ALSO: product_repository.dart:230–234 (deleteProduct callable — same gap on the Dart side)

[HIGH] seller_products_viewmodel.dart:14–19
PROBLEM: `sellerProductsProvider` streams the full seller product collection with no `.limit()` — a seller with hundreds/thousands of products streams every doc on every open, costing reads at scale.
FIX: Replace the unbounded stream with a paginated `FutureProvider` + cursor or add `.limit(BusinessRules.sellerProductsPageSize)` and implement infinite scroll in the screen.

[MEDIUM] product_repository.dart:437
PROBLEM: `watchFavorites` applies `BusinessRules.favoritesPageSize` (50) but `FavoritesScreen` presents all returned products in a single `GridView` with no load-more — users with >50 favorites silently lose the rest.
FIX: Add cursor-based pagination to `watchFavorites` and a load-more trigger in `FavoritesScreen`.

[BONUS] firestore.rules:325–326
PROBLEM: `isTrending` and `trendingAt` are in the seller create allowlist (comment even says "Admin only normally") — any approved seller can self-mark their product as trending on creation.
FIX: Remove `'isTrending', 'trendingAt'` from the create `hasOnly` list; keep only in the admin-only update rule (line 334–335).

[BONUS] modern_product_card.dart:8,21
PROBLEM: `price` and `compareAtPrice` are typed `double` (dollar amounts) — violates the cross-stack "money as int cents" rule; mismatch with the Product model will require caller-side `/100` conversions scattered everywhere.
FIX: Change to `final int priceCents` and `final int? compareAtPriceCents`; compute display string inside the widget with `(priceCents / 100).toStringAsFixed(2)`.

[BONUS] modern_product_card.dart:127
PROBLEM: `'Trending'` badge label is a hardcoded English string — not localized.
FIX: Replace with `'product.trending'.tr()` (add key to all locale files).

[BONUS] product_repository.dart:407–411
PROBLEM: `updateProduct` calls `sanitizeProductForFirestore(data)` which does NOT inject `updatedAt`; direct Firestore `.update()` calls will leave `updatedAt` stale unless the caller manually adds it.
FIX: In `sanitizeProductForFirestore` (or at the start of `updateProduct`), always set `data[Fields.updatedAt] = FieldValue.serverTimestamp()` when `ensureDateCreated` is false and the call is an update.

[BONUS] product_repository.dart:32–45 + 131–144
PROBLEM: Pre-write SKU uniqueness check is a read-then-write without a transaction — two concurrent `addProduct` calls with the same SKU can both pass the check and both write.
FIX: Perform the uniqueness check inside the `runTransaction` that writes the doc (or rely solely on the `on_product_created` trigger enforcement and remove the racy client-side check).

[BONUS] modern_product_card.dart (initState region)
PROBLEM: `_controller` and `_scaleAnimation` are declared `late` and initialized in `initState`, but `build` references `_scaleAnimation` before `initState` runs if the widget tree is built eagerly — also, hover scale of 1.05 on mobile is meaningless (no `MouseRegion` enter on touch) and wastes an `AnimationController`.
FIX: Guard with `kIsWeb || !Platform.isAndroid && !Platform.isIOS` before creating the controller, or use `TickerProviderStateMixin` conditionally.

[BONUS] seller_products_viewmodel.dart:62–75
PROBLEM: Success message is built with non-localized interpolated English (`'product${updated==1?'':'s'} ${action}d'`) — pluralization and past-tense are hardcoded in English.
FIX: Use locale-aware `'seller.bulk_action_success'.tr(namedArgs: {'count': updated, 'action': action})` with proper plural keys.
```

```
[CRITICAL] functions/products.py:547-558
PROBLEM: Duplicate-rating guard runs OUTSIDE the Firestore transaction; two concurrent requests both pass the check then both create a rating doc + double-increment the product average.
FIX: Move `existing_ratings_query` + early-return check inside `update_rating_transaction` (read it within the transaction so it's part of the same atomic snapshot).

[HIGH] firestore.rules:539
PROBLEM: `allow create, delete: if false` on `product_ratings` means admins have NO path to remove abusive reviews; schema_constants.dart even has `adminDeleteReview` constant that points nowhere.
FIX: Change to `allow create: if false; allow delete: if isAdmin();` and implement the matching `admin_delete_rating` Cloud Function.

[HIGH] firestore.rules:541-544
PROBLEM: Seller-reply rule allows updating `sellerReply`/`sellerReplyAt` without checking whether a reply already exists, bypassing the backend's once-only guard via direct Firestore SDK write.
FIX: Add `&& (!('sellerReply' in resource.data) || resource.data.sellerReply == null)` to the update condition.

[HIGH] rating_dialog.dart (entire file)
PROBLEM: No `TextField` for review text exists in the dialog; `reviewText` is never passed to `submitRating()`, so text reviews are silently discarded. `setReviewText()` in the viewmodel is dead code.
FIX: Add a `TextField` controller, bind it to local state, and pass `reviewText: _reviewController.text` to `viewModel.submitRating(...)`.

[MEDIUM] functions/products.py:503-509
PROBLEM: Premium check for photo reviews reads `users/{uid}.isPremium` (profile cache), not the authoritative `subscriptions/{uid}` document — inconsistent with the Q&A gate which uses `is_premium_authoritative()`.
FIX: Replace `_user_doc.to_dict().get(Fields.IS_PREMIUM, False)` with `is_premium_authoritative(user_id, db=db)`.

[MEDIUM] functions/products.py:559-570
PROBLEM: `rating_doc` is written without `helpfulCount` or `helpfulVoterIds` fields; downstream vote handler falls back to `get(..., 0)` / `get(..., [])` but the fields are absent in Firestore, violating the schema defaults.
FIX: Add `Fields.HELPFUL_COUNT: 0, Fields.HELPFUL_VOTER_IDS: []` to `rating_doc`.

[MEDIUM] functions/products.py:~2938 vs Ratings.json
PROBLEM: `sellerReply` is truncated to 500 chars in the handler but the canonical `Ratings.json` schema declares `maxLength: 1000`. Firestore rule enforces neither limit.
FIX: Align both to 1000 (match the schema), and add `.size() <= 1000` to the Firestore rule's seller-update condition.

[MEDIUM] firestore.rules:500-507
PROBLEM: `allow create` on `product_questions` checks `request.resource.data.question.size()` but the backend writes the field as `questionText` (per `Fields.QUESTION_TEXT`). The rule is mis-keyed and would silently pass any length since `question` key won't exist.
FIX: Replace `request.resource.data.question` with `request.resource.data.questionText`, or drop the create rule entirely (creates are Admin SDK only).

[MEDIUM] functions/products.py:2975 (vote_review_helpful)
PROBLEM: No check prevents a seller from voting "helpful" on reviews of their own product, enabling review score manipulation (e.g. mass-downvoting competitor mentions).
FIX: Inside `_vote_txn`, fetch the product doc and raise `permission-denied` if `product_data.sellerId == user_id`.

[MEDIUM] productdetails_screen.dart:807
PROBLEM: `_productRatingsProvider` uses `FirebaseFirestore.instance` directly instead of `ref.watch(firestoreProvider)`, bypassing DI and breaking emulator/env routing.
FIX: Pass `ref.watch(firestoreProvider)` into the provider and use it for the collection reference.

[LOW] functions/products.py:455-456 (docstring vs implementation)
PROBLEM: Docstring states "One rating per user per product" but the implementation checks per `orderId` only — a buyer with two delivered orders for the same product can submit two ratings, each incrementing the product average.
FIX: Add `.where(Fields.USER_ID, "==", user_id).where(Fields.PRODUCT_ID, "==", product_id)` check if one-per-user-per-product semantics are intended (design decision to confirm with Yunior).

[BONUS] productdetails_screen.dart:864-871
PROBLEM: Histogram star-counts are computed from the 10-item paginated `_productRatingsProvider` result, not from all ratings. Bars are skewed for products with >10 reviews. `ratingCount` total is correct but bucket counts are wrong.
FIX: Add `ratingHistogram: [int,int,int,int,int]` aggregate field to the product document (updated atomically in `update_rating_transaction`) and read from there.

[BONUS] productdetails_screen.dart (entire _ReviewCard, no reviewImageUrls render)
PROBLEM: `reviewImageUrls` field is never read or displayed in `_ReviewCard`; premium users who uploaded photos will never see them shown on the product page.
FIX: Add a horizontal image row in `_ReviewCard.build()` reading `review[Fields.reviewImageUrls] as List?` and rendering `CachedNetworkImage` thumbnails.

[BONUS] firestore.rules:540
PROBLEM: `allow read: if isAuthenticated()` on `product_ratings` exposes full `userId` (Firebase UID) of reviewers to every logged-in user, enabling cross-product user tracking without consent.
FIX: Remove direct client reads; serve ratings through the existing `get_product_ratings_paginated` function which can redact or hash the `userId` before returning.

[BONUS] functions/products.py:2904 (reply_to_product_rating, missing from grep — check function name)
PROBLEM: The function reads the product doc and the rating doc in two separate reads (no transaction) — a race condition exists where the product can be deleted between the two reads; also, a deleted product's rating can still receive a seller reply.
FIX: Wrap both reads + the update in a `@_firestore.transactional` block.

[BONUS] productdetails_screen.dart:1187-1219 (_QACard seller answer dialog)
PROBLEM: After `ref.read(qaControllerProvider.notifier).answerQuestion(...)` there is no `await` — the `ScaffoldMessenger.showSnackBar` fires immediately before the Future completes; errors are never surfaced to the seller.
FIX: `await` the call, watch `qaControllerProvider` state for `AsyncError` and show an error snackbar accordingly.

[BONUS] functions/products.py:449 (submit_product_rating)
PROBLEM: `rating` is accepted as a `float` (`isinstance(rating, (int, float))`) and stored as-is, but `Ratings.json` declares `"type": "number"` and `Ratings.json` allows decimals — the average recalculation then stores a float average, but the initial rating could be e.g. `3.7`. Buyers should only submit integer stars (1–5).
FIX: Add `if not isinstance(rating, int) or rating < 1 or rating > 5` to enforce integer-only star values from clients (floats are fine for the computed average stored on the product).
```

```
[CRITICAL] functions/handlers/payment_stripe.py:895 (checkout) + functions/handlers/coupons.py:redeem_coupon
PROBLEM: Coupon limit validation (read usedCount) and redemption (increment usedCount) are NOT atomic — two concurrent checkouts can both pass _coupon_within_limits and both receive the discount before either webhook fires, bypassing maxUsesTotal and maxUsesPerUser limits entirely.
FIX: In redeem_coupon transaction, re-validate both maxUsesTotal and maxUsesPerUser inside _redeem_txn before incrementing; raise an exception (logged, non-blocking to order) if limits exceeded so the discrepancy is flagged for fraud review.

[HIGH] functions/handlers/payment_stripe.py:499
PROBLEM: _coupon_not_expired returns True (coupon treated as valid) when expiresAt is a plain Python datetime without tzinfo or any unrecognized type — the final else branch has no return, falls off the function returning None (truthy in boolean context: actually None is falsy — wait, but the function body has `return True` as last statement only via indented else … let me re-read)

Actually re-reading lines 499-511:
```python
def _coupon_not_expired(coupon_data: dict) -> bool:
    expires_at = coupon_data.get(Fields.EXPIRES_AT)
    if expires_at is None:
        return True
    ...
    if hasattr(expires_at, "ToDatetime"):
        expires_dt = ...
    elif hasattr(expires_at, "astimezone"):
        expires_dt = ...
    else:
        expires_dt = None
    if expires_dt is not None and now_utc > expires_dt:
        return False
    return True
```

When `expires_at` is an unrecognized type (e.g. plain `datetime` without tzinfo), `expires_dt = None`, so `expires_dt is not None` is False, and function returns `True` — coupon treated as unexpired.
FIX: Replace `else: expires_dt = None` with `else: return False` — unknown timestamp types should fail closed (coupon rejected), not fail open.

[HIGH] functions/handlers/coupons.py:redeem_coupon (~line 155)
PROBLEM: redeem_coupon is called inside a bare except in the webhook handler (payment_stripe.py:2002-2009) and silently swallowed — the pending_redemptions fallback doc is written, but no retry cron job is visible in the codebase, meaning failed redemptions permanently leak coupon uses (usedCount never incremented, per-user useCount never incremented), enabling re-use.
FIX: Implement a cron/Cloud Task that processes pending_redemptions docs; without it the pending_redemptions fallback is dead letter.

[MEDIUM] functions/handlers/payment_stripe.py:908
PROBLEM: If coupon fails re-validation at payment time (e.g. expired between apply_coupon and checkout), the order proceeds with zero discount and no error is raised to the user — the buyer silently pays full price.
FIX: If coupon was submitted (coupon_code_raw set) but re-validation fails, raise HttpsError('failed-precondition', 'Coupon is no longer valid') so the frontend can prompt the user to remove it before retrying.

[MEDIUM] functions/handlers/coupons.py:apply_coupon (~line 120)
PROBLEM: apply_coupon reads coupon_ref first, then separately reads coupon_uses subcollection — these are two non-transactional reads. Between the two reads, usedCount could change; more importantly, `used_count` read from the coupon doc snapshot is stale by the time user_uses is fetched. Not a correctness issue for preview, but the validation in payment_stripe.py repeats the same non-atomic pattern and is the authoritative check.
FIX: No standalone fix needed in apply_coupon (it's preview-only), but document that payment_stripe.py's _coupon_within_limits is equally non-atomic and must be hardened per CRITICAL finding above.

[BONUS] lib/features/checkout/cart_provider.dart:cartSubtotalProvider (~line 98)
PROBLEM: Subtotal computed as `item.price * item.quantity` where `price` is a `double` (dollars) — violates the "money as cents int" rule; float arithmetic causes rounding drift that can diverge from server-computed subtotal_cents, triggering false subtotal mismatch errors at checkout.
FIX: Compute subtotal as `item.priceCents * item.quantity` (int cents), or ensure CartItemDetailModel exposes `priceCents` and use integer arithmetic throughout.

[BONUS] functions/handlers/coupons.py:redeem_coupon (~line 155)
PROBLEM: Per-user coupon_uses doc stores no orderId — only useCount and timestamps. If a user abuses a coupon (e.g. via refund + re-use), there's no per-use record linking to the specific order for fraud investigation.
FIX: Change subcollection structure to one doc per use: `coupon_uses/{userId}/uses/{orderId}` with `{usedAt, orderId}`, or add an `orderIds: []` array field alongside useCount.

[BONUS] functions/handlers/coupons.py:admin_create_coupon (~line 240)
PROBLEM: No idempotency check guards the final `coupon_ref.set()` — a duplicate check is done with `coupon_ref.get().exists`, but between that read and the `.set()`, a concurrent admin create for the same code would race; both would pass the exists check and the second write silently overwrites the first.
FIX: Use `coupon_ref.create()` (raises AlreadyExists if doc exists, atomic) instead of `coupon_ref.get().exists` + `coupon_ref.set()`.

[BONUS] functions/handlers/coupons.py:_compute_discount (~line 55)
PROBLEM: `discount_value` for PERCENT type is read raw without clamping to [0, 100] inside _compute_discount — if DB data is corrupted (e.g. discountValue=200), the function returns a discount larger than the cart subtotal, producing a negative total before the `max(0, ...)` floor in payment_stripe.py. The floor saves correctness but allows 100% discounts that weren't intended.
FIX: Add `discount_value = min(discount_value, 100)` inside the PERCENT branch of _compute_discount, and validate range in admin_create_coupon (already done) and re-validate server-side at checkout.

[BONUS] lib/features/checkout/checkout_screen.dart:292-294
PROBLEM: Displayed shipping/tax totals are NOT recalculated after coupon is applied — the UI shows the discount subtracted from subtotal, but shipping and tax rows remain unchanged. The actual charge on the backend re-derives tax from post-discount subtotal, so the displayed total will differ from the actual Stripe charge.
FIX: After applyCoupon succeeds, re-call the shipping/tax estimate endpoint (or invalidate the checkout cost provider) so displayed tax and total reflect the post-discount amounts.
```


[CRITICAL] payment_stripe.py:550
PROBLEM: `create_checkout_session` is missing its `@https_fn.on_call(**DEFAULT_OPTIONS)` decorator AND `def` function signature — the entire checkout handler exists as orphaned module-level code that is never registered as a Cloud Function and never executed.
FIX: Wrap the function body with `@https_fn.on_call(**DEFAULT_OPTIONS)\ndef create_checkout_session(req: https_fn.CallableRequest) -> dict[str, Any]:` before line 550's docstring.
ALSO: orders.py:140

[CRITICAL] orders.py:140
PROBLEM: `confirm_order_receipt` is missing its `@https_fn.on_call(**DEFAULT_OPTIONS)` decorator AND `def` function signature — the buyer-receipt capture endpoint is never deployed.
FIX: Add `@https_fn.on_call(**DEFAULT_OPTIONS)\ndef confirm_order_receipt(req: https_fn.CallableRequest) -> dict[str, Any]:` before the docstring at line 140.

[HIGH] payment_stripe.py:2826
PROBLEM: `order_doc` and `order_id` are referenced after the `for order_doc in orders:` loop in `process_dispute_created`, but they are only defined inside that loop body — if no order matches the `payment_intent_id`, both are unbound, crashing the webhook with `NameError` and leaving the dispute unlogged.
FIX: Initialize `order_doc = None` and `order_id = None` before the loop, and guard `if order_doc and order_doc.exists:` (already done) plus `if order_id:` for safe reference.

[HIGH] payment_stripe.py:2223
PROBLEM: `process_session_expired` uses a Firestore transaction to restore `STOCK_QUANTITY` via `_firestore.Increment`, but does NOT restore `WAREHOUSE_STOCK` or `inventoryLevels` — causing permanent warehouse stock desync on session expiry.
FIX: Call `_add_stock_restore_to_batch` instead, or replicate the warehouse restore logic from `_rollback_checkout` inside `_expire_in_transaction`.
ALSO: payment_stripe.py:2309 (`process_payment_intent_failed`), payment_stripe.py:2357 (`process_payment_intent_canceled`) — same omission.

[HIGH] payment_stripe.py:2560
PROBLEM: `process_refund_failed` creates a `SECURITY_ALERTS` doc but never fetches or updates the corresponding order with `requires_manual_review=True` — buyer funds lost with no order-level flag for manual review.
FIX: After creating the alert, look up the order by `charge_id` via the `ORDERS` collection and `order_ref.update({Fields.REQUIRES_MANUAL_REVIEW: True, Fields.MANUAL_REVIEW_REASON: "Refund failed"})`.

[HIGH] payment_stripe.py:1782
PROBLEM: `process_checkout_session_completed` reads `current_status` then updates the order without a Firestore transaction — two concurrent webhook deliveries (Stripe retries) can both pass the `current_status != PENDING` guard and double-confirm the order, triggering duplicate emails, duplicate license generation, and duplicate coupon redemption.
FIX: Wrap the status check + update in a `@get_transactional()` transaction that reads and writes `order_ref` atomically, returning early if status is not `PENDING`.

[MEDIUM] checkout_provider.dart:35
PROBLEM: `checkoutTotalProvider` computes `subtotal + taxAmount + shippingCost` but never subtracts `state.couponDiscountCents` — user sees incorrect (inflated) total while coupon is applied.
FIX: Change to `subtotal + checkoutState.taxAmount + checkoutState.shippingCost - (checkoutState.couponDiscountCents / 100.0)`.

[MEDIUM] payment_stripe.py:195
PROBLEM: `_rollback_checkout`'s warehouse restore loop computes `restore = min(qty, remaining)` instead of `min(wh_stock, remaining)` — it may over-restore the first warehouse (beyond what was originally drained from it) while other warehouses receive zero restoration, corrupting per-warehouse inventory.
FIX: Change to `restore = min(wh_stock, remaining)` so each warehouse is only refilled up to its pre-drain capacity contribution.

[MEDIUM] payment_stripe.py (checkout body ~line 1350)
PROBLEM: Order deduplication checks `subtotal_cents == actual_subtotal_cents` but ignores coupon discount — two orders for the same subtotal with different coupons will collide and return the first order's session, bypassing the second coupon validation.
FIX: Include `discount_amount_cents` in the dedup comparison: also check `recent_data.get(Fields.DISCOUNT_AMOUNT_CENTS) == discount_amount_cents`.

[BONUS] order_repository.dart:68
PROBLEM: `watchBuyerOrders` and `watchSellerOrders` both filter on `paymentStatus` but omit `PaymentStatus.authorized` — orders in authorized state (confirmed but not captured) are invisible to both buyer and seller UIs.
FIX: Add `constants.PaymentStatus.authorized.value` to both `whereIn` lists (it is already present in buyer's list — check `watchSellerOrders` specifically).

[BONUS] cart_repository.dart:55
PROBLEM: `CartModel` is created with `createdAt: DateTime.now()` (client clock) instead of a server timestamp — skews ordering and can drift across devices; Firestore's server timestamp sentinel cannot be used in transactions but a `FieldValue.serverTimestamp()` outside transactions should be used.
FIX: Use `FieldValue.serverTimestamp()` for `createdAt` when setting the cart doc, or convert to use the server value at write time.

[BONUS] checkout_provider.dart:29
PROBLEM: `checkoutTaxRateProvider` hardcodes `0.13` (Ontario HST) as the default tax rate when no address is available — this incorrect default rate is used in tax display before the user selects an address, and is wrong for all non-Ontario provinces.
FIX: Return `0.0` (or the national GST minimum `0.05`) as the default, or show no tax estimate until an address is selected.

[BONUS] payment_stripe.py (OrderItem in validated_item)
PROBLEM: `OrderItem.json` and validated order items store `price` as a float (dollars), not integer cents — violates the schema rule "money as cents" and the order-level amounts are in cents, creating an inconsistent schema that risks floating-point rounding errors on price * quantity across items.
FIX: Store `priceCents: int(round(db_price * 100))` in the item snapshot, update `OrderItem.json` to `"type": "integer"` named `priceCents`, and update all references (`item[Fields.PRICE] * 100` → `item[Fields.PRICE_CENTS]`).

[BONUS] payment_stripe.py:220
PROBLEM: `_rollback_checkout` updates `order_ref` (marks as FAILED) outside the stock-restore transaction — if the Firestore `order_ref.update` call fails after stock is restored, the order stays in `pending`/`awaiting_payment` status while stock is already restored, enabling the user to re-trigger checkout against restored stock without a valid order state.
FIX: Include the `order_ref.update` inside the same `rollback_stock` transaction.

[BONUS] checkout_provider.dart:startCheckout
PROBLEM: `mounted` is checked after `await _stripeCircuitBreaker.execute(...)` via `if (!mounted)`, but `mounted` is not a valid property on `StateNotifier` — it will always be `true` and the check never protects against use-after-dispose.
FIX: Remove the `!mounted` checks inside `StateNotifier` methods (they're meaningless here); use `if (!state.isProcessing) return ...` guards instead, or track disposal manually with a `_disposed` flag.

Now I have enough context for a comprehensive audit. Here are the findings:

---

```
[CRITICAL] functions/products.py:on_product_created (line ~450)
PROBLEM: Trigger returns early for ALL new products because viewmodel creates with `lifecycleStatus='draft'` and `BUYER_VISIBLE = frozenset({'active'})`. Guard `if product_data.get(Fields.LIFECYCLE_STATUS) not in ProductLifecycleStatusValues.BUYER_VISIBLE: return` kills the entire validation/approval workflow — SKU uniqueness, price/stock checks, address verification, slug assignment, admin notification, and `under_review` transition never run.
FIX: Remove or restructure the early-return guard in `on_product_created` (intended for Algolia indexing); run all validation unconditionally, then gate only the Algolia index call behind `BUYER_VISIBLE`.
ALSO: add_product_viewmodel.dart:~180 (creates with lifecycleStatus=draft)
```

```
[CRITICAL] lib/core/repositories/product_repository.dart:getUploadUrl (~line 210)
PROBLEM: Sends `{Fields.fileName: fileName}` (key `'fileName'` singular) but backend `upload_product_images` reads `data.get("fileNames", [])` (key `'fileNames'` plural) → always raises "No files specified". All product image uploads fail before they start.
FIX: Rewrite `getUploadUrl` (or replace it) to send `{'fileNames': [fileName], 'contentTypes': ['image/jpeg']}` and read `result.data['uploadUrls'][0]['uploadUrl']`.
ALSO: functions/products.py:upload_product_images:L115
```

```
[CRITICAL] lib/core/repositories/product_repository.dart:_uploadSingleImage (~line 280)
PROBLEM: Constructs public URL as `"${ConfigService().imageBaseUrl}/products/$fileName"` but the backend stores the file at a UUID-based R2 key (`R2Config.get_image_path("products", f"{uuid4()}.{ext}")`). The constructed URL path never matches the uploaded object — all product images 404.
FIX: Have the backend return `publicUrl` in the response and use that instead of constructing a local URL; mirrors the correct pattern already used in `uploadReviewImages`.
ALSO: functions/products.py:upload_product_images:~L180
```

```
[HIGH] functions/products.py:on_product_created (~line 530)
PROBLEM: `compareAtPrice > price` validation exists in `on_product_updated` but is absent from `on_product_created`. A seller can write a product with `compareAtPrice <= price` directly to Firestore (bypassing Flutter validation) and the trigger won't catch it on creation.
FIX: Add same `compare_at_price`/`price` guard block from `on_product_updated` (~line 700) into `on_product_created` before slug assignment.
```

```
[HIGH] lib/core/repositories/product_repository.dart:addProductWithId (~line 160)
PROBLEM: Primary warehouse is selected as `.firstOrNull` (first in the `warehouseIds` array), but `_derive_ship_from_fields` in Python prioritizes `isDefault: true`. The Dart client therefore denormalizes `shipFromCity/Province/Country` from the wrong warehouse whenever the default warehouse isn't first in the list.
FIX: After fetching warehouse docs, pick the one where `data?['isDefault'] == true`, falling back to first if none is marked default — matching the backend's priority logic.
ALSO: product_repository.dart:addProduct (~line 80) same bug
```

```
[HIGH] add_product_viewmodel.dart:addProduct (~line 150)
PROBLEM: Warehouse stock emptiness check (`useWarehouses && state.warehouseStockMap.isEmpty`) fires AFTER images are already uploaded to R2, orphaning the uploaded images when the check fails.
FIX: Move the warehouse-stock guard into the pre-upload validation section (before `state = state.copyWith(isLoading: true)`), alongside the existing delivery-tier check.
```

```
[HIGH] lib/core/repositories/product_repository.dart:addProduct / addProductWithId (~lines 50, 140)
PROBLEM: Pre-write SKU uniqueness query has no `lifecycleStatus` filter — it blocks reuse of a SKU from a rejected or draft product. Backend trigger correctly excludes `archived`. A seller who deletes (archives) a product can never reuse that SKU from the Dart client, while the backend would allow it.
FIX: Add `.where(Fields.lifecycleStatus, whereNotIn: [ProductLifecycleStatusValues.archived, ProductLifecycleStatusValues.rejected])` to both Dart SKU checks.
```

```
[MEDIUM] productaddimages_screen.dart:_ProductAddImagesState
PROBLEM: `initState` sets `_imageModels = List.from(widget.imageModels)` but `didUpdateWidget` is never overridden. If the parent rebuilds and passes a new `imageModels` list (e.g., on viewmodel state change), the widget's local copy goes stale and syncs break.
FIX: Override `didUpdateWidget` and update `_imageModels` when `widget.imageModels != oldWidget.imageModels`.
```

```
[MEDIUM] add_product_viewmodel.dart:addProduct
PROBLEM: No max-length validation for `name` or `description` in the viewmodel before submit. A seller can write arbitrarily long strings; the backend trigger sanitizes text but doesn't enforce length limits, and Algolia has a 10 KB record size limit.
FIX: Add `name.trim().length > 100` (or per-schema limit) and `description.trim().length > 5000` guards mirroring backend `ValidationLimits` class.
```

```
[MEDIUM] add_product_viewmodel.dart:addProduct (~line 200)
PROBLEM: `state.isLoading` guard at the top prevents double-submit, but there is no guard if the screen is popped mid-flight — the provider is `autoDispose` and could be disposed while an async chain (image compress → upload → Firestore write) is in progress, causing silent failures or partial writes with no user feedback.
FIX: Capture a `mounted` check after each major await, or use a `CancelToken`-style flag; also wrap the entire try block to set `isLoading: false` in a `finally` clause (currently only done in catch path).
```

---

```
[BONUS] functions/products.py:submit_product_rating (~line 380)
PROBLEM: `@_firestore.transactional` is applied before `_firestore` is guaranteed non-None — the module-level `_firestore` is `None` until `get_db()` is called first. If `submit_product_rating` is invoked before any other handler runs in this Cloud Function instance, `_firestore.transactional` would throw `AttributeError: 'NoneType'`.
FIX: Call `get_db()` at the top of `submit_product_rating` (before the `@_firestore.transactional` decorated inner function is defined) to guarantee `_firestore` is initialized.
```

```
[BONUS] functions/products.py:_fire_back_in_stock_notifications (~line 890)
PROBLEM: `notifiedAt` is set to `datetime.now(UTC)` (client time), not `get_server_timestamp()`. Under concurrent cloud function invocations, clock skew between instances can cause double-notification for the same subscriber.
FIX: Use Firestore server timestamp via `get_server_timestamp()` and pass it as a separate pre-computed value, or use a Firestore transaction to ensure idempotent single-write.
```

```
[BONUS] productaddimages_screen.dart:_pickImage
PROBLEM: After `await picker.pickImage(...)`, the method uses `setState` and calls `widget.onImagesChanged` without checking `if (!mounted) return`. If the widget is removed from the tree during the gallery picker async call, `setState` throws.
FIX: Add `if (!mounted) return;` immediately after `await picker.pickImage(...)`.
```

```
[BONUS] add_product_viewmodel.dart:_validateAndCompressImage
PROBLEM: `bytes.length > maxImageSize` throws an `Exception` with a localization key string (`.tr()`), but at this point the viewmodel is in an isolate (`compute`) context. `easy_localization` `.tr()` extension requires a Flutter widget tree context and will either return the raw key or crash in a background isolate.
FIX: Return `null` instead of throwing, then surface the error in `_compressImages` as a user-facing state update; or throw a plain English string without `.tr()`.
```

```
[BONUS] lib/core/repositories/product_repository.dart:_uploadSingleImage (~line 285)
PROBLEM: `ConfigService().imageBaseUrl` is sourced from Firebase Remote Config which may not be loaded yet on first cold start, resulting in empty base URL and malformed image URLs stored permanently in Firestore.
FIX: Assert `imageBaseUrl.isNotEmpty` before constructing the URL and throw if empty; ensure Remote Config is fetched and activated before the add-product flow is accessible.
```

```
[BONUS] add_product_viewmodel.dart
PROBLEM: `state.freeShippingAt10Plus` is collected in state and shown in UI but never sent to Firestore in the `Product(...)` constructor — the field is absent from the model instantiation. The feature flag is silently dropped.
FIX: Add `freeShippingAt10Plus: state.freeShippingAt10Plus` to the `Product(...)` constructor call and ensure the field is defined in the `Product` Freezed model and `product.py` Pydantic model.
```

```
[BONUS] functions/products.py:on_product_created (~line 600)
PROBLEM: `_notify_admins_new_product` is called AFTER the product is set to `under_review`. If it throws (swallowed by try/except), admins never receive notification, and the product sits in `under_review` indefinitely with no visibility — no retry mechanism exists.
FIX: Write to a `admin_notifications` queue collection so a separate cron can retry failed admin notifications, or log to a `security_alerts` doc to surface the failure.
```

```
[BONUS] lib/features/seller/warehouses_viewmodel.dart:_addressToMap (~line 130)
PROBLEM: `latitude` and `longitude` are included in the address payload sent to `create_warehouse` / `update_warehouse`, but the backend immediately calls `_geocode_warehouse_address` and overwrites these with its own geocoded values. Sending client-supplied coordinates wastes bandwidth and could mislead debugging.
FIX: Remove `Fields.latitude` and `Fields.longitude` from `_addressToMap` — backend geocoding is the single source of truth.
```

```
[BONUS] functions/products.py:delete_warehouse (~line 980)
PROBLEM: After deleting warehouse docs from the batch, `_derive_ship_from_fields` is called on stale `pdata` (the pre-delete product dict that still contains the deleted `warehouseIds`). It will try to fetch the just-deleted warehouse doc, get `doc.exists = False`, potentially leave `shipFromCountry` as the deleted warehouse's country.
FIX: Remove the deleted `warehouseId` from `pdata['warehouseIds']` before calling `_derive_ship_from_fields(seller_id, pdata)`.
```

```
[BONUS] lib/features/products/add_product_viewmodel.dart:addProduct
PROBLEM: `AddProductState` is not reset to a clean state on success — only `isLoading: false, isSuccess: true` is set. If the screen remains mounted (e.g., `autoDispose` hasn't fired yet) and the user somehow re-enters, `imageModels`, `selectedWarehouseIds`, and `warehouseStockMap` from the previous submission persist.
FIX: On success, call `state = AddProductState()` (full reset) before setting `isSuccess: true`, or ensure the screen always pops immediately on success to guarantee provider disposal.
```
---

## Audit Findings — Product Upload / Supplier / Stock Notifications / UI Widgets (2026-02-23)

### Product Upload & Supplier Config

```
[CRITICAL] product_repository.dart:352
PROBLEM: `getUploadUrl` calls `upload_product_images` with `{Fields.fileName: fileName}` (singular key) but the backend reads `data.get("fileNames", [])` and immediately raises `HttpsError("invalid-argument", "No files specified")` — product image upload is completely broken.
FIX: Call with `{'fileNames': [fileName], 'contentTypes': ['image/jpeg']}` and read `result.data['uploadUrls'][0]['uploadUrl']` from the response array.
```

```
[CRITICAL] product_repository.dart:468
PROBLEM: `_uploadSingleImage` constructs the public URL as `"${ConfigService().imageBaseUrl}/products/$fileName"` using the client-generated filename, but the backend stores the image at a UUID-based key under an env-prefixed path (`R2Config.get_image_path("products", "{uuid}.jpg")`). The stored URL will 404 in every environment.
FIX: Use the `publicUrl` returned by the `upload_product_images` function response (`uploadUrls[i].publicUrl`) instead of constructing the URL client-side.
```

```
[CRITICAL] supplier_config.dart:23 / schema_constants.py:1134 / schema_constants.dart:1408
PROBLEM: `supplierPlatforms` map exposes 20+ supplier IDs to sellers (spocket, printful, amazon_usa, walmart, gmarket, coupang, rakuten, made_in_china, global_sources, faire, amazon_europe, costco, etsy_wholesale, custom, local_canada, etc.) but `SupplierTypeValues.ALL` in both Python and Dart only permits 8 values. Any product saved with an unlisted supplier type will fail `validate_supplier_type` in the Firestore trigger and be deactivated silently.
FIX: Add all supplier IDs from `supplierPlatforms` map to `SupplierTypeValues` in both `schema_constants.py` and `schema_constants.dart`; note that `local_canada` in the Dart config maps to `local` in schema constants — either align the ID or add both.
```

```
[HIGH] supplier_config.dart:543 / products.py:~845
PROBLEM: `SupplierPlatformConfig.isActive = false` only removes the supplier from the UI dropdown. No backend mechanism hides or deactivates products whose `supplier.type` matches a deactivated platform. Products remain fully searchable via Algolia and `get_products`.
FIX: On supplier deactivation, run a batch update (Cloud Function or admin script) that sets `isActive = false` / moves `lifecycleStatus` to `suspended` for all products where `supplier.type == supplierId`, and removes them from the Algolia index.
```

```
[HIGH] supplier_config.dart:~476 (SupplierPlatformConfig) / add_product_viewmodel.dart:~291
PROBLEM: `minDeliveryDays` and `maxDeliveryDays` exist in Dart config but are never stored on the Firestore product document or mapped to `SellerDeliveryOption.estimatedDays`. Shipping display cannot use supplier-sourced delivery estimates.
FIX: During product creation, populate `SellerDeliveryOption.estimatedDays` from `getSupplierDeliveryRange(supplierType)` when the seller selects a supplier platform and has not manually set delivery days.
```

```
[MEDIUM] add_product_viewmodel.dart:262
PROBLEM: Product is created with `sellerId: _ref.read(userIdProvider)!` and written directly to Firestore from the client SDK — no Cloud Function enforces that `sellerId == auth.uid`. A compromised client can write any `sellerId`.
FIX: Move product creation to a Cloud Function (`create_product`) that derives `seller_id = req.auth.uid` server-side, matching the pattern used in all other sensitive writes.
```

```
[MEDIUM] add_product_viewmodel.dart:283
PROBLEM: `createdAt: DateTime.now()` is set client-side. A seller can manipulate device clock, corrupting product ordering, "new arrivals," and time-based ranking.
FIX: Remove `createdAt` from the client payload and set it with `FieldValue.serverTimestamp()` in the Firestore write (or backend CF at creation time).
```

```
[MEDIUM] product.py:272-273 (also product.py:86, 142, 230)
PROBLEM: `price: float` (dollar float) is the stored primary field alongside derived `priceCents: int`. Violates "money as cents" cross-stack rule. Same issue with `compareAtPrice: float`, `SellerDeliveryOption.cost: float`, `SupplierInfo.cost: float`.
FIX: Make `priceCents: int` the primary field; expose `price` as computed property (`priceCents / 100`). Apply to `compareAtPrice`, `cost`, `deliveryOption.cost`.
```

```
[LOW] products.py (no import handler)
PROBLEM: No `import_supplier_product` Cloud Function exists — checklist items 4/8/9/10 (mapped import, R2 image import with env prefix, supplierSku→sellerSku dedup, cross-seller import guard) are entirely unimplemented.
FIX: Create `import_supplier_product` handler: validates `sellerId == req.auth.uid`, copies supplier images to R2 via `R2Config.get_image_path(...)`, sets `sellerSku = supplierSku`, enforces dedup via existing uniqueness query.
```

```
[BONUS] addproduct_screen.dart:71-80
PROBLEM: `_selectedSupplierType`, `_selectedSupplierCurrency`, `_hasTracking`, `_inventoryManaged`, `_trackQuantity`, `_allowBackorder`, `_lowStockAlertEnabled`, `_selectedSubcategory` are local `setState` fields in the screen. Violates MVVM.
FIX: Move all supplier and inventory UI state fields into `AddProductState` with corresponding setters in `AddProductViewModel`.
```

```
[BONUS] addproduct_screen.dart:303
PROBLEM: `compareAtPrice` validation logic lives in the screen's `TextFormField` validator — business rule duplicated from ViewModel.
FIX: Remove the inline validator; rely solely on `AddProductViewModel.addProduct` validation at line 93.
```

```
[BONUS] addproduct_screen.dart:180
PROBLEM: `IconButton` at line 180 (back button) has no `tooltip:` — accessibility violation.
FIX: Add `tooltip: MaterialLocalizations.of(context).backButtonTooltip`.
```

```
[BONUS] supplier_config.dart:36-556
PROBLEM: All supplier platform `color:` fields use hardcoded `Color(0xFF...)` and `Colors.blue` — banned per no-hardcoded-colors rule.
FIX: Map brand colors to `DesignTokens` semantic tokens or add brand-color constants to `DesignTokens`.
```

```
[BONUS] supplier_config.dart:163
PROBLEM: `oberlo` is listed as active but Oberlo was permanently shut down by Shopify in June 2022.
FIX: Set `isActive: false` on `oberlo` entry; add `deprecationNote` field to `SupplierPlatformConfig`.
```

```
[BONUS] product_repository.dart:83
PROBLEM: Warehouse address denormalization silently swallows all exceptions (`catch (_) {}`). `shipFromCity`/Province/Country never set on failure — silently broken.
FIX: Replace `catch (_) {}` with `catch (e) { AppError.log(e, context: 'addProduct.warehouseDenorm'); }`.
```

```
[BONUS] add_product_viewmodel.dart:74
PROBLEM: `IS_TEST` env var bypasses security checks (address verification, image requirements) without any other gate.
FIX: Remove `IS_TEST` bypass from shipped ViewModel; integration tests should use a mock `ProductRepository`.
```

---

### Stock Notifications

```
[CRITICAL] functions/products.py:_fire_back_in_stock_notifications
PROBLEM: Back-in-stock notification call is inside the early-return branch only; any update that touches a non-skip field alongside stockQuantity exits via the full-validation path and never fires notifications.
FIX: Call `_fire_back_in_stock_notifications(product_id, before_data, product_data)` unconditionally just before the final `index_product` call at the end of `on_product_updated`.
```

```
[CRITICAL] functions/products.py:subscribe_stock_notification / _fire_back_in_stock_notifications
PROBLEM: Subscriptions store only productId, no variantId. When variant A restocks, all subscribers are emailed — including those wanting variant B still out of stock.
FIX: Add `variantKey` (serialized optionValues map) to both subscription doc and fire logic; filter notifications by matching variantKey.
ALSO: lib/features/products/stock_notification_provider.dart:11 — provider family key is productId only; extend to Tuple(productId, variantKey).
ALSO: lib/screens/product/productdetails_screen.dart:576 — call payload must include variantKey.
```

```
[CRITICAL] functions/orders.py (feature absent)
PROBLEM: No code removes stock_notification entries when buyer purchases the notified product; stale subscriptions accumulate and re-fire on next restock.
FIX: After order confirmed/captured, batch-delete all stock_notifications where userId==buyer AND productId IN purchased product IDs (and matching variantKey once added).
```

```
[CRITICAL] functions/products.py:on_product_deleted
PROBLEM: on_product_deleted only removes Algolia entry; orphan stock_notification documents remain forever. Soft-delete path (ARCHIVED) also has no notification cleanup.
FIX: In `delete_product` callable (after lifecycle update), batch-delete all stock_notifications where productId == product_id. Add same cleanup to on_product_deleted for hard deletes.
```

```
[HIGH] lib/models/variant_models.dart:38
PROBLEM: ProductVariantEntry.price is double? — violates money-as-cents rule; cross-stack mismatch with Python/Firestore.
FIX: Change to `int? priceCents`, add `double get priceDollars => (priceCents ?? 0) / 100.0`; update fromMap/toMap; sync Python variant model + Product.json.
```

```
[HIGH] functions/products.py:subscribe_stock_notification (~line 1770)
PROBLEM: Out-of-stock check reads top-level stockQuantity — on a variant product, subscriber for out-of-stock variant (e.g. Size XL) is blocked with "Product is already in stock" because another variant (Size S) has stock > 0.
FIX: When product has variants, check stock of the specific requested variantKey instead of top-level stockQuantity.
```

```
[HIGH] lib/screens/product/productdetails_screen.dart:561 (_toggleNotification)
PROBLEM: Screen directly calls FirebaseFunctions.instance — violates MVVM.
FIX: Move toggle logic into StockNotificationNotifier; call ref.read(stockNotificationNotifierProvider(productId).notifier).subscribe/unsubscribe() from widget.
```

```
[MEDIUM] lib/features/products/stock_notification_provider.dart:18
PROBLEM: StockNotificationNotifier initializes with hardcoded AsyncValue.data(false) — if user already subscribed in a previous session, UI incorrectly shows "Notify me".
FIX: Add init() method that checks existing subscription state via backend/Firestore query; call from notifier constructor.
```

```
[MEDIUM] functions/products.py:_fire_back_in_stock_notifications (~line 2540)
PROBLEM: Email link is `https://orignagta.ca/products/{product_id}` — no variant anchor; users who subscribed for a specific variant land on product page with no context.
FIX: Once variantKey added, append `?variant={variantKey}` in the email CTA href.
```

```
[BONUS] functions/products.py:submit_product_rating
PROBLEM: @_firestore.transactional decorator references global _firestore which can be None if get_server_timestamp() was never called before decorator evaluation at module-import time; causes AttributeError.
FIX: Access _firestore inside the function body (not as decorator) or use @firestore.transactional after importing firestore at module level.
```

```
[BONUS] functions/products.py:vote_review_helpful
PROBLEM: helpfulVoterIds is an unbounded array on the rating document; at 100M+ users approaches Firestore's 1 MB document limit.
FIX: Move votes to subcollection review_votes/{userId} with boolean field; derive helpfulCount via counter or aggregation.
```

```
[BONUS] functions/products.py:subscribe_stock_notification
PROBLEM: createdAt set with datetime.now(UTC) instead of get_server_timestamp(); clock skew possible.
FIX: Replace datetime.now(UTC) with get_server_timestamp().
```

```
[BONUS] lib/features/products/stock_notification_provider.dart:20
PROBLEM: StateNotifierProvider.autoDispose loses subscription state when product detail screen is popped; returns to false even if subscribed.
FIX: Remove autoDispose or store subscription state in persistent provider/cache keyed by productId.
```

---

### UI Widgets / Animations / Mascot

```
[HIGH] shop_mascot.dart:511
PROBLEM: `const Color(0xFF1A1A2A)` hardcoded in MascotPainter._drawFace; bypasses DesignTokens.
FIX: replace with `DesignTokens.darkBackground` (add named constant `maskColor` if exact value differs).
```

```
[HIGH] shop_mascot.dart:585
PROBLEM: `Paint()..color = Colors.white` hardcoded for hands in MascotPainter.
FIX: replace with `DesignTokens.textOnPrimary`.
```

```
[HIGH] canadian_moose.dart:38-50
PROBLEM: `MooseTips._tips` uses raw hardcoded English strings instead of localization keys (unlike `MascotTips` which correctly uses `.tr()`); breaks i18n.
FIX: Convert to localization keys via `easy_localization` matching `mascot.*` key pattern.
```

```
[HIGH] animations.dart (widgets/):44
PROBLEM: `AnimatedEmptyState` uses `textTertiary` (#6B7280) for icon color — risk if placed on colored background.
FIX: Document intent with comment or use `textSecondary` for better contrast safety margin.
```

```
[HIGH] mascot_preview.dart:41
PROBLEM: Both autoDispose providers watched in build — swapping mascots mid-session may dispose and recreate controller mid-animation.
FIX: Store providers via `ref.read` in `initState` and pass as constructor args, or remove `autoDispose` for preview.
```

```
[MEDIUM] modern_button.dart:54-57
PROBLEM: When `isDisabled=true`, tapping still triggers `_scaleController.forward()` via GestureDetector.onTapDown — visual scale with no action.
FIX: Verify `GestureDetector.onTapDown` is null when disabled (should already be handled — re-verify end-to-end).
```

```
[MEDIUM] modern_textfield.dart:60
PROBLEM: `FocusNode _focusNode` created in initState but never passed to TextFormField — `focusNode:` property missing from constructor call.
FIX: Add `focusNode: _focusNode,` to the TextFormField widget.
```

```
[MEDIUM] shop_mascot.dart:94-101
PROBLEM: `Future.delayed(Duration(seconds: 2))` — if `widget.showSpeechBubble` changes to false during delay, bubble still appears.
FIX: Add `if (!widget.showSpeechBubble) return;` inside the delayed callback after `mounted` check.
```

```
[MEDIUM] animations.dart (core/):124
PROBLEM: ShimmerLoading uses hardcoded `Color(0xFFE0E0E0)` and `Color(0xFFF5F5F5)` — wrong in dark mode.
FIX: Replace with `DesignTokens.outline` and `DesignTokens.surfaceVariant` (or add shimmerBase/shimmerHighlight tokens).
```

```
[MEDIUM] animations.dart (core/):318
PROBLEM: AnimatedCheckmark hardcodes `Color(0xFF10B981)` as default color — this is DesignTokens.success but referenced as raw hex.
FIX: Change default to `color = DesignTokens.success`.
```

```
[MEDIUM] mascot_preview.dart:46
PROBLEM: Raw `AppBar` used instead of `ModernAppBar`/`CustomAppBar` — violates AppBar consistency rule.
FIX: Replace with `CustomAppBar(title: 'Mascot Preview')`.
```

```
[MEDIUM] responsive_layout.dart:167-179
PROBLEM: No `mobile` variant — smallest layout is `mobilePlus` (320px+), leaving `mobile` constant unused.
FIX: Add `mobile` named parameter for `width < mobilePlus`, or document `mobilePlus` covers all phones ≥ 320px intentionally.
```

```
[MEDIUM] glassmorphism.dart:31
PROBLEM: `GlassAppBar.backgroundColor` defaults to `const Color(0xFFFFFFFF)` — raw hardcoded color.
FIX: Default to `DesignTokens.surface`.
```

```
[LOW] deferred_widget.dart:38
PROBLEM: `DeferredWidget._loaded` is a static Map that grows indefinitely with no eviction.
FIX: Document this is intentional or add `clearCache()` for testing.
```

```
[LOW] modern_card.dart:47
PROBLEM: ModernCard creates AnimationController for hover but mobile never fires MouseRegion events — wasted resources.
FIX: Guard `_onHover` calls with `kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux`.
```

```
[LOW] shop_mascot.dart:606
PROBLEM: MascotPainter.shouldRepaint always returns true — repaints every frame even if nothing changed.
FIX: Compare all fields: `return idleValue != old.idleValue || jumpValue != old.jumpValue || blinkValue != old.blinkValue || breathingValue != old.breathingValue || lookTarget != old.lookTarget || excitement != old.excitement;`
```

```
[LOW] glassmorphism.dart:372
PROBLEM: SpeechBubbleTailPainter.shouldRepaint returns false unconditionally (fine) but no const constructor — new painter allocated every rebuild.
FIX: Make it a const singleton or `static const _painter = SpeechBubbleTailPainter()`.
```

```
[BONUS] modern_textfield.dart:97
PROBLEM: suffixIcon always shows 'Toggle password visibility' as semantics label even for non-password fields.
FIX: Expose `suffixIconSemanticLabel` parameter; default to 'Toggle password visibility' only when `isPassword == true`.
```

```
[BONUS] shop_mascot.dart:133-151
PROBLEM: `_launchSupportEmail` is defined but never called from any gesture handler — dead code.
FIX: Wire to tap handler on speech bubble or remove and handle email launch at screen level.
```

```
[BONUS] canadian_moose.dart:5
PROBLEM: `url_launcher` imported but likely never wired — dead import.
FIX: Verify and remove unused import/function if not wired.
```

```
[BONUS] moose_provider.dart + mascot_provider.dart
PROBLEM: Both autoDispose — in mascot_preview.dart both are ref.watch'd in build; autoDispose could tear down controller mid-animation.
FIX: Remove autoDispose from providers used in long-lived screens, or use keepAlive() inside provider body.
```

```
[BONUS] animations.dart (core/):50-60
PROBLEM: AnimatedListItem uses `Future.delayed(widget.delay * widget.index)` with no upper cap — 100 items = 5-second wait for last item.
FIX: Cap stagger: `Future.delayed(widget.delay * widget.index.clamp(0, 10), ...)`.
```

```
[BONUS] responsive_layout.dart:134-159
PROBLEM: ResponsiveGridView uses GridView.builder without shrinkWrap or bounded height — throws unbounded height if placed in Column directly.
FIX: Add `shrinkWrap: true, physics: const NeverScrollableScrollPhysics()` as optional params, or document it requires bounded parent.
```

```
[BONUS] modern_appbar.dart:37
PROBLEM: `leadingIcon` is silently ignored when `showBackButton = true` — no assertion or warning.
FIX: Add `assert(!(showBackButton && leadingIcon != null), 'leadingIcon is ignored when showBackButton is true')`.
```

```
[BONUS] custom_app_bar.dart:95
PROBLEM: _CartBadge calls Navigator.pushNamed and showLoginPrompt(context) without `if (!context.mounted) return;` guard.
FIX: Add `if (!context.mounted) return;` before navigation calls.
```
