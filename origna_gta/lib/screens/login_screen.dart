import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/terms_screen.dart';

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
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: const Icon(Icons.shopping_bag, size: 60, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text('OrignaGta', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text(
                          state.isLogin ? 'Welcome back!' : 'Create your account',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 48),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: [
                              if (!state.isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                                  validator: (value) {
                                    if (state.isLogin) return null;
                                    if (value == null || value.isEmpty) return 'Please enter your name';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: state.obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(state.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: viewModel.toggleObscurePassword,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              if (!state.isLogin) ...[
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: state.acceptedTerms,
                                        onChanged: (v) => viewModel.setAcceptedTerms(v ?? false),
                                        activeColor: const Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => viewModel.setAcceptedTerms(!state.acceptedTerms),
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                            children: [
                                              const TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms and Conditions',
                                                style: const TextStyle(
                                                  color: Color(0xFFFF6B35),
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration.underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                                                  },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: state.isLoading || (!state.isLogin && !state.acceptedTerms)
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      viewModel.handleAuth(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text.trim(),
                                        name: !state.isLogin ? _nameController.text.trim() : null,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: state.isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(state.isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.isLogin) ...[
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Or continue with', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: state.isLoading ? null : viewModel.handleGoogleSignIn,
                              icon: Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                              ),
                              label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                disabledBackgroundColor: Colors.grey[200],
                                disabledForegroundColor: Colors.grey[500],
                                elevation: 0,
                                side: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  viewModel.toggleAuthMode();
                                  _formKey.currentState?.reset();
                                },
                          child: Text(
                            state.isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In',
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
    ).showSnackBar(const SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
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
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
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
                              ).showSnackBar(const SnackBar(content: Text('Password reset link sent!'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            messanger.showSnackBar(const SnackBar(content: Text('Failed to send reset link'), backgroundColor: Colors.red));
                          } finally {
                            setState(() => isSending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  child: isSending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
