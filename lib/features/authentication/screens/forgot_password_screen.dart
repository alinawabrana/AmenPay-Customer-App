import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.forgotPassword(
        email: _emailController.text.trim(),
        securityAnswer1: _answer1Controller.text.trim(),
        securityAnswer2: _answer2Controller.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      final data = res['data'] as Map<String, dynamic>?;
      final token = data?['reset_token']?.toString() ?? '';
      final email = data?['email']?.toString() ?? _emailController.text.trim();

      context.push(
        AppRoutes.resetPasswordPath,
        extra: {'email': email, 'token': token},
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        textDirection: Directionality.of(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l10n.t('forgot_password_title'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.t('forgot_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                CustomTextField(
                  label: l10n.t('registered_email'),
                  hintText: l10n.t('enter_your_email'),
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.t('please_enter_email');
                    }
                    if (!value.contains('@')) {
                      return l10n.t('please_enter_valid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: l10n.t('security_question_1'),
                  hintText: l10n.t('your_answer'),
                  icon: Icons.school_outlined,
                  controller: _answer1Controller,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('security_answer_required')
                      : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: l10n.t('security_question_2'),
                  hintText: l10n.t('your_answer'),
                  icon: Icons.menu_book_outlined,
                  controller: _answer2Controller,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('security_answer_required')
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(l10n.t('verify_reset_password')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
