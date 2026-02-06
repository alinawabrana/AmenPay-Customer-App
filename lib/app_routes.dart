import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/features/authentication/screens/add_payment_card_screen.dart';
import 'package:palmpay/features/authentication/screens/create_account_screen.dart';
import 'package:palmpay/features/authentication/screens/sign_in_screen.dart';
import 'package:palmpay/features/home/screens/home_screen.dart';
import 'package:palmpay/features/qr_code/screens/my_qr_code_screen.dart';
import 'package:palmpay/features/payment_methods/screens/enroll_palm_vein_screen.dart';
import 'package:palmpay/features/payment_methods/screens/nfc_card_screen.dart';
import 'package:palmpay/features/payment_methods/screens/palm_vein_screen.dart';
import 'package:palmpay/features/payment_methods/screens/payment_methods_screen.dart';
import 'package:palmpay/features/settings/screens/edit_profile_screen.dart';
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
  static const String myQrCodePath = '/my-qr-code';
  static const String editProfilePath = '/edit-profile';

  static const String paymentMethodsPath = '/payment-methods';
  static const String paymentMethodsQrPath = '/payment-methods/qr';
  static const String paymentMethodsNfcPath = '/payment-methods/nfc';
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
        path: myQrCodePath,
        builder: (context, state) => const MyQrCodeScreen(),
      ),
      GoRoute(
        path: editProfilePath,
        builder: (context, state) => const EditProfileScreen(),
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
                builder: (context, state) => const EnrollPalmVeinScreen(),
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
                builder: (context, state) =>
                    const _PlaceholderTabScreen(title: 'Analytics'),
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

class _PlaceholderTabScreen extends StatelessWidget {
  final String title;

  const _PlaceholderTabScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
