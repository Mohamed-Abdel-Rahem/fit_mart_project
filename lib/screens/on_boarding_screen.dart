import 'package:fitsmart/app_routes.dart';
import 'package:fitsmart/models/onboarding_data.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _contentController;
  late AnimationController _imageController;
  late AnimationController _indicatorController;

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
  void initState() {
    super.initState();
    _pageController = PageController();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _imageController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    _contentController.reset();
    _imageController.reset();
    _indicatorController.reset();

    _contentController.forward();
    _imageController.forward();
    _indicatorController.forward();
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
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
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) {
          final routeBuilder = appRoutes[routeName];
          return routeBuilder != null
              ? routeBuilder(context)
              : const Scaffold();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return Stack(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeIn),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeIn),
                  ),
                  child: const Scaffold(),
                ),
              ),
              FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _indicatorController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _indicatorController,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(220),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _pages.asMap().entries.map((entry) {
              final isActive = _currentPage == entry.key;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onPrimary.withAlpha(150),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(100),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
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
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: _onPageChanged,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return _buildPageContent(context, _pages[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    OnboardingData data,
    int pageIndex,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
          ),
        );

    final descriptionAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
          ),
        );

    final buttonAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    final imageAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));

    return Stack(
      children: [
        Container(color: colorScheme.surface),
        Column(
          children: [
            Expanded(
              flex: 2,
              child: ScaleTransition(
                scale: imageAnimation,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _imageController,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(data.imagePath),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(flex: 2, child: SizedBox.expand(child: Container())),
          ],
        ),
        Column(
          children: [
            Expanded(flex: 2, child: Container()),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onSurface.withAlpha(50),
                        blurRadius: 15.0,
                        offset: const Offset(0, -8),
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

                      SlideTransition(
                        position: titleAnimation,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _contentController,
                              curve: const Interval(
                                0.1,
                                0.6,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: Text(
                            data.title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 32,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      if (data.subDescription != null) ...[
                        SlideTransition(
                          position: descriptionAnimation,
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _contentController,
                                    curve: const Interval(
                                      0.2,
                                      0.7,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                            child: Text(
                              data.subDescription!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      SlideTransition(
                        position: descriptionAnimation,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _contentController,
                              curve: const Interval(
                                0.25,
                                0.75,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: Text(
                            data.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer.withAlpha(
                                200,
                              ),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SlideTransition(
                        position: buttonAnimation,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _contentController,
                              curve: const Interval(
                                0.3,
                                0.8,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: _AnimatedButton(
                            screenWidth: screenWidth,
                            colorScheme: colorScheme,
                            theme: theme,
                            isLastPage: _currentPage == _pages.length - 1,
                            onPressed: _goNext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _AnimatedSkipButton(
            colorScheme: colorScheme,
            theme: theme,
            onPressed: _skip,
          ),
        ),
      ],
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final double screenWidth;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isLastPage;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.screenWidth,
    required this.colorScheme,
    required this.theme,
    required this.isLastPage,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _shadowAnimation = Tween<double>(
      begin: 8,
      end: 16,
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

  void _onPressed() {
    _hoverController.forward().then((_) {
      _hoverController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _shadowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.colorScheme.primary.withAlpha(120),
                    blurRadius: _shadowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SizedBox(
                width: widget.screenWidth * 0.7,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isLastPage ? 'Get Started' : 'Next',
                        style: widget.theme.textTheme.titleLarge?.copyWith(
                          color: widget.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        widget.isLastPage
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        color: widget.colorScheme.onPrimary,
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

class _AnimatedSkipButton extends StatefulWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onPressed;

  const _AnimatedSkipButton({
    required this.colorScheme,
    required this.theme,
    required this.onPressed,
  });

  @override
  State<_AnimatedSkipButton> createState() => _AnimatedSkipButtonState();
}

class _AnimatedSkipButtonState extends State<_AnimatedSkipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(80),
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          child: Text(
            'Skip',
            style: widget.theme.textTheme.labelLarge?.copyWith(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
