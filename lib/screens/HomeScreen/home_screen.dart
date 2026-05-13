// screens/home_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitsmart/screens/HomeScreen/size_calculator_screen.dart';
import 'package:fitsmart/screens/TryOnScreens/virtual_try_on_screen.dart';
import 'package:fitsmart/screens/VirtualDressRoomScreen/virtual_dress_room_screen.dart';
import 'package:fitsmart/screens/ai_stylist_screen.dart';
import 'package:flutter/material.dart';
import 'package:fitsmart/app_routes.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userPhotoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _PremiumBackground(colorScheme: colorScheme)),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'FitSmart',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildPremiumHeader(userName, userPhotoUrl, colorScheme, theme),
                          const SizedBox(height: 24),
                          _buildFeatureGrid(context, colorScheme),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String name, String? url, ColorScheme scheme, ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(2, (index) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.4),
                    child: Container(
                      width: 90 + (index * 20),
                      height: 90 + (index * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withOpacity(0.15 - (index * 0.05)),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
                Hero(
                  tag: 'user_avatar',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: scheme.primaryContainer,
                      backgroundImage: url != null ? NetworkImage(url) : null,
                      child: url == null ? Icon(Icons.person_outline, size: 40, color: scheme.primary) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome back,',
              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              name,
              style: theme.textTheme.displaySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureGrid(BuildContext context, ColorScheme scheme) {
    final features = [
      _FeatureData(Icons.auto_fix_high, 'Virtual Try-On', 'AI-powered fitting room', const VirtualTryOnScreen()),
      _FeatureData(Icons.brush_outlined, 'AI Stylist', 'Personalized recommendations', const AIStylistScreen()),
      _FeatureData(Icons.checkroom, 'Dress Room', 'Manage your collection', const VirtualDressRoomScreen()),
      _FeatureData(Icons.straighten, 'Size Calc', 'Find your perfect fit', const SizeCalculatorScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          return _PremiumFeatureCard(
            data: features[index],
            index: index,
            parentController: _mainController,
            colorScheme: scheme,
          );
        },
      ),
    );
  }
}

class _PremiumFeatureCard extends StatefulWidget {
  final _FeatureData data;
  final int index;
  final AnimationController parentController;
  final ColorScheme colorScheme;

  const _PremiumFeatureCard({
    required this.data,
    required this.index,
    required this.parentController,
    required this.colorScheme,
  });

  @override
  State<_PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<_PremiumFeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final staggerAnimation = CurvedAnimation(
      parent: widget.parentController,
      curve: Interval(0.4 + (widget.index * 0.1), 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: staggerAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: staggerAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - staggerAnimation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) => widget.data.target,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
          decoration: BoxDecoration(
            color: widget.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.colorScheme.outlineVariant.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: widget.colorScheme.shadow.withOpacity(_isPressed ? 0.02 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.data.icon, color: widget.colorScheme.primary, size: 28),
                ),
                const Spacer(),
                Text(
                  widget.data.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PremiumBackground({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(
        color1: colorScheme.primary.withOpacity(0.05),
        color2: colorScheme.secondary.withOpacity(0.03),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _BackgroundPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 150, paint..color = color1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 200, paint..color = color2);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), 180, paint..color = color1.withOpacity(0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget target;

  _FeatureData(this.icon, this.title, this.subtitle, this.target);
}