import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';
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
  setUpAll(() {
    initTestMocks();
  });
  late FakeAuthRepository fakeAuthRepo;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late GlobalKey<FormState> formKey;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  });

  group('LoginScreen Smoke Test', () {
    testWidgets('renders login screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const LoginScreen(),
        ),
      );

      // Advance animations
      await tester.pumpAndSettle();

      expect(find.text('OrignaGta'), findsOneWidget);
      expect(find.byType(LoginScreenLayout), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('toggles between login and register mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initial mode is login
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byKey(const Key('login_name_field')), findsNothing);

      // Scroll to toggle button
      final toggleButton = find.byKey(const Key('login_toggle_mode_button'));
      await tester.ensureVisible(toggleButton);
      await tester.pumpAndSettle();

      // Tap toggle button
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Should be in register mode
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const Key('login_name_field')), findsOneWidget);

      // Reset physical size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows Google sign-in when layout enables it', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreenLayout(
              isLogin: true,
              obscurePassword: true,
              isLoading: false,
              acceptedTerms: true,
              marketingOptIn: false,
              showGoogleSignIn: true,
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              formKey: formKey,
              onAuthToggle: _noop,
              onAuthSubmit: _noop,
              onGoogleSignIn: _noop,
              onAppleSignIn: _noop,
              onForgotPassword: _noop,
              onToggleObscurePassword: _noop,
              onTermsChanged: _noopChanged,
              onMarketingOptInChanged: _noopChanged,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_google_button')), findsOneWidget);
    });

    testWidgets('hides Google sign-in when layout disables it', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreenLayout(
              isLogin: true,
              obscurePassword: true,
              isLoading: false,
              acceptedTerms: true,
              marketingOptIn: false,
              showGoogleSignIn: false,
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              formKey: formKey,
              onAuthToggle: _noop,
              onAuthSubmit: _noop,
              onGoogleSignIn: _noop,
              onAppleSignIn: _noop,
              onForgotPassword: _noop,
              onToggleObscurePassword: _noop,
              onTermsChanged: _noopChanged,
              onMarketingOptInChanged: _noopChanged,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_google_button')), findsNothing);
    });
  });
}

void _noop() {}
void _noopChanged(bool? _) {}
