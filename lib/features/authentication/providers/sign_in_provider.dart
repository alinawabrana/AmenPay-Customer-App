import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';

/// Provider for sign in form state management
final signInProvider = StateNotifierProvider<SignInNotifier, SignInState>(
  (ref) => SignInNotifier(),
);

class SignInState {
  final String email;
  final String password;
  final bool rememberMe;
  final bool isPasswordVisible;

  SignInState({
    this.email = '',
    this.password = '',
    this.rememberMe = false,
    this.isPasswordVisible = false,
  });

  SignInState copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? isPasswordVisible,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }
}

class SignInNotifier extends StateNotifier<SignInState> {
  SignInNotifier() : super(SignInState());

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> signIn(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call login API
      await ApiService.login(email: state.email, password: state.password);

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('login_successful')),
            backgroundColor: const Color(0xFF00AA44),
          ),
        );
      }

      // Check if user has cards
      try {
        final hasCardsResponse = await ApiService.checkHasCards();

        if (context.mounted) {
          // Check if response contains "no record found" message
          if (hasCardsResponse.containsKey('message') &&
              hasCardsResponse['message'] == 'no record found') {
            // Navigate to add payment card screen
            context.go(AppRoutes.addCardPath);
          } else {
            // Navigate to home screen
            context.go(AppRoutes.homePath);
          }
        }
      } catch (e) {
        // If check cards fails, navigate to add payment card screen
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          context.go(AppRoutes.addCardPath);
        }
      }
    } catch (e) {
      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void navigateToCreateAccount(BuildContext context) {
    context.push(AppRoutes.createAccountPath);
  }
}
