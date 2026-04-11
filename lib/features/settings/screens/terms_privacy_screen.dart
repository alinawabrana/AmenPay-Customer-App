import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

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
        title: Text(l10n.t('terms_privacy'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _PolicySection(
            title: l10n.t('terms_use_app_title'),
            body: l10n.t('terms_use_app_body'),
          ),
          const SizedBox(height: 16),
          _PolicySection(
            title: l10n.t('terms_payments_title'),
            body: l10n.t('terms_payments_body'),
          ),
          const SizedBox(height: 16),
          _PolicySection(
            title: l10n.t('terms_card_data_title'),
            body: l10n.t('terms_card_data_body'),
          ),
          const SizedBox(height: 16),
          _PolicySection(
            title: l10n.t('terms_privacy_security_title'),
            body: l10n.t('terms_privacy_security_body'),
          ),
          const SizedBox(height: 16),
          _PolicySection(
            title: l10n.t('terms_support_compliance_title'),
            body: l10n.t('terms_support_compliance_body'),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

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
