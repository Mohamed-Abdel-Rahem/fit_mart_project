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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Helper widget to build feature cards
  Widget _buildFeatureCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget targetScreen,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      // Use surfaceContainer for a slight lift from the background surface
      color: colorScheme.surfaceContainerHigh,
      elevation: 6, // Slightly reduced elevation for a flatter look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        },
        // Visual feedback on tap for "live" feel
        highlightColor: colorScheme.primary.withOpacity(0.1),
        splashColor: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Use primary color container for icon background
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Add a subtle arrow icon for interactivity cue
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: colorScheme.outline,
              ),
            ],
          ),
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
            color: colorScheme
                .onPrimaryContainer, // Adjust text color for primaryContainer
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        // Center the content within the SingleChildScrollView
        child: SingleChildScrollView(
          child: Column(
            // Use CrossAxisAlignment.stretch for full width cards
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // UPDATED Header Area: Now includes a subtle animation.
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                color: colorScheme.surface,
                child: Column(
                  children: [
                    // Animated User Avatar/Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: CircleAvatar(
                        radius:
                            35, // Slightly larger radius for animation focus
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
                    ),
                    const SizedBox(height: 16),
                    // Welcome message
                    Text(
                      'Hello, $userName!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Ready to explore your smart fashion features?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ), // Reduced spacing since the header is smaller
              // FEATURE 1: Virtual Try-On Studio
              _buildFeatureCard(
                context: context,
                colorScheme: colorScheme,
                icon: Icons.auto_fix_high,
                title: 'Virtual Try-On Studio',
                subtitle: 'Seamlessly try on new clothes using AI generation.',
                targetScreen: const VirtualTryOnScreen(),
              ),

              // NEW FEATURE 3: AI Stylist
              _buildFeatureCard(
                context: context,
                colorScheme: colorScheme,
                icon: Icons.brush_outlined,
                title: 'AI Stylist',
                subtitle:
                    'Get personalized outfit recommendations and styling tips.',
                targetScreen:
                    const AIStylistScreen(), // Placeholder: Pointing to TryOn for now
              ),

              // FEATURE 2: Virtual Dress Room
              _buildFeatureCard(
                context: context,
                colorScheme: colorScheme,
                icon: Icons.checkroom,
                title: 'Virtual Dress Room',
                subtitle:
                    'Manage and view all your saved garments in one place.',
                targetScreen: const VirtualDressRoomScreen(),
              ),
              _buildFeatureCard(
                context: context,
                colorScheme: colorScheme,
                icon: Icons.straighten,
                title: 'Smart Size Calculator',
                subtitle: 'Enter your measurements for perfect fits.',
                targetScreen: const SizeCalculatorScreen(),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
