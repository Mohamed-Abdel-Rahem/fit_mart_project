// app_routes.dart
import 'package:fitsmart/screens/HomeScreen/home_screen.dart';
import 'package:fitsmart/screens/SettingsScreen/settings_screen.dart';
import 'package:fitsmart/screens/login_screen.dart';
import 'package:fitsmart/screens/on_boarding_screen.dart';
import 'package:fitsmart/screens/reset_password_screen.dart'; // Add this import
import 'package:fitsmart/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:fitsmart/screens/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/home': (context) => const HomeScreen(),
  '/signup': (context) => const SignUpScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/login': (context) => const LoginScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/reset_password': (context) => const ResetPasswordScreen(), // Add this route
};

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String resetPassword = '/reset_password'; // Add this constant
}
