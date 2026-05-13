// // ignore_for_file: use_build_context_synchronously

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fitsmart/screens/signup_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fitsmart/app_routes.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );

//     _scaleAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
//     );

//     _controller.forward();

//     Timer(const Duration(seconds: 3), _navigateBasedOnAuth);
//   }

//   Future<void> _navigateBasedOnAuth() async {
//     User? currentUser = _auth.currentUser;

//     if (currentUser == null) {
//       _pushWithAnimation(AppRoutes.onboarding, isNamed: true);
//       return;
//     }

//     try {
//       DocumentSnapshot userDoc = await _firestore
//           .collection('Users')
//           .doc(currentUser.uid)
//           .get();

//       if (userDoc.exists) {
//         _pushWithAnimation(AppRoutes.home, isNamed: true);
//       } else {
//         _pushWithAnimation(
//           SignUpScreen(
//             prefillName: currentUser.displayName,
//             prefillEmail: currentUser.email,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error checking profile: $e')));
//       }
//       _pushWithAnimation(AppRoutes.onboarding, isNamed: true);
//     }
//   }

//   void _pushWithAnimation(dynamic target, {bool isNamed = false}) {
//     Navigator.pushReplacement(
//       context,
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 800),
//         pageBuilder: (context, animation, secondaryAnimation) {
//           if (isNamed) {
//             final routeBuilder = appRoutes[target];
//             return routeBuilder != null
//                 ? routeBuilder(context)
//                 : const Scaffold();
//           }
//           return target as Widget;
//         },
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(
//             opacity: animation,
//             child: SlideTransition(
//               position: animation.drive(
//                 Tween(
//                   begin: const Offset(0.0, 0.05),
//                   end: Offset.zero,
//                 ).chain(CurveTween(curve: Curves.easeOut)),
//               ),
//               child: child,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               colorScheme.primary,
//               colorScheme.secondary,
//               colorScheme.primaryContainer,
//             ],
//             stops: const [0.0, 0.6, 1.0],
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Image.asset(
//                     'assets/icon/logo.png',
//                     height: 150,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Text(
//                   'FitSmart',
//                   style: theme.textTheme.displaySmall?.copyWith(
//                     color: colorScheme.onPrimary,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 2.0,
//                     shadows: [
//                       Shadow(
//                         blurRadius: 10.0,
//                         color: colorScheme.onSurface.withAlpha(77),
//                         offset: const Offset(2, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 64),
//               SizedBox(
//                 width: 32,
//                 height: 32,
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     colorScheme.onPrimary,
//                   ),
//                   strokeWidth: 3,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitsmart/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      _pushWithAnimation(AppRoutes.onboarding, isNamed: true);
    });
  }

  void _pushWithAnimation(dynamic target, {bool isNamed = false}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          if (isNamed) {
            final routeBuilder = appRoutes[target];
            return routeBuilder != null
                ? routeBuilder(context)
                : const Scaffold();
          }
          return target as Widget;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.primaryContainer,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/icon/logo.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'FitSmart',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: colorScheme.onSurface.withAlpha(77),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
