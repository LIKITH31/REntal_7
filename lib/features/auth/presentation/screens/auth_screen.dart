import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';

import '../../../../core/providers/items_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary, // #781C2E
              Theme.of(context).colorScheme.secondary, // #8B2635
              Theme.of(context).colorScheme.tertiary, // #9E2F3C
              // using surfaceTint for the 4th variation if we want a really rich gradient, or just the 3
              Theme.of(context).colorScheme.surfaceTint, // #B13843
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6EE), // Warm Cream
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 200.ms)
                      .shimmer(delay: 800.ms, duration: 1500.ms),
                  const SizedBox(height: 32),
                  Text(
                    'Rental App',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.3),
                  const SizedBox(height: 8),
                  Text(
                    'Rent & Resale Marketplace',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 48),
                  // Auth Card
                  Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_isLogin)
                                  TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (!_isLogin &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      )
                                      .animate()
                                      .fadeIn(delay: 500.ms)
                                      .slideX(begin: -0.2),
                                if (!_isLogin) const SizedBox(height: 16),
                                TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.email),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(delay: 600.ms)
                                    .slideX(begin: -0.2),
                                const SizedBox(height: 16),
                                TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      obscureText: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(delay: 700.ms)
                                    .slideX(begin: -0.2),
                                const SizedBox(height: 8),
                                if (_isLogin)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _handleForgotPassword(),
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleAuth,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                _isLogin
                                                    ? 'Sign In'
                                                    : 'Sign Up',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 800.ms)
                                    .scale(begin: const Offset(0.9, 0.9)),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleGoogleSignIn,
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        size: 32,
                                      ),
                                      label: const Text('Continue with Google'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 900.ms)
                                    .scale(begin: const Offset(0.9, 0.9)),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? "Don't have an account? Sign Up"
                                        : 'Already have an account? Sign In',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ).animate().fadeIn(delay: 1000.ms),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address to reset password'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isLogin) {
        // Sign In
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Sign Up
        final credential = await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        // Create user profile in Firestore
        if (credential?.user != null) {
          await firestoreService.createUserProfile(
            credential!.user!,
            name: _nameController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      // Navigate back on success
      // In the new flow, AuthGate handles navigation, so we just pop if pushed or let stream update handle it
      // But for now, let's keep it safe. If we are in AuthGate, state change will rebuild MainNavigator.
      // If we pushed AuthScreen, we need to pop.
      // However, we are changing Main to be AuthGate based.
      // So we might not need to pop manually if we are at root.
      // Let's assume we might be using it as a standalone screen or replaced.
      // We'll leave the pop if it can pop, but AuthGate is better.
      // For now, let's just show success.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin ? '✅ Signed in successfully!' : '✅ Account created!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();

      // Auto-switch to Sign In if account exists
      if (message.contains('An account already exists')) {
        setState(() => _isLogin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account already exists. Switched to Sign In mode.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      print('Starting Google Sign In...');
      final credential = await authService.signInWithGoogle();

      // If credential is null (cancelled), we just return
      if (credential == null) {
        print('Google Sign In cancelled by user');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      print('Google Sign In successful: ${credential.user?.uid}');

      if (credential.user != null) {
        print('Creating/updating user profile...');

        // Create/update user profile
        await firestoreService.createUserProfile(credential.user!);

        // Verify user was actually saved
        final userExists = await firestoreService.userExistsInFirestore(
          credential.user!.uid,
        );
        print('User exists in Firestore after creation: $userExists');

        print('User profile created successfully');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userExists
                  ? '✅ Signed in with Google!'
                  : '⚠️ Signed in but profile may not be saved',
            ),
            backgroundColor: userExists ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error in Google Sign In: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
