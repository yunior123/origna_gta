import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/models/models.dart';
import '../test_utils.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> ensureUserDocumentExists() async {}
  @override
  Future<bool> isEmailVerified() async => false;
  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name, {
    bool marketingOptIn = false,
  }) async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signInWithApple() async {}
  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> validateCurrentUser() async => true;
  @override
  Stream<UserModel?> watchProfile(String userId) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  late FakeAuthRepository fakeAuthRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
  });

  group('LoginScreen widget tests', () {
    testWidgets('renders login screen with form fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepo)],
          child: const LoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(LoginScreenLayout), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('toggle mode shows name field in register mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepo)],
          child: const LoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('login_name_field')), findsNothing);

      final toggleBtn = find.byKey(const Key('login_toggle_mode_button'));
      await tester.ensureVisible(toggleBtn);
      await tester.pump();
      await tester.tap(toggleBtn);
      await tester.pump();

      expect(find.byKey(const Key('login_name_field')), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('LoginScreenLayout renders with all callbacks', (tester) async {
      final ec = TextEditingController();
      final pc = TextEditingController();
      final nc = TextEditingController();
      final fk = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreenLayout(
              isLogin: true,
              obscurePassword: true,
              isLoading: false,
              acceptedTerms: false,
              marketingOptIn: false,
              showGoogleSignIn: true,
              nameController: nc,
              emailController: ec,
              passwordController: pc,
              formKey: fk,
              onAuthToggle: () {},
              onAuthSubmit: () {},
              onGoogleSignIn: () {},
              onAppleSignIn: () {},
              onForgotPassword: () {},
              onToggleObscurePassword: () {},
              onTermsChanged: (_) {},
              onMarketingOptInChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);

      nc.dispose();
      ec.dispose();
      pc.dispose();
    });

    testWidgets('LoginScreenLayout hides Google button when disabled', (
      tester,
    ) async {
      final ec = TextEditingController();
      final pc = TextEditingController();
      final nc = TextEditingController();
      final fk = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreenLayout(
              isLogin: true,
              obscurePassword: true,
              isLoading: false,
              acceptedTerms: false,
              marketingOptIn: false,
              showGoogleSignIn: false,
              nameController: nc,
              emailController: ec,
              passwordController: pc,
              formKey: fk,
              onAuthToggle: () {},
              onAuthSubmit: () {},
              onGoogleSignIn: () {},
              onAppleSignIn: () {},
              onForgotPassword: () {},
              onToggleObscurePassword: () {},
              onTermsChanged: (_) {},
              onMarketingOptInChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('login_google_button')), findsNothing);

      nc.dispose();
      ec.dispose();
      pc.dispose();
    });

    testWidgets('LoginScreenLayout shows Google button when enabled', (
      tester,
    ) async {
      final ec = TextEditingController();
      final pc = TextEditingController();
      final nc = TextEditingController();
      final fk = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreenLayout(
              isLogin: true,
              obscurePassword: true,
              isLoading: false,
              acceptedTerms: false,
              marketingOptIn: false,
              showGoogleSignIn: true,
              nameController: nc,
              emailController: ec,
              passwordController: pc,
              formKey: fk,
              onAuthToggle: () {},
              onAuthSubmit: () {},
              onGoogleSignIn: () {},
              onAppleSignIn: () {},
              onForgotPassword: () {},
              onToggleObscurePassword: () {},
              onTermsChanged: (_) {},
              onMarketingOptInChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('login_google_button')), findsOneWidget);

      nc.dispose();
      ec.dispose();
      pc.dispose();
    });
  });
}
