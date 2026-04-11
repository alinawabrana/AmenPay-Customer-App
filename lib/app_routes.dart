import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/features/authentication/screens/add_payment_card_screen.dart';
import 'package:palmpay/features/authentication/screens/create_account_screen.dart';
import 'package:palmpay/features/authentication/screens/forgot_password_screen.dart';
import 'package:palmpay/features/authentication/screens/reset_password_screen.dart';
import 'package:palmpay/features/authentication/screens/sign_in_screen.dart';
import 'package:palmpay/features/analytics/screens/analytics_screen.dart';
import 'package:palmpay/features/home/screens/home_screen.dart';
import 'package:palmpay/features/qr_code/screens/my_qr_code_screen.dart';
import 'package:palmpay/features/payment_methods/screens/enroll_palm_vein_screen.dart';
import 'package:palmpay/features/payment_methods/screens/nfc_card_screen.dart';
import 'package:palmpay/features/payment_methods/screens/palm_vein_screen.dart';
import 'package:palmpay/features/payment_methods/screens/payment_methods_screen.dart';
import 'package:palmpay/features/settings/screens/edit_profile_screen.dart';
import 'package:palmpay/features/settings/screens/notifications_screen.dart';
import 'package:palmpay/features/settings/screens/about_screen.dart';
import 'package:palmpay/features/settings/screens/contact_us_screen.dart';
import 'package:palmpay/features/settings/screens/terms_privacy_screen.dart';
import 'package:palmpay/screens/loading_screen.dart';

import 'features/settings/screens/profile_screen.dart';

typedef TabShellBuilder =
    Widget Function(
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    );

class AppRoutes {
  static const String loadingPath = '/loading';
  static const String signInPath = '/signin';
  static const String createAccountPath = '/create-account';
  static const String addCardPath = '/add-card';
  static const String forgotPasswordPath = '/forgot-password';
  static const String resetPasswordPath = '/reset-password';
  static const String myQrCodePath = '/my-qr-code';
  static const String editProfilePath = '/edit-profile';
  static const String notificationsPath = '/notifications';
  static const String contactUsPath = '/contact-us';
  static const String termsPrivacyPath = '/terms-privacy';
  static const String aboutPath = '/about';

  static const String paymentMethodsPath = '/payment-methods';
  static const String paymentMethodsQrPath = '/payment-methods/qr';
  static const String paymentMethodsNfcPath = '/payment-methods/nfc';
  static const String paymentMethodsNfcEnrollPath =
      '/payment-methods/nfc/enroll';
  static const String paymentMethodsPalmPath = '/payment-methods/palm';
  static const String paymentMethodsPalmEnrollPath =
      '/payment-methods/palm/enroll';

  static const String homePath = '/home';
  static const String analyticsPath = '/analytics';
  static const String cardPath = '/card';
  static const String settingsPath = '/settings';

  static List<RouteBase> routes({required TabShellBuilder tabShellBuilder}) {
    return [
      GoRoute(
        path: loadingPath,
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: signInPath,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: createAccountPath,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: addCardPath,
        builder: (context, state) => const AddPaymentCardScreen(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: resetPasswordPath,
        builder: (context, state) {
          final extra = (state.extra ?? const <String, dynamic>{})
              as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: extra['email']?.toString() ?? '',
            token: extra['token']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: myQrCodePath,
        builder: (context, state) => const MyQrCodeScreen(),
      ),
      GoRoute(
        path: editProfilePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: notificationsPath,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: contactUsPath,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: termsPrivacyPath,
        builder: (context, state) => const TermsPrivacyScreen(),
      ),
      GoRoute(
        path: aboutPath,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: paymentMethodsPath,
        builder: (context, state) => const PaymentMethodsScreen(),
        routes: [
          GoRoute(
            path: 'qr',
            builder: (context, state) => const MyQrCodeScreen(),
          ),
          GoRoute(
            path: 'nfc',
            builder: (context, state) => const NfcCardScreen(),
            routes: [
              GoRoute(
                path: 'enroll',
                builder: (context, state) => NfcEnrollScreen(
                  args: (state.extra ?? const <String, dynamic>{})
                      as Map<String, dynamic>,
                ),
              ),
              GoRoute(
                path: 'detail',
                builder: (context, state) => NfcCardDetailScreen(
                  args:
                      (state.extra ?? const <String, dynamic>{})
                          as Map<String, dynamic>,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'palm',
            builder: (context, state) => const PalmVeinScreen(),
            routes: [
              GoRoute(
                path: 'enroll',
                builder: (context, state) {
                  final extra = (state.extra ?? const <String, dynamic>{})
                      as Map<String, dynamic>;
                  final raw =
                      extra['payment_method_id'] ??
                      extra['paymentMethodId'] ??
                      extra['id'];
                  final id =
                      raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
                  final rawCard =
                      extra['card_id'] ?? extra['cardId'] ?? extra['card_id'];
                  final cardId =
                      rawCard is num ? rawCard.toInt() : int.tryParse('$rawCard');
                  return EnrollPalmVeinScreen(
                    paymentMethodId: id,
                    cardId: cardId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: tabShellBuilder,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: homePath,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: analyticsPath,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: cardPath,
                builder: (context, state) => const NfcCardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: settingsPath,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
