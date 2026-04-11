import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMail() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    final subject = _subjectController.text.trim().isEmpty
        ? 'AmenPay Support Request'
        : _subjectController.text.trim();
    final body = '''
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}

Message:
${_messageController.text.trim()}
''';

    final uri = Uri(
      scheme: 'mailto',
      path: 'huzaifafarooq164@gmail.com',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('contact_no_mail_app')),
        ),
      );
    }
  }

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
        title: Text(l10n.t('contact_us'), style: ATextTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  l10n.t('contact_intro'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ContactField(
                controller: _nameController,
                label: l10n.t('full_name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.t('please_enter_full_name')
                    : null,
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _emailController,
                label: l10n.t('email_address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return l10n.t('please_enter_email');
                  if (!text.contains('@')) return l10n.t('please_enter_valid_email');
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _subjectController,
                label: l10n.t('subject'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.t('contact_subject_required')
                    : null,
              ),
              const SizedBox(height: 14),
              _ContactField(
                controller: _messageController,
                label: l10n.t('message'),
                minLines: 6,
                maxLines: 8,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.t('contact_message_required')
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _sendMail,
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.t('contact_send_message')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ContactField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
