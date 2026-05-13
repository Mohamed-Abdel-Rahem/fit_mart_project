// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitsmart/app_routes.dart';
import 'package:fitsmart/models/auth_service.dart';
import 'package:fitsmart/screens/SettingsScreen/basic_info_screen.dart';
import 'package:fitsmart/screens/SettingsScreen/change_password_screen.dart';
import 'package:fitsmart/screens/VerificationScreens/verification_screen.dart';
import 'package:fitsmart/screens/signup_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentImageUrl;

  late final AnimationController _pageController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _loadCurrentImageUrl();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutExpo,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _pageController, curve: Curves.easeOutExpo),
        );

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentImageUrl() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();

      if (userDoc.exists && mounted) {
        setState(() {
          _currentImageUrl = userDoc.get('photoUrl') as String?;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Error loading profile image: $e',
          isError: true,
        ),
      );
    }
  }

  void _handleLogout() async {
    await _authService.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        final curved = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          scale: curved,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              elevation: 0,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(0.88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.all(24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Enter Password',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: TextField(
                controller: controller,
                obscureText: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, controller.text.trim());
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDeleteAccount() async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        final curved = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          scale: curved,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              elevation: 0,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.15),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to permanently delete your account?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final userProviders = user.providerData.map((e) => e.providerId).toList();

      if (userProviders.contains('google.com')) {
        final credential = await _authService.getGoogleReauthCredential();

        if (credential == null) {
          throw Exception('Google Sign-In failed');
        }

        await user.reauthenticateWithCredential(credential);
      } else if (userProviders.contains('password')) {
        final password = await _promptForPassword();

        if (password == null) return;

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
      }

      final uid = user.uid;

      await _firestore.collection('Users').doc(uid).delete();

      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Account deleted successfully', isError: false),
      );

      _handleLogout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Error deleting account: $e', isError: true),
      );
    }
  }

  void _handleChangePassword() async {
    final user = _auth.currentUser;

    if (user == null ||
        user.providerData.any((p) => p.providerId == 'google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Password change not available for Google accounts',
          isError: true,
        ),
      );

      return;
    }

    final password = await _promptForPassword();

    if (password == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutExpo,
                      ),
                    ),
                child: const ChangePasswordScreen(),
              ),
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Verification failed: $e', isError: true),
      );
    }
  }

  void _handleUpdateProfileImage(String photoUrl) async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore.collection('Users').doc(user.uid).update({
        'photoUrl': photoUrl,
      });

      await user.updatePhotoURL(photoUrl);

      if (mounted) {
        setState(() {
          _currentImageUrl = photoUrl;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Profile image updated successfully',
          isError: false,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Error updating profile image: $e',
          isError: true,
        ),
      );
    }
  }

  SnackBar _buildSnackBar({required String message, required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;

    return SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isError
                    ? [
                        colorScheme.errorContainer.withOpacity(0.95),
                        colorScheme.error.withOpacity(0.25),
                      ]
                    : [
                        colorScheme.primaryContainer.withOpacity(0.95),
                        colorScheme.primary.withOpacity(0.18),
                      ],
              ),
              border: Border.all(
                color: isError
                    ? colorScheme.error.withOpacity(0.25)
                    : colorScheme.primary.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([_floatingController, _pulseController]),
        builder: (_, __) {
          final floatingValue = sin(_floatingController.value * 2 * pi);

          return Stack(
            children: [
              Positioned(
                top: -120 + (floatingValue * 30),
                right: -80,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.28),
                          colorScheme.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -160 - (floatingValue * 20),
                left: -100,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.tertiary.withOpacity(0.2),
                          colorScheme.tertiary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: colorScheme.surface.withOpacity(0.7),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Settings',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const Spacer(),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 34),
                            Hero(
                              tag: 'profile-image',
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (_, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.tertiary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.35,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.surface,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: CustomImagePicker(
                                      currentImageUrl: _currentImageUrl,
                                      imageSize: 82,
                                      onImageUploaded:
                                          _handleUpdateProfileImage,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 38),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 25,
                                  sigmaY: 25,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    color: colorScheme.surface.withOpacity(0.7),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withOpacity(
                                          0.08,
                                        ),
                                        blurRadius: 40,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSettingTile(
                                        index: 0,
                                        title: 'Basic Info',
                                        icon: Icons.person_outline_rounded,
                                        tooltip:
                                            'Update your name and phone number',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 600,
                                                  ),
                                              pageBuilder: (_, animation, __) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position:
                                                        Tween<Offset>(
                                                          begin: const Offset(
                                                            0.08,
                                                            0,
                                                          ),
                                                          end: Offset.zero,
                                                        ).animate(
                                                          CurvedAnimation(
                                                            parent: animation,
                                                            curve: Curves
                                                                .easeOutExpo,
                                                          ),
                                                        ),
                                                    child:
                                                        const BasicInfoScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      _buildSettingTile(
                                        index: 1,
                                        title: 'Change Password',
                                        icon: Icons.lock_reset_rounded,
                                        tooltip: 'Change your account password',
                                        onTap: _handleChangePassword,
                                      ),
                                      _buildSettingTile(
                                        index: 2,
                                        title: 'Verify Email',
                                        icon: Icons.verified_user_outlined,
                                        tooltip: 'Verify your email address',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 600,
                                                  ),
                                              pageBuilder: (_, animation, __) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position:
                                                        Tween<Offset>(
                                                          begin: const Offset(
                                                            0.08,
                                                            0,
                                                          ),
                                                          end: Offset.zero,
                                                        ).animate(
                                                          CurvedAnimation(
                                                            parent: animation,
                                                            curve: Curves
                                                                .easeOutExpo,
                                                          ),
                                                        ),
                                                    child:
                                                        const EmailVerificationScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      _buildSettingTile(
                                        index: 3,
                                        title: 'Share App',
                                        icon: Icons.share_rounded,
                                        tooltip: 'Share this app with others',
                                        onTap: () {},
                                      ),
                                      _buildSettingTile(
                                        index: 4,
                                        title: 'Sign Out',
                                        icon: Icons.logout_rounded,
                                        tooltip: 'Sign out of your account',
                                        onTap: _handleLogout,
                                      ),
                                      _buildSettingTile(
                                        index: 5,
                                        title: 'Delete Account',
                                        icon: Icons.delete_outline_rounded,
                                        tooltip:
                                            'Permanently delete your account',
                                        isDanger: true,
                                        onTap: _handleDeleteAccount,
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingTile({
    required int index,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + (index * 120)),
      curve: Curves.easeOutExpo,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Tooltip(
          message: tooltip,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (_, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutExpo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDanger
                          ? [
                              colorScheme.errorContainer.withOpacity(0.9),
                              colorScheme.error.withOpacity(0.08),
                            ]
                          : [
                              colorScheme.surfaceContainerHighest.withOpacity(
                                0.75,
                              ),
                              colorScheme.surface.withOpacity(0.45),
                            ],
                    ),
                    border: Border.all(
                      color: isDanger
                          ? colorScheme.error.withOpacity(0.15)
                          : colorScheme.outlineVariant.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDanger
                            ? colorScheme.error.withOpacity(0.06)
                            : colorScheme.primary.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDanger
                                ? [
                                    colorScheme.error,
                                    colorScheme.error.withOpacity(0.7),
                                  ]
                                : [colorScheme.primary, colorScheme.tertiary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDanger
                                  ? colorScheme.error.withOpacity(0.3)
                                  : colorScheme.primary.withOpacity(0.3),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: isDanger
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface.withOpacity(0.55),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: isDanger
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
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
    );
  }
}
