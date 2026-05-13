import 'package:fitsmart/app_routes.dart';
import 'package:fitsmart/models/onboarding_data.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Virtual Try-On',
      description:
          'Preview new clothes on your personal photos to see how they fit and look before you buy.',
      subDescription:
          'Upload a photo and instantly layer clothing items onto your image.',
      imagePath: 'assets/images/closet_icon.jpeg',
    ),
    OnboardingData(
      title: 'Your Smart Closet',
      description:
          'Save your favorite outfits, track your try-on history, and organize all the clothes you own digitally.',
      subDescription: 'Track owned items and visualize perfect coordination.',
      imagePath: 'assets/images/donate_icon.jpeg',
    ),
    OnboardingData(
      title: 'Donate & Inspire',
      description:
          'Easily find local charities to donate your old clothes and contribute to sustainable fashion.',
      subDescription: 'Promote sustainable fashion and support those in need.',
      imagePath: 'assets/images/vto_icon.jpeg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pushWithAnimation(AppRoutes.signup);
    }
  }

  void _skip() {
    _pushWithAnimation(AppRoutes.signup);
  }

  void _pushWithAnimation(String routeName) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          final routeBuilder = appRoutes[routeName];
          return routeBuilder != null ? routeBuilder(context) : const Scaffold();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.05), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(179),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _pages.asMap().entries.map((entry) {
          final isActive = _currentPage == entry.key;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? colorScheme.primary : colorScheme.onPrimary,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            return _buildPageContent(context, _pages[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, OnboardingData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              height: screenHeight * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(data.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withAlpha(50),
                      blurRadius: 15.0,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildPageIndicator(colorScheme)),
                    const SizedBox(height: 32),
                    Text(
                      data.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (data.subDescription != null) ...[
                      Text(
                        data.subDescription!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      data.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer.withAlpha(179),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.7,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: colorScheme.primary.withAlpha(150),
                            ),
                            onPressed: _goNext,
                            child: Text(
                              (_currentPage == _pages.length - 1)
                                  ? 'Get Started'
                                  : 'Next',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          child: TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 18,
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black.withAlpha(128),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}