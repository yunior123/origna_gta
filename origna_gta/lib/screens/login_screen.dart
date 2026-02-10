import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

import '../features/auth/login_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final viewModel = ref.read(loginViewModelProvider.notifier);

    // Listen for success or error
    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        _onAuthSuccess();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: DesignTokens.success, behavior: SnackBarBehavior.floating));
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: DesignTokens.error, behavior: SnackBarBehavior.floating));
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DesignTokens.primary.withValues(alpha: 0.05), DesignTokens.secondary.withValues(alpha: 0.05)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20, vertical: DesignTokens.spacing24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with animation
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: DesignTokens.primaryGradient,
                                borderRadius: BorderRadius.circular(DesignTokens.radius24),
                                boxShadow: DesignTokens.shadowLg,
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                            child: const Text(
                              'OrignaGta',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            state.isLogin ? 'Welcome back to your marketplace' : 'Start selling or shopping today',
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500, letterSpacing: 0.2),
                          ),
                          const SizedBox(height: 40),

                          // Form fields in glass container
                          GlassContainer(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Column(
                                children: [
                                  if (!state.isLogin) ...[
                                    ModernTextField(
                                      label: 'Full Name',
                                      hint: 'John Doe',
                                      controller: _nameController,
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (state.isLogin) return null;
                                        if (value == null || value.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: DesignTokens.spacing16),
                                  ],
                                  ModernTextField(
                                    key: const Key('login_email_field'),
                                    label: 'Email Address',
                                    hint: 'you@example.com',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.mail_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: DesignTokens.spacing16),
                                  ModernTextField(
                                    key: const Key('login_password_field'),
                                    label: 'Password',
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    isPassword: state.obscurePassword,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: state.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    onSuffixTap: viewModel.toggleObscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 6) {
                                        return 'Minimum 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (!state.isLogin) ...[
                                    const SizedBox(height: DesignTokens.spacing16),
                                    Row(
                                      children: [
                                        Semantics(
                                          label: 'checkbox-accept-terms',
                                          child: Checkbox(
                                            value: state.acceptedTerms,
                                            onChanged: (v) => viewModel.setAcceptedTerms(v ?? false),
                                            fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return DesignTokens.primary;
                                              }
                                              return null;
                                            }),
                                          ),
                                        ),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                              children: [
                                                const TextSpan(text: 'I agree to the '),
                                                TextSpan(
                                                  text: 'Terms & Conditions',
                                                  style: const TextStyle(
                                                    color: DesignTokens.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () => openTermsOfService(context),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: const TextStyle(
                                                    color: DesignTokens.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () => openPrivacyPolicy(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Primary action button
                          ModernButton(
                            key: const Key('login_submit_button'),
                            label: state.isLogin ? 'Sign In' : 'Create Account',
                            isLoading: state.isLoading,
                            isPrimary: true,
                            onPressed: () {
                              // Terms Validation check
                              if (!state.isLogin && !state.acceptedTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please accept the Terms and Conditions to continue'),
                                    backgroundColor: DesignTokens.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                viewModel.handleAuth(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  name: !state.isLogin ? _nameController.text.trim() : null,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          if (state.isLogin) ...[
                            Semantics(
                              label: 'btn-forgot-password',
                              button: true,
                              child: TextButton(
                                onPressed: () => _showForgotPasswordDialog(context),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing12),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ModernButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata,
                              isPrimary: false,
                              isLoading: state.isLoading,
                              onPressed: state.isLoading ? null : viewModel.handleGoogleSignIn,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Toggle auth mode
                          Semantics(
                            label: 'btn-toggle-auth-mode',
                            button: true,
                            child: GestureDetector(
                              onTap: state.isLoading
                                  ? null
                                  : () {
                                      viewModel.toggleAuthMode();
                                      _formKey.currentState?.reset();
                                    },
                              child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                children: [
                                  TextSpan(text: state.isLogin ? "Don't have an account? " : 'Already have an account? '),
                                  TextSpan(
                                    text: state.isLogin ? 'Sign Up' : 'Sign In',
                                    style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  void _onAuthSuccess() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Welcome back!'), backgroundColor: DesignTokens.success, behavior: SnackBarBehavior.floating));
    Navigator.of(context).pop();
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your email to receive a password reset link.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                Semantics(
                  label: 'btn-forgot-cancel',
                  button: true,
                  child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ),
                Semantics(
                  label: 'btn-forgot-send',
                  button: true,
                  child: ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final messanger = ScaffoldMessenger.of(context);

                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSending = true);
                          try {
                            await ref.read(loginViewModelProvider.notifier).resetPassword(emailController.text.trim());
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Password reset link sent!'), backgroundColor: DesignTokens.success));
                            }
                          } catch (e) {
                            messanger.showSnackBar(const SnackBar(content: Text('Failed to send reset link'), backgroundColor: DesignTokens.error));
                          } finally {
                            setState(() => isSending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                  child: isSending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Send'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
