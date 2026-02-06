import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/utils/constants/image_text.dart';
import 'package:palmpay/services/storage_service.dart';

import '../services/api_service.dart';

/// Loading screen that appears after splash screen
/// Shows app initialization progress with secure connection status
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    _animateDots();
    _checkAuthAndNavigate();
  }

  /// Checks authentication and card status, then navigates accordingly
  void _checkAuthAndNavigate() async {
    // Wait a minimum loading time (e.g., 2.5s)
    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      final isAuthenticated = await StorageService.isAuthenticated();

      if (!mounted) return;

      if (!isAuthenticated) {
        // Not logged in → navigate to SignInScreen
        context.go(AppRoutes.signInPath);
      } else {
        // Logged in → check if user has cards
        final hasCardsResponse = await ApiService.checkHasCards();

        if (!mounted) return;

        // Determine if user has no card
        final noCards =
            hasCardsResponse.containsKey('message') &&
            hasCardsResponse['message'].toString().toLowerCase() ==
                'no record found';

        if (noCards) {
          context.go(AppRoutes.addCardPath);
        } else {
          context.go(AppRoutes.homePath);
        }
      }
    } catch (e) {
      // In case of any error, navigate to SignInScreen
      if (!mounted) return;
      context.go(AppRoutes.signInPath);
    }
  }

  void _animateDots() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentDot = (_currentDot + 1) % 3; // Changed to 3 dots
        });
        _animateDots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light grey background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Icon with Secured Badge - Centered
                  SizedBox(
                    width: 120, // Width to accommodate icon + badge
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // App Icon (square with rounded corners, blue gradient background, white palm)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF1E88E5), // Lighter blue at top
                                Color(0xFF238EC2), // Darker blue at bottom
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Rounded corners
                          ),
                          child: Center(
                            child: Image.asset(
                              AImageText.amenIcon,
                              width: 60,
                              height: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Secured Badge 16px from the right edge of icon (vertically centered)
                        Positioned(
                          right:
                              0, // 16px from right edge of the 96px icon = at position 0 of the 120px container
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(26),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield,
                              size: 18,
                              color: Color(0xFF238EC2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 24px spacing
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    l10n.t('app_name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 32 / 24,
                      letterSpacing: 0.1,
                      color: Color(0xFF333333), // Dark grey
                    ),
                  ),

                  // 8px spacing
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    l10n.t('secure_vein_payment'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                      color: Color(0xFF4B5563), // Light grey
                    ),
                  ),

                  // 24px spacing
                  const SizedBox(height: 24),

                  // Progress Indicator (3 dots) - Centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index < _currentDot
                              ? const Color(0xFF238EC2) // Blue for active dots
                              : const Color(
                                  0xFFE5E7EB,
                                ), // Light grey for inactive dots
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  // Large spacer to push bottom content down
                  const SizedBox(height: 120),

                  // Loading Spinner - Centered
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE5E7EB),
                    ), // Light grey
                    strokeWidth: 2,
                  ),

                  // 16px spacing
                  const SizedBox(height: 16),

                  // Connection Status: "Initializing secure connection..." - Centered
                  Text(
                    l10n.t('initializing_secure_connection'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                      letterSpacing: -0.5,
                      color: Color(0xFF9CA3AF), // Light grey
                    ),
                  ),

                  // 12px spacing
                  const SizedBox(height: 12),

                  // Encryption Details: "256-bit Encryption" with padlock icon - Centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 14,
                        color: Color(0xFF238EC2), // Blue padlock
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.t('encryption_256_bit'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                          letterSpacing: -0.5,
                          color: Color(0xFF9CA3AF), // Light grey
                        ),
                      ),
                    ],
                  ),

                  // 24px spacing
                  const SizedBox(height: 24),

                  // Version Number: "Version 2.1.0" - Centered
                  Text(
                    l10n.t('version_number'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
                      letterSpacing: -0.5,
                      color: Color(0xFFD1D5DB), // Very light grey
                    ),
                  ),

                  // Bottom padding
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
