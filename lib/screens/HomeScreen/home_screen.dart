// screens/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitsmart/screens/HomeScreen/size_calculator_screen.dart';
import 'package:fitsmart/screens/TryOnScreens/virtual_try_on_screen.dart';
import 'package:fitsmart/screens/VirtualDressRoomScreen/virtual_dress_room_screen.dart';
import 'package:fitsmart/screens/ai_stylist_screen.dart';
import 'package:flutter/material.dart';
import 'package:fitsmart/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pageController;
  late AnimationController _cardsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Page entrance animation
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );

    // Cards stagger animation
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  // Helper widget to build feature cards with stagger animation
  Widget _buildFeatureCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget targetScreen,
    required int cardIndex,
  }) {
    // Calculate stagger delay for each card
    final staggerDelay = cardIndex * 0.15;
    final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Interval(staggerDelay, staggerDelay + 0.4, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(delayedAnimation),
      child: FadeTransition(
        opacity: delayedAnimation,
        child: _CardWithHoverEffect(
          context: context,
          colorScheme: colorScheme,
          icon: icon,
          title: title,
          subtitle: subtitle,
          targetScreen: targetScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    // Get user's display name or fallback to 'User'
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    // Check for user photo URL
    final userPhotoUrl = user?.photoURL;

    return Scaffold(
      // Set background color to the standard surface color
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // Use primaryContainer for consistent AppBar background
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        title: Text(
          'FitSmart',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: _pageController,
                curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HEADER AREA: With enhanced animations
                  _buildHeaderSection(
                    context: context,
                    colorScheme: colorScheme,
                    userName: userName,
                    userPhotoUrl: userPhotoUrl,
                    fadeAnimation: _fadeAnimation,
                    pulseAnimation: _scaleAnimation,
                  ),

                  const SizedBox(height: 20),

                  // FEATURE 1: Virtual Try-On Studio
                  _buildFeatureCard(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.auto_fix_high,
                    title: 'Virtual Try-On Studio',
                    subtitle: 'Seamlessly try on new clothes using AI generation.',
                    targetScreen: const VirtualTryOnScreen(),
                    cardIndex: 0,
                  ),

                  // FEATURE 2: AI Stylist
                  _buildFeatureCard(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.brush_outlined,
                    title: 'AI Stylist',
                    subtitle:
                        'Get personalized outfit recommendations and styling tips.',
                    targetScreen: const AIStylistScreen(),
                    cardIndex: 1,
                  ),

                  // FEATURE 3: Virtual Dress Room
                  _buildFeatureCard(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.checkroom,
                    title: 'Virtual Dress Room',
                    subtitle:
                        'Manage and view all your saved garments in one place.',
                    targetScreen: const VirtualDressRoomScreen(),
                    cardIndex: 2,
                  ),

                  // FEATURE 4: Smart Size Calculator
                  _buildFeatureCard(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.straighten,
                    title: 'Smart Size Calculator',
                    subtitle: 'Enter your measurements for perfect fits.',
                    targetScreen: const SizeCalculatorScreen(),
                    cardIndex: 3,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header section widget
  Widget _buildHeaderSection({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String userName,
    required String? userPhotoUrl,
    required Animation<double> fadeAnimation,
    required Animation<double> pulseAnimation,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      color: colorScheme.surface,
      child: Column(
        children: [
          // Animated User Avatar with Glow Effect
          ScaleTransition(
            scale: pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Avatar
                CircleAvatar(
                  radius: 35,
                  backgroundColor: colorScheme.primary,
                  backgroundImage: userPhotoUrl != null
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 35,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Welcome message with typewriter-like fade
          FadeTransition(
            opacity: fadeAnimation,
            child: Text(
              'Hello, $userName!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle with delayed fade
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _pageController,
                curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
              ),
            ),
            child: Text(
              'Ready to explore your smart fashion features?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful card widget with hover/tap animation effects
class _CardWithHoverEffect extends StatefulWidget {
  final BuildContext context;
  final ColorScheme colorScheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget targetScreen;

  const _CardWithHoverEffect({
    required this.context,
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.targetScreen,
  });

  @override
  State<_CardWithHoverEffect> createState() => _CardWithHoverEffectState();
}

class _CardWithHoverEffectState extends State<_CardWithHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverScale;
  late Animation<double> _hoverShadow;
  late Animation<Color?> _hoverColor;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hoverScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _hoverShadow = Tween<double>(begin: 6, end: 12).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _hoverColor = ColorTween(
      begin: widget.colorScheme.surfaceContainerHigh,
      end: widget.colorScheme.surfaceContainer,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    _hoverController.forward();
  }

  void _onHoverExit() {
    _hoverController.reverse();
  }

  void _onTap() {
    // Scale animation on tap
    _hoverController.forward().then((_) {
      _hoverController.reverse();
    });

    // Navigate to target screen
    Navigator.push(
      widget.context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: ScaleTransition(
        scale: _hoverScale,
        child: AnimatedBuilder(
          animation: _hoverShadow,
          builder: (context, child) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: _hoverColor.value,
              elevation: _hoverShadow.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: _onTap,
                highlightColor:
                    widget.colorScheme.primary.withOpacity(0.1),
                splashColor: widget.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Animated icon container
                      _AnimatedIconContainer(
                        icon: widget.icon,
                        colorScheme: widget.colorScheme,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated arrow
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(value * 4, 0),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: widget.colorScheme.outline,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated icon container
class _AnimatedIconContainer extends StatefulWidget {
  final IconData icon;
  final ColorScheme colorScheme;

  const _AnimatedIconContainer({
    required this.icon,
    required this.colorScheme,
  });

  @override
  State<_AnimatedIconContainer> createState() => _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<_AnimatedIconContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  void _startRotation() {
    _rotateController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _startRotation(),
      child: RotationTransition(
        turns: Tween<double>(begin: 0, end: 0.25).animate(
          CurvedAnimation(parent: _rotateController, curve: Curves.easeOut),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            size: 40,
            color: widget.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}