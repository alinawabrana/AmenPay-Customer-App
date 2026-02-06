import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/constants/image_text.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';

import '../../authentication/models/profile/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.t('profile'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(theme: theme),
            const SizedBox(height: 24),
            Text(
              l10n.t('account_settings'),
              style: theme.textTheme.titleLarge?.copyWith(height: 28 / 18),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                _SettingsRow(
                  title: l10n.t('payment_methods'),
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFF238EC2),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  showDivider: true,
                  onTap: () => context.push(AppRoutes.paymentMethodsPath),
                ),
                _SettingsRow(
                  title: l10n.t('security_settings'),
                  icon: Icons.shield,
                  iconColor: const Color(0xFF16A34A),
                  iconBackgroundColor: const Color(0xFFF0FDF4),
                  showDivider: true,
                  onTap: () {},
                ),
                _SettingsRow(
                  title: l10n.t('notifications'),
                  icon: Icons.notifications,
                  iconColor: const Color(0xFF9333EA),
                  iconBackgroundColor: const Color(0xFFFAF5FF),
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('support'),
              style: theme.textTheme.titleLarge?.copyWith(height: 28 / 18),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                _SettingsRow(
                  title: l10n.t('help_support'),
                  icon: Icons.help,
                  iconColor: const Color(0xFFEA580C),
                  iconBackgroundColor: const Color(0xFFFFF7ED),
                  showDivider: true,
                  onTap: () {},
                ),
                _SettingsRow(
                  title: l10n.t('contact_us'),
                  icon: Icons.email,
                  iconColor: const Color(0xFF238EC2),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                _SettingsRow(
                  title: l10n.t('terms_privacy'),
                  icon: Icons.description,
                  iconColor: const Color(0xFF4B5563),
                  iconBackgroundColor: const Color(0xFFF3F4F6),
                  showDivider: true,
                  onTap: () {},
                ),
                _SettingsRow(
                  title: l10n.t('rate_our_app'),
                  icon: Icons.star,
                  iconColor: const Color(0xFFCA8A04),
                  iconBackgroundColor: const Color(0xFFFEF9C3),
                  showDivider: true,
                  onTap: () {},
                ),
                _SettingsRow(
                  title: l10n.t('about'),
                  icon: Icons.info,
                  iconColor: const Color(0xFF4B5563),
                  iconBackgroundColor: const Color(0xFFF3F4F6),
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LogoutButton(
              onPressed: () async {
                try {
                  await ApiService.logout();
                  if (context.mounted) {
                    final l10n = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.t('logout_successful')),
                        backgroundColor: const Color(0xFF00AA44),
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    context.go(AppRoutes.signInPath);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final ThemeData theme;

  const _ProfileCard({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(profileRefreshProvider);
    return Container(
      height: 268,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: FutureBuilder(
        future: Future.wait([
          ApiService.getUserDetails(),
          ApiService.getProfileImage(),
        ]),
        builder: (context, snapshot) {
          String fullname = '';
          String email = '';
          String? url;

          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
            final user = snapshot.data![0] as dynamic;
            if (user is UserModel) {
              fullname = user.fullname;
              email = user.email;
            }

            final imageRes = snapshot.data![1];
            if (imageRes is Map<String, dynamic>) {
              final v = imageRes['image_url'] ?? imageRes['imageUrl'];
              if (v is String && v.trim().isNotEmpty) {
                url = ApiService.normalizePublicImageUrl(v);
              }
            }
          }

          final ImageProvider avatarProvider = (url == null)
              ? const AssetImage(AImageText.palmPayLogo)
              : NetworkImage(url);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: (url == null)
                    ? null
                    : () {
                        showDialog<void>(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: InteractiveViewer(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.network(url!, fit: BoxFit.cover),
                                ),
                              ),
                            );
                          },
                        );
                      },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFFFFFFF),
                        offset: Offset(0, 0),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x330066CC),
                        offset: Offset(0, 0),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                    image: DecorationImage(
                      image: avatarProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fullname,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(height: 28 / 20),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.editProfilePath),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.t('edit_profile')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x00000000).withAlpha(13),
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 73,
        padding: const EdgeInsetsDirectional.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: -0.5,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            SizedBox(
              width: 20,
              height: 25,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9CA3AF),
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFECACA), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0x00000000).withAlpha(13),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 16,
                height: 14,
                child: Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.t('logout'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: const Color(0xFFDC2626)),
            ),
          ],
        ),
      ),
    );
  }
}
