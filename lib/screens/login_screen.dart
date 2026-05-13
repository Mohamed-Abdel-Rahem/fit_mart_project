// lib/screens/login_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitsmart/app_routes.dart';
import 'package:fitsmart/models/auth_service.dart';
import 'package:fitsmart/screens/signup_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      User? user = credential.user;

      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login failed: Profile data missing. Please sign up.',
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = '';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = 'Wrong password or invalid credentials.';
      } else {
        errorMsg = 'Login Error: ${e.message}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _authService.signInWithGoogle(
      onIncompleteProfile: (name, email) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SignUpScreen(prefillName: name, prefillEmail: email),
          ),
        );
      },
      onSuccess: () {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    if (_authService.lastError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authService.lastError!)));
      _authService.lastError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _isVisible ? 1.0 : 0.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Client Login',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Welcome back! Please login to your account.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                      0,
                      _isVisible ? 0 : 20,
                      0,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _emailController,
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainerLow,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Password',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.left,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainerLow,
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.resetPassword,
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: screenWidth,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loginAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              shadowColor: colorScheme.primary.withAlpha(150),
                            ),
                            child: Text(
                              'LOGIN',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colorScheme.onSurfaceVariant,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'OR',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colorScheme.onSurfaceVariant,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Hero(
                            tag: 'google_auth',
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: _handleGoogleSignIn,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      FontAwesomeIcons.google,
                                      size: 30,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signup,
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }
}
