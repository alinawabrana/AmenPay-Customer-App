import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
        ),
        title: Text(l10n.t('about'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _InfoHero(
            title: l10n.t('about_amenpay_user_app'),
            subtitle: l10n.t('about_hero_subtitle'),
            icon: const IconData(0xe853, fontFamily: 'MaterialIcons'),
            accent: const Color(0xFF238EC2),
            tint: const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: l10n.t('about_what_amenpay_title'),
            body: l10n.t('about_what_amenpay_body'),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: l10n.t('about_two_app_title'),
            body: l10n.t('about_two_app_body'),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: l10n.t('about_supported_methods_title'),
            body: l10n.t('about_supported_methods_body'),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: l10n.t('about_user_role_title'),
            body: l10n.t('about_user_role_body'),
          ),
        ],
      ),
    );
  }
}

class _InfoHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color tint;

  const _InfoHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
