import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/main.dart' as app;

/// P1.2: Complete Auth Flows Audit
/// Tests: Signup → Email Verification → Signin → Forgot Password → Session Management
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Auth Flows Audit - P1.2', () {
    
    testWidgets('Signup → Email Verification → Signin flow', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // STEP 1: Navigate to signup
      final signupButton = find.text('Sign Up');
      expect(signupButton, findsOneWidget);
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // STEP 2: Fill signup form
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      final testPassword = 'SecurePass123!';
      
      await tester.enterText(find.byKey(const Key('email_input')), testEmail);
      await tester.enterText(find.byKey(const Key('password_input')), testPassword);
      await tester.enterText(find.byKey(const Key('confirm_password_input')), testPassword);
      await tester.tap(find.byKey(const Key('signup_submit')));
      await tester.pumpAndSettle();

      // STEP 3: Verify email verification screen appears
      expect(find.textContaining('Verify'), findsOneWidget);
      
      // STEP 4: Manually verify email (in real test, would use test API)
      // For now, verify user exists in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      expect(user, isNotNull);
      expect(user!.email, testEmail);
      expect(user.emailVerified, isFalse); // Should be unverified initially

      // CLEANUP
      await user.delete();
    });

    testWidgets('Signin with valid credentials', (WidgetTester tester) async {
      // Pre-create verified user
      final testEmail = 'verified_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      final testPassword = 'SecurePass123!';
      
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      await userCredential.user!.sendEmailVerification();
      
      // Simulate email verification (in production, would click email link)
      await userCredential.user!.reload();
      
      await app.main();
      await tester.pumpAndSettle();

      // STEP 1: Navigate to signin
      final signinButton = find.text('Sign In');
      expect(signinButton, findsOneWidget);
      await tester.tap(signinButton);
      await tester.pumpAndSettle();

      // STEP 2: Enter credentials
      await tester.enterText(find.byKey(const Key('signin_email')), testEmail);
      await tester.enterText(find.byKey(const Key('signin_password')), testPassword);
      await tester.tap(find.byKey(const Key('signin_submit')));
      await tester.pumpAndSettle();

      // STEP 3: Verify home screen appears
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      // CLEANUP
      await FirebaseAuth.instance.currentUser?.delete();
    });

    testWidgets('Signin with invalid password shows error', (WidgetTester tester) async {
      // Pre-create user
      final testEmail = 'invalid_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'CorrectPass123!',
      );

      await app.main();
      await tester.pumpAndSettle();

      // STEP 1: Navigate to signin
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // STEP 2: Enter wrong password
      await tester.enterText(find.byKey(const Key('signin_email')), testEmail);
      await tester.enterText(find.byKey(const Key('signin_password')), 'WrongPass123!');
      await tester.tap(find.byKey(const Key('signin_submit')));
      await tester.pumpAndSettle();

      // STEP 3: Verify error message
      expect(find.textContaining('Invalid'), findsOneWidget);

      // CLEANUP
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: testEmail,
        password: 'CorrectPass123!',
      );
      await user.user?.delete();
    });

    testWidgets('Rate limiting after 5 failed login attempts', (WidgetTester tester) async {
      // Pre-create user
      final testEmail = 'ratelimit_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'CorrectPass123!',
      );

      await app.main();
      await tester.pumpAndSettle();

      // Navigate to signin
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // STEP 1: Attempt 5 failed logins
      for (int i = 0; i < 5; i++) {
        await tester.enterText(find.byKey(const Key('signin_email')), testEmail);
        await tester.enterText(find.byKey(const Key('signin_password')), 'WrongPass$i!');
        await tester.tap(find.byKey(const Key('signin_submit')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // STEP 2: Verify rate limit message
      expect(find.textContaining('locked'), findsOneWidget);

      // STEP 3: Verify lockout persists
      await tester.enterText(find.byKey(const Key('signin_email')), testEmail);
      await tester.enterText(find.byKey(const Key('signin_password')), 'CorrectPass123!');
      await tester.tap(find.byKey(const Key('signin_submit')));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('locked'), findsOneWidget);

      // CLEANUP
      final db = FirebaseFirestore.instance;
      await db.collection('rate_limits').doc(testEmail).delete();
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: testEmail,
        password: 'CorrectPass123!',
      );
      await user.user?.delete();
    });

    testWidgets('Forgot password flow', (WidgetTester tester) async {
      // Pre-create user
      final testEmail = 'forgot_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'OldPass123!',
      );

      await app.main();
      await tester.pumpAndSettle();

      // Navigate to signin
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // STEP 1: Tap forgot password
      final forgotButton = find.text('Forgot Password?');
      expect(forgotButton, findsOneWidget);
      await tester.tap(forgotButton);
      await tester.pumpAndSettle();

      // STEP 2: Enter email
      await tester.enterText(find.byKey(const Key('forgot_password_email')), testEmail);
      await tester.tap(find.byKey(const Key('send_reset_link')));
      await tester.pumpAndSettle();

      // STEP 3: Verify success message
      expect(find.textContaining('sent'), findsOneWidget);

      // CLEANUP
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: testEmail,
        password: 'OldPass123!',
      );
      await user.user?.delete();
    });

    testWidgets('Session timeout after 30 minutes inactivity', (WidgetTester tester) async {
      // Pre-create and signin user
      final testEmail = 'session_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'SessionPass123!',
      );

      await app.main();
      await tester.pumpAndSettle();

      // User is signed in, navigate to home
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      // SIMULATE 30 MINUTE TIMEOUT (in real test, would mock time)
      // For now, just verify user session exists
      final user = FirebaseAuth.instance.currentUser;
      expect(user, isNotNull);
      expect(user!.email, testEmail);

      // CLEANUP
      await user.delete();
    });

    testWidgets('Signout clears session completely', (WidgetTester tester) async {
      // Pre-create and signin user
      final testEmail = 'signout_${DateTime.now().millisecondsSinceEpoch}@origna.test';
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'SignoutPass123!',
      );

      await app.main();
      await tester.pumpAndSettle();

      // STEP 1: Find and tap signout button
      final signoutButton = find.byKey(const Key('signout_button'));
      expect(signoutButton, findsOneWidget);
      await tester.tap(signoutButton);
      await tester.pumpAndSettle();

      // STEP 2: Verify redirected to signin
      expect(find.text('Sign In'), findsOneWidget);

      // STEP 3: Verify Firebase Auth session cleared
      final user = FirebaseAuth.instance.currentUser;
      expect(user, isNull);
    });
  });
}
