import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palmpay/features/authentication/providers/welcome_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/widgets/palm_icon_container.dart';
import 'package:palmpay/widgets/secured_badge.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final welcomeNotifier = ref.read(welcomeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light gray background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Secured Badge at the top right, 16px from right
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: const SecuredBadge(),
                    ),
                  ),

                  // 16px spacing between badge and logo
                  const SizedBox(height: 16),

                  // Palm Icon Container centered
                  const Center(child: PalmIconContainer()),

                  // 24px spacing below Palm Icon
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    l10n.t('app_name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 32 / 24,
                      letterSpacing: 0.1,
                      color: Color(0xFF238EC2),
                    ),
                  ),

                  // 64px vertical spacing
                  const SizedBox(height: 64),

                  // Welcome text column - Centered
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Welcome text
                      Text(
                        '${l10n.t('welcome_to')}\n${l10n.t('app_name')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 38 / 30,
                          letterSpacing: -0.5,
                          color: Color(0xFF333333),
                        ),
                      ),

                      // 15px vertical spacing
                      const SizedBox(height: 15),

                      // Bullet line
                      Text(
                        l10n.t('secure_fast_convenient'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 28 / 18,
                          letterSpacing: -0.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),

                  // 64px vertical spacing
                  const SizedBox(height: 64),

                  // Buttons section - Centered
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Elevated Button: Sign In
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            welcomeNotifier.navigateToSignIn(context);
                          },
                          child: const Text('Sign In'),
                        ),
                      ),

                      // 16px spacing
                      const SizedBox(height: 16),

                      // Outlined Button: Create Account
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            welcomeNotifier.navigateToCreateAccount(context);
                          },
                          child: const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
