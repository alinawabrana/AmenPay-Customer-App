import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';

/// Provider for welcome screen state management
final welcomeProvider = Provider((ref) {
  return WelcomeNotifier();
});

class WelcomeNotifier {
  /// Navigate to sign in screen
  void navigateToSignIn(BuildContext context) {
    context.go(AppRoutes.signInPath);
  }

  /// Navigate to create account screen
  void navigateToCreateAccount(BuildContext context) {
    context.push(AppRoutes.createAccountPath);
  }

  /// Navigate as guest
  void navigateAsGuest(BuildContext context) {
    // TODO: Implement guest navigation
  }
}
