import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/services/api_service.dart';

/// Provider for create account form state management
final createAccountProvider =
    StateNotifierProvider<CreateAccountNotifier, CreateAccountState>(
      (ref) => CreateAccountNotifier(),
    );

class CreateAccountState {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String securityAnswer1;
  final String securityAnswer2;
  final bool agreeToTerms;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;

  CreateAccountState({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.securityAnswer1 = '',
    this.securityAnswer2 = '',
    this.agreeToTerms = false,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  CreateAccountState copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    String? securityAnswer1,
    String? securityAnswer2,
    bool? agreeToTerms,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
  }) {
    return CreateAccountState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      securityAnswer1: securityAnswer1 ?? this.securityAnswer1,
      securityAnswer2: securityAnswer2 ?? this.securityAnswer2,
      agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
    );
  }
}

class CreateAccountNotifier extends StateNotifier<CreateAccountState> {
  CreateAccountNotifier() : super(CreateAccountState());

  void updateFullName(String value) {
    state = state.copyWith(fullName: value);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  void updateSecurityAnswer1(String value) {
    state = state.copyWith(securityAnswer1: value);
  }

  void updateSecurityAnswer2(String value) {
    state = state.copyWith(securityAnswer2: value);
  }

  void toggleAgreeToTerms() {
    state = state.copyWith(agreeToTerms: !state.agreeToTerms);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  Future<void> createAccount(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call signup API
      await ApiService.signup(
        fullName: state.fullName,
        email: state.email,
        phoneNumber: state.phoneNumber,
        password: state.password,
        passwordConfirmation: state.confirmPassword,
        securityAnswer1: state.securityAnswer1,
        securityAnswer2: state.securityAnswer2,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to home screen after successful signup
        context.go(AppRoutes.signInPath);
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

  Future<void> addCard(
    BuildContext context, {
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
    required String cardType,
    VoidCallback? onSuccess,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call add card API
      await ApiService.addCard(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        cardholderName: cardholderName,
        cardType: cardType,
      );

      onSuccess?.call();

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to home screen after successful card addition
        context.go(AppRoutes.homePath);
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

  void navigateToSignIn(BuildContext context) {
    context.go(AppRoutes.signInPath);
  }
}
