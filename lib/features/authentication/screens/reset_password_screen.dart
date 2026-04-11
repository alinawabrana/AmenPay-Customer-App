import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      await ApiService.resetPassword(
        email: widget.email,
        token: widget.token,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('password_reset_success')),
          backgroundColor: const Color(0xFF00AA44),
        ),
      );
      context.go(AppRoutes.signInPath);
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
                    l10n.t('reset_password_title'),
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
                    l10n.t('reset_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                CustomTextField(
                  label: l10n.t('password'),
                  hintText: l10n.t('create_a_password'),
                  icon: Icons.lock_outline,
                  obscureText: !_passwordVisible,
                  controller: _passwordController,
                  onVisibilityToggle: (_) {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_enter_password');
                    }
                    if (value.length < 8) {
                      return l10n.t('password_min_length');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: l10n.t('confirm_password'),
                  hintText: l10n.t('confirm_password'),
                  icon: Icons.lock_outline,
                  obscureText: !_confirmPasswordVisible,
                  controller: _confirmPasswordController,
                  onVisibilityToggle: (_) {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.t('please_confirm_password');
                    }
                    if (value != _passwordController.text) {
                      return l10n.t('passwords_do_not_match');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(l10n.t('submit')),
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
